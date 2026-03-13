# R Analytics Scripts

## Overview

This directory contains R scripts for analyzing RL system performance, costs, and convergence.

---

## Primary Scripts

### cost-analysis-minimal.R
**Status:** ✅ Primary (use this one)
- Base R only (no dependencies)
- Provides agent ROI ranking, cost analysis, efficiency metrics
- Works on any system with R installed
- Usage: `Rscript cost-analysis-minimal.R`

**Output:**
- Agent ROI ranking (success per 1K tokens)
- Task cost breakdown
- Efficiency recommendations

---

## Optional Scripts

### cost-analysis-standalone.R
**Status:** Optional (if you have ggplot2)
- Requires: ggplot2 (install: `install.packages("ggplot2")`)
- Adds visualization: ROI bar chart, cost vs success plot
- Usage: `Rscript cost-analysis-standalone.R`

### cost-analysis.R
**Status:** Optional (if you have tidyverse)
- Requires: tidyverse, ggplot2, jsonlite
- Most feature-rich version with multiple visualizations
- Usage: `Rscript cost-analysis.R`

### rl-plots.R
**Status:** Optional (visualization alternative)
- Requires: ggplot2
- Generates RL convergence plots, agent comparison
- Usage: `Rscript rl-plots.R`

### rl-analytics.R
**Status:** Optional (advanced analysis)
- Requires: tidyverse, ggplot2, jsonlite
- Full tidyverse-based analysis pipeline
- Usage: `Rscript rl-analytics.R`

---

## Which One to Use?

| Scenario | Script | Dependencies |
|----------|--------|--------------|
| **Just want results** | cost-analysis-minimal.R | None (base R) |
| **Want plots too** | cost-analysis-standalone.R | ggplot2 |
| **Want full analysis** | cost-analysis.R | tidyverse |
| **Convergence plots** | rl-plots.R | ggplot2 |
| **Deep analysis** | rl-analytics.R | tidyverse |

**Recommendation:** Start with `cost-analysis-minimal.R`. Add others if you need visualizations.

---

## Setup (Optional)

To enable visualization scripts:

```bash
# Install ggplot2
R -e "install.packages('ggplot2')"

# Install tidyverse (includes ggplot2, dplyr, etc.)
R -e "install.packages('tidyverse')"
```

---

## Data Flow

```
RL outcome logs (data/rl/*.jsonl)
    ↓
[Pick a script above]
    ↓
Console output (text) + optional PNG plots (output/)
```

---

## Examples

```bash
# Minimal (always works)
Rscript cost-analysis-minimal.R

# With visualizations (if ggplot2 installed)
Rscript cost-analysis-standalone.R

# Full pipeline (if tidyverse installed)
Rscript cost-analysis.R
```

All three produce analysis; the fancier versions add plots.

---

## Notes

- `cost-analysis-minimal.R` is the recommended primary script
- Other scripts are provided as options if you want visualizations
- All scripts read from the same data sources
- Output goes to stdout (text) or `output/` (PNG plots)

For usage details, see `/docs/SYSTEM_IMPROVEMENTS_SUMMARY.md`.
