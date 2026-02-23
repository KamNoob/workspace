# Reinforcement Learning: An Introduction (Sutton & Barto, 2nd Ed.)
## Enhanced Knowledge Base Version

**Source:** Richard S. Sutton and Andrew G. Barto (MIT Press, 2018)  
**Pages:** 548 | **Focus:** Practical RL fundamentals for quick reference

---

## Quick Reference Index

### Core Concepts
- **Agent-Environment Loop:** State → Action → Reward → Next State
- **Value Function:** v(s) = expected return from state s; q(s,a) = from state s taking action a
- **Policy:** π(a|s) = probability of action a in state s
- **Bellman Equation:** Foundation for DP, RL convergence proofs

### Three Main Approaches
1. **Tabular Methods** (small state spaces)
   - Dynamic Programming (requires model)
   - Monte Carlo (model-free, episode-based)
   - Temporal Difference (model-free, bootstrap)

2. **Function Approximation** (large/continuous spaces)
   - Linear: v(s,w) = w^T φ(s)
   - Non-linear: Neural networks

3. **Policy Search** (direct policy optimization)

---

## Part I: Tabular Solution Methods

### Ch 1: Introduction
**Key Ideas:**
- Trial-and-error learning (exploiting reward signal)
- Delayed feedback (credit assignment problem)
- Exploration vs Exploitation tradeoff

**Elements:**
- Agent, Environment, State space S, Action space A
- Reward function R(s,a,s'), Transition function P(s'|s,a)
- Discount factor γ (0 ≤ γ ≤ 1)

**Classic Example: Tic-Tac-Toe**
- Value = probability of winning from current state
- Learn by self-play with bootstrapping

---

### Ch 2: Multi-Armed Bandits
**Problem:** Choose from k actions without state transitions (stateless RL)

**Methods:**
| Method | Formula | Pros | Cons |
|--------|---------|------|------|
| ε-greedy | Pick argmax with prob (1-ε), random with ε | Simple | Wastes samples on random |
| Optimistic Init | Start Q(a) high → encourages exploration | Automatic | Problem-dependent |
| UCB | Pick argmax Q(a) + c√(ln t / N(a)) | Principled | Requires tuning c |
| Gradient Bandit | π(a) ∝ exp(H(a)); H updated via reward | Theoretical | More complex |
| Thompson Sampling | Sample from posterior of each arm | Adaptive | Bayesian overhead |

**Incremental Update:** Q(a) ← Q(a) + (1/N) * (R - Q(a))

---

### Ch 3: Finite Markov Decision Processes
**MDP Tuple:** <S, A, P, R, γ>

**Returns (Discounted):** G_t = R_{t+1} + γR_{t+2} + γ²R_{t+3} + ... = E[Σ γ^k R_{t+k+1}]

