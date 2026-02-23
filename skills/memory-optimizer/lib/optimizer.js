#!/usr/bin/env node

/**
 * Memory Optimizer - RL-Based Persistent Memory System
 * Uses Q-Learning + Eligibility Traces to optimize memory storage & retrieval
 */

class MemoryOptimizer {
  constructor(config = {}) {
    this.config = {
      alpha: config.alpha || 0.01,           // Learning rate
      gamma: config.gamma || 0.99,           // Discount factor
      lambda: config.lambda || 0.9,          // Trace decay
      max_memories: config.max_memories || 1000,
      forgetting_threshold: config.forgetting_threshold || 0.05
    };

    // Q-table: memory_id → value estimate
    this.q_values = {};
    
    // Eligibility traces: memory_id → decay value
    this.traces = {};
    
    // Memory store
    this.memories = {};
    
    // Statistics
    this.stats = {
      total_recalls: 0,
      successful_recalls: 0,
      total_stores: 0,
      avg_lookup_time: 0,
      access_history: []
    };

    this.memory_counter = 0;
  }

  /**
   * Store a fact with RL optimization
   */
  store(fact) {
    const id = `mem_${++this.memory_counter}`;
    
    const memory = {
      id,
      text: fact.text || fact,
      category: fact.category || 'fact',
      context: fact.context || 'general',
      timestamp: Date.now(),
      access_count: 0,
      last_accessed: null,
      value: 0
    };

    this.memories[id] = memory;
    this.q_values[id] = 0.5;  // Initialize Q-value
    this.traces[id] = 0;       // Initialize trace

    this.stats.total_stores++;

    return {
      id,
      status: 'stored',
      value: 0.5,
      message: `Stored: "${fact.text || fact}"`
    };
  }

  /**
   * Recall a fact (with optimization learning)
   */
  recall(query, context = 'general') {
    const start_time = Date.now();
    
    // Find matching memories (simple substring match)
    const candidates = Object.values(this.memories)
      .filter(m => m.text.toLowerCase().includes(query.toLowerCase()) ||
                   (m.category && m.category.includes(query.toLowerCase())))
      .sort((a, b) => (this.q_values[b.id] || 0) - (this.q_values[a.id] || 0))
      .slice(0, 3);

    const lookup_time = Date.now() - start_time;

    if (candidates.length === 0) {
      // Record failure
      const reward = -20;  // Penalty for not finding memory
      this.recordFailure(query, context);
      return {
        status: 'not_found',
        reward,
        message: `No memories found for: "${query}"`
      };
    }

    // Best match
    const best = candidates[0];
    best.access_count++;
    best.last_accessed = Date.now();

    // Calculate reward
    const reward = this.calculateReward(lookup_time, context, best);

    // Update Q-values using TD learning
    this.updateQValues(best.id, reward, context);

    // Track statistics
    this.stats.total_recalls++;
    this.stats.successful_recalls++;
    this.stats.access_history.push({
      timestamp: Date.now(),
      query,
      memory_id: best.id,
      reward,
      lookup_time
    });

    return {
      status: 'found',
      memory: best.text,
      category: best.category,
      q_value: this.q_values[best.id],
      reward,
      lookup_time,
      candidates: candidates.map(c => ({
        text: c.text.substring(0, 50) + '...',
        q_value: this.q_values[c.id]
      }))
    };
  }

  /**
   * Q-Learning with Eligibility Traces
   */
  updateQValues(memory_id, reward, context) {
    // TD error
    const current_q = this.q_values[memory_id] || 0;
    const max_next_q = Math.max(...Object.values(this.q_values), 0);
    const td_error = reward + this.config.gamma * max_next_q - current_q;

    // Update traces
    this.traces[memory_id] = (this.traces[memory_id] || 0) * this.config.lambda * this.config.gamma + 1;

    // Update Q-values using traces
    Object.keys(this.memories).forEach(id => {
      const trace = this.traces[id] || 0;
      if (trace > 0) {
        const old_q = this.q_values[id] || 0;
        this.q_values[id] = old_q + this.config.alpha * td_error * trace;
        
        // Decay trace
        this.traces[id] = trace * this.config.lambda * this.config.gamma;
      }
    });
  }

  /**
   * Calculate reward signal
   */
  calculateReward(lookup_time, context, memory) {
    let reward = 0;

    // Recall success
    reward += 10;

    // Context match
    if (memory.context === context || memory.context === 'general') {
      reward += 5;
    }

    // Lookup time penalty
    reward -= Math.max(0, (lookup_time - 10) * 0.1);  // Penalize slow retrieval

    // Access frequency bonus
    reward += Math.min(5, memory.access_count * 0.1);

    return reward;
  }

  /**
   * Record failure (memory not found)
   */
  recordFailure(query, context) {
    const reward = -20;  // Significant penalty
    this.stats.access_history.push({
      timestamp: Date.now(),
      query,
      status: 'failed',
      reward
    });
    this.stats.total_recalls++;
  }

