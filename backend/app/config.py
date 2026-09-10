from urllib.parse import urlparse

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import make_url


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file="/run/fit/.env", extra="ignore")

    database_url: str
    session_cookie_name: str = "fit_session"
    csrf_cookie_name: str = "fit_csrf"
    trusted_origin: str = "https://fit.birek.online"
    session_lifetime_hours: int = Field(default=24, gt=0)

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, value: str) -> str:
        try:
            database_url = make_url(value)
        except Exception as error:
            raise ValueError("DATABASE_URL must be a PostgreSQL asyncpg URL") from error
        if database_url.drivername != "postgresql+asyncpg" or not database_url.host or not database_url.database:
            raise ValueError("DATABASE_URL must be a PostgreSQL asyncpg URL")
        return value

    @field_validator("trusted_origin")
    @classmethod
    def validate_trusted_origin(cls, value: str) -> str:
        origin = urlparse(value)
        if (
            origin.scheme != "https"
            or not origin.hostname
            or origin.path
            or origin.params
            or origin.query
            or origin.fragment
            or origin.username
            or origin.password
        ):
            raise ValueError("TRUSTED_ORIGIN must be an HTTPS origin")
        return value


settings = Settings()
