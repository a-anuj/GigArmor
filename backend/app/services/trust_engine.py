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


# ── Layer 1: Device Sensor Signals ──────────────────────────────────────────────
def _layer1_device_signals() -> float:
    """Mock: Accelerometer, Cell tower ID cross-check, Battery drain rate."""
    # 95% of the time, sensors validate successfully
    return random.uniform(0.85, 1.0) if random.random() < 0.95 else random.uniform(0.1, 0.4)

# ── Layer 2: Behavioral & Platform Signals ────────────────────────────────────
def _layer2_behavior_signals(baseline_score: float) -> float:
    """Mock: Platform delivery activity drop, historical behavioral baseline, cross-zone claim ratio."""
    stochastic_component = random.uniform(0.75, 1.0) if random.random() < 0.90 else random.uniform(0.3, 0.6)
    
    # Isolation Forest simulated blend: 70% stochastic + 30% historical baseline
    return (stochastic_component * 100 * (1 - _BASELINE_WEIGHT)) + (baseline_score * _BASELINE_WEIGHT)

# ── Layer 3: Network Graph Signals ────────────────────────────────────────────
def _layer3_network_graph() -> float:
    """Mock: Temporal burst detection, shared device fingerprint graph, referral network topology."""
    # 98% of the time, no syndicate patterns detected
    return random.uniform(0.90, 1.0) if random.random() < 0.98 else random.uniform(0.2, 0.5)


def calculate_trust_score(worker_id: int, baseline_score: float = 75.0) -> float:
    """
    Compute a multi-layer trust score for a potential claim.
    Incorporates:
     1. Device-level signals (motion patterns)
     2. Behavioral profiling & Platform signals (baseline_score)
     3. Network-level validation & temporal burst analysis
    """
    layer1_trust = _layer1_device_signals()
    layer2_trust = _layer2_behavior_signals(baseline_score)
    layer3_trust = _layer3_network_graph()

    raw = layer2_trust * layer1_trust * layer3_trust
    score = round(min(100.0, max(0.0, raw)), 2)

    logger.info(
        f"Trust score for worker={worker_id}: {score:.2f} "
        f"(raw={raw:.2f}, baseline={baseline_score})"
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
