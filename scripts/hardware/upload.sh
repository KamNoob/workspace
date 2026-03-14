#!/bin/bash

# ESP32 Upload Helper
# Works around permission issues by:
# 1. Checking port permissions
# 2. Retrying with escalation if needed
# 3. Providing clear feedback

PORT="/dev/ttyUSB0"
BOARD="esp32:esp32:esp32"
SKETCH_DIR="/home/art/.openclaw/workspace/scripts/hardware/morpheus_client"

echo "╔════════════════════════════════════════════╗"
echo "║  ESP32 Upload Helper                       ║"
echo "╠════════════════════════════════════════════╣"
echo "║  Port: $PORT                               ║"
echo "║  Board: $BOARD                             ║"
echo "║  Sketch: morpheus_client.ino               ║"
echo "╚════════════════════════════════════════════╝"
echo

# Check if port exists
if [ ! -e "$PORT" ]; then
    echo "❌ Port $PORT not found!"
    echo "   Available serial ports:"
    ls -la /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "   (none found)"
    exit 1
fi

# Check permissions
if [ ! -r "$PORT" ]; then
    echo "⚠️  No read permission on $PORT"
    echo "   Owner: $(ls -l $PORT | awk '{print $3}')"
    echo "   Mode: $(ls -l $PORT | awk '{print $1}')"
    echo
    echo "   To fix, add yourself to dialout group:"
    echo "   $ sudo usermod -a -G dialout \$USER"
    echo "   $ newgrp dialout"
    echo
    echo "   Or try with sudo:"
    echo "   $ sudo bash upload.sh"
    exit 1
fi

# Try upload
echo "📤 Uploading sketch to ESP32..."
echo

cd "$SKETCH_DIR" || exit 1

arduino-cli upload -p "$PORT" -b "$BOARD" . 2>&1 | tee /tmp/upload.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo
    echo "✅ Upload successful!"
    echo
    echo "Next steps:"
    echo "1. ESP32 should reboot automatically"
    echo "2. Monitor serial output:"
    echo "   $ arduino-cli monitor -p $PORT -c baudrate=115200"
    echo "3. Check Morpheus server logs:"
    echo "   $ tail -f ~/logs/morpheus-decisions.jsonl"
else
    echo
    echo "❌ Upload failed. Check output above."
    exit 1
fi
