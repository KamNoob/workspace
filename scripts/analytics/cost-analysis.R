#!/usr/bin/env Rscript
# cost-analysis.R
# Analyze token costs, ROI per agent, and budget allocation.
#
# Requires: rl-outcomes.csv with token_count column
# Output: cost-analysis plots in output/

library(tidyverse)
library(ggplot2)

# ─── Load Data ─────────────────────────────────────────────────────────────

load_outcomes <- function() {
    file_path <- "data/rl/rl-outcomes.csv"
    
    if (!file.exists(file_path)) {
        cat("⚠️  Creating sample data (real data at:", file_path, ")\n")
        # Generate sample data for demo
        agents <- c("Codex", "Scout", "Cipher", "Veritas", "QA", "Prism",
                    "Chronicle", "Sentinel", "Lens", "Echo", "Navigator")
        tasks <- c("code", "research", "security", "docs", "test")
        
        data <- expand.grid(
            agent = agents,
            task = tasks,
            replication = 1:2
        ) %>%
            mutate(
                success = sample(c(0, 1), n(), replace = TRUE, prob = c(0.02, 0.98)),
                token_count = rnorm(n(), mean = 2000, sd = 800),
                token_count = pmax(token_count, 100)
            ) %>%
            select(-replication)
        
        return(data)
    }
    
    cat("📖 Loading outcomes from:", file_path, "\n")
    
    outcomes <- read.csv(file_path, stringsAsFactors = FALSE)
    
    # Ensure token_count column exists
    if (!"token_count" %in% names(outcomes)) {
        cat("⚠️  No token_count column, using random values for demo\n")
        outcomes$token_count <- rnorm(nrow(outcomes), mean = 2000, sd = 800)
        outcomes$token_count <- pmax(outcomes$token_count, 100)
    }
    
    cat("✓ Loaded", nrow(outcomes), "outcomes\n\n")
    return(outcomes)
}

# ─── Cost Analysis Functions ───────────────────────────────────────────────

analyze_agent_costs <- function(outcomes) {
    cat("=== Agent Cost Analysis ===\n\n")
    
    agent_stats <- outcomes %>%
        group_by(agent) %>%
        summarise(
            total_calls = n(),
            total_tokens = sum(token_count, na.rm = TRUE),
            avg_tokens = mean(token_count, na.rm = TRUE),
            success_count = sum(success, na.rm = TRUE),
            failure_count = sum(1 - success, na.rm = TRUE),
            success_rate = mean(success, na.rm = TRUE),
            tokens_per_success = total_tokens / sum(success, na.rm = TRUE),
            roi = sum(success, na.rm = TRUE) / (total_tokens / 1000),  # Success per 1K tokens
            .groups = "drop"
        ) %>%
        arrange(desc(roi))
    
    # Print summary
    cat("✓ Agent ROI Ranking:\n")
    for (i in 1:min(5, nrow(agent_stats))) {
        row <- agent_stats[i, ]
        cat("  ", i, ". ", row$agent, ": ", 
            round(row$roi, 3), " success/1K tokens (", 
            round(row$success_rate * 100, 1), "% success)\n", sep = "")
    }
    
    cat("\n✓ Cost by Agent:\n")
    for (i in 1:min(5, nrow(agent_stats))) {
        row <- agent_stats[i, ]
        cat("  ", row$agent, ": ", 
            round(row$avg_tokens), " avg tokens/call\n", sep = "")
    }
    
    return(agent_stats)
}

analyze_task_costs <- function(outcomes) {
    cat("\n=== Task Cost Analysis ===\n\n")
    
    task_stats <- outcomes %>%
        group_by(task) %>%
        summarise(
            total_calls = n(),
            total_tokens = sum(token_count, na.rm = TRUE),
            avg_tokens = mean(token_count, na.rm = TRUE),
            success_rate = mean(success, na.rm = TRUE),
            .groups = "drop"
        ) %>%
        arrange(desc(avg_tokens))
    
    cat("✓ Most Expensive Tasks:\n")
    for (i in 1:nrow(task_stats)) {
        row <- task_stats[i, ]
        cat("  ", row$task, ": ", round(row$avg_tokens), 
            " avg tokens (", round(row$success_rate * 100, 1), "% success)\n", sep = "")
    }
    
    return(task_stats)
}

analyze_efficiency <- function(agent_stats) {
    cat("\n=== Efficiency Ranking ===\n\n")
    
    cat("✓ Tokens per Success (lower is better):\n")
    efficiency <- agent_stats %>%
        arrange(tokens_per_success) %>%
        head(5)
    
    for (i in 1:nrow(efficiency)) {
        row <- efficiency[i, ]
        cat("  ", row$agent, ": ", round(row$tokens_per_success), 
            " tokens per success\n", sep = "")
    }
}

# ─── Plotting Functions ────────────────────────────────────────────────────

