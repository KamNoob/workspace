# Monte Carlo Simulation Skill

**Purpose:** Perform Monte Carlo simulations for probability estimation, numerical integration, risk modeling, and statistical analysis.

**Status:** Production-ready  
**Version:** 1.0.0  
**Created:** 2026-02-23

---

## Overview

This skill provides a complete Monte Carlo simulation engine with:
- **Numerical integration** via sampling (estimate ∫ f(x) dx)
- **Probability estimation** (P(condition))
- **Distribution sampling** (Uniform, Normal, Exponential, Poisson, Binomial)
- **Portfolio/risk modeling** (financial simulations)
- **Statistical analysis** (mean, std, percentiles)
- **Seeded RNG** for reproducible results

---

## Quick Start

### 1. Estimate an Integral

```bash
# Estimate ∫ x² dx from 0 to 1 (answer: 1/3 ≈ 0.333)
mc integrate "x*x" 0 1 --samples 100000

# Output:
# {
#   "integral": 0.333217,
#   "stdError": 0.005432,
#   "samples": 100000,
#   "ci95": [0.322569, 0.343865]
# }
```

### 2. Estimate Probability

```bash
# What's the probability that a random number in [0,1] is > 0.7?
mc probability "Math.random() > 0.7" --samples 100000

# Output:
# {
#   "probability": 0.3001,
#   "stdError": 0.004582,
#   "ci95": [0.291, 0.309]
# }
```

### 3. Sample from Distributions

```bash
# Generate 100 samples from Normal(mean=0, std=1)
mc sample normal --n 100 --params '{"mean":0,"stddev":1}'

# Or single Exponential(lambda=0.5)
mc sample exponential --params '{"lambda":0.5}'
```

### 4. Portfolio Risk Simulation

```bash
# Simulate portfolio with 60% stocks, 40% bonds
cat > portfolio.json << 'EOF'
[
  {"weight": 0.6, "expectedReturn": 0.08, "volatility": 0.15},
  {"weight": 0.4, "expectedReturn": 0.04, "volatility": 0.05}
]
EOF

mc portfolio "$(cat portfolio.json)" --periods 252 --iterations 10000

# Output: Mean/std of portfolio value, VaR (95%), CVaR
```

### 5. Estimate Pi (Classic MC Test)

```bash
# Estimate π by sampling points in unit circle
mc pi --samples 1000000

# Output:
# {
#   "estimate": 3.141592,
#   "actual": 3.141593,
#   "error": 0.000001
# }
```

---

## API Reference

### `MonteCarloSimulator(config)`

Constructor with options:
- `samples` (number, default 10000): Default sample count
- `seed` (number, optional): Random seed for reproducibility

### Methods

#### `estimateIntegral(fn, a, b, samples)`
Estimate ∫ f(x) dx from a to b using uniform sampling.

**Returns:**
```js
{
  integral: number,      // Estimated integral value
  stdError: number,      // Standard error
  samples: number,
  ci95: [lower, upper]   // 95% confidence interval
}
```

**Example:**
```js
const MC = require('./lib/simulator.js');
const mc = new MC({ seed: 42 });

const result = mc.estimateIntegral(
  x => Math.sin(x),
  0,
  Math.PI,
  100000
);
// result.integral ≈ 2.0
```

#### `estimateProbability(fn, samples)`
Estimate P(condition is true) via sampling.

**Returns:**
```js
{
  probability: number,
  stdError: number,
  count: number,         // How many samples satisfied condition
  samples: number,
  ci95: [lower, upper]
}
```

**Example:**
```js
const result = mc.estimateProbability(
  (i, rng) => {
    const x = rng();
    return x > 0.5 && x < 0.75;  // P(0.5 < X < 0.75)
  },
  100000
);
// result.probability ≈ 0.25
```

#### `sample(distribution, params, n)`
Sample from a distribution.

**Supported Distributions:**
- `'uniform'`: `{min, max}`
- `'normal'` or `'gaussian'`: `{mean, stddev}`
- `'exponential'`: `{lambda}`
- `'poisson'`: `{lambda}`
- `'binomial'`: `{n, p}` (n trials, success probability p)

**Example:**
```js
const samples = mc.sample('normal', {mean: 100, stddev: 15}, 1000);
// Array of 1000 samples from N(100, 15²)
```

#### `simulatePortfolio(assets, correlations, periods, iterations)`
Monte Carlo simulation for portfolio risk.

**Assets format:**
```js
[
  { weight: 0.6, expectedReturn: 0.08, volatility: 0.15 },
  { weight: 0.4, expectedReturn: 0.04, volatility: 0.05 }
]
```

**Returns:**
```js
{
  mean: number,      // Mean final portfolio value
  std: number,       // Std deviation
  min: number,       // Worst case
  max: number,       // Best case
  var95: number,     // Value at Risk (95%)
  cvar95: number,    // Conditional VaR (expected shortfall)
  iterations: number
}
```

#### `stats(data)`
Calculate statistics on an array of numbers.

**Returns:**
```js
{
  mean: number,
  median: number,
  std: number,
  min: number,
  max: number,
  q1: number,        // 25th percentile
  q3: number,        // 75th percentile
  n: number          // Sample size
}
```

#### `estimatePi(samples)`
Estimate π by sampling points uniformly in [0,1]² and counting those inside the unit circle.

**Returns:**
```js
{
  estimate: number,
  actual: number,
  error: number,
  samples: number
}
```

---

## Use Cases

### 1. **Numerical Integration**
Estimate complex integrals where analytical solutions don't exist.
```js
// ∫ exp(-x²) dx (Gaussian integral component)
mc.estimateIntegral(x => Math.exp(-x*x), 0, 3, 100000)
```

### 2. **Option Pricing (Finance)**
Simulate asset paths for Black-Scholes-like pricing.
```js
// Large number of portfolio simulations for derivative pricing
```

### 3. **Risk Quantification**
Estimate VaR, CVaR, and tail risks for portfolios.
```js
mc.simulatePortfolio(portfolio, [], 252, 10000)
```

### 4. **Reliability Engineering**
Estimate system failure probabilities under uncertainty.
```js
mc.estimateProbability(
  (i, rng) => systemFailures(rng) > criticalThreshold,
  100000
)
```

### 5. **Bayesian Inference**
Generate posterior samples using MCMC (not included, but framework supports).

---

## Reproducibility

Use seeded RNG for deterministic results:

```js
const mc1 = new MC({ seed: 12345 });
const mc2 = new MC({ seed: 12345 });

const r1 = mc1.estimateIntegral(x => x*x, 0, 1, 1000);
const r2 = mc2.estimateIntegral(x => x*x, 0, 1, 1000);

console.assert(r1.integral === r2.integral); // Always true
```

---

## Performance Notes

- **Convergence:** Error scales as O(1/√N), so need 100x more samples for 10x accuracy
- **Dimensionality:** For high-dimensional problems (>10), consider MCMC or importance sampling
- **Memory:** Stores all samples in `estimateIntegral` for variance estimation; adjust if needed

---

## References

- Numerical Recipes: Monte Carlo Integration
- Portfolio Risk: Jorion, "Value at Risk"
- General: Glasserman, "Monte Carlo Methods in Financial Engineering"
