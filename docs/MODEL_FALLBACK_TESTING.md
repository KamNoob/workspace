# Model Fallback Chain Testing & Validation

**Created:** 2026-03-07  
**Status:** Documented  
**Purpose:** Verify continuity during provider outages  

---

## Fallback Chain Configuration

**Current Chain:**
```
Primary: Sonnet 4.6 (anthropic/claude-sonnet-4-6)
   ↓ (on failure)
Fallback 1: Opus 4.5 (anthropic/claude-opus-4-5)
   ↓ (on failure)
Fallback 2: Sonnet 4.5 (anthropic/claude-sonnet-4-5)
   ↓ (on failure)
Fallback 3: Mistral (ollama/mistral:latest, local)
```

**Model Characteristics:**

| Model | Provider | Context Window | Speed | Cost | Availability |
|-------|----------|----------------|-------|------|--------------|
| Sonnet 4.6 | Anthropic (cloud) | 200K tokens | Fast | $3/1M in, $15/1M out | 99.9% |
| Opus 4.5 | Anthropic (cloud) | 200K tokens | Medium | $15/1M in, $75/1M out | 99.9% |
| Sonnet 4.5 | Anthropic (cloud) | 200K tokens | Fast | $3/1M in, $15/1M out | 99.9% |
| Mistral | Local (Ollama) | 128K tokens | Medium | $0 | 100% (if host up) |

---

## Fallback Trigger Scenarios

###1. API Rate Limits (429)
- **Primary Model:** Returns 429 Too Many Requests
- **OpenClaw Action:** Immediately switch to next fallback
- **Retry:** Primary model re-enabled after cool-down (5-10 min)

### 2. Service Outage (502/503/504)
- **Primary Model:** Gateway errors, service unavailable
- **OpenClaw Action:** Switch to fallback, retry primary after 30s
- **Duration:** Typically <5 minutes (Anthropic 99.9% SLA)

### 3. API Key Exhaustion (401/403)
- **Primary Model:** Invalid or expired credentials
- **OpenClaw Action:** Switch to fallback, alert user
- **Resolution:** Manual intervention (update API key)

### 4. Timeout (>60s)
- **Primary Model:** Request exceeds timeout threshold
- **OpenClaw Action:** Cancel request, retry with fallback
- **Common Cause:** Large context, complex reasoning, network latency

### 5. Model Unavailable (400/500)
- **Primary Model:** Model deprecated, temporarily disabled
- **OpenClaw Action:** Switch to fallback, log warning
- **Example:** Anthropic phase-out of older models

---

## Verification Checklist

### Configuration Verification

- [ ] Default model set: `openclaw.json` → `models.default`
- [ ] Fallback chain defined: `openclaw.json` → `models.fallbacks[]`
- [ ] All models accessible: API keys valid, Ollama models pulled
- [ ] Timeout thresholds configured (default: 60s)
- [ ] Retry logic enabled (OpenClaw default: 2 retries per model)

**Check Current Config:**
```bash
jq '.models' ~/.openclaw/openclaw.json
```

**Expected Output:**
```json
{
  "default": "anthropic/claude-sonnet-4-6",
  "fallbacks": [
    "anthropic/claude-opus-4-5",
    "anthropic/claude-sonnet-4-5",
    "ollama/mistral:latest"
  ]
}
```

### Functional Testing (Manual)

**Test 1: Simulated Rate Limit**
```bash
# Temporarily exhaust Anthropic quota (make many rapid requests)
for i in {1..100}; do
  echo "Request $i"
  # (OpenClaw will hit rate limit, trigger fallback)
done
```

**Expected Behavior:**
- First ~20-50 requests: Sonnet 4.6 (success)
- Next requests: 429 errors → Switch to Opus 4.5
- If Opus exhausted → Switch to Sonnet 4.5
- If Sonnet exhausted → Switch to Mistral (local, unlimited)

**Test 2: Simulated Outage (Mock Server)**
```bash
# Use mitmproxy or similar to inject 502 errors
# (Advanced testing, requires setup)
```

**Test 3: Model Unavailable (Wrong Model Name)**
```bash
# Temporarily set wrong model name
jq '.models.default = "anthropic/claude-sonnet-99.9"' ~/.openclaw/openclaw.json > tmp.json
mv tmp.json ~/.openclaw/openclaw.json

# Restart gateway
openclaw gateway restart

# Make request (should auto-fall back to Opus 4.5)
```

### Automated Testing (Future)

**Test Script:** `scripts/test-model-fallback.sh`

```bash
#!/bin/bash
# Test model fallback chain (requires test environment)

set -euo pipefail

echo "🧪 Testing Model Fallback Chain"

# Test 1: Primary model available
echo "Test 1: Primary model (Sonnet 4.6)"
RESPONSE=$(curl -s http://localhost:18789/v1/chat/completions \
  -H "Authorization: Bearer $GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "anthropic/claude-sonnet-4-6",
    "messages": [{"role":"user","content":"Say OK"}]
  }')

if echo "$RESPONSE" | jq -e '.model' | grep -q "sonnet-4-6"; then
  echo "✅ Primary model working"
else
  echo "❌ Primary model failed"
fi

# Test 2: Force fallback (inject error)
echo "Test 2: Force fallback to Opus 4.5"
# (Implementation depends on OpenClaw testing API)

# Test 3: Verify Mistral local fallback
echo "Test 3: Mistral local fallback"
ollama run mistral "Say OK" && echo "✅ Mistral available" || echo "❌ Mistral unavailable"

echo "🏁 Test complete"
```

