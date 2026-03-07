#!/usr/bin/env node

/**
 * Task Classification with Neural Networks
 * Uses Transformers.js for local zero-shot classification
 * 
 * Usage: ./classify-task.js "task description here"
 * Output: JSON with task_type, confidence, and intent
 */

const { pipeline } = require('@xenova/transformers');

// Task type categories (aligned with Q-Learning system)
// Using descriptive labels for better zero-shot classification
const TASK_TYPES = [
  'research and investigation',
  'software development and coding',
  'security audit and vulnerability assessment',
  'infrastructure setup and automation',
  'data analysis and metrics',
  'technical documentation and writing'
];

// Intent/urgency categories
const URGENCY_LEVELS = [
  'urgent - needs immediate action',
  'normal - standard priority',
  'routine - maintenance or scheduled'
];

// Complexity levels
const COMPLEXITY_LEVELS = [
  'low complexity - simple task',
  'medium complexity - moderate effort',
  'high complexity - extensive work'
];

async function classifyTask(taskDescription) {
  try {
    // Load zero-shot classification model (small, efficient)
    // Using DistilBERT for task classification
    const classifier = await pipeline(
      'zero-shot-classification',
      'Xenova/distilbert-base-uncased-mnli'
    );
    
    // Classify task type
    const taskTypeResult = await classifier(taskDescription, TASK_TYPES, {
      multi_label: false
    });
    
    // Classify urgency
    const urgencyResult = await classifier(taskDescription, URGENCY_LEVELS, {
      multi_label: false
    });
    
    // Classify complexity
    const complexityResult = await classifier(taskDescription, COMPLEXITY_LEVELS, {
      multi_label: false
    });
    
    // Extract top predictions and normalize to Q-Learning categories
    const rawTaskType = taskTypeResult.labels[0];
    const taskTypeConfidence = taskTypeResult.scores[0];
    
    // Map descriptive labels back to Q-Learning categories
    const typeMap = {
      'research and investigation': 'research',
      'software development and coding': 'code',
      'security audit and vulnerability assessment': 'security',
      'infrastructure setup and automation': 'infrastructure',
      'data analysis and metrics': 'analysis',
      'technical documentation and writing': 'documentation'
    };
    const taskType = typeMap[rawTaskType] || rawTaskType;
    
    const urgency = urgencyResult.labels[0].split(' - ')[0];
    const urgencyConfidence = urgencyResult.scores[0];
    
    const complexity = complexityResult.labels[0].split(' - ')[0].replace(' complexity', '');
    const complexityConfidence = complexityResult.scores[0];
    
    // Prepare output
    const result = {
      task_type: taskType,
      confidence: taskTypeConfidence,
      intent: {
        urgency: urgency,
        urgency_confidence: urgencyConfidence,
        complexity: complexity,
        complexity_confidence: complexityConfidence
      },
      all_task_scores: {},
      timestamp: new Date().toISOString()
    };
    
    // Include all task type scores for analysis (normalized)
    taskTypeResult.labels.forEach((label, idx) => {
      const normalizedLabel = typeMap[label] || label;
      result.all_task_scores[normalizedLabel] = taskTypeResult.scores[idx];
    });
    
    return result;
    
  } catch (error) {
    return {
      error: error.message,
      task_description: taskDescription,
      timestamp: new Date().toISOString()
    };
  }
}

// Main execution
(async () => {
  const taskDescription = process.argv[2];
  
  if (!taskDescription) {
    console.error('Usage: classify-task.js "task description"');
    process.exit(1);
  }
  
  const startTime = Date.now();
  const result = await classifyTask(taskDescription);
  const duration = Date.now() - startTime;
  
  result.inference_time_ms = duration;
  
  console.log(JSON.stringify(result, null, 2));
})();
