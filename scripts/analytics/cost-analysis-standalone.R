#!/usr/bin/env Rscript
# cost-analysis-standalone.R
# Analyze costs without tidyverse dependency
# Requires: base R + ggplot2

library(ggplot2)

# ─── Load Data ─────────────────────────────────────────────────────────────

load_outcomes <- function() {
    cat("📖 Generating sample cost data for demo...\n\n")
    
    # Create sample data (real data would come from rl-outcomes.csv)
    agents <- c("Codex", "Scout", "Cipher", "Veritas", "QA", "Prism",
                "Chronicle", "Sentinel", "Lens", "Echo", "Navigator")
    tasks <- c("code", "research", "security", "docs", "test")
    
    # Generate outcomes
    outcomes <- data.frame()
    set.seed(42)
    
    for (i in 1:50) {
        agent <- sample(agents, 1)
        task <- sample(tasks, 1)
        
        # Success rate depends on agent-task compatibility
        success_prob <- if (agent == "Codex" && task == "code") 0.95
                       else if (agent == "Scout" && task == "research") 0.94
                       else if (agent == "Cipher" && task == "security") 0.96
                       else 0.92
        
        success <- rbinom(1, 1, success_prob)
        token_count <- round(rnorm(1, mean = 2000, sd = 500))
        token_count <- max(token_count, 500)
        
        outcomes <- rbind(outcomes, data.frame(
            agent = agent,
            task = task,
            success = success,
            token_count = token_count
        ))
    }
    
    cat("✓ Generated", nrow(outcomes), "sample outcomes\n\n")
    return(outcomes)
}

# ─── Cost Analysis ────────────────────────────────────────────────────────

analyze_agent_costs <- function(outcomes) {
    cat("=== Agent Cost Analysis ===\n\n")
    
    # Aggregate by agent
    agent_summary <- aggregate(cbind(success, token_count) ~ agent, 
                               data = outcomes, 
                               FUN = function(x) c(
                                   total = length(x),
                                   sum = sum(x),
                                   mean = mean(x)
                               ))
    
    # Flatten
    agent_summary <- data.frame(
        agent = agent_summary$agent,
        total_calls = agent_summary$success[, "length"],
        success_count = agent_summary$success[, "sum"],
        success_rate = agent_summary$success[, "mean"],
        total_tokens = agent_summary$token_count[, "sum"],
        avg_tokens = agent_summary$token_count[, "mean"]
    )
    
    # Calculate ROI
    agent_summary$tokens_per_success <- agent_summary$total_tokens / (agent_summary$success_count + 0.1)
    agent_summary$roi <- agent_summary$success_count / (agent_summary$total_tokens / 1000)
    
    # Sort by ROI
    agent_summary <- agent_summary[order(agent_summary$roi, decreasing = TRUE), ]
    
    cat("✓ Agent ROI Ranking:\n")
    for (i in 1:min(5, nrow(agent_summary))) {
        agent <- agent_summary[i, ]
        cat("  ", i, ". ", agent$agent, ": ROI = ", 
            round(agent$roi, 3), 
            " (", round(agent$success_rate * 100, 1), "% success)\n", sep = "")
    }
    
    cat("\n✓ Most Expensive Agents:\n")
    expensive <- agent_summary[order(agent_summary$avg_tokens, decreasing = TRUE), ]
    for (i in 1:min(5, nrow(expensive))) {
        agent <- expensive[i, ]
        cat("  ", agent$agent, ": ", round(agent$avg_tokens), " avg tokens/call\n", sep = "")
    }
    
    return(agent_summary)
}

