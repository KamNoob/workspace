#!/usr/bin/env node

/**
 * Bootstrap Memory Optimizer with your actual memories
 * Integrates MEMORY.md and daily memory files into RL system
 */

const MemoryOptimizer = require('./optimizer');
const fs = require('fs');
const path = require('path');

class MemoryBootstrap {
  constructor() {
    this.optimizer = new MemoryOptimizer({
      alpha: 0.01,
      gamma: 0.99,
      lambda: 0.9
    });
  }

  /**
   * Load memories from daily memory files
   */
  loadDailyMemories() {
    const memory_dir = path.join(__dirname, '../../memory');
    
    if (!fs.existsSync(memory_dir)) {
      console.log('[Bootstrap] Memory directory not found');
      return 0;
    }

    let count = 0;
    const memory_files = fs.readdirSync(memory_dir)
      .filter(f => f.endsWith('.md'))
      .sort()
      .reverse()  // Most recent first
      .slice(0, 5);  // Load last 5 days

    memory_files.forEach(file => {
      const file_path = path.join(memory_dir, file);
      const content = fs.readFileSync(file_path, 'utf8');
      
      // Extract facts from each daily memory
      const facts = this.extractFacts(content, file);
      facts.forEach(fact => {
        this.optimizer.store({
          text: fact.text,
          category: fact.category,
          context: fact.context
        });
        count++;
      });
    });

    console.log(`[Bootstrap] Loaded ${count} facts from daily memories`);
    return count;
  }

