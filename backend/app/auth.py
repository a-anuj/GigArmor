"""
HustleHalt — JWT Authentication Utilities
Password hashing  |  Token creation  |  Token verification
"""
from datetime import datetime, timedelta, timezone
from typing import Optional

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError, VerificationError, InvalidHashError
from jose import JWTError, jwt
from fastapi.security import OAuth2PasswordBearer

from app.config import settings

# ── Argon2id Password Hashing ─────────────────────────────────────────────────
# OWASP-recommended Argon2id parameters (as of 2024):
#   time_cost=3 iterations | memory_cost=64 MB | parallelism=4 threads
_ph = PasswordHasher(
    time_cost=3,
    memory_cost=65536,  # 64 MB
    parallelism=4,
    hash_len=32,
    salt_len=16,
)


def hash_password(plain: str) -> str:
    """Return an Argon2id hash of *plain*."""
    return _ph.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    """
    Return ``True`` if *plain* matches the Argon2id *hashed* string.
    Returns ``False`` on any verification failure (wrong password, bad hash, etc.).
    """
    try:
        return _ph.verify(hashed, plain)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


# ── JWT ───────────────────────────────────────────────────────────────────────
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def create_access_token(
    subject: str | int,
    expires_delta: Optional[timedelta] = None,
) -> str:
    """
    Create a signed JWT.

    :param subject: The value to encode as ``sub`` (typically worker_id).
    :param expires_delta: Override the default expiry window.
    :returns: Encoded JWT string.
    """
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    payload = {"sub": str(subject), "exp": expire, "iat": datetime.now(timezone.utc)}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_access_token(token: str) -> Optional[str]:
    """
    Decode and verify a JWT.

    :returns: The ``sub`` claim (worker_id as str) or ``None`` if invalid.
    """
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        return payload.get("sub")
    except JWTError:
        return None
