"""
HustleHalt — Application Configuration
Reads all settings from .env — add new keys here when you add new integrations
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Database — PostgreSQL (Supabase) in prod, SQLite works locally too
    DATABASE_URL: str

    # Redis — optional for local dev, required in prod for burst detection
    REDIS_URL: str = "redis://localhost:6379/0"

    # App
    APP_ENV: str = "development"
    SECRET_KEY: str = "changeme-replace-before-production"
    DEBUG: bool = True

    # JWT — 24h tokens so workers stay logged in through the day
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24

    # UPI Payout Gateway — Razorpay in prod, mock URL for demo
    UPI_WEBHOOK_URL: str = "https://mock-upi.example.com/payout"
    UPI_API_KEY: str = "mock-api-key-replace-in-production"

    # Razorpay Payment Gateway (Option 1)
    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""

    # OpenWeatherMap — free tier (1000 calls/day), used for M_weather and real triggers
    OPENWEATHERMAP_API_KEY: str = ""

    # AQICN — free token, used for AQI trigger (T2)
    AQICN_API_TOKEN: str = ""

    # Set to false to use hardcoded mock data instead of live API calls (useful in CI)
    USE_REAL_WEATHER_API: bool = True


settings = Settings()
