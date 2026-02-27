#!/usr/bin/env node

/**
 * Monte Carlo CLI Tool
 */

const MC = require('../lib/simulator.js');
const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const command = args[0];

function help() {
  console.log(`
Monte Carlo Simulation CLI

USAGE:
  mc <command> [options]

COMMANDS:
  integrate <func> <a> <b> [--samples N] [--seed S]
    Estimate integral of function f(x) from a to b
    Example: mc integrate "x*x" 0 1

  probability <condition> [--samples N]
    Estimate probability that condition is true
    Example: mc probability "x > 0.5" --samples 100000

  sample <distribution> [--n N] [--params JSON]
    Sample from a distribution
    Example: mc sample normal --n 100 --params '{"mean":0,"stddev":1}'

  portfolio <assetsJSON> [--periods N] [--iterations I]
    Monte Carlo portfolio simulation
    Example: mc portfolio '[{"weight":0.6,"expectedReturn":0.08,"volatility":0.15}]'

  pi [--samples N]
    Estimate Pi using Monte Carlo
    Example: mc pi --samples 1000000

  stats <data.json>
    Calculate statistics on data
    Example: mc stats data.json

OPTIONS:
  --samples N       Number of MC samples (default 10000)
  --seed S          Random seed for reproducibility
  --params JSON     Parameter object as JSON
  --periods N       Time periods for simulation
  --iterations I    Number of iterations
  --help            Show this help
  `);
}

function parseArgs(args, startIdx = 1) {
  const opts = {};
  for (let i = startIdx; i < args.length; i++) {
    if (args[i].startsWith('--')) {
      const key = args[i].slice(2);
      const val = args[i + 1];
      if (!val || val.startsWith('--')) {
        opts[key] = true;
      } else {
        try {
          opts[key] = JSON.parse(val);
        } catch {
          opts[key] = val;
        }
        i++;
      }
    }
  }
  return opts;
}

try {
  if (!command || command === '--help' || command === 'help') {
    help();
    process.exit(0);
  }

  const opts = parseArgs(args, 1);
  const mc = new MC(opts);

  switch (command) {
    case 'integrate': {
      const fnStr = args[1];
      const a = parseFloat(args[2]);
      const b = parseFloat(args[3]);
      const fn = new Function('x', `return ${fnStr}`);
      const result = mc.estimateIntegral(fn, a, b, opts.samples);
      console.log(JSON.stringify(result, null, 2));
      break;
    }

    case 'probability': {
      const condition = args[1];
      const fn = new Function('i', 'rng', `return ${condition}`);
      const result = mc.estimateProbability(fn, opts.samples);
      console.log(JSON.stringify(result, null, 2));
      break;
    }

    case 'sample': {
      const dist = args[1];
      const n = opts.n || 1;
      const params = opts.params || {};
      const result = mc.sample(dist, params, n);
      console.log(Array.isArray(result) ? JSON.stringify(result, null, 2) : result);
      break;
    }

    case 'portfolio': {
      const assets = JSON.parse(args[1]);
      const result = mc.simulatePortfolio(
        assets,
        opts.correlations || [],
        opts.periods || 252,
        opts.iterations || 1000
      );
      console.log(JSON.stringify(result, null, 2));
      break;
    }

    case 'pi': {
      const result = mc.estimatePi(opts.samples);
      console.log(JSON.stringify(result, null, 2));
      break;
    }

    case 'stats': {
      const file = args[1];
      const data = JSON.parse(fs.readFileSync(file, 'utf8'));
      const result = mc.stats(data);
      console.log(JSON.stringify(result, null, 2));
      break;
    }

    default:
      console.error(`Unknown command: ${command}`);
      help();
      process.exit(1);
  }
} catch (err) {
  console.error('Error:', err.message);
  process.exit(1);
}
