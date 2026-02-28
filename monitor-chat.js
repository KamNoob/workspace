#!/usr/bin/env node
// Monitor pending chat messages and send alerts via OpenClaw message system

import fetch from 'node-fetch'
import fs from 'fs'
import path from 'path'

const STATE_FILE = '/tmp/chat-monitor-state.json'

async function getPending() {
  try {
    const res = await fetch('http://localhost:4001/api/admin/pending')
    const data = await res.json()
    return data.pending || []
  } catch (e) {
    console.error('Fetch error:', e.message)
    return []
  }
}

function getState() {
  try {
    if (fs.existsSync(STATE_FILE)) {
      return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'))
    }
  } catch (e) {}
  return { lastChecked: 0, processedMsgs: [] }
}

function setState(state) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2), 'utf8')
}

async function main() {
  const pending = await getPending()
  const state = getState()
  
  if (pending.length === 0) {
    // No pending messages, silent
    return
  }
  
  // Find new unprocessed messages
  const newMsgs = pending.filter(p => !state.processedMsgs.includes(p.messageId))
  
  if (newMsgs.length === 0) {
    // All pending already processed
    return
  }
  
  // Log pending messages for Morpheus to see
  console.log(`[CHAT] ${newMsgs.length} unanswered message(s):`)
  for (const msg of newMsgs) {
    console.log(`  [${msg.conversationId}] ${msg.message}`)
    state.processedMsgs.push(msg.messageId)
  }
  
  setState(state)
}

main().catch(e => console.error('Error:', e.message))
