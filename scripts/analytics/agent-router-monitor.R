#!/usr/bin/env Rscript
# agent-router-monitor.R
#
# Phase 3C: Agent Router Monitoring Dashboard
#
# Tracks prediction accuracy, success rates by agent/method,
# and visualizes performance trends.
#
# Usage:
#   Rscript scripts/analytics/agent-router-monitor.R status
#   Rscript scripts/analytics/agent-router-monitor.R summary
#   Rscript scripts/analytics/agent-router-monitor.R accuracy
#   Rscript scripts/analytics/agent-router-monitor.R export
#
# Output: Tables + metrics to console (pure R, no dependencies)

# ============================================================================
# Configuration
# ============================================================================

PREDICTIONS_LOG <- "data/rl/agent-router-predictions.jsonl"
TASK_OUTCOMES_LOG <- "data/rl/rl-task-execution-log.jsonl"

# ============================================================================
# Pure R JSON parsing (minimal)
# ============================================================================

parse_json_line <- function(line) {
  # Simple JSON line parser for our flat structure
  # Format: {"timestamp":"...", "task":"...", "agent":"...", "method":"...", "confidence":0.5}
  
  line <- trimws(line)
  if (nchar(line) == 0 || substr(line, 1, 1) != "{") return(NULL)
  
  record <- list()
  
  # Extract timestamp
  ts_match <- regexpr('"timestamp":"([^"]+)"', line, perl = TRUE)
  if (ts_match > 0) {
    ts_text <- regmatches(line, ts_match)
    record$timestamp <- sub('"timestamp":"', "", sub('"', "", ts_text))
  }
  
  # Extract task
  task_match <- regexpr('"task":"([^"]+)"', line, perl = TRUE)
  if (task_match > 0) {
    task_text <- regmatches(line, task_match)
    record$task <- sub('"task":"', "", sub('"', "", task_text))
  }
  
  # Extract agent
  agent_match <- regexpr('"agent":"([^"]+)"', line, perl = TRUE)
  if (agent_match > 0) {
    agent_text <- regmatches(line, agent_match)
    record$agent <- sub('"agent":"', "", sub('"', "", agent_text))
  }
  
  # Extract method
  method_match <- regexpr('"method":"([^"]+)"', line, perl = TRUE)
  if (method_match > 0) {
    method_text <- regmatches(line, method_match)
    record$method <- sub('"method":"', "", sub('"', "", method_text))
  }
  
  # Extract confidence
  conf_match <- regexpr('"confidence":([0-9.]+)', line, perl = TRUE)
  if (conf_match > 0) {
    conf_text <- regmatches(line, conf_match)
    record$confidence <- as.numeric(sub('"confidence":', "", conf_text))
  }
  
  # Extract success (optional)
  success_match <- regexpr('"success":(true|false)', line, perl = TRUE)
  if (success_match > 0) {
    success_text <- regmatches(line, success_match)
    record$success <- as.logical(sub('"success":', "", success_text))
  }
  
  return(if (length(record) > 0) record else NULL)
}

load_predictions <- function() {
  # Load predictions from JSONL log
  if (!file.exists(PREDICTIONS_LOG)) {
    cat("No predictions log found\n")
    return(data.frame())
  }
  
  lines <- readLines(PREDICTIONS_LOG)
  predictions <- list()
  
  for (line in lines) {
    record <- parse_json_line(line)
    if (!is.null(record)) {
      predictions[[length(predictions) + 1]] <- record
    }
  }
  
  if (length(predictions) == 0) {
    return(data.frame())
  }
  
  # Convert list of lists to data frame
  df <- do.call(rbind, lapply(predictions, function(x) {
    data.frame(
      timestamp = x$timestamp %||% NA,
      task = x$task %||% NA,
      agent = x$agent %||% NA,
      method = x$method %||% NA,
      confidence = x$confidence %||% NA,
      stringsAsFactors = FALSE
    )
  }))
  
  return(df)
}

# Null coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# ============================================================================
# Analysis Functions
# ============================================================================

