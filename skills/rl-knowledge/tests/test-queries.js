#!/usr/bin/env node

/**
 * Test Suite for RL Knowledge Base
 */

const RLKnowledgeBase = require('../lib/rl-kb');

const tests = [
  {
    name: 'Load KB',
    fn: (kb) => Object.keys(kb.kb).length > 0
  },
  {
    name: 'Query Algorithm',
    fn: (kb) => {
      const result = kb.query('algorithm', 'Q-Learning');
      return result.name === 'Q-Learning';
    }
  },
  {
    name: 'Compare Algorithms',
    fn: (kb) => {
      const result = kb.query('compare', 'Sarsa vs Q-Learning');
      return result.type === 'comparison';
    }
  },
  {
    name: 'Search',
    fn: (kb) => {
      const result = kb.search('Bellman');
      return result.total > 0;
    }
  },
  {
    name: 'Explain Concept',
    fn: (kb) => {
      const result = kb.explain('exploration_exploitation');
      return result.type === 'explanation';
    }
  },
  {
    name: 'List Algorithms',
    fn: (kb) => {
      const result = kb.listAlgorithms();
      return result.tabular && result.function_approximation;
    }
  },
  {
    name: 'Get Convergence',
    fn: (kb) => {
      const result = kb.getConvergence('Q-Learning');
      return !result.error;
    }
  },
  {
    name: 'Pseudocode Generation',
    fn: (kb) => {
      const result = kb.getPseudocode('Q-Learning');
      return result.pseudocode && result.pseudocode.length > 0;
    }
  }
];

function run() {
  console.log('\n╔════════════════════════════════════════╗');
  console.log('║  RL Knowledge Base - Test Suite       ║');
  console.log('╚════════════════════════════════════════╝\n');

  const kb = new RLKnowledgeBase();
  let passed = 0;
  let failed = 0;

  tests.forEach((test, idx) => {
    try {
      const result = test.fn(kb);
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
