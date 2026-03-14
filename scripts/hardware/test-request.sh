#!/bin/bash

echo "Testing Morpheus Server..."

# Test 1: Health check
echo -e "\n1. Health Check:"
curl -s http://localhost:8000/api/health

# Test 2: Simple decision
echo -e "\n\n2. POST Decision:"
{
  printf 'POST /api/decide HTTP/1.1\r\n'
  printf 'Host: localhost:8000\r\n'
  printf 'Content-Type: application/json\r\n'
  printf 'Content-Length: 61\r\n'
  printf '\r\n'
  printf '{"sensor":"temperature","value":42.5,"unit":"C","device_id":"ESP32_001"}'
} | nc localhost 8000

# Test 3: Get recent decisions
echo -e "\n\n3. Get Recent Decisions:"
curl -s http://localhost:8000/api/decisions/5
