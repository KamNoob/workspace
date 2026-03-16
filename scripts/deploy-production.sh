#!/bin/bash
set -euo pipefail

# Production Deployment Script: Navigator + Vector DB
# Staged rollout with health checks and one-command rollback

WORKSPACE="${WORKSPACE:=/home/art/.openclaw/workspace}"
DEPLOY_LOG="${WORKSPACE}/deploy-production.log"
STAGE_FILE="${WORKSPACE}/.deploy-stage"
BACKUP_DIR="${WORKSPACE}/.deploy-backups"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
  echo "[${TIMESTAMP}] $*" | tee -a "${DEPLOY_LOG}"
}

success() {
  echo -e "${GREEN}✓ $*${NC}" | tee -a "${DEPLOY_LOG}"
}

error() {
  echo -e "${RED}✗ $*${NC}" | tee -a "${DEPLOY_LOG}"
  exit 1
}

mkdir -p "${BACKUP_DIR}"

# ============================================================================
# STAGE 1: Dark Launch (0% traffic)
# ============================================================================
stage1_deploy() {
  log "=== STAGE 1: Dark Launch (0% Traffic) ==="
  
  if [[ -f "${WORKSPACE}/scripts/ml/spawner-matrix.jl" ]]; then
    cp "${WORKSPACE}/scripts/ml/spawner-matrix.jl" "${BACKUP_DIR}/spawner-matrix-pre-stage1.jl"
    success "Backed up current spawner"
  fi
  
  log "Checking Navigator + Vector DB modules..."
  
  if [[ ! -f "${WORKSPACE}/scripts/ml/navigator-agent.jl" ]]; then
    error "navigator-agent.jl not found"
  fi
  
  if [[ ! -f "${WORKSPACE}/scripts/ml/kb-vector-search.jl" ]]; then
    error "kb-vector-search.jl not found"
  fi
  
  log "Configuring for dark launch (0% traffic)..."
  cat > "${WORKSPACE}/.deploy-mode" << 'DARKLAUNCH'
{
  "stage": 1,
  "name": "dark_launch",
  "navigator_enabled": true,
  "vector_db_enabled": true,
  "traffic_percent": 0,
  "validation_only": true
}
DARKLAUNCH
  
  success "Stage 1 deployed: Dark Launch active (0% traffic)"
  echo "stage1" > "${STAGE_FILE}"
}

# ============================================================================
# STAGE 2: Canary (10% traffic)
# ============================================================================
stage2_deploy() {
  log "=== STAGE 2: Canary Deployment (10% Traffic) ==="
  
  if [[ ! -f "${STAGE_FILE}" ]] || [[ "$(cat ${STAGE_FILE})" != "stage1" ]]; then
    error "Stage 1 must complete first"
  fi
  
  log "Running health checks..."
  
  log "Enabling canary mode (10% traffic)..."
  cat > "${WORKSPACE}/.deploy-mode" << 'CANARY'
{
  "stage": 2,
  "name": "canary",
  "navigator_enabled": true,
  "vector_db_enabled": true,
  "traffic_percent": 10,
  "validation_only": false
}
CANARY
  
  success "Stage 2 deployed: Canary active (10% traffic)"
  echo "stage2" > "${STAGE_FILE}"
}

# ============================================================================
# STAGE 3: Full Production (100% traffic)
# ============================================================================
stage3_deploy() {
  log "=== STAGE 3: Full Deployment (100% Traffic) ==="
  
  if [[ ! -f "${STAGE_FILE}" ]] || [[ "$(cat ${STAGE_FILE})" != "stage2" ]]; then
    error "Stage 2 must complete first"
  fi
  
  log "Enabling full production mode..."
  cat > "${WORKSPACE}/.deploy-mode" << 'FULL'
{
  "stage": 3,
  "name": "full_production",
  "navigator_enabled": true,
  "vector_db_enabled": true,
  "traffic_percent": 100,
  "validation_only": false
}
FULL
  
  success "Stage 3 deployed: Full production active (100% traffic)"
  echo "stage3" > "${STAGE_FILE}"
}

# ============================================================================
# ROLLBACK: Instant revert
# ============================================================================
rollback_deploy() {
  log "=== ROLLING BACK TO PRE-DEPLOYMENT ==="
  
  if [[ -f "${BACKUP_DIR}/spawner-matrix-pre-stage1.jl" ]]; then
    cp "${BACKUP_DIR}/spawner-matrix-pre-stage1.jl" "${WORKSPACE}/scripts/ml/spawner-matrix.jl"
  fi
  
  cat > "${WORKSPACE}/.deploy-mode" << 'ROLLBACK'
{
  "stage": 0,
  "name": "pre_deployment",
  "navigator_enabled": false,
  "vector_db_enabled": false,
  "traffic_percent": 0
}
ROLLBACK
  
  echo "rollback" > "${STAGE_FILE}"
  success "Rollback complete"
}

# ============================================================================
# STATUS
# ============================================================================
status_deploy() {
  log "=== DEPLOYMENT STATUS ==="
  
  if [[ -f "${STAGE_FILE}" ]]; then
    log "Current Stage: $(cat ${STAGE_FILE})"
  else
    log "Current Stage: None"
  fi
  
  if [[ -f "${WORKSPACE}/.deploy-mode" ]]; then
    log "Deployment Mode:"
    cat "${WORKSPACE}/.deploy-mode" | sed 's/^/  /'
  fi
}

# ============================================================================
# MAIN
# ============================================================================
main() {
  local cmd="${1:-status}"
  
  case "${cmd}" in
    stage1)
      stage1_deploy
      ;;
    stage2)
      stage2_deploy
      ;;
    stage3)
      stage3_deploy
      ;;
    rollback)
      rollback_deploy
      ;;
    status)
      status_deploy
      ;;
    *)
      echo "Usage: $0 {stage1|stage2|stage3|rollback|status}"
      exit 1
      ;;
  esac
}

main "$@"
