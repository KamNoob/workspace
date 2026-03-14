#!/bin/bash

# Install Morpheus as systemd service

SERVICE_NAME="morpheus"
SERVICE_FILE="/home/art/.openclaw/workspace/scripts/hardware/morpheus.service"
SYSTEMD_DIR="$HOME/.config/systemd/user"

echo "╔════════════════════════════════════════════╗"
echo "║  Morpheus Systemd Installation             ║"
echo "╚════════════════════════════════════════════╝"
echo

# Create systemd user directory
mkdir -p "$SYSTEMD_DIR"
echo "✅ Created $SYSTEMD_DIR"

# Copy service file
cp "$SERVICE_FILE" "$SYSTEMD_DIR/$SERVICE_NAME.service"
echo "✅ Installed $SERVICE_NAME.service"

# Reload systemd
systemctl --user daemon-reload
echo "✅ Reloaded systemd"

# Enable service
systemctl --user enable "$SERVICE_NAME.service"
echo "✅ Enabled $SERVICE_NAME service"

# Start service
systemctl --user start "$SERVICE_NAME.service"
echo "✅ Started $SERVICE_NAME service"

# Check status
sleep 2
echo
echo "Service Status:"
systemctl --user status "$SERVICE_NAME.service" --no-pager

echo
echo "Useful commands:"
echo "  Start:   systemctl --user start $SERVICE_NAME"
echo "  Stop:    systemctl --user stop $SERVICE_NAME"
echo "  Status:  systemctl --user status $SERVICE_NAME"
echo "  Logs:    journalctl --user -u $SERVICE_NAME -f"
echo "  Restart: systemctl --user restart $SERVICE_NAME"
echo

# Verify connectivity
echo "Testing connectivity..."
sleep 2
HEALTH=$(curl -s http://localhost:8000/api/health 2>/dev/null | grep -o '"status":"ok"')
if [ ! -z "$HEALTH" ]; then
    echo "✅ Server responding on :8000"
else
    echo "⚠️  Server not responding yet (may still be starting)"
fi
