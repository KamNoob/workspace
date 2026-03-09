#!/usr/bin/env node

/**
 * Sentinel LLMfit CLI
 * Infrastructure planning tool for model deployment
 * 
 * Usage:
 *   sentinel-llmfit analyze <ram_gb> <vram_gb> <cpu_cores>
 *   sentinel-llmfit search <criteria>
 *   sentinel-llmfit usecase <usecase>
 *   sentinel-llmfit architecture <arch>
 *   sentinel-llmfit recommend <model_name> <ram_gb> <vram_gb>
 *   sentinel-llmfit stats
 */

const LLMfitAnalyzer = require('../lib/llmfit-analyzer.js');

const args = process.argv.slice(2);
const command = args[0];
const analyzer = new LLMfitAnalyzer();

function showHelp() {
  console.log(`
Sentinel LLMfit CLI - Infrastructure Planning Tool

Usage:
  sentinel-llmfit analyze <ram_gb> <vram_gb> <cpu_cores>
    Analyze models for your hardware
    Example: sentinel-llmfit analyze 32 8 8

  sentinel-llmfit search <criteria>
    Search for models by name/use case
    Example: sentinel-llmfit search "chat"

  sentinel-llmfit usecase <usecase>
    Get models for a specific use case
    Example: sentinel-llmfit usecase "chat"

  sentinel-llmfit architecture <arch>
    Get models with specific architecture
    Example: sentinel-llmfit architecture llama

  sentinel-llmfit recommend <model_name> <ram_gb> <vram_gb>
    Get upgrade recommendations for a model
    Example: sentinel-llmfit recommend "mistral" 16 0

  sentinel-llmfit list
    List all available models

  sentinel-llmfit stats
    Show database statistics

  sentinel-llmfit help
    Show this help message
  `);
}

try {
  switch (command) {
    case 'analyze': {
      if (!args[1] || !args[2] || !args[3]) {
        console.error('Error: analyze requires <ram_gb> <vram_gb> <cpu_cores>');
        process.exit(1);
      }
      const specs = {
        total_ram_gb: parseFloat(args[1]),
        vram_gb: parseFloat(args[2]),
        cpu_cores: parseInt(args[3])
      };
      const results = analyzer.analyzeForSystem(specs);
      console.log(JSON.stringify(results.slice(0, 15), null, 2));
      break;
    }

    case 'search': {
      if (!args[1]) {
        console.error('Error: search requires a query');
        process.exit(1);
      }
      const query = args[1].toLowerCase();
      const results = analyzer.models.filter(m =>
        m.name.toLowerCase().includes(query) ||
        m.use_case.toLowerCase().includes(query) ||
        m.architecture.toLowerCase().includes(query)
      );
      console.log(`Found ${results.length} model(s):\n`);
      results.slice(0, 20).forEach(m => {
        console.log(`${m.name}`);
        console.log(`  Use: ${m.use_case}`);
        console.log(`  Arch: ${m.architecture} | Params: ${m.parameter_count}`);
        console.log(`  Min RAM: ${m.min_ram_gb}GB | Min VRAM: ${m.min_vram_gb}GB`);
        console.log('');
      });
      break;
    }

    case 'usecase': {
      if (!args[1]) {
        console.error('Error: usecase requires a use case name');
        process.exit(1);
      }
      const results = analyzer.getByUseCase(args[1]);
      console.log(`${results.length} model(s) for "${args[1]}":\n`);
      results.slice(0, 15).forEach(m => {
        console.log(`${m.name} (${m.parameter_count})`);
        console.log(`  Context: ${m.context_length} | Min RAM: ${m.min_ram_gb}GB`);
      });
      console.log('');
      break;
    }

    case 'architecture': {
      if (!args[1]) {
        console.error('Error: architecture requires an architecture name');
        process.exit(1);
      }
      const results = analyzer.getByArchitecture(args[1]);
      console.log(`${results.length} model(s) with architecture "${args[1]}":\n`);
      results.slice(0, 15).forEach(m => {
        console.log(`${m.name} (${m.parameter_count})`);
      });
      console.log('');
      break;
    }

    case 'recommend': {
      if (!args[1] || !args[2] || args[3] === undefined) {
        console.error('Error: recommend requires <model_name> <ram_gb> <vram_gb>');
        process.exit(1);
      }
      const query = args[1].toLowerCase();
      const model = analyzer.models.find(m => m.name.toLowerCase().includes(query));
      if (!model) {
        console.error(`Model not found: ${args[1]}`);
        process.exit(1);
      }
      const specs = {
        total_ram_gb: parseFloat(args[2]),
        vram_gb: parseFloat(args[3]),
        cpu_cores: 4 // default
      };
      const recommendation = analyzer.recommendUpgrades(model, specs);
      console.log(JSON.stringify(recommendation, null, 2));
      break;
    }

    case 'list': {
      const models = analyzer.listModels();
      console.log(`${models.length} models available:\n`);
      models.slice(0, 30).forEach(m => {
        console.log(`${m.name} | ${m.params} | ${m.use_case}`);
      });
      if (models.length > 30) {
        console.log(`\n... and ${models.length - 30} more`);
      }
      break;
    }

    case 'stats': {
      const stats = analyzer.getStats();
      console.log(JSON.stringify(stats, null, 2));
      break;
    }

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
