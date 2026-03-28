/**
 * Monte Carlo Simulation Engine - Hybrid Version
 * Delegates heavy operations to optimized binaries (Rust, Go, Julia)
 * Falls back to JavaScript for small samples and development
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

class MonteCarloHybridSimulator {
  constructor(config = {}) {
    this.config = {
      samples: config.samples || 10000,
      seed: config.seed || null,
      useRust: config.useRust !== false,      // Heavy integration/sampling
      useGo: config.useGo !== false,          // Parallel portfolio sims
      useJulia: config.useJulia !== false,    // Batch math operations
      rustThreshold: config.rustThreshold || 50000,  // Use Rust when samples > this
      goThreshold: config.goThreshold || 10000,      // Use Go when iterations > this
      ...config
    };
    this.rng = this.createRNG(this.config.seed);
  }

  /**
   * Create seeded RNG for reproducibility
   */
  createRNG(seed) {
    if (!seed) {
      return () => Math.random();
    }
    let a = seed;
    return () => {
      a |= 0;
      a = (a + 0x6d2b79f5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  /**
   * Check if binary exists
   */
  binaryExists(name) {
    const binPath = path.join(__dirname, '..', 'bin', name);
    return fs.existsSync(binPath);
  }

  /**
   * Execute external binary with JSON I/O
   */
  async executeBinary(binName, args, input = null) {
    return new Promise((resolve, reject) => {
      const proc = spawn(path.join(__dirname, '..', 'bin', binName), args);
      let stdout = '';
      let stderr = '';

      proc.stdout.on('data', (data) => { stdout += data; });
      proc.stderr.on('data', (data) => { stderr += data; });

      if (input) {
        proc.stdin.write(JSON.stringify(input));
      }
      proc.stdin.end();

      proc.on('close', (code) => {
        if (code !== 0) {
          reject(new Error(`${binName} failed: ${stderr}`));
        } else {
          try {
            resolve(JSON.parse(stdout));
          } catch (e) {
            reject(new Error(`${binName} output invalid JSON: ${stdout}`));
          }
        }
      });

      proc.on('error', reject);
    });
  }

  /**
   * Estimate integral using optimal method
   */
  async estimateIntegral(fn, a, b, samples = this.config.samples) {
    // For small samples, use JS
    if (samples < this.config.rustThreshold) {
      return this._estimateIntegralJS(fn, a, b, samples);
    }

    // For large samples, try Rust
    if (this.config.useRust && this.binaryExists('mc-rust')) {
      try {
        return await this.executeBinary('mc-rust', 
          ['integrate', a.toString(), b.toString(), samples.toString()]);
      } catch (e) {
        console.warn('Rust integration failed, falling back to JS:', e.message);
      }
    }

    // Fallback to JS
    return this._estimateIntegralJS(fn, a, b, samples);
  }

  /**
   * JavaScript fallback for integral estimation
   */
  _estimateIntegralJS(fn, a, b, samples) {
    let sum = 0;
    const width = b - a;
    const values = [];

    for (let i = 0; i < samples; i++) {
      const x = a + this.rng() * width;
      const fx = fn(x);
      values.push(fx);
      sum += fx;
    }

    const mean = sum / samples;
    const integral = width * mean;
    const variance = values.reduce((acc, v) => acc + (v - mean) ** 2, 0) / samples;
    const stdError = Math.sqrt(variance / samples) * width;

    return {
      integral: parseFloat(integral.toFixed(6)),
      stdError: parseFloat(stdError.toFixed(6)),
      samples,
      ci95: [
        parseFloat((integral - 1.96 * stdError).toFixed(6)),
        parseFloat((integral + 1.96 * stdError).toFixed(6))
      ],
      backend: 'js'
    };
  }

  /**
   * Estimate probability
   */
  async estimateProbability(fn, samples = this.config.samples) {
    // Use JS for probability (faster than spawning process)
    let count = 0;
    for (let i = 0; i < samples; i++) {
      if (fn(i, this.rng)) count++;
    }

    const probability = count / samples;
    const stdError = Math.sqrt(probability * (1 - probability) / samples);

    return {
      probability: parseFloat(probability.toFixed(6)),
      stdError: parseFloat(stdError.toFixed(6)),
      count,
      samples,
      ci95: [
        Math.max(0, parseFloat((probability - 1.96 * stdError).toFixed(6))),
        Math.min(1, parseFloat((probability + 1.96 * stdError).toFixed(6)))
      ],
      backend: 'js'
    };
  }

  /**
   * Sample from distributions
   */
  async sample(distribution, params = {}, n = 1) {
    // For large sample counts, try Go (parallelized sampling)
    if (n >= this.config.goThreshold && this.config.useGo && this.binaryExists('mc-go')) {
      try {
        const result = await this.executeBinary('mc-go',
          ['sample', distribution, n.toString()],
          params);
        return result.samples;
      } catch (e) {
        console.warn('Go sampling failed, falling back to JS:', e.message);
      }
    }

    // Fallback to JS
    return this._sampleJS(distribution, params, n);
  }

  /**
   * JavaScript fallback for sampling
   */
  _sampleJS(distribution, params = {}, n = 1) {
    const samples = [];
    for (let i = 0; i < n; i++) {
      switch (distribution.toLowerCase()) {
        case 'uniform':
          samples.push(this.sampleUniform(params.min || 0, params.max || 1));
          break;
        case 'normal': case 'gaussian':
          samples.push(this.sampleNormal(params.mean || 0, params.stddev || 1));
          break;
        case 'exponential':
          samples.push(this.sampleExponential(params.lambda || 1));
          break;
        case 'poisson':
          samples.push(this.samplePoisson(params.lambda || 1));
          break;
        case 'binomial':
          samples.push(this.sampleBinomial(params.n || 10, params.p || 0.5));
          break;
        default:
          throw new Error(`Unknown distribution: ${distribution}`);
      }
    }
    return n === 1 ? samples[0] : samples;
  }

  /**
   * Portfolio simulation with Go acceleration
   */
  async simulatePortfolio(assets, correlations, periods = 252, iterations = 1000) {
    // For large iterations, try Go (embarrassingly parallel)
    if (iterations >= this.config.goThreshold && this.config.useGo && 
        this.binaryExists('mc-go')) {
      try {
        return await this.executeBinary('mc-go',
          ['portfolio', periods.toString(), iterations.toString()],
          { assets, correlations });
      } catch (e) {
        console.warn('Go portfolio sim failed, falling back to JS:', e.message);
      }
    }

    // Fallback to JS
    return this._simulatePortfolioJS(assets, correlations, periods, iterations);
  }

  /**
   * JavaScript fallback for portfolio simulation
   */
  _simulatePortfolioJS(assets, correlations, periods, iterations) {
    const returns = [];
    const volatility = assets.map(a => a.volatility);
    const expectedReturn = assets.map(a => a.expectedReturn);
    const weights = assets.map(a => a.weight);

    for (let iter = 0; iter < iterations; iter++) {
      let portfolioValue = 100;

      for (let t = 0; t < periods; t++) {
        let periodReturn = 0;
        for (let i = 0; i < assets.length; i++) {
          const assetReturn = expectedReturn[i] / 252 + 
                             volatility[i] / Math.sqrt(252) * this.sampleNormal(0, 1);
          periodReturn += weights[i] * assetReturn;
        }
        portfolioValue *= (1 + periodReturn);
      }
      returns.push(portfolioValue);
    }

    returns.sort((a, b) => a - b);
    const mean = returns.reduce((a, b) => a + b) / returns.length;
    const std = Math.sqrt(returns.reduce((a, b) => a + (b - mean) ** 2) / returns.length);

    return {
      mean: parseFloat(mean.toFixed(2)),
      std: parseFloat(std.toFixed(2)),
      min: parseFloat(returns[0].toFixed(2)),
      max: parseFloat(returns[returns.length - 1].toFixed(2)),
      var95: parseFloat(returns[Math.floor(0.05 * returns.length)].toFixed(2)),
      cvar95: parseFloat(returns.slice(0, Math.floor(0.05 * returns.length))
        .reduce((a, b) => a + b) / Math.floor(0.05 * returns.length).toFixed(2)),
      iterations,
      backend: 'js'
    };
  }

  /**
   * Estimate Pi
   */
  async estimatePi(samples = this.config.samples) {
    // For large samples, try Rust
    if (samples >= this.config.rustThreshold && this.config.useRust && 
        this.binaryExists('mc-rust')) {
      try {
        return await this.executeBinary('mc-rust',
          ['pi', samples.toString()]);
      } catch (e) {
        console.warn('Rust pi estimation failed, falling back to JS:', e.message);
      }
    }

    return this._estimatePiJS(samples);
  }

  /**
   * JavaScript fallback for pi estimation
   */
  _estimatePiJS(samples) {
    let inside = 0;
    for (let i = 0; i < samples; i++) {
      const x = this.rng();
      const y = this.rng();
      if (x * x + y * y <= 1) inside++;
    }
    const piEstimate = 4 * inside / samples;
    return {
      estimate: parseFloat(piEstimate.toFixed(6)),
      actual: parseFloat(Math.PI.toFixed(6)),
      error: parseFloat(Math.abs(piEstimate - Math.PI).toFixed(6)),
      samples,
      backend: 'js'
    };
  }

  /**
   * Distribution sampling methods (JS fallbacks)
   */
  sampleUniform(min, max) {
    return min + this.rng() * (max - min);
  }

  sampleNormal(mean, stddev) {
    const u1 = this.rng();
    const u2 = this.rng();
    const z0 = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
    return mean + stddev * z0;
  }

  sampleExponential(lambda) {
    return -Math.log(1 - this.rng()) / lambda;
  }

  samplePoisson(lambda) {
    let L = Math.exp(-lambda);
    let k = 0;
    let p = 1;
    do {
      p *= this.rng();
      if (p > L) k++;
    } while (p > L);
    return k;
  }

  sampleBinomial(n, p) {
    let count = 0;
    for (let i = 0; i < n; i++) {
      if (this.rng() < p) count++;
    }
    return count;
  }

  /**
   * Statistics
   */
  stats(data) {
    const sorted = [...data].sort((a, b) => a - b);
    const mean = data.reduce((a, b) => a + b) / data.length;
    let median;
    if (sorted.length % 2 === 0) {
      median = (sorted[sorted.length / 2 - 1] + sorted[sorted.length / 2]) / 2;
    } else {
      median = sorted[Math.floor(sorted.length / 2)];
    }
    const std = Math.sqrt(data.reduce((a, b) => a + (b - mean) ** 2) / data.length);

    return {
      mean: parseFloat(mean.toFixed(6)),
      median: parseFloat(median.toFixed(6)),
      std: parseFloat(std.toFixed(6)),
      min: sorted[0],
      max: sorted[sorted.length - 1],
      q1: sorted[Math.floor(0.25 * sorted.length)],
      q3: sorted[Math.floor(0.75 * sorted.length)],
      n: data.length
    };
  }
}

module.exports = MonteCarloHybridSimulator;
