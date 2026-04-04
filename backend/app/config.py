"""
HustleHalt — Application Configuration
Reads settings from environment variables / .env file.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── Database ─────────────────────────────────────────
    # Default: SQLite (zero-config for hackathon demos)
    DATABASE_URL: str = "sqlite:///./hustlehalt.db"

    # ── Redis (optional, falls back to in-process tasks) ─
    REDIS_URL: str = "redis://localhost:6379/0"

    # ── App ───────────────────────────────────────────────
    APP_ENV: str = "development"
    SECRET_KEY: str = "hustlehalt-dev-secret-key"
    DEBUG: bool = True

    # ── UPI Mock Webhook ─────────────────────────────────
    UPI_WEBHOOK_URL: str = "https://mock-upi.example.com/payout"
    UPI_API_KEY: str = "mock-api-key"


settings = Settings()