status_report <- function(predictions) {
  # Print status report
  cat("\n📊 Agent Router Status\n")
  cat("=======================\n\n")
  
  if (nrow(predictions) == 0) {
    cat("No predictions yet\n")
    return()
  }
  
  cat(sprintf("Total predictions: %d\n", nrow(predictions)))
  
  cat("\nPredictions by method:\n")
  method_counts <- table(predictions$method)
  print(method_counts)
  
  cat("\nPredictions by agent:\n")
  agent_counts <- sort(table(predictions$agent), decreasing = TRUE)
  print(agent_counts)
  
  cat("\nPredictions by task:\n")
  task_counts <- sort(table(predictions$task), decreasing = TRUE)
  print(task_counts)
  
  cat("\nConfidence statistics:\n")
  cat(sprintf("  Mean: %.3f\n", mean(predictions$confidence, na.rm = TRUE)))
  cat(sprintf("  Median: %.3f\n", median(predictions$confidence, na.rm = TRUE)))
  cat(sprintf("  Min: %.3f\n", min(predictions$confidence, na.rm = TRUE)))
  cat(sprintf("  Max: %.3f\n", max(predictions$confidence, na.rm = TRUE)))
  cat(sprintf("  High confidence (≥0.6): %d (%.1f%%)\n",
              sum(predictions$confidence >= 0.6, na.rm = TRUE),
              100 * mean(predictions$confidence >= 0.6, na.rm = TRUE)))
}

summary_report <- function(predictions) {
  # Print summary report
  cat("\n📈 Agent Router Summary\n")
  cat("=======================\n\n")
  
  status_report(predictions)
  
  cat("\n✅ Method Distribution\n")
  cat("---------------------\n")
  
  methods <- predictions$method
  nn_count <- sum(methods == "neural_network", na.rm = TRUE)
  ql_count <- sum(methods == "qlearning", na.rm = TRUE)
  
  cat(sprintf("Neural Network: %d (%.1f%%)\n", 
              nn_count, 
              100 * nn_count / length(methods)))
  cat(sprintf("Q-Learning:     %d (%.1f%%)\n", 
              ql_count, 
              100 * ql_count / length(methods)))
}

export_metrics <- function(predictions) {
  # Export metrics to JSON
  cat("\n📤 Metrics Export\n")
  cat("=================\n")
  
  if (nrow(predictions) == 0) {
    cat("No predictions to analyze\n")
    return()
  }
  
  metrics <- sprintf(
    '{\n  "timestamp": "%s",\n  "predictions_total": %d,\n  "method_neural_network": %d,\n  "method_qlearning": %d,\n  "confidence_mean": %.3f,\n  "confidence_high": %d\n}',
    Sys.time(),
    nrow(predictions),
    sum(predictions$method == "neural_network", na.rm = TRUE),
    sum(predictions$method == "qlearning", na.rm = TRUE),
    mean(predictions$confidence, na.rm = TRUE),
    sum(predictions$confidence >= 0.6, na.rm = TRUE)
  )
  
  cat(metrics)
  cat("\n")
  
  # Save to file
  write(metrics, "data/rl/agent-router-metrics.json")
  cat("✓ Metrics saved to data/rl/agent-router-metrics.json\n")
}

# ============================================================================
# Main
# ============================================================================

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  action <- if (length(args) > 0) args[1] else "status"
  
  # Load data
  predictions <- load_predictions()
  
  # Execute action
  if (action == "status") {
    status_report(predictions)
  } else if (action == "summary") {
    summary_report(predictions)
  } else if (action == "export") {
    export_metrics(predictions)
  } else if (action == "help") {
    cat("Agent Router Monitor\n\n")
    cat("Usage: Rscript agent-router-monitor.R <action>\n\n")
    cat("Actions:\n")
    cat("  status   - Show current status and distribution\n")
    cat("  summary  - Show summary with method breakdown\n")
    cat("  export   - Export metrics to JSON\n")
    cat("  help     - Show this help\n")
  } else {
    cat("Unknown action:", action, "\n")
    cat("Use 'help' for available actions\n")
  }
}

if (!interactive()) {
  main()
}
