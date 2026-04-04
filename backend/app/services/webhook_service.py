"""
GigArmor — Mock UPI Payout Webhook Service (Phase 5)

In production: calls Razorpay / PhonePe / PayU payout API.
For demo: logs the payout and returns a mock success response.
"""
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


def fire_upi_webhook(upi_id: str, amount: float, claim_id: int) -> dict:
    """
    Simulates an instant UPI payout to the worker.

    Logs the transaction and returns a mock gateway response.
    In production, replace the body with an actual httpx POST call to
    the payment gateway's disbursement endpoint.
    """
    reference_id = f"GIGARMOR-CLM-{claim_id}-{int(datetime.utcnow().timestamp())}"

    payload = {
        "upi_id":       upi_id,
        "amount":       amount,
        "currency":     "INR",
        "reference_id": reference_id,
        "description":  "GigArmor Parametric Insurance Payout — Zero Touch",
        "initiated_at": datetime.utcnow().isoformat() + "Z",
    }

    # ── Mock response (replace with real API call in production) ──────────────
    logger.info(
        f"🚀 UPI PAYOUT FIRED → {upi_id} | ₹{amount:.2f} | Ref: {reference_id}"
    )

    return {
        "status":         "SUCCESS",
        "gateway":        "GigArmor-MockPay",
        "transaction_id": reference_id,
        "upi_id":         upi_id,
        "amount":         amount,
        "currency":       "INR",
        "message":        f"₹{amount:.0f} credited instantly to {upi_id}",
        "timestamp":      datetime.utcnow().isoformat() + "Z",
    }