**Value Functions:**
- v_π(s) = E_π[G_t | S_t = s] = Σ_a π(a|s) Σ_{s',r} p(s',r|s,a)[r + γv_π(s')]
- q_π(s,a) = E_π[G_t | S_t = s, A_t = a]
- v_π(s) = Σ_a π(a|s) q_π(s,a)

**Optimal:**
- v_*(s) = max_π v_π(s)
- π_* achieves v_* everywhere (may not be unique)

**Bellman Optimality:**
- v_*(s) = Σ_a π_*(a|s) [r + γ Σ_{s'} p(s'|s,a)v_*(s')]

---

### Ch 4: Dynamic Programming
**Requires:** Full model (P, R known)

#### Policy Evaluation (Prediction)
Iteratively apply Bellman backup until convergence:
```
V(s) ← Σ_a π(a|s) [R(s,a) + γ Σ_{s'} p(s'|s,a)V(s')]
```

#### Policy Improvement (Control)
Greedily improve policy given value:
```
π'(s) = argmax_a Σ_{s'} p(s'|s,a)[R(s,a) + γV(s')]
```

#### Policy Iteration
Repeat: Evaluate → Improve (guaranteed to converge to optimal)

#### Value Iteration
Single backup combining both:
```
V(s) ← max_a [R(s,a) + γ Σ_{s'} p(s'|s,a)V(s')]
```
Converges to v_* in fewer iterations than policy iteration (but each is costly).

#### Asynchronous DP
- Update states out-of-order (more flexible)
- Prioritized sweeping: prioritize high-error states
- Real-time DP: interleave with interaction

---

### Ch 5: Monte Carlo Methods
**Idea:** Learn from complete episodes (no model needed)

#### MC Prediction
- Visit state s → accumulate returns from that point
- Averaging converges to v_π (law of large numbers)

**Implementations:**
- **First-visit MC:** Average G_t first time s appears per episode
- **Every-visit MC:** Average each occurrence

#### MC Control
1. Policy Evaluation: MC prediction for current π
2. Policy Improvement: ε-greedy over action values
3. **Exploring Starts:** Ensure all (s,a) pairs visited infinitely often
   - Alternative: ε-greedy exploration (no exploring starts needed)

#### Off-Policy Learning
**Importance Sampling:** Reweight returns by likelihood ratio
```
G_t^weighted = (π(A_t|S_t)/μ(A_t|S_t)) * (π(A_{t+1}|S_{t+1})/μ(A_{t+1}|S_{t+1})) * ... * G_t
```
- High variance; use ordinary IS or weighted IS
- Requires π(a|s) > 0 when μ(a|s) > 0 (coverage)

---

### Ch 6: Temporal Difference (TD) Learning
**Combines MC sampling + DP bootstrapping**

#### TD(0) Prediction
```
V(S_t) ← V(S_t) + α[R_{t+1} + γV(S_{t+1}) - V(S_t)]
                                    ↑ TD error
```
- Single sample, no model, no waiting for episode end
- Converges to v_π (with decaying α)

**Advantages:**
- Lower variance than MC (bootstrap uses V estimate)
- Can learn online (don't need full episode)
- Can learn from incomplete episodes

#### On-Policy TD Control: Sarsa
```
Q(S_t, A_t) ← Q(S_t, A_t) + α[R_{t+1} + γQ(S_{t+1}, A_{t+1}) - Q(S_t, A_t)]
```
Update with actual next action (follows behavior policy).

#### Off-Policy TD Control: Q-Learning
```
Q(S_t, A_t) ← Q(S_t, A_t) + α[R_{t+1} + γ max_a Q(S_{t+1}, a) - Q(S_t, A_t)]
```
Update with greedy next action (target policy learning).

**Key:** Q-learning learns optimal policy while following exploratory behavior.

#### Double Q-Learning
Separate networks to avoid maximization bias:
```
Q(S_t, A_t) ← Q(S_t, A_t) + α[R_{t+1} + γQ(S_{t+1}, argmax_a Q'(S_{t+1}, a)) - Q(S_t, A_t)]
```

#### Expected Sarsa
```
Q(S_t, A_t) ← Q(S_t, A_t) + α[R_{t+1} + γ Σ_a π(a|S_{t+1})Q(S_{t+1}, a) - Q(S_t, A_t)]
```
Smoother updates, intermediate variance.

---

### Ch 7: n-Step Bootstrapping
**Spectrum between MC (n=∞) and TD(1)**

#### n-Step TD Returns
```
G_t^(n) = R_{t+1} + γR_{t+2} + ... + γ^(n-1)R_{t+n} + γ^n V(S_{t+n})
```

#### n-Step Sarsa / Q-Learning
Use G_t^(n) in place of single-step target.

#### Tree Backup (Off-Policy n-step)
Avoids importance sampling; uses tree of possible futures weighted by policy.

#### Lambda Return & TD(λ)
**Eligibility Traces:** Combine all n-step returns exponentially:
```
G_t^λ = (1-λ) Σ_{n=1}^∞ λ^(n-1) G_t^(n)
```
- λ=0: TD(0)
- λ=1: MC
- 0<λ<1: Spectrum
- Efficient forward/backward view implementations

---

### Ch 8: Planning & Learning with Tabular Methods

#### Dyna-Q
**Learn model + values simultaneously:**
1. Real experience: Learn model P, R; update Q
2. Simulated experience: Use model to generate trajectories; update Q

```
For each real step:
  - Observe s', r
  - Update Q(s,a)
  - Update model M(s,a) → (s', r)
  - For κ simulated steps:
    - Sample s, a from memory
    - Use model: s' ← M(s,a)
    - Update Q(s,a) ← Q(s,a) + α[r + γ max Q(s',a')]
```

**Prioritized Sweeping:** Prioritize recently-changed state-actions.

---

## Part II: Approximate Solution Methods

### Ch 9: On-Policy Approximation with Function Approximation
**Problem:** Tabular fails for large/continuous spaces

#### Linear Function Approximation
```
v̂(s,w) = w^T φ(s) = Σ_i w_i φ_i(s)
```
where φ(s) = [φ_1(s), ..., φ_d(s)] are features.

**Update:** w ← w + α[R - v̂(s,w)]∇v̂(s,w) = w + α[R - w^T φ]φ

#### Tile Coding (Coarse Coding)
- Tile state space with overlapping tiles
- Feature = 1 if in tile, 0 otherwise
- Generalization via overlap; resolution via tile count

#### Radial Basis Functions (RBF)
```
φ_i(s) = exp(-(||s - c_i||^2 / (2σ_i^2)))
```
Smooth, local features.

#### Gradient Descent Convergence
- Converges to local optimum iff step size sufficient
- May diverge if off-policy (deadly triad: FA + bootstrapping + off-policy)

---

### Ch 10: Episodic Semi-Gradient Methods

#### Semi-Gradient TD(0)
```
w ← w + α[R_{t+1} + γv̂(S_{t+1},w) - v̂(S_t,w)]∇v̂(S_t,w)
```
Not true gradient (bootstraps on estimated value), but often works.

#### Semi-Gradient Sarsa & Expected Sarsa
```
Q̂(s,a,w) ← Q̂(s,a,w) + α[R_{t+1} + γQ̂(S_{t+1},A_{t+1},w) - Q̂(S_t,A_t,w)]∇Q̂
```

#### Mountain Car Problem
- State: position, velocity
- Action: push left / right / coast
- Reward: -1 per step (goal: reach top)
- Challenge: sparse reward, credit assignment
- Solution: TC + FA learns exploiting state generalization

---

### Ch 11: Off-Policy Methods with Approximation

#### Deadly Triad
**Fails:** Function Approximation + Bootstrapping + Off-Policy
- Can diverge due to feedback loops through estimates
- Solutions:
  - Prioritized Experience Replay
  - Importance Sampling Weights
  - Gradient TD / TDC (true gradient, stable)

#### Gradient TD (GTD)
Uses secondary weights to stabilize off-policy learning (theory sound, practical overhead).

---

### Ch 12: Eligibility Traces (FA)
**Combine advantages of n-step methods with λ-returns:**

#### Accumulating Trace
```
e(s) ← γλe(s) + ∇v̂(S_t,w)
w ← w + αδe
```
where δ = R - v̂(S_t, w) + γv̂(S_{t+1},w)

#### Replacing Trace
```
e(s) ← γλe(s) ∨ ∇v̂(S_t,w)   [reset to 1 if visited]
```
Reduces variance for RL.

#### Dutch Traces
Interpolate eligibility decay:
```
e(s) ← λ(γe(s) + (1-γ)v̂(s)) + ∇v̂(S_t,w)
```

---

## Part III: Policy Gradient Methods

### Ch 13: Policy Gradient Methods
**Learn policy π_θ directly (not via value).**

#### REINFORCE (Monte Carlo Policy Gradient)
```
θ ← θ + α ∇ ln π(A_t|S_t,θ) G_t
```
- Low variance baseline b(s) subtraction: ∇ ln π * (G_t - b(s))
- Often use v̂(s) as baseline

#### Actor-Critic
Combine policy (actor) + value (critic):
```
Critic:  w ← w + α[R + γv̂(s',w) - v̂(s,w)]∇v̂(s,w)
Actor:   θ ← θ + β ∇ ln π(a|s,θ) [R + γv̂(s',w) - v̂(s,w)]
                    = θ + β ∇ ln π * TD error
```

#### Natural Gradient
Use Fisher Information metric (more efficient convergence):
```
θ ← θ + α F^(-1) ∇J(θ)
```

#### PPO / TRPO
Limit policy change per update via KL divergence or clipping (prevents huge updates).

---

## Part IV: Advanced Topics

### Ch 14: Psychology
**Historical roots & connections:**
- Law of Effect (Thorndike)
- Instrumental Conditioning
- Temporal Difference ≈ Dopamine Signal

### Ch 15: Neuroscience
**Brain & RL:**
- Dopamine encodes prediction error (TD error)
- Value neurons (lateral intraparietal area, others)
- Policy neurons (prefrontal cortex)

### Ch 16: Applications
- **Elevator Scheduling**
- **Game Playing (Backgammon, Chess, Go)**
  - TD-Gammon (Tesauro): Self-play RL beat world champion
  - AlphaGo: Deep RL + Monte Carlo Tree Search
- **Robot Control**
- **Recommendation Systems**

---

## Key Algorithms Quick Reference

### Tabular Methods
| Algorithm | Type | Model | Formula |
|-----------|------|-------|---------|
| DP Value Iteration | On-policy | Yes | V ← max E[r + γV'] |
| MC Control | On-policy | No | Q ← Q + α(G - Q) |
| Sarsa | On-policy | No | Q ← Q + α(r + γQ' - Q) |
| Q-Learning | Off-policy | No | Q ← Q + α(r + γ max Q' - Q) |
| TD(λ) | On-policy | No | e ← λγe + 1; w ← w + αδe |

### FA Methods
| Algorithm | Formula |
|-----------|---------|
| Semi-Grad TD | w ← w + α(r + γv̂' - v̂)∇v̂ |
| REINFORCE | θ ← θ + α∇ln π (G - b) |
| Actor-Critic | θ ← θ + α∇ln π (r + γv̂' - v̂) |

---

## Essential Concepts

### Exploration-Exploitation
- **Exploitation:** Take best known action
- **Exploration:** Try new actions to learn
- **Methods:** ε-greedy, UCB, Thompson Sampling, Information Gain

### Credit Assignment
- Immediate reward easy; sparse/delayed harder
- Solutions: Eligibility traces, n-step returns, policy gradient

### Function Approximation Challenges
- Off-policy instability (deadly triad)
- Bias-variance (linear FA better than tabular for large spaces, but biased)
- Scalability (neural networks work, but less interpretable)

### Convergence Guarantees
- **TD(0):** Converges under decaying α to v_π (stochastic approximation)
- **Q-Learning:** Converges to v_* (but off-policy + FA unstable)
- **Policy Gradient:** Convergence to local optimum (non-convex)

---

## Notation Summary
- **s, S_t:** state
- **a, A_t:** action
- **r, R_t:** reward (immediate)
- **G_t:** return (cumulative discounted reward)
- **v(s):** state value function
- **q(s,a):** action value function
- **π:** policy (π(a|s) = prob of a in s)
- **γ:** discount factor
- **α:** step-size / learning rate
- **λ:** trace decay parameter
- **θ, w:** parameters for approximation
- **δ_t:** TD error = R + γV' - V

---

## Study Path
1. **Master Tabular RL (Ch 1-8):** Understand fundamentals
2. **Function Approximation (Ch 9-12):** Scale to real problems
3. **Policy Gradient (Ch 13):** Alternative, powerful approach
4. **Applications:** Combine theory + practice

---

## Related Resources
- **Original Papers:** Cited throughout (Watkins, Konda, Sutton, Barto, etc.)
- **Code:** Textbook includes Python exercises
- **Companion:** Sutton's lecture notes at RL course site

---

*Enhanced for quick reference, concept mapping, and integration into AI knowledge bases. Focus: Algorithms, intuition, convergence, practical usage.*
