from datetime import date, datetime, timezone
from math import isfinite
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from app.health.contract import (
    MAX_BATCH_ITEMS,
    MAXIMUM_SOURCE_LENGTH,
    MAXIMUM_STEPS,
    MAXIMUM_WEIGHT_KG,
    MINIMUM_SAMPLE_DATE,
    MINIMUM_WEIGHT_KG,
    STEPS_METHOD_MANUAL_VERIFIED_TOTAL,
    WARSAW_ZONE,
    WEIGHT_FUTURE_TOLERANCE,
)


class ConsentRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)

    consent: Literal[True]

    @field_validator("consent", mode="before")
    @classmethod
    def literal_true(cls, value):
        if value is not True:
            raise ValueError("Invalid consent")
        return value


class WeightSampleInput(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)

    measured_at: datetime = Field(alias="measuredAt")
    value: float
    unit: Literal["kg"]
    source: str

    @field_validator("measured_at")
    @classmethod
    def measured_at_requires_offset(cls, value: datetime) -> datetime:
        if value.tzinfo is None:
            raise ValueError("measuredAt requires an explicit offset")
        return value

    @field_validator("value")
    @classmethod
    def value_requires_finite_kilograms(cls, value: float) -> float:
        if not isfinite(value) or not MINIMUM_WEIGHT_KG <= value <= MAXIMUM_WEIGHT_KG:
            raise ValueError("value must be a finite number in kilograms")
        return value

    @field_validator("source")
    @classmethod
    def source_requires_bounded_text(cls, value: str) -> str:
        if not 1 <= len(value) <= MAXIMUM_SOURCE_LENGTH:
            raise ValueError("source must be 1-100 characters")
        return value


class StepsSampleInput(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)

    day: date
    value: int
    method: Literal[STEPS_METHOD_MANUAL_VERIFIED_TOTAL]

    @field_validator("value")
    @classmethod
    def value_requires_bounded_total(cls, value: int) -> int:
        if not 0 <= value <= MAXIMUM_STEPS:
            raise ValueError("value must be an integer between 0 and 100000")
        return value


class ImportRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)

    version: Literal[1]

    @field_validator("version", mode="before")
    @classmethod
    def literal_version(cls, value):
        if type(value) is not int or value != 1:
            raise ValueError("Invalid version")
        return value
    weights: list[WeightSampleInput] = []
    steps: list[StepsSampleInput] = []

    @model_validator(mode="after")
    def validate_batch_bounds(self) -> "ImportRequest":
        total = len(self.weights) + len(self.steps)
        if total == 0:
            raise ValueError("batch must not be empty")
        if total > MAX_BATCH_ITEMS:
            raise ValueError("batch exceeds the maximum item count")

        now = datetime.now(timezone.utc)
        today = now.astimezone(WARSAW_ZONE).date()
        for sample in self.steps:
            if sample.day < MINIMUM_SAMPLE_DATE or sample.day > today:
                raise ValueError("day must fall between 2000-01-01 and today")
        if len({sample.day for sample in self.steps}) != len(self.steps):
            raise ValueError("only one steps result per day per batch")

        weight_ceiling = now + WEIGHT_FUTURE_TOLERANCE
        for sample in self.weights:
            measured_utc = sample.measured_at.astimezone(timezone.utc)
            if measured_utc < datetime(MINIMUM_SAMPLE_DATE.year, MINIMUM_SAMPLE_DATE.month, MINIMUM_SAMPLE_DATE.day, tzinfo=timezone.utc):
                raise ValueError("measuredAt must be on or after 2000-01-01")
            if measured_utc > weight_ceiling:
                raise ValueError("measuredAt must not be in the future")
        return self
