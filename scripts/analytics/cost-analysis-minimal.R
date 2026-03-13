#!/usr/bin/env Rscript
# cost-analysis-minimal.R
# Cost analysis in base R only (no dependencies)

# ─── Load Data ─────────────────────────────────────────────────────────────

generate_sample_outcomes <- function() {
    cat("📖 Generating sample cost data for demo...\n\n")
    
    agents <- c("Codex", "Scout", "Cipher", "Veritas", "QA", "Prism",
                "Chronicle", "Sentinel", "Lens", "Echo", "Navigator")
    tasks <- c("code", "research", "security", "docs", "test")
    
    outcomes <- data.frame()
    set.seed(42)
    
    for (i in 1:50) {
        agent <- sample(agents, 1)
        task <- sample(tasks, 1)
        
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
            token_count = token_count,
            stringsAsFactors = FALSE
        ))
    }
    
    cat("✓ Generated", nrow(outcomes), "sample outcomes\n\n")
    return(outcomes)
}

# ─── Analysis ──────────────────────────────────────────────────────────────

analyze_costs <- function(outcomes) {
    cat("=== Agent Cost Analysis ===\n\n")
    
    # Get unique agents
    agents <- sort(unique(outcomes$agent))
    
    cat("✓ Agent ROI Ranking:\n\n")
    
    results <- data.frame()
    
    for (agent in agents) {
        agent_outcomes <- outcomes[outcomes$agent == agent, ]
        
        total_calls <- nrow(agent_outcomes)
        success_count <- sum(agent_outcomes$success)
        success_rate <- success_count / total_calls
        total_tokens <- sum(agent_outcomes$token_count)
        avg_tokens <- mean(agent_outcomes$token_count)
        roi <- success_count / (total_tokens / 1000)
        
        results <- rbind(results, data.frame(
            agent = agent,
            total_calls = total_calls,
            success_count = success_count,
            success_rate = round(success_rate, 3),
            avg_tokens = round(avg_tokens),
            roi = round(roi, 3),
            stringsAsFactors = FALSE
        ))
    }
    
    # Sort by ROI
    results <- results[order(results$roi, decreasing = TRUE), ]
    
    for (i in 1:nrow(results)) {
        r <- results[i, ]
        cat("  ", i, ". ", r$agent, 
            ": ROI=", r$roi, 
            " (", round(r$success_rate*100), "% success, ", r$avg_tokens, " tokens/call)\n", sep = "")
    }
    
    cat("\n=== Task Cost Analysis ===\n\n")
    
    tasks <- sort(unique(outcomes$task))
    
    cat("✓ Cost by Task:\n\n")
    
    for (task in tasks) {
        task_outcomes <- outcomes[outcomes$task == task, ]
        
        total_calls <- nrow(task_outcomes)
        success_rate <- sum(task_outcomes$success) / total_calls
        avg_tokens <- mean(task_outcomes$token_count)
        
        cat("  ", task, 
            ": ", round(avg_tokens), " avg tokens (", round(success_rate*100), "% success, ", total_calls, " calls)\n", sep = "")
    }
    
    return(results)
}

# ─── Main ──────────────────────────────────────────────────────────────────

main <- function() {
    cat("╔════════════════════════════════════════════════════════╗\n")
    cat("║ Cost Analysis: Token Spend & ROI (Base R)              ║\n")
    cat("╚════════════════════════════════════════════════════════╝\n\n")
    
    outcomes <- generate_sample_outcomes()
    agent_stats <- analyze_costs(outcomes)
    
    cat("\n✅ Cost analysis complete!\n")
    cat("\n📊 Summary:\n")
    cat("  Total outcomes analyzed:", nrow(outcomes), "\n")
    cat("  Total tokens spent:", sum(outcomes$token_count), "\n")
    cat("  Success rate:", round(mean(outcomes$success)*100, 1), "%\n")
    cat("  Avg tokens per success:", round(sum(outcomes$token_count) / sum(outcomes$success)), "\n")
    
    cat("\n💡 Recommendations:\n")
    cat("  1. Focus on high-ROI agents (use more)\n")
    cat("  2. Investigate low-ROI agents (optimize or replace)\n")
    cat("  3. Track cost trends over time\n")
}

main()
