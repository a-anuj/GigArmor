"""
HustleHalt — Trust Score Engine (Phase 5, Fraud Check)

Generates a trust score (0–100) per potential claim.
For demo: heavily weighted towards 75+ to simulate the typical legitimate worker.

Score thresholds:
  ≥ 75  → Auto-Approved  (UPI webhook fires immediately)
  40–74 → Soft-Hold       (passive re-verification, webhook withheld)
  < 40  → Blocked         (fraud suspected, no payout)
"""
import random
import logging

logger = logging.getLogger(__name__)

# Distribution weights for demo realism (70% approve, 20% hold, 10% block)
_APPROVE_PROB: float = 0.70
_HOLD_PROB: float    = 0.20   # cumulative: 0.90
# remaining 0.10 → Blocked

_BASELINE_WEIGHT: float = 0.30  # How strongly baseline influences final score


def calculate_trust_score(worker_id: int, baseline_score: float = 75.0) -> float:
    """
    Compute a trust score for a potential claim.

    Blends a stochastic component (simulating live data signals) with the
    worker's stored trust_baseline_score as a Bayesian prior.
    """
    roll = random.random()

    if roll < _APPROVE_PROB:
        stochastic = random.uniform(75.0, 100.0)
    elif roll < _APPROVE_PROB + _HOLD_PROB:
        stochastic = random.uniform(40.0, 74.9)
    else:
        stochastic = random.uniform(0.0, 39.9)

    # Blend: 70% stochastic + 30% historical baseline
    raw = stochastic * (1 - _BASELINE_WEIGHT) + baseline_score * _BASELINE_WEIGHT
    score = round(min(100.0, max(0.0, raw)), 2)

    logger.info(
        f"Trust score for worker={worker_id}: {score:.2f} "
        f"(stochastic={stochastic:.2f}, baseline={baseline_score})"
    )
    return score


def get_claim_status(trust_score: float) -> str:
    """Map a trust score to its claim status string."""
    if trust_score >= 75.0:
        return "Auto-Approved"
    elif trust_score >= 40.0:
        return "Soft-Hold"
    else:
        return "Blocked"
