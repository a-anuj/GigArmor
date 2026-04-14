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

    DATABASE_URL: str

    REDIS_URL: str

    APP_ENV: str
    SECRET_KEY: str
    DEBUG: bool
    UPI_WEBHOOK_URL: str
    UPI_API_KEY: str

    # JWT
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours


settings = Settings()
