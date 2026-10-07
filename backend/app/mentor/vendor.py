"""Bounded, fixed-endpoint transports for the mentor providers."""
import asyncio
import json
import math
import re
from typing import Any

import httpx
from fastapi import HTTPException

_OPENAI_URL = "https://api.openai.com/v1/responses"
_ELEVEN_VOICES_URL = "https://api.elevenlabs.io/v2/voices?page_size=20&include_total_count=false"
_MAX_RESPONSE = 64 * 1024
_MAX_AUDIO_RESPONSE = 2 * 1024 * 1024
_transport: httpx.AsyncBaseTransport | None = None

_OPENAI_MODELS = {"gpt-4.1-mini", "gpt-4.1-mini-2025-04-14"}
_STT_MODELS = {"scribe_v2"}
_TTS_MODELS = {"eleven_multilingual_v2"}
_VOICE_ID = re.compile(r"^[A-Za-z0-9]{1,64}$")

_SYSTEM_INSTRUCTIONS = (
    "Jesteś spokojnym, konkretnym i wymagającym polskim partnerem treningowym: "
    "wspierasz dyscyplinę oraz wszechstronność, nigdy nie zawstydzasz. Przy "
    "niejednoznacznym ciężarze, liczbie powtórzeń lub celu pytasz o doprecyzowanie. "
    "Nie diagnozujesz, nie wnioskujesz o cechach medycznych, pasie ani stylu karate, "
    "nie naśladujesz Masutatsu Oyama i nie tworzysz fałszywych cytatów. Nie udzielasz instrukcji "
    "dla ryzykownych urazów. Używaj wyłącznie znanych identyfikatorów katalogu; nie "
    "wykonujesz żadnych zapisów. Propozycja jest wyłącznie do jawnego potwierdzenia "
    "użytkownika, edycji albo anulowania."
)

_PROPOSAL_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "required": ["kind", "exercise_id", "weight_kg", "reps"],
    "properties": {
        "kind": {"type": "string", "enum": ["start_workout", "log_set", "navigate_exercises"]},
        "exercise_id": {"type": ["string", "null"]},
        "weight_kg": {"type": ["number", "null"]},
        "reps": {"type": ["integer", "null"]},
    },
}
_OUTPUT_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "required": ["text", "proposal"],
    "properties": {"text": {"type": "string"}, "proposal": {"anyOf": [{"type": "null"}, _PROPOSAL_SCHEMA]}},
}


def _client() -> httpx.AsyncClient:
    return httpx.AsyncClient(
        transport=_transport,
        follow_redirects=False,
        trust_env=False,
        timeout=httpx.Timeout(45.0, connect=10.0, read=30.0, write=15.0, pool=10.0),
    )


def _unavailable(status_code: int = 502) -> HTTPException:
    return HTTPException(status_code, "Mentor unavailable")


async def _read_response(response: httpx.Response, maximum: int) -> bytes:
    if response.status_code >= 500:
        raise _unavailable(503)
    if response.status_code < 200 or response.status_code >= 300:
        raise _unavailable()
    content_length = response.headers.get("content-length")
    if content_length and (not content_length.isdecimal() or int(content_length) > maximum):
        raise _unavailable()
    body = bytearray()
    async for chunk in response.aiter_bytes():
        if len(body) + len(chunk) > maximum:
            raise _unavailable()
        body.extend(chunk)
    return bytes(body)


async def _request_bytes(method: str, url: str, *, maximum: int, **kwargs: Any) -> tuple[httpx.Response, bytes]:
    try:
        async with _client() as client:
            async with asyncio.timeout(45):
                async with client.stream(method, url, **kwargs) as response:
                    return response, await _read_response(response, maximum)
    except HTTPException:
        raise
    except (httpx.HTTPError, TimeoutError, ValueError):
        raise _unavailable(503) from None


def _json_object(body: bytes) -> dict[str, Any]:
    try:
        parsed = json.loads(body)
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise _unavailable() from None
    if not isinstance(parsed, dict):
        raise _unavailable()
    return parsed


def _valid_number(value: Any, lower: float, upper: float) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and lower <= value <= upper


def _validate_proposal(value: Any) -> dict[str, Any] | None:
    if value is None:
        return None
    if not isinstance(value, dict) or set(value) != {"kind", "exercise_id", "weight_kg", "reps"}:
        raise _unavailable()
    kind, exercise_id, weight, reps = value["kind"], value["exercise_id"], value["weight_kg"], value["reps"]
    if kind not in {"start_workout", "log_set", "navigate_exercises"}:
        raise _unavailable()
    if exercise_id is not None and (not isinstance(exercise_id, str) or not _VOICE_ID.fullmatch(exercise_id)):
        raise _unavailable()
    if weight is not None and not _valid_number(weight, 0, 1000):
        raise _unavailable()
    if reps is not None and (not isinstance(reps, int) or isinstance(reps, bool) or not 1 <= reps <= 1000):
        raise _unavailable()
    if kind == "log_set" and (exercise_id is None or weight is None or reps is None):
        raise _unavailable()
    if kind == "navigate_exercises" and (exercise_id is not None or weight is not None or reps is not None):
        raise _unavailable()
    if kind == "start_workout" and (weight is not None or reps is not None):
        raise _unavailable()
    return {"kind": kind, "exercise_id": exercise_id, "weight_kg": weight, "reps": reps}


