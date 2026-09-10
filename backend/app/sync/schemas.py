from datetime import datetime
from math import isfinite
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, JsonValue, field_validator


class SyncSchema(BaseModel):
    model_config = ConfigDict(populate_by_name=True)


class SyncRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid", strict=True)


class PushOperation(SyncRequest):
    operation_id: UUID = Field(alias="operationId", strict=False)
    entity_type: str = Field(alias="entityType", min_length=1, max_length=64)
    entity_id: UUID = Field(alias="entityId", strict=False)
    base_version: int = Field(alias="baseVersion", ge=0)
    payload: dict[str, JsonValue]
    deleted: bool

    @field_validator("payload")
    @classmethod
    def validate_finite_json_payload(cls, payload: dict[str, JsonValue]) -> dict[str, JsonValue]:
        def validate(value: JsonValue) -> None:
            if isinstance(value, float):
                if not isfinite(value):
                    raise ValueError("payload numbers must be finite")
            elif isinstance(value, list):
                for item in value:
                    validate(item)
            elif isinstance(value, dict):
                for item in value.values():
                    validate(item)

        validate(payload)
        return payload


class PushRequest(SyncRequest):
    operations: list[PushOperation] = Field(max_length=100)


class AcceptedOperation(SyncSchema):
    operation_id: UUID = Field(alias="operationId")
    version: int
    updated_at: datetime = Field(alias="updatedAt")
    duplicate: bool


class SyncRecordResponse(SyncSchema):
    entity_type: str = Field(alias="entityType")
    entity_id: UUID = Field(alias="entityId")
    version: int
    payload: dict[str, JsonValue]
    deleted_at: datetime | None = Field(alias="deletedAt")
    updated_at: datetime = Field(alias="updatedAt")


class SyncConflict(SyncSchema):
    operation_id: UUID = Field(alias="operationId")
    record: SyncRecordResponse


class IndeterminateOperationConflict(SyncSchema):
    operation_id: UUID = Field(alias="operationId")
    kind: Literal["indeterminateOperation"] = "indeterminateOperation"


class OperationReuseConflict(SyncSchema):
    operation_id: UUID = Field(alias="operationId")
    kind: Literal["operationReuse"] = "operationReuse"


class PushResponse(BaseModel):
    accepted: list[AcceptedOperation]
    conflicts: list[SyncConflict | IndeterminateOperationConflict | OperationReuseConflict]


class SyncChangeResponse(SyncRecordResponse):
    cursor: int


class PullResponse(BaseModel):
    cursor: int
    changes: list[SyncChangeResponse]
