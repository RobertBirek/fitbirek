from uuid import UUID

from pydantic import BaseModel


class LoginRequest(BaseModel):
    email: str
    password: str


class SessionResponse(BaseModel):
    accountId: UUID
    email: str
