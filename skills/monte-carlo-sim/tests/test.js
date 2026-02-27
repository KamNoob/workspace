/**
 * Monte Carlo Simulation Tests
 */

const MC = require('../lib/simulator.js');

function assert(condition, message) {
  if (!condition) {
    console.error(`✗ FAILED: ${message}`);
    process.exit(1);
  }
}

function test(name, fn) {
  try {
    fn();
    console.log(`✓ ${name}`);
  } catch (err) {
    console.error(`✗ ${name}: ${err.message}`);
    process.exit(1);
  }
}

const mc = new MC({ seed: 42 });

// Test 1: Integral Estimation
test('estimateIntegral: ∫x² dx from 0 to 1 ≈ 1/3', () => {
  const result = mc.estimateIntegral(x => x * x, 0, 1, 100000);
  assert(Math.abs(result.integral - 1/3) < 0.01, 
    `Expected ~0.333, got ${result.integral}`);
  assert(result.ci95, 'Should have confidence interval');
});

// Test 2: Probability Estimation
test('estimateProbability: P(X > 0.5) ≈ 0.5', () => {
  const result = mc.estimateProbability(
    (i, rng) => rng() > 0.5,
    100000
  );
  assert(Math.abs(result.probability - 0.5) < 0.01,
    `Expected ~0.5, got ${result.probability}`);
});

// Test 3: Pi Estimation
test('estimatePi: π ≈ 3.14159', () => {
  const result = mc.estimatePi(1000000);
  assert(Math.abs(result.estimate - Math.PI) < 0.01,
    `Expected ~3.14159, got ${result.estimate}`);
});

// Test 4: Normal Distribution Sampling
test('sample: Normal distribution has correct mean/std', () => {
  const samples = mc.sample('normal', {mean: 100, stddev: 15}, 10000);
  const stats = mc.stats(samples);
  assert(Math.abs(stats.mean - 100) < 2,
    `Expected mean ~100, got ${stats.mean}`);
  assert(Math.abs(stats.std - 15) < 2,
    `Expected std ~15, got ${stats.std}`);
});

// Test 5: Uniform Distribution
test('sample: Uniform distribution matches range', () => {
  const samples = mc.sample('uniform', {min: 5, max: 10}, 10000);
  const stats = mc.stats(samples);
  assert(stats.min >= 5 && stats.max <= 10,
    `Expected range [5,10], got [${stats.min}, ${stats.max}]`);
  assert(Math.abs(stats.mean - 7.5) < 0.5,
    `Expected mean ~7.5, got ${stats.mean}`);
});

// Test 6: Seeded RNG Reproducibility
test('RNG with seed produces identical results', () => {
  const mc1 = new MC({ seed: 999 });
  const mc2 = new MC({ seed: 999 });
  
  const result1 = mc1.estimateIntegral(x => x*x, 0, 1, 5000);
  const result2 = mc2.estimateIntegral(x => x*x, 0, 1, 5000);
  
  assert(result1.integral === result2.integral,
    `Seeded RNG should produce identical results`);
});

// Test 7: Statistics
test('stats: Descriptive statistics are correct', () => {
  const data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  const stats = mc.stats(data);
  
  assert(stats.mean === 5.5, `Expected mean 5.5, got ${stats.mean}`);
  assert(stats.median === 5.5, `Expected median 5.5, got ${stats.median}`);
  assert(stats.min === 1, `Expected min 1, got ${stats.min}`);
  assert(stats.max === 10, `Expected max 10, got ${stats.max}`);
});

// Test 8: Poisson Distribution
test('sample: Poisson distribution basic properties', () => {
  const samples = mc.sample('poisson', {lambda: 5}, 10000);
  const stats = mc.stats(samples);
  // For Poisson, mean should equal lambda
  assert(Math.abs(stats.mean - 5) < 0.5,
    `Expected mean ~5, got ${stats.mean}`);
});

// Test 9: Portfolio Simulation
test('simulatePortfolio: Returns valid risk metrics', () => {
  const assets = [
    { weight: 0.6, expectedReturn: 0.08, volatility: 0.15 },
    { weight: 0.4, expectedReturn: 0.04, volatility: 0.05 }
  ];
  const result = mc.simulatePortfolio(assets, [], 252, 1000);
  
  assert(result.mean > 0, 'Mean should be positive');
  assert(result.std > 0, 'Std should be positive');
  assert(result.var95 > 0, 'VaR should be positive');
  assert(result.min < result.mean, 'Min should be less than mean');
  assert(result.max > result.mean, 'Max should be greater than mean');
});

// Test 10: Error Handling
test('error handling: Invalid distribution throws error', () => {
  try {
    mc.sample('unknown_dist', {}, 1);
    assert(false, 'Should have thrown error');
  } catch (err) {
    assert(err.message.includes('Unknown distribution'), 
      'Should have appropriate error message');
  }
});

console.log('\n✓ All tests passed!');
