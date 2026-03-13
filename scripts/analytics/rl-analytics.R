#!/usr/bin/env Rscript
# rl-analytics.R
# Visualize RL learning curves, agent specialization, and convergence
#
# Usage:
#   Rscript rl-analytics.R
#
# Requirements:
#   install.packages(c("tidyverse", "ggplot2", "jsonlite"))

library(tidyverse)
library(ggplot2)
library(jsonlite)

# ─── Load Data ──────────────────────────────────────────────────────────────

load_outcome_log <- function() {
    logfile <- "data/rl/rl-task-execution-log.jsonl"
    
    if (!file.exists(logfile)) {
        cat("❌ Outcome log not found:", logfile, "\n")
        return(NULL)
    }
    
    cat("📖 Loading outcome log:", logfile, "\n")
    
    lines <- readLines(logfile)
    outcomes <- map_df(lines, ~fromJSON(.x))
    
    cat("✓ Loaded", nrow(outcomes), "outcomes\n\n")
    return(outcomes)
}

load_q_values <- function() {
    statefile <- "data/rl/rl-agent-selection.json"
    
    if (!file.exists(statefile)) {
        cat("⚠️  Q-values file not found:", statefile, "\n")
        return(NULL)
    }
    
    cat("📖 Loading Q-values:", statefile, "\n")
    
    data <- fromJSON(statefile)
    task_types <- data$task_types
    
    # Convert to tidy format
    q_df <- tibble()
    for (task in names(task_types)) {
        agents_dict <- task_types[[task]]$agents
        for (agent in names(agents_dict)) {
            agent_data <- agents_dict[[agent]]
            q_df <- bind_rows(q_df, tibble(
                task = task,
                agent = agent,
                q_score = agent_data$q_score,
                success_count = agent_data$success_count,
                failure_count = agent_data$failure_count,
                total_uses = agent_data$total_uses,
                success_rate = agent_data$success_rate
            ))
        }
    }
    
    cat("✓ Loaded", nrow(q_df), "agent-task pairs\n\n")
    return(q_df)
}

# ─── Analysis Functions ────────────────────────────────────────────────────

analyze_success_rate <- function(outcomes) {
    cat("=== 1. Success Rate Over Time ===\n")
    
    outcomes_sorted <- outcomes %>%
        arrange(timestamp) %>%
        mutate(seq = row_number())
    
    # Rolling success rate (window of 5)
    outcomes_sorted <- outcomes_sorted %>%
        mutate(
            success_int = as.integer(success),
            rolling_success = zoo::rollmean(success_int, k=3, fill=NA)
        )
    
    overall_success <- mean(outcomes_sorted$success, na.rm=TRUE)
    cat("✓ Overall success rate:", round(overall_success * 100, 1), "%\n")
    cat("✓ Total outcomes:", nrow(outcomes_sorted), "\n")
    
    # Print by agent
    by_agent <- outcomes_sorted %>%
        group_by(agent) %>%
        summarise(
            n = n(),
            success_rate = mean(success, na.rm=TRUE),
            .groups = "drop"
        ) %>%
        arrange(desc(success_rate))
    
    cat("\n✓ Success rate by agent:\n")
    print(by_agent)
    
    return(outcomes_sorted)
}

analyze_task_specialization <- function(outcomes, q_values) {
    cat("\n=== 2. Task Specialization ===\n")
    
    if (is.null(q_values)) {
        cat("⚠️  No Q-values to analyze\n")
        return(NULL)
    }
    
    # Agent dominance by task
    dominance <- q_values %>%
        group_by(task) %>%
        arrange(desc(q_score)) %>%
        slice(1) %>%
        select(task, agent, q_score) %>%
        arrange(desc(q_score))
    
    cat("\n✓ Best agent for each task:\n")
    print(dominance)
    
    return(dominance)
}

analyze_convergence <- function(q_values) {
    cat("\n=== 3. Convergence Status ===\n")
    
    if (is.null(q_values)) {
        cat("⚠️  No Q-values to analyze\n")
        return(NULL)
    }
    
    q_stats <- q_values %>%
        summarise(
            mean_q = mean(q_score, na.rm=TRUE),
            sd_q = sd(q_score, na.rm=TRUE),
            min_q = min(q_score, na.rm=TRUE),
            max_q = max(q_score, na.rm=TRUE),
            n_nonzero = sum(q_score > 0)
        )
    
    cat("\n✓ Q-value statistics:\n")
    cat("  Mean Q:", round(q_stats$mean_q[1], 3), "\n")
    cat("  Std Dev:", round(q_stats$sd_q[1], 3), "\n")
    cat("  Range: [", round(q_stats$min_q[1], 3), ",", round(q_stats$max_q[1], 3), "]\n")
    cat("  Non-zero Q-values:", q_stats$n_nonzero[1], "/ 99\n")
    
    # Convergence indicator
    if (q_stats$n_nonzero[1] < 10) {
        cat("\n⚠️  System still in early learning phase (few non-zero Q-values)\n")
    } else if (q_stats$sd_q[1] < 0.1) {
        cat("\n✓ Q-values showing convergence (low std dev)\n")
    } else {
        cat("\n→ Q-values still diverging, more outcomes needed\n")
    }
    
    return(q_stats)
}

