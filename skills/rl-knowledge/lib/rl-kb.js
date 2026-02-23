#!/usr/bin/env node

/**
 * RL Knowledge Base - Query Interface
 * Sutton & Barto 2nd Edition Enhanced Integration
 */

const fs = require('fs');
const path = require('path');

class RLKnowledgeBase {
  constructor() {
    this.dataPath = path.join(__dirname, '../data');
    this.kb = this.loadKB();
    this.index = this.buildIndex();
  }

  loadKB() {
    try {
      const jsonPath = path.join(__dirname, '../../..', 'RL-BOOK-ENHANCED.json');
      return JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    } catch (e) {
      console.error('Error loading KB:', e.message);
      return {};
    }
  }

  buildIndex() {
    const idx = {
      algorithms: {},
      concepts: {},
      chapters: {},
      methods: {},
      tags: {}
    };

    // Index algorithms
    if (this.kb.algorithms) {
      Object.entries(this.kb.algorithms).forEach(([category, algs]) => {
        (Array.isArray(algs) ? algs : [algs]).forEach(alg => {
          const name = alg.name.toLowerCase();
          idx.algorithms[name] = { ...alg, category };
          (alg.name.split(/\s+/).slice(0, 2)).forEach(word => {
            if (!idx.tags[word.toLowerCase()]) idx.tags[word.toLowerCase()] = [];
            idx.tags[word.toLowerCase()].push(name);
          });
        });
      });
    }

    // Index concepts from multiple sources
    if (this.kb.key_concepts) {
      Object.entries(this.kb.key_concepts).forEach(([concept, data]) => {
        idx.concepts[concept.toLowerCase()] = data;
      });
    }

    // Also index core concepts from quick_reference
    if (this.kb.quick_reference && this.kb.quick_reference.core_concepts) {
      this.kb.quick_reference.core_concepts.forEach(concept => {
        const name = concept.name.toLowerCase();
        idx.concepts[name] = concept;
      });
    }

    // Index chapters
    if (this.kb.parts) {
      this.kb.parts.forEach(part => {
        if (part.chapters) {
          part.chapters.forEach(ch => {
            idx.chapters[ch.chapter] = { ...ch, part_id: part.part_id };
          });
        }
      });
    }

    return idx;
  }

  query(type, term) {
    const t = term.toLowerCase();
    
    switch(type) {
      case 'algorithm':
        return this.queryAlgorithm(t);
      case 'concept':
        return this.queryConcept(t);
      case 'chapter':
        return this.queryChapter(t);
      case 'compare':
        return this.queryCompare(t);
      case 'search':
        return this.search(t);
      case 'explain':
        return this.explain(t);
      default:
        return { error: `Unknown query type: ${type}` };
    }
  }

  queryAlgorithm(name) {
    const alg = this.index.algorithms[name];
    if (!alg) {
      // Try fuzzy match
      const matches = Object.keys(this.index.algorithms)
        .filter(k => k.includes(name))
        .slice(0, 5);
      if (matches.length) {
        return { 
          error: `Algorithm "${name}" not found. Did you mean:`,
          suggestions: matches
        };
      }
      return { error: `Algorithm "${name}" not found` };
    }

    return {
      type: 'algorithm',
      ...alg,
      related: this.findRelated(name)
    };
  }

  queryConcept(concept) {
    const data = this.index.concepts[concept];
    if (!data) {
      return { error: `Concept "${concept}" not found` };
    }
    return { type: 'concept', concept, ...data };
  }

  queryChapter(num) {
    const ch = this.index.chapters[parseInt(num)];
    if (!ch) {
      return { error: `Chapter ${num} not found` };
    }
    return { type: 'chapter', ...ch };
  }

  queryCompare(comparison) {
    const [a, b] = comparison.split(/\s+vs\s+|\s+vs\.\s+/);
    const alg1 = this.queryAlgorithm(a.trim());
    const alg2 = this.queryAlgorithm(b.trim());

    if (alg1.error || alg2.error) {
      return { error: 'One or both algorithms not found' };
    }

    return {
      type: 'comparison',
      algorithm_1: { name: alg1.name, type: alg1.type, convergence: alg1.convergence },
      algorithm_2: { name: alg2.name, type: alg2.type, convergence: alg2.convergence },
      analysis: this.compareAlgorithms(alg1, alg2)
    };
  }