  /**
   * Get memory statistics
   */
  getStatistics() {
    const q_values = Object.values(this.q_values);
    const avg_q = q_values.length > 0 ? q_values.reduce((a, b) => a + b) / q_values.length : 0;
    const success_rate = this.stats.total_recalls > 0 ? 
      (this.stats.successful_recalls / this.stats.total_recalls * 100).toFixed(2) : 0;

    const total_stored = this.stats.total_stores || Object.keys(this.memories).length;

    const most_valuable = Object.entries(this.q_values)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([id, q]) => ({
        text: this.memories[id] ? this.memories[id].text.substring(0, 60) : 'unknown',
        q_value: q.toFixed(3),
        access_count: this.memories[id] ? this.memories[id].access_count : 0
      }));

    const least_valuable = Object.entries(this.q_values)
      .sort((a, b) => a[1] - b[1])
      .slice(0, 5)
      .map(([id, q]) => ({
        text: this.memories[id] ? this.memories[id].text.substring(0, 60) : 'unknown',
        q_value: q.toFixed(3)
      }));

    return {
      total_memories: Object.keys(this.memories).length,
      total_stored,
      total_recalls: this.stats.total_recalls,
      successful_recalls: this.stats.successful_recalls,
      success_rate: `${success_rate}%`,
      average_q_value: avg_q.toFixed(3),
      learning_rate: this.config.alpha,
      discount_factor: this.config.gamma,
      trace_decay: this.config.lambda,
      config: this.config,
      most_valuable,
      least_valuable
    };
  }

  /**
   * Consolidate memory (remove low-value facts)
   */
  consolidate() {
    const threshold = this.config.forgetting_threshold;
    const to_remove = Object.entries(this.q_values)
      .filter(([_, q]) => q < threshold)
      .map(([id, _]) => id);

    const removed_count = to_remove.length;
    to_remove.forEach(id => {
      delete this.memories[id];
      delete this.q_values[id];
      delete this.traces[id];
    });

    return {
      consolidated: true,
      removed: removed_count,
      remaining: Object.keys(this.memories).length,
      freed_space: `${(removed_count / (removed_count + Object.keys(this.memories).length) * 100).toFixed(1)}%`
    };
  }

  /**
   * Export learned priorities for persistence
   */
  export() {
    return {
      q_values: this.q_values,
      config: this.config,
      stats: this.stats,
      timestamp: Date.now()
    };
  }

  /**
   * Import learned priorities
   */
  import(data) {
    if (data.q_values) this.q_values = data.q_values;
    if (data.config) this.config = { ...this.config, ...data.config };
    if (data.stats) this.stats = data.stats;
  }

  /**
   * Get memory by ID
   */
  getMemory(id) {
    return this.memories[id] || null;
  }

  /**
   * List all memories (sorted by Q-value)
   */
  listMemories() {
    return Object.values(this.memories)
      .sort((a, b) => (this.q_values[b.id] || 0) - (this.q_values[a.id] || 0))
      .map(m => ({
        id: m.id,
        text: m.text,
        category: m.category,
        q_value: (this.q_values[m.id] || 0).toFixed(3),
        access_count: m.access_count,
        age_ms: Date.now() - m.timestamp
      }));
  }

  /**
   * Reset all learning
   */
  reset() {
    this.q_values = {};
    this.traces = {};
    this.stats = {
      total_recalls: 0,
      successful_recalls: 0,
      total_stores: 0,
      access_history: []
    };

    Object.keys(this.memories).forEach(id => {
      this.q_values[id] = 0.5;
      this.traces[id] = 0;
    });

    return { status: 'reset', message: 'All learning values reset to initial state' };
  }
}

// CLI Interface
if (require.main === module) {
  const mo = new MemoryOptimizer();
  const args = process.argv.slice(2);

  if (!args.length) {
    console.log(`
Memory Optimizer - RL-Based Memory System

Usage:
  node optimizer.js store <text>              Store a fact
  node optimizer.js recall <query> [context]  Retrieve a fact
  node optimizer.js statistics                Show learning stats
  node optimizer.js list                      List all memories
  node optimizer.js consolidate               Remove low-value facts
  node optimizer.js reset                     Reset learning

Examples:
  node optimizer.js store "Q-Learning is off-policy"
  node optimizer.js recall "Q-Learning advantages"
  node optimizer.js statistics
    `);
    process.exit(0);
  }

  const [command, ...params] = args;

  try {
    let result;
    
    switch(command) {
      case 'store':
        result = mo.store(params.join(' '));
        break;
      case 'recall':
        result = mo.recall(params[0], params[1] || 'general');
        break;
      case 'statistics':
        result = mo.getStatistics();
        break;
      case 'list':
        result = mo.listMemories();
        break;
      case 'consolidate':
        result = mo.consolidate();
        break;
      case 'reset':
        result = mo.reset();
        break;
      default:
        result = { error: `Unknown command: ${command}` };
    }

    console.log(JSON.stringify(result, null, 2));
  } catch (e) {
    console.error(JSON.stringify({ error: e.message }, null, 2));
    process.exit(1);
  }
}

module.exports = MemoryOptimizer;