plot_roi_by_agent <- function(agent_stats) {
    cat("\n📊 Creating plot 1: ROI by Agent...\n")
    
    agent_stats_sorted <- agent_stats %>%
        arrange(desc(roi)) %>%
        mutate(agent = factor(agent, levels = agent))
    
    p <- ggplot(agent_stats_sorted, aes(x = agent, y = roi, fill = success_rate)) +
        geom_col() +
        geom_text(aes(label = round(roi, 2)), vjust = -0.5, size = 3) +
        scale_fill_gradient(low = "lightcoral", high = "darkgreen", limits = c(0, 1)) +
        coord_flip() +
        labs(
            title = "Agent ROI (Success per 1K Tokens)",
            x = "Agent",
            y = "ROI (successes per 1K tokens)",
            fill = "Success Rate",
            subtitle = "Higher is better"
        ) +
        theme_minimal() +
        theme(
            plot.title = element_text(size = 12, face = "bold"),
            axis.text.y = element_text(size = 10)
        )
    
    dir.create("output", showWarnings = FALSE, recursive = TRUE)
    ggsave("output/01-agent-roi.png", p, width = 10, height = 8, dpi = 100)
    cat("✓ Saved: output/01-agent-roi.png\n")
}

plot_avg_tokens <- function(agent_stats) {
    cat("\n📊 Creating plot 2: Average Tokens per Agent...\n")
    
    agent_stats_sorted <- agent_stats %>%
        arrange(desc(avg_tokens)) %>%
        mutate(agent = factor(agent, levels = agent))
    
    p <- ggplot(agent_stats_sorted, aes(x = agent, y = avg_tokens)) +
        geom_col(fill = "steelblue") +
        geom_text(aes(label = round(avg_tokens)), vjust = -0.5, size = 3) +
        coord_flip() +
        labs(
            title = "Average Tokens per Call by Agent",
            x = "Agent",
            y = "Average Tokens"
        ) +
        theme_minimal() +
        theme(plot.title = element_text(size = 12, face = "bold"))
    
    ggsave("output/02-avg-tokens.png", p, width = 10, height = 8, dpi = 100)
    cat("✓ Saved: output/02-avg-tokens.png\n")
}

plot_cost_vs_success <- function(agent_stats) {
    cat("\n📊 Creating plot 3: Cost vs Success Rate...\n")
    
    p <- ggplot(agent_stats, aes(x = avg_tokens, y = success_rate, 
                                  size = total_calls, label = agent)) +
        geom_point(alpha = 0.6, color = "steelblue") +
        geom_text(hjust = 0.5, vjust = -0.5, size = 3) +
        labs(
            title = "Cost vs Success Rate (bubble = # of calls)",
            x = "Average Tokens per Call",
            y = "Success Rate",
            size = "Number of Calls"
        ) +
        theme_minimal() +
        theme(plot.title = element_text(size = 12, face = "bold"))
    
    ggsave("output/03-cost-vs-success.png", p, width = 10, height = 7, dpi = 100)
    cat("✓ Saved: output/03-cost-vs-success.png\n")
}

plot_task_costs <- function(task_stats) {
    cat("\n📊 Creating plot 4: Cost by Task Type...\n")
    
    task_stats_sorted <- task_stats %>%
        arrange(desc(avg_tokens)) %>%
        mutate(task = factor(task, levels = task))
    
    p <- ggplot(task_stats_sorted, aes(x = task, y = avg_tokens, fill = success_rate)) +
        geom_col() +
        geom_text(aes(label = round(avg_tokens)), vjust = -0.5, size = 3) +
        scale_fill_gradient(low = "lightcoral", high = "darkgreen") +
        labs(
            title = "Average Cost by Task Type",
            x = "Task Type",
            y = "Average Tokens",
            fill = "Success Rate"
        ) +
        theme_minimal() +
        theme(plot.title = element_text(size = 12, face = "bold"))
    
    ggsave("output/04-cost-by-task.png", p, width = 10, height = 6, dpi = 100)
    cat("✓ Saved: output/04-cost-by-task.png\n")
}

# ─── Main ──────────────────────────────────────────────────────────────────

main <- function() {
    cat("╔════════════════════════════════════════════════════════╗\n")
    cat("║ Cost Analysis: Token Spend & ROI                        ║\n")
    cat("╚════════════════════════════════════════════════════════╝\n\n")
    
    # Load
    outcomes <- load_outcomes()
    
    # Analyze
    agent_stats <- analyze_agent_costs(outcomes)
    task_stats <- analyze_task_costs(outcomes)
    analyze_efficiency(agent_stats)
    
    # Plot
    plot_roi_by_agent(agent_stats)
    plot_avg_tokens(agent_stats)
    plot_cost_vs_success(agent_stats)
    plot_task_costs(task_stats)
    
    cat("\n✅ Cost analysis complete!\n")
    cat("📂 Plots saved to: output/\n")
}

if (interactive()) {
    main()
} else {
    main()
}
