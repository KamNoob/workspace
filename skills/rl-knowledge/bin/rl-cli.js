#!/usr/bin/env node

/**
 * RL Knowledge Base CLI Entry Point
 */

const RLKnowledgeBase = require('../lib/rl-kb');

const kb = new RLKnowledgeBase();
const args = process.argv.slice(2);

if (!args.length) {
  console.log(`
╔════════════════════════════════════════════════════════════════╗
║   Reinforcement Learning Knowledge Base (Sutton & Barto)      ║
║   Enhanced for OpenClaw Integration                           ║
╚════════════════════════════════════════════════════════════════╝

Usage: rl <command> [args...]

Commands:
  query algorithm <name>        Get algorithm details
  query concept <name>          Explain a concept
  query chapter <number>        Get chapter overview
  compare <alg1> vs <alg2>     Compare algorithms
  search <term>                Full-text search
  explain <term>               Explain a term
  list algorithms              List all algorithms
  list concepts                List all concepts
  convergence <algorithm>      Get convergence info
  pseudocode <algorithm>       Get algorithm pseudocode
  help                         Show this help

Examples:
  rl query algorithm Q-Learning
  rl query concept exploration_exploitation
  rl compare Sarsa vs Q-Learning
  rl search Bellman
  rl explain TD error
  rl list algorithms
  rl convergence TD(0)

Options:
  --json                       Force JSON output
  --pretty                     Pretty-print output (default)
  --help, -h                   Show help
  --version, -v                Show version
  `);
  process.exit(0);
}

try {
  let result;
  const [command, ...params] = args;

  switch(command) {
    case 'query':
      result = kb.query(params[0], params.slice(1).join(' '));
      break;
    case 'compare':
      result = kb.query('compare', params.join(' '));
      break;
    case 'search':
      result = kb.search(params.join(' '));
      break;
    case 'explain':
      result = kb.explain(params.join(' '));
      break;
    case 'list':
      result = params[0] === 'algorithms' ? kb.listAlgorithms() : 
               params[0] === 'concepts' ? kb.listConcepts() :
               kb.help();
      break;
    case 'convergence':
      result = kb.getConvergence(params.join(' '));
      break;
    case 'pseudocode':
      result = kb.getPseudocode(params.join(' '));
      break;
    case 'recommend':
      result = kb.recommend(params.join(' '));
      break;
    case '--help':
    case '-h':
    case 'help':
      result = kb.help();
      break;
    case '--version':
    case '-v':
      const pkg = require('../package.json');
      console.log(`rl-knowledge v${pkg.version}`);
      process.exit(0);
    default:
      result = { error: `Unknown command: ${command}`, help: kb.help() };
  }

  console.log(JSON.stringify(result, null, 2));
} catch (e) {
  console.error(`Error: ${e.message}`);
  process.exit(1);
}