---

## Monitoring & Alerts

### Metrics to Track

**Model Usage Distribution:**
```bash
# Check logs for model usage per day
jq '.model' ~/.openclaw/logs/gateway.log | sort | uniq -c
```

**Expected (Normal):**
```
  950 anthropic/claude-sonnet-4-6  # 95% primary
   30 anthropic/claude-opus-4.5    # 3% fallback
   15 anthropic/claude-sonnet-4.5  # 1.5% fallback
    5 ollama/mistral:latest        # 0.5% fallback
```

**Alerts (Set Up via Cron or Monitoring Tool):**
- [ ] Fallback usage > 10% (indicates primary model issues)
- [ ] Mistral fallback triggered (last resort, lower quality)
- [ ] All models failing (rare, requires manual intervention)

### Log Analysis

**Check Recent Fallbacks:**
```bash
grep -i "fallback" ~/.openclaw/logs/gateway.log | tail -20
```

**Count Fallbacks Per Day:**
```bash
grep -i "fallback" ~/.openclaw/logs/gateway.log \
  | grep "$(date +%Y-%m-%d)" \
  | wc -l
```

---

## Fallback Behavior Impact

### Quality Impact

**Primary → Fallback 1 (Sonnet 4.6 → Opus 4.5):**
- Quality: ⬆️ Slight improvement (Opus is larger, more capable)
- Speed: ⬇️ Slower (~2x response time)
- Cost: ⬆️ 5x more expensive

**Fallback 1 → Fallback 2 (Opus 4.5 → Sonnet 4.5):**
- Quality: ⬇️ Slight decrease (Sonnet older version)
- Speed: ⬆️ Faster (~same as Sonnet 4.6)
- Cost: ⬇️ Same as Sonnet 4.6

**Fallback 2 → Fallback 3 (Sonnet 4.5 → Mistral local):**
- Quality: ⬇️ Significant decrease (7B vs 175B+ parameters)
- Speed: ⬇️ Slower (CPU inference, no GPU on this host)
- Cost: ⬇️ Free (local inference)

**Recommendation:** Monitor fallback usage. If Mistral is triggered frequently, consider:
1. Upgrading Anthropic plan (higher rate limits)
2. Adding GPU-accelerated local model (e.g., Llama 3.1 70B)
3. Secondary cloud provider (OpenAI GPT-4, Google Gemini)

---

## Contingency Plans

### Scenario 1: All Anthropic Models Down
**Likelihood:** <0.01% (three 9s uptime)  
**Fallback:** Mistral (local)  
**Impact:** Lower quality responses, slower inference  
**Action:** Monitor Anthropic status page, wait for restoration

### Scenario 2: API Key Revoked/Exhausted
**Likelihood:** Low (unless quota exceeded)  
**Fallback:** Mistral (local)  
**Impact:** All cloud models unavailable  
**Action:** Update API key in `.env`, restart gateway

### Scenario 3: Local Ollama Crash
**Likelihood:** Low  
**Fallback:** None (last resort)  
**Impact:** All models unavailable if cloud down simultaneously  
**Action:** `sudo systemctl restart ollama`, check logs

### Scenario 4: Network Outage (No Internet)
**Likelihood:** Medium (ISP issues, datacenter problems)  
**Fallback:** Mistral (local) if Ollama up  
**Impact:** Cloud models unavailable, local models OK  
**Action:** Wait for network restoration

---

## Best Practices

### 1. Keep Ollama Models Updated
```bash
# Pull latest Mistral
ollama pull mistral

# Verify available
ollama list
```

### 2. Monitor API Quotas
- Check Anthropic dashboard daily
- Set up billing alerts (AWS, Anthropic)
- Track usage in MEMORY.md (session updates)

### 3. Test Fallbacks Quarterly
- Simulate outages every 3 months
- Document failures, fix issues
- Update this document with lessons learned

### 4. Diversify Providers (Future)
- Add OpenAI GPT-4 as Fallback 1.5
- Add Google Gemini as Fallback 2.5
- Keep Mistral as ultimate fallback

### 5. Log Fallback Events
```bash
# Add to MEMORY.md session updates
echo "$(date +%Y-%m-%d): Fallback triggered (Sonnet 4.6 → Opus 4.5), reason: rate limit" >> ~/.openclaw/workspace/memory/fallback-log.txt
```

---

## Testing Schedule

**Quarterly (Every 3 Months):**
- [ ] Verify all fallback models accessible
- [ ] Simulate rate limit (rapid requests)
- [ ] Test local Ollama failover
- [ ] Review fallback logs (check frequency)
- [ ] Update API keys if needed

**Next Test:** 2026-06-07 (3 months from 2026-03-07)

---

## Status

**Configuration:** ✅ Verified  
**Testing:** ⚠️ Manual testing pending (requires simulation)  
**Monitoring:** ⚠️ Log analysis available, automated alerts not configured  
**Documentation:** ✅ Complete  

**Next Steps:**
1. Create `scripts/test-model-fallback.sh` (automated testing)
2. Set up cron job for fallback usage monitoring
3. Test quarterly (schedule reminder)
4. Consider adding OpenAI/Gemini as secondary cloud providers

---

## Tags

model-fallback, continuity, high-availability, Anthropic, Claude, Mistral, Ollama, rate-limits, service-outage, resilience

---

**Created:** 2026-03-07  
**Verified:** Configuration only (functional testing pending)  
**Next Review:** 2026-06-07 (quarterly)
