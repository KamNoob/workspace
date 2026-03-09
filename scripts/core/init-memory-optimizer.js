#!/usr/bin/env node
/**
 * Session Memory Optimizer Initialization
 * Auto-loads and integrates RL-based memory optimization
 * Called by session bootstrap
 */

const RTMO = require('./MEMORY-INTEGRATION.js');

// Initialize on require
console.log('[Memory Optimizer] Initializing Q-learning memory system...');

// Export for session use
module.exports = {
  /**
   * Wrap memory_store with RL optimization
   */
  async memoryStore(fact) {
    return RTMO.onMemoryStore(fact);
  },

  /**
   * Wrap memory_recall with RL optimization
   */
  async memoryRecall(query, context = 'general') {
    return RTMO.onMemoryRecall(query, context);
  },

  /**
   * Get current learning statistics
   */
  getStats() {
    return RTMO.getStatistics();
  },

  /**
   * Show learning progress report
   */
  report() {
    return RTMO.reportProgress();
  },

  /**
   * Consolidate low-value memories
   */
  consolidate() {
    return RTMO.consolidate();
  },

  /**
   * Save state (called on session shutdown)
   */
  saveState() {
    RTMO.saveState();
  },

  /**
   * Direct access to optimizer
   */
  optimizer: RTMO
};
