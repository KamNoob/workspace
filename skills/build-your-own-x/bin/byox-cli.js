#!/usr/bin/env node

/**
 * Build Your Own X CLI
 * Query and discover tutorials for building technologies from scratch
 */

const BuildYourOwnXIndex = require('../lib/byox-index.js');

const args = process.argv.slice(2);
const command = args[0];
const index = new BuildYourOwnXIndex();

function showHelp() {
  console.log(`
Build Your Own X - Tutorial Discovery CLI

Usage:
  byox list                      List all categories
  byox search <query>            Search for tutorials (keyword)
  byox category <name>           Get tutorials in a category
  byox language <lang>           Get tutorials in a language
  byox random                    Get a random tutorial
  byox stats                     Show statistics
  byox help                      Show this help

Examples:
  byox search database
  byox category "Build your own Database"
  byox language python
  byox random
  byox stats

Environment:
  Set BYOX_REPO to point to your build-your-own-x clone
  Default: ~/.openclaw/workspace/build-your-own-x
  `);
}

try {
  switch (command) {
    case 'list':
      console.log('Categories:');
      index.listCategories().forEach(cat => console.log(`  - ${cat}`));
      break;

    case 'search':
      if (!args[1]) {
        console.error('Error: query required');
        process.exit(1);
      }
      const searchResults = index.search(args[1]);
      console.log(`Found ${searchResults.length} tutorial(s):\n`);
      console.log(index.formatResults(searchResults));
      break;

    case 'category':
      if (!args[1]) {
        console.error('Error: category name required');
        process.exit(1);
      }
      const category = index.getCategory(args[1]);
      if (!category) {
        console.error(`Category not found: ${args[1]}`);
        console.log('\nAvailable categories:');
        index.listCategories().forEach(cat => console.log(`  - ${cat}`));
        process.exit(1);
      }
      console.log(`${args[1]}:\n`);
      category.forEach(t => console.log(index.formatTutorial({ category: args[1], ...t })));
      break;

    case 'language':
      if (!args[1]) {
        console.error('Error: language required');
        process.exit(1);
      }
      const langResults = index.getLanguage(args[1]);
      console.log(`${langResults.length} tutorial(s) in ${args[1]}:\n`);
      console.log(index.formatResults(langResults));
      break;

    case 'random':
      const random = index.getRandom();
      console.log('Random tutorial:\n');
      console.log(index.formatTutorial(random));
      break;

    case 'stats':
      const stats = index.getStats();
      console.log(`
Statistics:
  Total Categories: ${stats.totalCategories}
  Total Tutorials: ${stats.totalTutorials}

Top Languages:
${stats.languages.slice(0, 10).map(l => `  ${l.language}: ${l.count}`).join('\n')}
      `);
      break;

    case 'help':
    case '--help':
    case '-h':
      showHelp();
      break;

    default:
      console.error(`Unknown command: ${command || '(none)'}`);
      showHelp();
      process.exit(1);
  }
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
}
