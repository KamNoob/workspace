#!/usr/bin/env node

/**
 * Test suite for task classification
 * Validates accuracy against known examples
 */

const { execSync } = require('child_process');

// Known test cases with expected classifications
const TEST_CASES = [
  {
    description: "Research OAuth 2.0 security best practices",
    expected_type: "research",
    expected_complexity: "low"
  },
  {
    description: "Build secure API authentication system",
    expected_type: "code",
    expected_complexity: "high"
  },
  {
    description: "Audit system for vulnerabilities and security holes",
    expected_type: "security",
    expected_complexity: "medium"
  },
  {
    description: "Set up automated monitoring and deployment pipeline",
    expected_type: "infrastructure",
    expected_complexity: "high"
  },
  {
    description: "Analyze user engagement metrics and generate report",
    expected_type: "analysis",
    expected_complexity: "medium"
  },
  {
    description: "Write comprehensive API documentation",
    expected_type: "documentation",
    expected_complexity: "low"
  },
  {
    description: "Quick lookup of error code meaning",
    expected_type: "research",
    expected_complexity: "low"
  },
  {
    description: "Implement machine learning model for image classification",
    expected_type: "code",
    expected_complexity: "high"
  }
];

function classify(description) {
  try {
    const result = execSync(
      `node scripts/nn/classify-task.js "${description}"`,
      { encoding: 'utf8', cwd: process.env.HOME + '/.openclaw/workspace' }
    );
    return JSON.parse(result);
  } catch (error) {
    return { error: error.message };
  }
}

console.log('🧪 Testing Task Classifier\n');
console.log('═'.repeat(80));

let correct = 0;
let total = TEST_CASES.length;
let totalTime = 0;

TEST_CASES.forEach((testCase, idx) => {
  console.log(`\nTest ${idx + 1}/${total}: ${testCase.description}`);
  
  const result = classify(testCase.description);
  
  if (result.error) {
    console.log(`❌ ERROR: ${result.error}`);
    return;
  }
  
  const typeMatch = result.task_type === testCase.expected_type;
  const complexityMatch = result.intent.complexity === testCase.expected_complexity;
  
  console.log(`  Predicted: ${result.task_type} (${(result.confidence * 100).toFixed(1)}% confidence)`);
  console.log(`  Expected:  ${testCase.expected_type}`);
  console.log(`  Result:    ${typeMatch ? '✅ CORRECT' : '❌ WRONG'}`);
  
  console.log(`  Complexity: ${result.intent.complexity} (expected: ${testCase.expected_complexity})`);
  console.log(`  Inference:  ${result.inference_time_ms}ms`);
  
  if (typeMatch) correct++;
  totalTime += result.inference_time_ms;
});

console.log('\n' + '═'.repeat(80));
console.log(`\n📊 Results:`);
console.log(`  Accuracy: ${correct}/${total} (${(correct/total * 100).toFixed(1)}%)`);
console.log(`  Avg Time: ${(totalTime/total).toFixed(0)}ms per classification`);
console.log(`  Status:   ${correct/total >= 0.85 ? '✅ PASSING (≥85%)' : '⚠️ NEEDS IMPROVEMENT'}`);
