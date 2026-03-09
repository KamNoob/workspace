#!/usr/bin/env node

/**
 * LLMfit Infrastructure Analyzer
 * Hardware-aware model selection for Sentinel infrastructure planning
 * 
 * Scores models against system specs to determine:
 * - Runnable models (perfect fit, good fit, marginal fit)
 * - Memory requirements (RAM, VRAM)
 * - Estimated tokens/second
 * - Optimal quantization
 * - Run mode (GPU, CPU offload, CPU-only)
 */

const fs = require('fs');
const path = require('path');

class LLMfitAnalyzer {
  constructor() {
    const dbPath = path.join(__dirname, '../references/hf_models.json');
    this.models = JSON.parse(fs.readFileSync(dbPath, 'utf8'));
    this.fitLevels = {
      'perfect': 4,
      'good': 3,
      'marginal': 2,
      'tootight': 1,
      'impossible': 0
    };
  }

  /**
   * List all available models with basic info
   */
  listModels() {
    return this.models.map(m => ({
      name: m.name,
      params: m.parameter_count,
      params_raw: m.parameters_raw,
      use_case: m.use_case,
      context: m.context_length,
      min_ram: m.min_ram_gb,
      min_vram: m.min_vram_gb,
      quantization: m.quantization,
      architecture: m.architecture
    }));
  }

  /**
   * Analyze models for a given hardware configuration
   * @param {object} systemSpecs - { total_ram_gb, cpu_cores, vram_gb }
   * @returns {array} Models ranked by fit (perfect, good, marginal, tootight, impossible)
   */
  analyzeForSystem(systemSpecs) {
    const { total_ram_gb, cpu_cores, vram_gb } = systemSpecs;

    return this.models.map(model => {
      const fit = this._calculateFit(model, systemSpecs);
      const runMode = this._selectRunMode(model, systemSpecs);
      const tps = this._estimateTps(model, runMode, cpu_cores);

      return {
        name: model.name,
        params: model.parameter_count,
        params_raw: model.parameters_raw,
        use_case: model.use_case,
        architecture: model.architecture,
        context_length: model.context_length,
        quantization: model.quantization,
        fit: fit,
        fit_score: this.fitLevels[fit],
        run_mode: runMode,
        estimated_tps: tps,
        memory: {
          min_ram_gb: model.min_ram_gb,
          recommended_ram_gb: model.recommended_ram_gb,
          min_vram_gb: model.min_vram_gb,
          available_ram_gb: total_ram_gb,
          available_vram_gb: vram_gb || 0
        },
        utilization: {
          ram_percent: ((model.min_ram_gb / total_ram_gb) * 100).toFixed(1),
          vram_percent: vram_gb ? ((model.min_vram_gb / vram_gb) * 100).toFixed(1) : 'N/A'
        },
        headroom: {
          ram_gb: (total_ram_gb - model.min_ram_gb).toFixed(1),
          vram_gb: vram_gb ? (vram_gb - model.min_vram_gb).toFixed(1) : 'N/A'
        }
      };
    }).sort((a, b) => b.fit_score - a.fit_score);
  }

  /**
   * Find models matching specific criteria
   * @param {object} criteria - { min_params, max_params, use_case, architecture, min_context }
   * @returns {array} Matching models
   */
  search(criteria) {
    return this.models.filter(m => {
      if (criteria.min_params && m.parameters_raw < criteria.min_params) return false;
      if (criteria.max_params && m.parameters_raw > criteria.max_params) return false;
      if (criteria.use_case && !m.use_case.toLowerCase().includes(criteria.use_case.toLowerCase())) return false;
      if (criteria.architecture && m.architecture !== criteria.architecture) return false;
      if (criteria.min_context && m.context_length < criteria.min_context) return false;
      return true;
    });
  }

  /**
   * Get models suitable for specific use cases
   */
  getByUseCase(useCase) {
    const normalized = useCase.toLowerCase();
    return this.models.filter(m => m.use_case.toLowerCase().includes(normalized));
  }

  /**
   * Get models with specific architecture (mistral, llama, phi, etc)
   */
  getByArchitecture(architecture) {
    return this.models.filter(m => m.architecture === architecture.toLowerCase());
  }

