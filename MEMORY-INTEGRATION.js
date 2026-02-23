/**
 * Real-Time Memory Optimization
 * Integrates MemoryOptimizer with OpenClaw persistent memory
 */

const MemoryOptimizer = require('./skills/memory-optimizer/lib/optimizer');
const fs = require('fs');
const path = require('path');

class RealTimeMemoryOptimizer {
  constructor() {
    this.optimizer = new MemoryOptimizer({
      alpha: 0.01,
      gamma: 0.99,
      lambda: 0.9
    });
    
    this.persistence_file = path.join(__dirname, '.memory-optimizer-state.json');
    this.stats_file = path.join(__dirname, '.memory-optimizer-stats.json');
    
    // Load previous session state if exists
    this.loadState();
  }

  /**
   * Wrap memory_store to track stored facts
   */
  async onMemoryStore(fact) {
    const stored = this.optimizer.store({
      text: fact.text,
      category: fact.category || 'fact',
      context: fact.context || 'general'
    });
    
    console.log(`[Memory] Stored: "${fact.text.substring(0, 40)}..." (Q: ${stored.value})`);
    return stored;
  }

  /**
   * Wrap memory_recall to track success and learn
   */
  async onMemoryRecall(query, context = 'general') {
    const start = Date.now();
    const result = this.optimizer.recall(query, context);
    const lookup_time = Date.now() - start;

    if (result.status === 'found') {
      console.log(`[Memory] Found: "${result.memory.substring(0, 40)}..." (Q: ${result.q_value.toFixed(3)}, reward: ${result.reward.toFixed(2)})`);
      return {
        status: 'found',
        memory: result.memory,
        q_value: result.q_value,
        lookup_time
      };
    } else {
      console.log(`[Memory] Not found: "${query}" (penalty: ${result.reward})`);
      return { status: 'not_found' };
    }
  }

  /**
   * Periodic consolidation (auto cleanup)
   */
  consolidate() {
    const result = this.optimizer.consolidate();
    console.log(`[Memory] Consolidated: Removed ${result.removed} low-value facts, freed ${result.freed_space}`);
    return result;
  }

  /**
   * Get real-time statistics
   */
  getStatistics() {
    const stats = this.optimizer.getStatistics();
    return {
      total_memories: stats.total_memories,
      total_recalls: stats.total_recalls,
      success_rate: stats.success_rate,
      average_q_value: stats.average_q_value,
      most_valuable: stats.most_valuable,
      least_valuable: stats.least_valuable
    };
  }

  /**
   * Monitor learning progress
   */
  reportProgress() {
    const stats = this.getStatistics();
    return `
╔════════════════════════════════════════════════════════════╗
║         MEMORY OPTIMIZATION REPORT                        ║
╠════════════════════════════════════════════════════════════╣
║ Total Memories:        ${String(stats.total_memories).padEnd(35)} ║
║ Total Recalls:         ${String(stats.total_recalls).padEnd(35)} ║
║ Success Rate:          ${String(stats.success_rate).padEnd(35)} ║
║ Avg Q-Value:           ${String(stats.average_q_value).padEnd(35)} ║
║                                                            ║
║ TOP 3 VALUABLE:                                          ║
${stats.most_valuable.slice(0, 3).map((m, i) => 
  `║ ${i+1}. "${m.text.substring(0, 35).padEnd(35)}" Q:${m.q_value.padEnd(5)} ║`
).join('\n')}
║                                                            ║
║ CANDIDATES FOR FORGETTING:                               ║
${stats.least_valuable.slice(0, 2).map((m, i) => 
  `║ "${m.text.substring(0, 48).padEnd(48)}" Q:${m.q_value} ║`
).join('\n')}
╚════════════════════════════════════════════════════════════╝
    `;
  }

  /**
   * Save optimizer state for persistence
   */
  saveState() {
    const state = this.optimizer.export();
    fs.writeFileSync(this.persistence_file, JSON.stringify(state, null, 2));
    console.log(`[Memory] State saved`);
  }

  /**
   * Load optimizer state from previous session
   */
  loadState() {
    if (fs.existsSync(this.persistence_file)) {
      try {
        const state = JSON.parse(fs.readFileSync(this.persistence_file, 'utf8'));
        this.optimizer.import(state);
        console.log(`[Memory] Loaded previous state (${Object.keys(state.q_values).length} memories)`);
      } catch (e) {
        console.log(`[Memory] Could not load state:`, e.message);
      }
    }
  }

  /**
   * Reset learning (start fresh)
   */
  reset() {
    const result = this.optimizer.reset();
    console.log(`[Memory] ${result.message}`);
    return result;
  }
}

// Export as singleton for integration
const rtmo = new RealTimeMemoryOptimizer();

module.exports = rtmo;

// If run directly, show demo
if (require.main === module) {
  console.log('\n🧠 Real-Time Memory Optimization Demo\n');
  
  // Simulate memory interactions
  rtmo.onMemoryStore({ text: 'Q-Learning: off-policy TD algorithm', category: 'RL' });
  rtmo.onMemoryStore({ text: 'Sarsa: on-policy TD algorithm', category: 'RL' });
  rtmo.onMemoryStore({ text: 'Actor-Critic: policy gradient method', category: 'RL' });
  
  console.log('\n--- Learning phase ---\n');
  
  // Query Q-Learning multiple times (learning)
  for (let i = 0; i < 5; i++) {
    rtmo.onMemoryRecall('Q-Learning', 'rl');
  }
  
  console.log('\n--- Statistics ---\n');
  console.log(rtmo.reportProgress());
  
  // Save state for next session
  rtmo.saveState();
  
  console.log('\n✅ Demo complete - state saved for next session\n');
}