  compareAlgorithms(alg1, alg2) {
    return {
      model_required: {
        alg1: alg1.requires_model ? 'Yes' : 'No',
        alg2: alg2.requires_model ? 'Yes' : 'No'
      },
      policy_type: {
        alg1: alg1.type,
        alg2: alg2.type
      },
      key_difference: this.identifyDifference(alg1, alg2)
    };
  }

  identifyDifference(alg1, alg2) {
    if (alg1.requires_model !== alg2.requires_model) {
      return `${alg1.name} ${alg1.requires_model ? 'requires' : 'does not require'} model; ${alg2.name} ${alg2.requires_model ? 'does' : 'does not'}`;
    }
    if (alg1.type !== alg2.type) {
      return `${alg1.name} is ${alg1.type}; ${alg2.name} is ${alg2.type}`;
    }
    return 'Both algorithms have similar properties';
  }

  search(term) {
    const results = [];
    const t = term.toLowerCase();

    // Search algorithms
    if (this.index.algorithms) {
      Object.entries(this.index.algorithms).forEach(([key, alg]) => {
        if (key.includes(t) || 
            (alg.formula && alg.formula.toLowerCase().includes(t)) ||
            (alg.convergence && alg.convergence.toLowerCase().includes(t))) {
          results.push({ type: 'algorithm', name: alg.name, match: key });
        }
      });
    }

    // Search concepts
    if (this.index.concepts) {
      Object.entries(this.index.concepts).forEach(([key, concept]) => {
        if (key.includes(t) || 
            (concept.definition && concept.definition.toLowerCase().includes(t))) {
          results.push({ type: 'concept', name: key });
        }
      });
    }

    // Search chapters
    if (this.index.chapters) {
      Object.entries(this.index.chapters).forEach(([num, ch]) => {
        if ((ch.title && ch.title.toLowerCase().includes(t)) || 
            (ch.topics && ch.topics.some(tp => tp.toLowerCase().includes(t)))) {
          results.push({ type: 'chapter', chapter: num, title: ch.title });
        }
      });
    }

    return {
      type: 'search',
      query: term,
      results: results.length > 0 ? results.slice(0, 10) : [],
      total: results.length
    };
  }

  explain(term) {
    const t = term.toLowerCase();
    
    // Check if it's an algorithm
    if (this.index.algorithms[t]) {
      const alg = this.index.algorithms[t];
      return {
        type: 'explanation',
        term: alg.name,
        category: 'algorithm',
        formula: alg.formula,
        description: alg.convergence || 'Check convergence_guarantees',
        properties: {
          requires_model: alg.requires_model,
          policy_type: alg.type
        }
      };
    }

    // Check if it's a concept
    if (this.index.concepts[t]) {
      const concept = this.index.concepts[t];
      return {
        type: 'explanation',
        term: t,
        category: 'concept',
        definition: concept.definition,
        components: concept.challenges || concept.methods || concept.solutions
      };
    }

    return { error: `Cannot explain "${term}" - not found in knowledge base` };
  }

  findRelated(algorithm) {
    const related = [];
    const algs = this.kb.algorithms.tabular_methods || [];
    
    algs.forEach(alg => {
      if (alg.name.toLowerCase() !== algorithm) {
        related.push(alg.name);
      }
    });

    return related.slice(0, 3);
  }

  recommend(problemDesc) {
    const desc = problemDesc.toLowerCase();
    const scores = {};

    Object.entries(this.index.algorithms).forEach(([key, alg]) => {
      scores[alg.name] = 0;
      if (desc.includes('model') && !alg.requires_model) scores[alg.name] += 2;
      if (desc.includes('offline') && alg.type === 'Off-policy') scores[alg.name] += 2;
      if (desc.includes('online') && alg.type === 'On-policy') scores[alg.name] += 2;
      if (desc.includes('continuous') && alg.category === 'function_approximation_methods') scores[alg.name] += 2;
    });

    const recommendations = Object.entries(scores)
      .filter(([_, score]) => score > 0)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([name, score]) => ({ name, score }));