async def openai_reply(key: str, model: str, messages: list[dict], *, max_output_tokens: int = 800) -> dict:
    if not isinstance(key, str) or not key or model not in _OPENAI_MODELS or not 1 <= max_output_tokens <= 800 or not isinstance(messages, list):
        raise _unavailable()
    payload = {
        "model": model,
        "instructions": _SYSTEM_INSTRUCTIONS,
        "input": messages,
        "max_output_tokens": max_output_tokens,
        "store": False,
        "text": {"format": {"type": "json_schema", "name": "mentor_reply", "strict": True, "schema": _OUTPUT_SCHEMA}},
    }
    _, body = await _request_bytes("POST", _OPENAI_URL, maximum=_MAX_RESPONSE, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"}, json=payload)
    response = _json_object(body)
    if response.get("status") != "completed" or response.get("incomplete_details") is not None:
        raise _unavailable()
    output = response.get("output")
    if not isinstance(output, list):
        raise _unavailable()
    text: str | None = None
    for item in output:
        if not isinstance(item, dict) or set(item) - {"id", "type", "role", "status", "content"} or item.get("type") != "message" or item.get("status", "completed") != "completed" or not isinstance(item.get("content"), list):
            raise _unavailable()
        for content in item["content"]:
            if not isinstance(content, dict):
                raise _unavailable()
            if content.get("type") == "refusal" or "refusal" in content:
                raise _unavailable()
            if content.get("type") == "output_text" and isinstance(content.get("text"), str):
                text = content["text"]
    if text is None:
        raise _unavailable()
    decoded = _json_object(text.encode())
    answer_text = decoded.get("text")
    if set(decoded) != {"text", "proposal"} or not isinstance(answer_text, str) or not answer_text.strip() or len(answer_text) > 2000:
        raise _unavailable()
    usage = response.get("usage")
    tokens = usage.get("output_tokens") if isinstance(usage, dict) else None
    if not isinstance(tokens, int) or isinstance(tokens, bool) or not 0 <= tokens <= max_output_tokens:
        raise _unavailable()
    return {"text": answer_text, "proposal": _validate_proposal(decoded.get("proposal")), "tokens": tokens}


async def list_voices(key: str) -> list[dict]:
    if not isinstance(key, str) or not key:
        raise _unavailable()
    _, body = await _request_bytes("GET", _ELEVEN_VOICES_URL, maximum=_MAX_RESPONSE, headers={"xi-api-key": key})
    voices = _json_object(body).get("voices")
    if not isinstance(voices, list):
        raise _unavailable()
    safe: list[dict] = []
    for voice in voices[:20]:
        if not isinstance(voice, dict):
            continue
        voice_id, name = voice.get("voice_id"), voice.get("name")
        if isinstance(voice_id, str) and _VOICE_ID.fullmatch(voice_id) and isinstance(name, str) and 0 < len(name.strip()) <= 100:
            safe.append({"voice_id": voice_id, "name": name.strip()})
    return safe


async def transcribe(key: str, model: str, audio: bytes, content_type: str) -> str:
    if not isinstance(key, str) or not key or model not in _STT_MODELS or content_type not in {"audio/webm", "audio/mp4"} or not isinstance(audio, bytes) or not audio or len(audio) > _MAX_AUDIO_RESPONSE:
        raise _unavailable()
    filename = "audio.webm" if content_type == "audio/webm" else "audio.mp4"
    _, body = await _request_bytes("POST", "https://api.elevenlabs.io/v1/speech-to-text", maximum=_MAX_RESPONSE, headers={"xi-api-key": key}, data={"model_id": model, "language_code": "pl", "diarize": "false", "tag_audio_events": "false", "file_format": "other"}, files={"file": (filename, audio, content_type)})
    text = _json_object(body).get("text")
    if not isinstance(text, str) or len(text.strip()) > 2000:
        raise _unavailable()
    return text.strip()


async def speak(key: str, model: str, voice_id: str, text: str) -> bytes:
    if not isinstance(key, str) or not key or model not in _TTS_MODELS or not _VOICE_ID.fullmatch(voice_id) or not isinstance(text, str) or not 1 <= len(text.strip()) <= 2000:
        raise _unavailable()
    response, body = await _request_bytes("POST", f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=mp3_44100_128", maximum=_MAX_AUDIO_RESPONSE, headers={"xi-api-key": key, "Accept": "audio/mpeg", "Content-Type": "application/json"}, json={"text": text.strip(), "model_id": model})
    if response.headers.get("content-type", "").split(";", 1)[0].lower() != "audio/mpeg":
        raise _unavailable()
    return body
