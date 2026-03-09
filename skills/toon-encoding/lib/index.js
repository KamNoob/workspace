/**
 * TOON Encoding Skill
 * 
 * Provides Node.js API for encoding/decoding TOON format
 * with OpenClaw agent integration helpers
 */

import { encode, decode, encodeLines, decodeStream } from '@toon-format/toon'

/**
 * Encode JSON to TOON (compact format)
 * @param {any} data - JSON-serializable data
 * @param {Object} options - Encoding options
 * @returns {string} TOON-encoded output
 */
export function encodeToon(data, options = {}) {
  return encode(data, {
    delimiter: options.delimiter || ',',
    indent: options.indent || 2,
    keyFolding: options.keyFolding || 'off',
    flattenDepth: options.flattenDepth,
  })
}

/**
 * Decode TOON back to JSON
 * @param {string} input - TOON-formatted input
 * @param {Object} options - Decoding options
 * @returns {any} Decoded JSON data
 */
export function decodeToon(input, options = {}) {
  return decode(input, {
    indent: options.indent || 2,
    strict: options.strict !== false,
    expandPaths: options.expandPaths || 'off',
  })
}

/**
 * Encode data for agent transmission (optimized for token efficiency)
 * 
 * @param {any} data - Data to encode
 * @returns {string} TOON-encoded, ready for agent prompt
 * 
 * @example
 * const agentRoster = { agents: [...] }
 * const compact = encodeForAgent(agentRoster)
 * // Send to agent with fewer tokens
 */
export function encodeForAgent(data) {
  return encode(data, {
    delimiter: ',',
    indent: 0, // Minimal indentation for agents
    keyFolding: 'safe',
  })
}

/**
 * Estimate token savings when encoding JSON to TOON
 * 
 * @param {string} jsonStr - JSON string
 * @returns {Object} { jsonTokens, toonTokens, saved, percent }
 */
export function estimateSavings(jsonStr) {
  const { estimateTokenCount } = require('tokenx')
  
  const jsonTokens = estimateTokenCount(jsonStr)
  
  let data
  try {
    data = JSON.parse(jsonStr)
  } catch {
    return null
  }
  
  const toonStr = encode(data)
  const toonTokens = estimateTokenCount(toonStr)
  
  return {
    jsonTokens,
    toonTokens,
    saved: jsonTokens - toonTokens,
    percent: ((jsonTokens - toonTokens) / jsonTokens * 100).toFixed(1),
  }
}

/**
 * Encode RL data (Q-scores, agent selections) for transmission
 * 
 * @param {Object} rlData - RL agent selection or Q-score data
 * @returns {string} Compact TOON representation
 * 
 * @example
 * import { encodeRLData } from '@toon-encoding/lib'
 * 
 * const qScores = JSON.parse(fs.readFileSync('rl-agent-selection.json'))
 * const compact = encodeRLData(qScores)
 * 
 * // Send to cron job or agent
 * cron.add({
 *   schedule: { kind: 'cron', expr: '0 9 * * *' },
 *   payload: { kind: 'systemEvent', text: `Q-scores: ${compact}` }
 * })
 */
export function encodeRLData(rlData) {
  return encode(rlData, {
    delimiter: ',',
    indent: 2,
    keyFolding: 'safe',
  })
}

/**
 * Batch encode multiple data objects with summaries
 * 
 * @param {Object} batch - { key: data, ... }
 * @returns {Object} { [key]: { original, toon, tokens } }
 */
export function encodeBatch(batch) {
  const result = {}
  
  for (const [key, data] of Object.entries(batch)) {
    const toonStr = encode(data)
    
    result[key] = {
      original: JSON.stringify(data),
      toon: toonStr,
      originalSize: JSON.stringify(data).length,
      toonSize: toonStr.length,
      compression: ((1 - toonStr.length / JSON.stringify(data).length) * 100).toFixed(1) + '%',
    }
  }
  
  return result
}

export { encode, decode, encodeLines, decodeStream }