    return {
      type: 'recommendation',
      problem: problemDesc,
      recommendations: recommendations.length > 0 ? recommendations : { note: 'Try search or list algorithms' }
    };
  }

  help() {
    return {
      commands: {
        'query algorithm <name>': 'Get details about an algorithm',
        'query concept <name>': 'Explain a concept',
        'query chapter <number>': 'Get chapter overview',
        'compare <alg1> vs <alg2>': 'Compare two algorithms',
        'search <term>': 'Full-text search',
        'explain <term>': 'Get explanation of term',
        'recommend <problem>': 'Recommend algorithm for problem',
        'list algorithms': 'List all algorithms',
        'list concepts': 'List all concepts',
        'convergence <algorithm>': 'Get convergence guarantees'
      },
      examples: [
        'rl query algorithm Q-Learning',
        'rl query concept exploration_exploitation',
        'rl compare Sarsa vs Q-Learning',
        'rl search Bellman',
        'rl recommend "offline learning without model"',
        'rl explain TD error'
      ]
    };
  }

  listAlgorithms() {
    return {
      type: 'list',
      category: 'algorithms',
      tabular: Object.values(this.index.algorithms)
        .filter(a => a.category === 'tabular_methods')
        .map(a => a.name),
      function_approximation: Object.values(this.index.algorithms)
        .filter(a => a.category === 'function_approximation_methods')
        .map(a => a.name)
    };
  }

  listConcepts() {
    return {
      type: 'list',
      category: 'concepts',
      concepts: Object.keys(this.index.concepts)
    };
  }

  getConvergence(algorithm) {
    const t = algorithm.toLowerCase();
    if (this.kb.convergence_guarantees) {
      const match = this.kb.convergence_guarantees.find(
        cg => cg.algorithm.toLowerCase().includes(t)
      );
      return match || { error: `No convergence info for ${algorithm}` };
    }
    return { error: 'Convergence data not found' };
  }

  getPseudocode(algorithm) {
    return {
      type: 'pseudocode',
      algorithm: algorithm,
      pseudocode: this.generatePseudocode(algorithm),
      source: 'Sutton & Barto 2nd Edition'
    };
  }

  generatePseudocode(alg) {
    const pseudocodes = {
      'q-learning': `
Initialize Q(s,a) arbitrarily
repeat (for each episode):
  s ← initial state
  repeat (for each step of episode):
    a ← ε-greedy(Q, s)
    take action a; observe r, s'
    Q(s,a) ← Q(s,a) + α[r + γ max_a' Q(s',a') - Q(s,a)]
    s ← s'
  until s is terminal
      `,
      'sarsa': `
Initialize Q(s,a) arbitrarily
repeat (for each episode):
  s ← initial state
  a ← ε-greedy(Q, s)
  repeat (for each step of episode):
    take action a; observe r, s'
    a' ← ε-greedy(Q, s')
    Q(s,a) ← Q(s,a) + α[r + γQ(s',a') - Q(s,a)]
    s ← s'; a ← a'
  until s is terminal
      `,
      'reinforce': `
Initialize θ
repeat (for each episode):
  generate episode: s_0, a_0, r_1, ..., s_T-1, a_T-1, r_T
  repeat (for t = 0 to T-1):
    G_t ← Σ_{k=t}^{T-1} γ^{k-t} r_{k+1}
    θ ← θ + α ∇ln π(a_t|s_t,θ) G_t
      `,
      'actor-critic': `
Initialize θ and w
repeat (for each episode):
  s ← initial state
  repeat (for each step of episode):
    a ← policy(s, θ)
    take action a; observe r, s'
    δ ← r + γV(s',w) - V(s,w)
    w ← w + β δ ∇V(s,w)
    θ ← θ + α δ ∇ln π(a|s,θ)
    s ← s'
  until s is terminal
      `
    };

    return pseudocodes[alg.toLowerCase()] || 
           `Pseudocode for ${alg} not available. Check source material.`;
  }
}

// CLI Interface
if (require.main === module) {
  const kb = new RLKnowledgeBase();
  const args = process.argv.slice(2);

  if (!args.length) {
    console.log(JSON.stringify(kb.help(), null, 2));
    process.exit(0);
  }

  const [command, ...params] = args;

  try {
    let result;
    
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
      case 'help':
        result = kb.help();
        break;
      default:
        result = { error: `Unknown command: ${command}`, help: kb.help() };
    }

    console.log(JSON.stringify(result, null, 2));
  } catch (e) {
    console.error(JSON.stringify({ error: e.message }, null, 2));
    process.exit(1);
  }
}

module.exports = RLKnowledgeBase;