analyze_task_costs <- function(outcomes) {
    cat("\n=== Task Cost Analysis ===\n\n")
    
    task_summary <- aggregate(cbind(success, token_count) ~ task,
                              data = outcomes,
                              FUN = function(x) c(
                                  total = length(x),
                                  sum = sum(x),
                                  mean = mean(x)
                              ))
    
    task_summary <- data.frame(
        task = task_summary$task,
        total_calls = task_summary$success[, "length"],
        success_count = task_summary$success[, "sum"],
        success_rate = task_summary$success[, "mean"],
        total_tokens = task_summary$token_count[, "sum"],
        avg_tokens = task_summary$token_count[, "mean"]
    )
    
    task_summary <- task_summary[order(task_summary$avg_tokens, decreasing = TRUE), ]
    
    cat("✓ Most Expensive Tasks:\n")
    for (i in 1:nrow(task_summary)) {
        task <- task_summary[i, ]
        cat("  ", task$task, ": ", round(task$avg_tokens), 
            " avg tokens (", round(task$success_rate * 100, 1), "% success)\n", sep = "")
    }
    
    return(task_summary)
}

# ─── Plotting ──────────────────────────────────────────────────────────────

plot_roi_by_agent <- function(agent_summary) {
    cat("\n📊 Creating plot 1: Agent ROI...\n")
    
    agent_summary <- agent_summary[order(agent_summary$roi), ]
    
    p <- ggplot(agent_summary, aes(x = reorder(agent, roi), y = roi, 
                                    fill = success_rate)) +
        geom_col() +
        geom_text(aes(label = round(roi, 2)), hjust = -0.1, size = 3) +
        scale_fill_gradient(low = "lightcoral", high = "darkgreen", limits = c(0, 1)) +
        coord_flip() +
        labs(
            title = "Agent ROI (Success per 1K tokens)",
            x = "Agent",
            y = "ROI",
            fill = "Success Rate"
        ) +
        theme_minimal() +
        theme(plot.title = element_text(size = 12, face = "bold"))
    
    dir.create("output", showWarnings = FALSE)
    ggsave("output/01-agent-roi.png", p, width = 10, height = 7, dpi = 100)
    cat("✓ Saved: output/01-agent-roi.png\n")
}

plot_avg_tokens <- function(agent_summary) {
    cat("\n📊 Creating plot 2: Average tokens...\n")
    
    agent_summary <- agent_summary[order(agent_summary$avg_tokens), ]
    
    p <- ggplot(agent_summary, aes(x = reorder(agent, avg_tokens), y = avg_tokens)) +
        geom_col(fill = "steelblue") +
        geom_text(aes(label = round(avg_tokens)), hjust = -0.1, size = 3) +
        coord_flip() +
        labs(
            title = "Average Tokens per Call by Agent",
            x = "Agent",
            y = "Avg Tokens"
        ) +
        theme_minimal() +
        theme(plot.title = element_text(size = 12, face = "bold"))
    
    ggsave("output/02-avg-tokens.png", p, width = 10, height = 7, dpi = 100)
    cat("✓ Saved: output/02-avg-tokens.png\n")
}

plot_cost_vs_success <- function(agent_summary) {
    cat("\n📊 Creating plot 3: Cost vs Success...\n")
    
    p <- ggplot(agent_summary, aes(x = avg_tokens, y = success_rate, 
                                    size = total_calls, label = agent)) +
        geom_point(alpha = 0.6, color = "steelblue") +
        geom_text(hjust = 0.5, vjust = -0.5, size = 3) +
        labs(
            title = "Cost vs Success Rate",
            x = "Avg Tokens per Call",
            y = "Success Rate",
            size = "# of Calls"
        ) +
        theme_minimal() +
        theme(plot.title = element_text(size = 12, face = "bold"))
    
    ggsave("output/03-cost-vs-success.png", p, width = 10, height = 7, dpi = 100)
    cat("✓ Saved: output/03-cost-vs-success.png\n")
}

# ─── Main ──────────────────────────────────────────────────────────────────

main <- function() {
    cat("╔════════════════════════════════════════════════════════╗\n")
    cat("║ Cost Analysis: Token Spend & ROI                        ║\n")
    cat("╚════════════════════════════════════════════════════════╝\n\n")
    
    outcomes <- load_outcomes()
    agent_stats <- analyze_agent_costs(outcomes)
    task_stats <- analyze_task_costs(outcomes)
    
    plot_roi_by_agent(agent_stats)
    plot_avg_tokens(agent_stats)
    plot_cost_vs_success(agent_stats)
    
    cat("\n✅ Cost analysis complete!\n")
    cat("📂 Plots saved to: output/\n")
}

main()