  /**
   * Recommend hardware upgrades to run a model
   * @param {object} model - Model object
   * @param {object} systemSpecs - Current system specs
   * @returns {object} Upgrade recommendations
   */
  recommendUpgrades(model, systemSpecs) {
    const upgrades = [];

    if (systemSpecs.total_ram_gb < model.min_ram_gb) {
      upgrades.push({
        type: 'RAM',
        current_gb: systemSpecs.total_ram_gb,
        needed_gb: model.min_ram_gb,
        recommended_gb: model.recommended_ram_gb,
        delta_gb: (model.recommended_ram_gb - systemSpecs.total_ram_gb).toFixed(1)
      });
    }

    if ((systemSpecs.vram_gb || 0) < model.min_vram_gb) {
      upgrades.push({
        type: 'VRAM',
        current_gb: systemSpecs.vram_gb || 0,
        needed_gb: model.min_vram_gb,
        delta_gb: (model.min_vram_gb - (systemSpecs.vram_gb || 0)).toFixed(1)
      });
    }

    return {
      model_name: model.name,
      current_fit: this._calculateFit(model, systemSpecs),
      upgrades_needed: upgrades.length > 0,
      upgrades: upgrades
    };
  }

  /**
   * Get statistics about the model database
   */
  getStats() {
    const architectures = new Set(this.models.map(m => m.architecture));
    const useCases = new Set();
    this.models.forEach(m => useCases.add(m.use_case));

    const params = this.models.map(m => m.parameters_raw).sort((a, b) => a - b);
    const minParams = params[0];
    const maxParams = params[params.length - 1];
    const medianParams = params[Math.floor(params.length / 2)];

    return {
      total_models: this.models.length,
      architectures: Array.from(architectures).sort(),
      use_cases: Array.from(useCases).sort(),
      parameters: {
        min: minParams,
        max: maxParams,
        median: medianParams
      },
      context_windows: {
        min: Math.min(...this.models.map(m => m.context_length)),
        max: Math.max(...this.models.map(m => m.context_length)),
        median: this._getMedian(this.models.map(m => m.context_length))
      }
    };
  }

  /**
   * Private: Calculate fit level for a model on given hardware
   */
  _calculateFit(model, systemSpecs) {
    const { total_ram_gb, vram_gb } = systemSpecs;

    // GPU available and fits
    if (vram_gb && vram_gb >= model.min_vram_gb) {
      if (vram_gb >= model.min_vram_gb * 1.5) return 'perfect';
      return 'good';
    }

    // CPU-only path
    if (total_ram_gb >= model.recommended_ram_gb) return 'perfect';
    if (total_ram_gb >= model.min_ram_gb) return 'good';
    if (total_ram_gb >= model.min_ram_gb * 0.8) return 'marginal';
    if (total_ram_gb >= model.min_ram_gb * 0.5) return 'tootight';

    return 'impossible';
  }

  /**
   * Private: Select best run mode (GPU, CPU offload, CPU-only)
   */
  _selectRunMode(model, systemSpecs) {
    const { vram_gb, total_ram_gb } = systemSpecs;

    if (vram_gb && vram_gb >= model.min_vram_gb) {
      return 'GPU';
    }

    if (vram_gb && total_ram_gb >= model.min_ram_gb) {
      return 'CPU_OFFLOAD';
    }

    return 'CPU_ONLY';
  }

  /**
   * Private: Estimate tokens/second based on model and hardware
   */
  _estimateTps(model, runMode, cpuCores) {
    // Rough estimates based on empirical data
    // These are conservative estimates; actual TPS varies by quantization, CPU model, etc.

    const baselineSmall = 20;  // tokens/sec for small models on CPU
    const baselineMedium = 10; // tokens/sec for medium models on CPU
    const baselineLarge = 5;   // tokens/sec for large models on CPU

    const params = model.parameters_raw;

    let baseTps;
    if (params < 2e9) baseTps = baselineSmall;
    else if (params < 10e9) baseTps = baselineMedium;
    else baseTps = baselineLarge;

    // Adjust for CPU cores (rough scaling)
    const coreAdjustment = Math.log(cpuCores) / Math.log(4); // normalize to 4-core baseline
    let adjustedTps = baseTps * coreAdjustment;

    // Boost for GPU
    if (runMode === 'GPU') {
      adjustedTps *= 5;  // Rough 5x speedup on GPU
    } else if (runMode === 'CPU_OFFLOAD') {
      adjustedTps *= 2;  // Modest speedup with offloading
    }

    return Math.round(adjustedTps);
  }

  /**
   * Private: Calculate median value
   */
  _getMedian(arr) {
    const sorted = [...arr].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /**
   * Format model for display
   */
  formatModel(model) {
    return `${model.name} (${model.parameter_count})\n  Use: ${model.use_case}\n  Context: ${model.context_length}\n  Min RAM: ${model.min_ram_gb}GB`;
  }

  /**
   * Format analysis result for display
   */
  formatAnalysis(analysis) {
    return analysis
      .slice(0, 10)
      .map(m => `${m.name} [${m.fit.toUpperCase()}] (${m.run_mode}, ${m.estimated_tps}tps)`)
      .join('\n');
  }
}

module.exports = LLMfitAnalyzer;