  /**
   * Extract actionable facts from memory content
   */
  extractFacts(content, source_file) {
    const facts = [];
    const date = source_file.replace('.md', '').split('-').slice(0, 3).join('-');

    // Extract sections
    const sections = content.split(/^#+\s+/m);
    
    sections.forEach(section => {
      const lines = section.split('\n');
      const title = lines[0];

      // Skip if empty
      if (!title || title.length === 0) return;

      // Extract checkmarks as completed facts
      lines.forEach(line => {
        if (line.match(/^- ✅/)) {
          const fact_text = line.replace('- ✅', '').trim();
          facts.push({
            text: `✅ ${fact_text}`,
            category: 'completion',
            context: title.toLowerCase().replace(/\s+/g, '-')
          });
        }
        
        // Extract key metrics
        if (line.match(/^\|\s+/)) {
          const cell = line.split('|')[1]?.trim();
          if (cell && cell.length > 0 && !cell.includes('---')) {
            facts.push({
              text: cell,
              category: 'metric',
              context: title.toLowerCase().replace(/\s+/g, '-')
            });
          }
        }
      });

      // Extract summary sentences
      const summary = lines
        .filter(l => l.match(/^[A-Z]/))
        .slice(0, 2)
        .join(' ')
        .trim();

      if (summary && summary.length > 10) {
        facts.push({
          text: summary,
          category: 'summary',
          context: title.toLowerCase().replace(/\s+/g, '-')
        });
      }
    });

    return facts;
  }

  /**
   * Load operational facts from your environment
   */
  loadOperationalFacts() {
    const facts = [
      // From MEMORY.md
      {
        text: 'Memory update: Notion sync integrated with OpenClaw',
        category: 'operational',
        context: 'notion-sync'
      },
      
      // From daily memories - Notion setup
      {
        text: '✅ Projects DB: 30d1ae7a37e2813ab1ecc474e12589f9',
        category: 'database',
        context: 'notion'
      },
      {
        text: '✅ Tasks DB: 30d1ae7a37e281998f35f5b239279588',
        category: 'database',
        context: 'notion'
      },
      {
        text: '✅ Team DB: 30d1ae7a37e28129a601cd92abb533fc',
        category: 'database',
        context: 'notion'
      },
      {
        text: '✅ Knowledge Base DB: 30d1ae7a37e281c6b095dc328caea7a9',
        category: 'database',
        context: 'notion'
      },
      
      // From daily memories - Agent assignments
      {
        text: 'Codex: 5 tasks (development/building)',
        category: 'agent-assignment',
        context: 'tasks'
      },
      {
        text: 'Sentinel: 5 tasks (DevOps/infrastructure)',
        category: 'agent-assignment',
        context: 'tasks'
      },
      {
        text: 'Lens: 2 tasks (analysis/optimization)',
        category: 'agent-assignment',
        context: 'tasks'
      },
      
      // Current operational state
      {
        text: 'OpenClaw status: Running on 2026.2.19-2 with 6 active sessions',
        category: 'operational',
        context: 'openclaw-status'
      },
      {
        text: 'Gateway: local loopback ws://127.0.0.1:18789, auth token configured',
        category: 'operational',
        context: 'gateway'
      },
      {
        text: 'Memory plugins: memory-lancedb enabled, auto-capture disabled',
        category: 'operational',
        context: 'memory-system'
      },
      {
        text: 'Heartbeat: 55m interval for cache warm, prompt caching enabled',
        category: 'optimization',
        context: 'token-efficiency'
      },
      {
        text: 'Default model: claude-haiku-4-5 with 200k context window',
        category: 'configuration',
        context: 'models'
      },
      
      // RL Skills deployed
      {
        text: '✅ RL Knowledge Base: 8/8 tests passing, 548 pages indexed',
        category: 'skill',
        context: 'rl'
      },
      {
        text: '✅ Memory Optimizer: 10/10 tests passing, Q-Learning + TD(λ)',
        category: 'skill',
        context: 'memory'
      },
      {
        text: 'Token savings: 70% on memory operations, 20-25% total reduction projected',
        category: 'metric',
        context: 'optimization'
      }
    ];

    facts.forEach(fact => {
      this.optimizer.store(fact);
    });

    console.log(`[Bootstrap] Loaded ${facts.length} operational facts`);
    return facts.length;
  }

  /**
   * Bootstrap initial Q-values based on importance
   */
  bootstrapQValues() {
    // High-importance facts get higher initial Q-values
    const boosted_contexts = [
      'database',       // Notion IDs are critical
      'gateway',        // Gateway config is critical
      'skill',          // Skills are important
      'operational'     // Operational facts matter
    ];

    Object.entries(this.optimizer.memories).forEach(([id, memory]) => {
      if (boosted_contexts.includes(memory.category)) {
        // Boost Q-value for important categories
        this.optimizer.q_values[id] = 0.8;  // Higher than default 0.5
      }
    });

    console.log('[Bootstrap] Bootstrapped Q-values for high-importance facts');
  }

  /**
   * Export and save
   */
  finalize() {
    this.optimizer.saveState = function() {
      const state = this.export();
      const file = path.join(__dirname, '../.memory-state-bootstrapped.json');
      fs.writeFileSync(file, JSON.stringify(state, null, 2));
      console.log(`[Bootstrap] State saved to ${file}`);
    };

    this.optimizer.saveState();
    return this.optimizer;
  }

  /**
   * Get bootstrap report
   */
  report() {
    const stats = this.optimizer.getStatistics();
    return `
╔════════════════════════════════════════════════════════════╗
║         MEMORY BOOTSTRAP COMPLETE                         ║
╠════════════════════════════════════════════════════════════╣
║ Total Memories Loaded:     ${String(stats.total_memories).padEnd(30)} ║
║ Average Q-Value:           ${String(stats.average_q_value).padEnd(30)} ║
║                                                            ║
║ High-Value Categories:                                   ║
║ - Database IDs (Notion)                                  ║
║ - Gateway Configuration                                 ║
║ - RL Skills Status                                       ║
║ - Operational Facts                                      ║
║                                                            ║
║ Next: System will optimize through your interactions     ║
║       Most-used facts will rise in priority              ║
║       Rarely-used facts will consolidate away            ║
╚════════════════════════════════════════════════════════════╝
    `;
  }
}

// Run bootstrap if called directly
if (require.main === module) {
  const bootstrap = new MemoryBootstrap();
  
  console.log('\n[Bootstrap] Starting memory optimizer bootstrap...\n');
  
  const daily_count = bootstrap.loadDailyMemories();
  const ops_count = bootstrap.loadOperationalFacts();
  bootstrap.bootstrapQValues();
  const optimizer = bootstrap.finalize();
  
  console.log(`\n[Bootstrap] Total facts loaded: ${daily_count + ops_count}\n`);
  console.log(bootstrap.report());
  
  console.log('\n✅ Memory optimizer is ready with your actual memories!\n');
}

module.exports = MemoryBootstrap;
