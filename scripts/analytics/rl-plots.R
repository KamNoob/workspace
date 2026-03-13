#!/usr/bin/env Rscript
# rl-plots.R
# Basic R analytics (no tidyverse dependency)
#
# Usage:
#   Rscript rl-plots.R
#
# Requirements:
#   install.packages(c("ggplot2", "jsonlite"))

library(ggplot2)
library(jsonlite)

# ─── Utility Functions ─────────────────────────────────────────────────────

load_csv_safe <- function(filepath) {
    if (!file.exists(filepath)) {
        cat("⚠️  File not found:", filepath, "\n")
        return(NULL)
    }
    return(read.csv(filepath, stringsAsFactors = FALSE))
}

load_json <- function(filepath) {
    if (!file.exists(filepath)) {
        cat("⚠️  File not found:", filepath, "\n")
        return(NULL)
    }
    return(fromJSON(filepath))
}

# ─── Analysis ──────────────────────────────────────────────────────────────

analyze_data <- function() {
    cat("╔════════════════════════════════════════════════════════╗\n")
    cat("║ RL System Analytics (Phase 3B)                         ║\n")
    cat("╚════════════════════════════════════════════════════════╝\n\n")
    
    # Create output directory
    dir.create("output", showWarnings = FALSE, recursive = TRUE)
    
    # Load Q-values
    cat("📖 Loading Q-values...\n")
    q_values <- load_csv_safe("data/rl/rl-q-values.csv")
    
    if (is.null(q_values)) {
        cat("   Creating sample data for demo...\n")
        q_values <- data.frame(
            task = rep(c("code", "research", "security"), 11),
            agent = rep(c("Codex", "Scout", "Cipher", "Veritas", "Sentinel", "Lens", "Chronicle", "Echo", "QA", "Prism", "Navigator"), 3),
            q_score = rnorm(33, mean = 0.5, sd = 0.2),
            visits = sample(0:20, 33, replace = TRUE)
        )
        q_values$q_score[q_values$q_score < 0] <- 0
        q_values$q_score[q_values$q_score > 1] <- 1
    }
    
    cat("✓ Loaded", nrow(q_values), "Q-values\n\n")
    
    # Load outcomes
    cat("📖 Loading outcomes...\n")
    outcomes <- load_csv_safe("data/rl/rl-outcomes.csv")
    
    if (is.null(outcomes)) {
        cat("   No outcomes yet (create with: julia spawner-matrix.jl spawn ...)\n\n")
    } else {
        cat("✓ Loaded", nrow(outcomes), "outcomes\n\n")
    }
    
    # Statistics
    cat("=== Q-Value Statistics ===\n")
    cat("Mean Q:", round(mean(q_values$q_score), 3), "\n")
    cat("Std Dev:", round(sd(q_values$q_score), 3), "\n")
    cat("Min Q:", round(min(q_values$q_score), 3), "\n")
    cat("Max Q:", round(max(q_values$q_score), 3), "\n\n")
    
    # Plot 1: Q-score distribution
    cat("📊 Creating plot 1: Q-value distribution...\n")
    p1 <- ggplot(q_values, aes(x = q_score)) +
        geom_histogram(binwidth = 0.05, alpha = 0.7, fill = "steelblue") +
        geom_vline(aes(xintercept = mean(q_score)), color = "red", linetype = "dashed", linewidth = 1) +
        labs(
            title = "Q-Value Distribution Across All Agent-Task Pairs",
            x = "Q-Score",
            y = "Frequency",
            subtitle = paste("Mean Q:", round(mean(q_values$q_score), 3))
        ) +
        theme_minimal() +
        theme(
            plot.title = element_text(size = 12, face = "bold"),
            plot.subtitle = element_text(size = 10)
        )
    
    ggsave("output/01-q-distribution.png", p1, width = 8, height = 6, dpi = 100)
    cat("✓ Saved: output/01-q-distribution.png\n\n")
    
    # Plot 2: Agent avg performance
    cat("📊 Creating plot 2: Agent average Q-scores...\n")
    agent_stats <- aggregate(q_score ~ agent, q_values, mean)
    agent_stats <- agent_stats[order(agent_stats$q_score, decreasing = TRUE), ]
    
    p2 <- ggplot(agent_stats, aes(x = reorder(agent, q_score), y = q_score)) +
        geom_col(fill = "steelblue") +
        coord_flip() +
        labs(
            title = "Agent Performance (Average Q-Score)",
            x = "Agent",
            y = "Average Q-Score"
        ) +
        theme_minimal() +
        theme(plot.title = element_text(size = 12, face = "bold"))
    
    ggsave("output/02-agent-comparison.png", p2, width = 8, height = 6, dpi = 100)
    cat("✓ Saved: output/02-agent-comparison.png\n\n")
    
    # Plot 3: Task heatmap
    cat("📊 Creating plot 3: Agent-task specialization heatmap...\n")
    p3 <- ggplot(q_values, aes(x = task, y = agent, fill = q_score)) +
        geom_tile() +
        geom_text(aes(label = round(q_score, 2)), size = 3, color = "black") +
        scale_fill_gradient(low = "white", high = "darkgreen", limits = c(0, 1)) +
        labs(
            title = "Agent Specialization by Task (Q-Score Heatmap)",
            x = "Task Type",
            y = "Agent",
            fill = "Q-Score"
        ) +
        theme_minimal() +
        theme(
            axis.text.x = element_text(angle = 45, hjust = 1),
            plot.title = element_text(size = 12, face = "bold"),
            panel.grid.major = element_blank()
        )
    
    ggsave("output/03-specialization-heatmap.png", p3, width = 10, height = 8, dpi = 100)
    cat("✓ Saved: output/03-specialization-heatmap.png\n\n")
    
    # Plot 4: Outcome success rate (if available)
    if (!is.null(outcomes)) {
        cat("📊 Creating plot 4: Success rate over time...\n")
        outcomes$seq <- 1:nrow(outcomes)
        outcomes$success_int <- as.integer(outcomes$success)
        
        p4 <- ggplot(outcomes, aes(x = seq, y = success_int)) +
            geom_point(alpha = 0.4, size = 2) +
            geom_smooth(method = "loess", formula = y ~ x, color = "blue", fill = "lightblue") +
            labs(
                title = "Success Rate Over Time",
                x = "Outcome Number (sequence)",
                y = "Success (1 = Yes, 0 = No)"
            ) +
            ylim(-0.1, 1.1) +
            theme_minimal() +
            theme(plot.title = element_text(size = 12, face = "bold"))
        
        ggsave("output/04-success-over-time.png", p4, width = 8, height = 6, dpi = 100)
        cat("✓ Saved: output/04-success-over-time.png\n\n")
    }
    
    cat("✅ Analysis complete!\n")
    cat("📂 Plots saved to: output/\n")
}

# Run
if (interactive()) {
    analyze_data()
} else {
    analyze_data()
}
