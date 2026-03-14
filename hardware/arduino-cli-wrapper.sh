#!/bin/bash

# Arduino CLI Wrapper
# Convenience script for common arduino-cli tasks
# 
# Usage:
#   ./arduino-cli-wrapper.sh list-boards
#   ./arduino-cli-wrapper.sh list-ports
#   ./arduino-cli-wrapper.sh compile uno blink_uno
#   ./arduino-cli-wrapper.sh upload uno /dev/ttyUSB0 blink_uno

CLI="$HOME/.local/bin/arduino-cli"
SKETCHES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/sketches" && pwd )"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Board aliases
declare -A BOARDS=(
  ["uno"]="arduino:avr:uno"
  ["nano"]="arduino:avr:nano"
  ["esp32"]="esp32:esp32:esp32"
  ["esp32-s3"]="esp32:esp32:esp32s3"
)

usage() {
  cat << EOF
Arduino CLI Wrapper - Convenience Commands

Usage:
  $0 <command> [options]

Commands:
  list-boards           List all installed board packages
  list-ports            List connected boards and ports
  compile <alias> <sketch>
                        Compile sketch for board
                        Example: $0 compile uno blink_uno
  
  upload <alias> <port> <sketch>
                        Compile and upload to board
                        Example: $0 upload uno /dev/ttyUSB0 blink_uno
  
  monitor <port> [baud]
                        Open serial monitor
                        Example: $0 monitor /dev/ttyUSB0 9600
  
  board-info <alias>    Show details for a board
                        Example: $0 board-info esp32
  
  new-sketch <name>     Create new sketch
                        Example: $0 new-sketch my_project

Board Aliases:
  uno, nano, esp32, esp32-s3

Examples:
  $0 list-ports
  $0 compile esp32 wifi_esp32
  $0 upload esp32 /dev/ttyUSB0 wifi_esp32
  $0 monitor /dev/ttyUSB0 115200

EOF
  exit 1
}

info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
  exit 1
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

list_boards() {
  info "Installed board packages:"
  $CLI core list
}

list_ports() {
  info "Connected boards:"
  $CLI board list
}

compile() {
  local alias=$1
  local sketch=$2
  
  [ -z "$alias" ] && error "Board alias required"
  [ -z "$sketch" ] && error "Sketch name required"
  
  local board="${BOARDS[$alias]}"
  [ -z "$board" ] && error "Unknown board alias: $alias. Known: ${!BOARDS[@]}"
  
  local sketch_path="$SKETCHES_DIR/$sketch"
  [ ! -d "$sketch_path" ] && error "Sketch not found: $sketch_path"
  
  info "Compiling $sketch for $alias ($board)..."
  $CLI compile -b "$board" "$sketch_path" || error "Compilation failed"
  info "✓ Compilation successful"
}

upload() {
  local alias=$1
  local port=$2
  local sketch=$3
  
  [ -z "$alias" ] && error "Board alias required"
  [ -z "$port" ] && error "Port required (e.g., /dev/ttyUSB0)"
  [ -z "$sketch" ] && error "Sketch name required"
  
  local board="${BOARDS[$alias]}"
  [ -z "$board" ] && error "Unknown board alias: $alias"
  
  local sketch_path="$SKETCHES_DIR/$sketch"
  [ ! -d "$sketch_path" ] && error "Sketch not found: $sketch_path"
  [ ! -e "$port" ] && error "Port not found: $port"
  
  info "Uploading $sketch to $port ($alias)..."
  $CLI compile -b "$board" "$sketch_path" || error "Compilation failed"
  $CLI upload -p "$port" -b "$board" "$sketch_path" || error "Upload failed"
  info "✓ Upload successful"
}

monitor() {
  local port=$1
  local baud=${2:-9600}
  
  [ -z "$port" ] && error "Port required"
  [ ! -e "$port" ] && error "Port not found: $port"
  
  info "Opening serial monitor on $port @ $baud baud..."
  info "(Press Ctrl+C to exit)"
  
  # Use screen if available, otherwise minicom, otherwise cu
  if command -v screen &> /dev/null; then
    screen "$port" "$baud"
  elif command -v minicom &> /dev/null; then
    minicom -D "$port" -b "$baud"
  elif command -v cu &> /dev/null; then
    cu -l "$port" -s "$baud"
  else
    error "No serial monitor found. Install screen, minicom, or cu."
  fi
}

board_info() {
  local alias=$1
  
  [ -z "$alias" ] && error "Board alias required"
  
  local board="${BOARDS[$alias]}"
  [ -z "$board" ] && error "Unknown board alias: $alias"
  
  info "Board details for $alias ($board):"
  $CLI board details "$board"
}

new_sketch() {
  local name=$1
  
  [ -z "$name" ] && error "Sketch name required"
  
  local sketch_dir="$SKETCHES_DIR/$name"
  
  if [ -d "$sketch_dir" ]; then
    error "Sketch already exists: $sketch_dir"
  fi
  
  mkdir -p "$sketch_dir"
  
  # Create basic .ino file
  cat > "$sketch_dir/$name.ino" << 'SKETCH'
/*
  Sketch: NAME_PLACEHOLDER
  
  TODO: Add description
*/

void setup() {
  Serial.begin(9600);
  Serial.println("Setup complete");
}

void loop() {
  // TODO: Add loop logic
  delay(1000);
}
SKETCH

  sed -i "s/NAME_PLACEHOLDER/$name/g" "$sketch_dir/$name.ino"
  
  info "Created sketch: $sketch_dir/$name.ino"
  info "Edit and build with:"
  info "  $0 compile <board_alias> $name"
}

# Main
case "${1:-}" in
  list-boards) list_boards ;;
  list-ports) list_ports ;;
  compile) compile "$2" "$3" ;;
  upload) upload "$2" "$3" "$4" ;;
  monitor) monitor "$2" "$3" ;;
  board-info) board_info "$2" ;;
  new-sketch) new_sketch "$2" ;;
  *) usage ;;
esac