# ─── Plotting Functions ────────────────────────────────────────────────────

plot_success_over_time <- function(outcomes_sorted) {
    cat("\n📊 Creating plot: Success rate over time...\n")
    
    p <- ggplot(outcomes_sorted, aes(x = seq)) +
        geom_point(aes(y = success_int), alpha = 0.3, size = 2) +
        geom_line(aes(y = rolling_success), color = "blue", linewidth = 1) +
        labs(
            title = "Success Rate Over Time",
            x = "Outcome Number",
            y = "Success (1=Yes, 0=No)",
            subtitle = "Blue line: 3-point rolling average"
        ) +
        theme_minimal() +
        theme(plot.title = element_text(size = 14, face = "bold"))
    
    ggsave("output/01-success-over-time.png", p, width = 10, height = 6)
    cat("✓ Saved: output/01-success-over-time.png\n")
}

plot_agent_specialization <- function(outcomes) {
    cat("\n📊 Creating plot: Agent specialization heatmap...\n")
    
    heatmap_data <- outcomes %>%
        group_by(task, agent) %>%
        summarise(
            n = n(),
            success_rate = mean(success, na.rm=TRUE),
            .groups = "drop"
        )
    
    p <- ggplot(heatmap_data, aes(x = task, y = agent, fill = success_rate)) +
        geom_tile() +
        geom_text(aes(label = round(success_rate, 2)), size = 3) +
        scale_fill_gradient(low = "white", high = "green", limits = c(0, 1)) +
        labs(
            title = "Agent Specialization by Task",
            x = "Task Type",
            y = "Agent",
            fill = "Success Rate"
        ) +
        theme_minimal() +
        theme(
            axis.text.x = element_text(angle = 45, hjust = 1),
            plot.title = element_text(size = 14, face = "bold")
        )
    
    ggsave("output/02-agent-specialization.png", p, width = 10, height = 8)
    cat("✓ Saved: output/02-agent-specialization.png\n")
}

plot_q_scores <- function(q_values) {
    cat("\n📊 Creating plot: Q-value distribution...\n")
    
    p <- ggplot(q_values, aes(x = q_score)) +
        geom_histogram(binwidth = 0.05, alpha = 0.7, fill = "steelblue") +
        geom_vline(xintercept = mean(q_values$q_score), color = "red", linetype = "dashed", linewidth = 1) +
        labs(
            title = "Q-Value Distribution",
            x = "Q-Score",
            y = "Frequency",
            subtitle = paste("Mean Q:", round(mean(q_values$q_score), 3))
        ) +
        theme_minimal() +
        theme(plot.title = element_text(size = 14, face = "bold"))
    
    ggsave("output/03-q-distribution.png", p, width = 10, height = 6)
    cat("✓ Saved: output/03-q-distribution.png\n")
}

plot_agent_comparison <- function(q_values) {
    cat("\n📊 Creating plot: Agent performance comparison...\n")
    
    agent_stats <- q_values %>%
        group_by(agent) %>%
        summarise(
            avg_q = mean(q_score, na.rm=TRUE),
            max_q = max(q_score, na.rm=TRUE),
            n_tasks = n(),
            .groups = "drop"
        ) %>%
        arrange(desc(avg_q))
    
    p <- ggplot(agent_stats, aes(x = reorder(agent, avg_q), y = avg_q)) +
        geom_col(fill = "steelblue") +
        geom_errorbar(aes(ymin = 0, ymax = max_q), width = 0.2, alpha = 0.5) +
        coord_flip() +
        labs(
            title = "Agent Performance (Average Q-Score)",
            x = "Agent",
            y = "Average Q-Score",
            subtitle = "Bars show max Q-score range"
        ) +
        theme_minimal() +
        theme(plot.title = element_text(size = 14, face = "bold"))
    
    ggsave("output/04-agent-comparison.png", p, width = 10, height = 8)
    cat("✓ Saved: output/04-agent-comparison.png\n")
}

# ─── Main ──────────────────────────────────────────────────────────────────

main <- function() {
    cat("╔══════════════════════════════════════════════════════════╗\n")
    cat("║ RL System Analytics & Visualization                      ║\n")
    cat("╚══════════════════════════════════════════════════════════╝\n\n")
    
    # Create output dir
    dir.create("output", showWarnings = FALSE)
    
    # Load data
    outcomes <- load_outcome_log()
    q_values <- load_q_values()
    
    if (is.null(outcomes) && is.null(q_values)) {
        cat("\n❌ No data available. Run some workflows first!\n")
        return(invisible(NULL))
    }
    
    # Analysis
    if (!is.null(outcomes)) {
        outcomes_sorted <- analyze_success_rate(outcomes)
        plot_success_over_time(outcomes_sorted)
        plot_agent_specialization(outcomes)
    }
    
    if (!is.null(q_values)) {
        analyze_task_specialization(outcomes, q_values)
        stats <- analyze_convergence(q_values)
        plot_q_scores(q_values)
        plot_agent_comparison(q_values)
    }
    
    cat("\n✅ Analysis complete!\n")
    cat("📂 Plots saved to: output/\n\n")
}

if (interactive()) {
    main()
} else {
    main()
}
