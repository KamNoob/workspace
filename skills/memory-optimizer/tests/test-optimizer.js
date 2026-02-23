#!/usr/bin/env node

/**
 * Test Suite for Memory Optimizer
 */

const MemoryOptimizer = require('../lib/optimizer');

const tests = [
  {
    name: 'Initialize Optimizer',
    fn: () => {
      const mo = new MemoryOptimizer();
      return mo.config.alpha === 0.01 && mo.config.gamma === 0.99;
    }
  },
  {
    name: 'Store Memory',
    fn: () => {
      const mo = new MemoryOptimizer();
      const result = mo.store('Q-Learning algorithm');
      return result.status === 'stored' && result.id.startsWith('mem_');
    }
  },
  {
    name: 'Recall Memory',
    fn: () => {
      const mo = new MemoryOptimizer();
      mo.store('Q-Learning is off-policy');
      const result = mo.recall('Q-Learning');
      return result.status === 'found' && result.memory.includes('off-policy');
    }
  },
  {
    name: 'Q-Learning Update',
    fn: () => {
      const mo = new MemoryOptimizer();
      mo.store('Test fact');
      const before_q = mo.q_values['mem_1'];
      mo.recall('Test');  // This should update Q-values
      const after_q = mo.q_values['mem_1'];
      return after_q > before_q;  // Q-value should increase after successful recall
    }
  },
  {
    name: 'Eligibility Traces',
    fn: () => {
      const mo = new MemoryOptimizer();
      mo.store('Memory 1');
      mo.store('Memory 2');
      mo.recall('Memory 1');  // Update traces
      // Check that trace was updated
      return mo.traces['mem_1'] > 0;
    }
  },
  {
    name: 'Statistics',
    fn: () => {
      const mo = new MemoryOptimizer();
      mo.store('Fact 1');
      mo.store('Fact 2');
      mo.recall('Fact 1');
      const stats = mo.getStatistics();
      return stats.total_stored === 2 && stats.total_recalls === 1;
    }
  },
  {
    name: 'Consolidation',
    fn: () => {
      const mo = new MemoryOptimizer();
      mo.store('Important fact');
      mo.store('Unimportant fact');
      // Manually set low Q-value
      mo.q_values['mem_2'] = 0.01;  // Below threshold
      const before = Object.keys(mo.memories).length;
      const result = mo.consolidate();
      const after = Object.keys(mo.memories).length;
      return before > after && result.removed > 0;
    }
  },
  {
    name: 'Context Learning',
    fn: () => {
      const mo = new MemoryOptimizer();
      mo.store({ text: 'RL fact', context: 'rl' });
      const recall1 = mo.recall('RL', 'rl');      // Matching context
      const recall2 = mo.recall('RL', 'python');   // Different context
      return recall1.reward > recall2.reward;
    }
  },
  {
    name: 'List Memories',
    fn: () => {
      const mo = new MemoryOptimizer();
      mo.store('Fact 1');
      mo.store('Fact 2');
      const list = mo.listMemories();
      return Array.isArray(list) && list.length === 2;
    }
  },
  {
    name: 'Reset Learning',
    fn: () => {
      const mo = new MemoryOptimizer();
      mo.store('Fact');
      mo.recall('Fact');
      mo.reset();
      return mo.q_values['mem_1'] === 0.5 && mo.stats.total_recalls === 0;
    }
  }
];

function run() {
  console.log('\n╔════════════════════════════════════════╗');
  console.log('║  Memory Optimizer - Test Suite        ║');
  console.log('╚════════════════════════════════════════╝\n');

  let passed = 0;
  let failed = 0;

  tests.forEach((test, idx) => {
    try {
      const result = test.fn();
      if (result) {
        console.log(`  ✓ [${idx + 1}/${tests.length}] ${test.name}`);
        passed++;
      } else {
        console.log(`  ✗ [${idx + 1}/${tests.length}] ${test.name} - returned false`);
        failed++;
      }
    } catch (e) {
      console.log(`  ✗ [${idx + 1}/${tests.length}] ${test.name} - ${e.message}`);
      failed++;
    }
  });

  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║  Results: ${passed} passed, ${failed} failed        │`);
  console.log(`╚════════════════════════════════════════╝\n`);

  process.exit(failed > 0 ? 1 : 0);
}

run();
