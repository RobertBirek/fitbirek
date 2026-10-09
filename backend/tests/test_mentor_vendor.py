import json
from pathlib import Path

import httpx
import pytest
from fastapi import HTTPException


@pytest.mark.asyncio
async def test_openai_accepts_completed_message_phase(monkeypatch):
    from app.mentor import catalog, vendor

    response = {
        "status": "completed",
        "output": [{
            "content": [{"type": "output_text", "text": '{"text":"gotowe","proposal":null}'}],
            "id": "msg_1",
            "phase": "final",
            "role": "assistant",
            "status": "completed",
            "type": "message",
        }],
        "usage": {"input_tokens": 1, "output_tokens": 1},
    }
    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(
        lambda request: httpx.Response(200, json=response),
    ))

    result = await vendor.openai_reply("key", catalog.profile_for_key("gpt-6-luna"), [])

    assert result["text"] == "gotowe"


@pytest.mark.asyncio
async def test_openai_uses_fixed_endpoint_and_keeps_key_out_of_body(monkeypatch):
    from app.mentor import catalog, vendor

    captured = {}

    def handler(request):
        captured["request"] = request
        return httpx.Response(
            200,
            json={
                "status": "completed",
                "output": [{"type": "message", "role": "assistant", "status": "completed", "content": [{"type": "output_text", "text": json.dumps({"text": "Spokojnie, zrób jedną serię.", "proposal": None})}]}],
                "usage": {"input_tokens": 3, "output_tokens": 7},
            },
        )

    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(handler))
    profile = catalog.profile_for_key("legacy-gpt-4.1-mini-2025-04-14")
    result = await vendor.openai_reply("private-key", profile, [{"role": "user", "content": "Pomóż"}])

    request = captured["request"]
    assert str(request.url) == "https://api.openai.com/v1/responses"
    assert request.headers["authorization"] == "Bearer private-key"
    assert "private-key" not in request.content.decode()
    payload = json.loads(request.content)
    assert payload["model"] == profile.provider_model_id
    assert payload["max_output_tokens"] == profile.max_output_tokens
    assert payload["store"] is False
    assert "tools" not in payload
    assert result == {"text": "Spokojnie, zrób jedną serię.", "proposal": None, "input_tokens": 3, "output_tokens": 7}


@pytest.mark.asyncio
async def test_openai_requires_usage_and_sends_safety_contract(monkeypatch):
    from app.mentor import catalog, vendor

    captured = {}
    response = {"status": "completed", "output": [{"type": "message", "content": [{"type": "output_text", "text": '{"text":"ok","proposal":null}'}]}]}
    def handler(request):
        captured.update(json.loads(request.content))
        return httpx.Response(200, json=response)
    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(handler))
    with pytest.raises(HTTPException):
        await vendor.openai_reply("key", catalog.profile_for_key("legacy-gpt-4.1-mini-2025-04-14"), [])
    instructions = captured["instructions"].lower()
    for phrase in ("bez presji", "bez oceniania", "wszechstron", "oyama", "pas", "medycz", "potwierdzenia", "persona", "pamięć", "historia", "kontekst", "nieufn", "niższego priorytetu"):
        assert phrase in instructions
    assert "wymagając" not in instructions


@pytest.mark.asyncio
async def test_openai_uses_reasoning_only_when_active_profile_requires_it(monkeypatch):
    from app.mentor import catalog, vendor

    captured = []
    response = {
        "status": "completed",
        "output": [
            {"type": "reasoning", "id": "rs_1", "status": "completed", "summary": []},
            {"type": "message", "role": "assistant", "status": "completed", "content": [{"type": "output_text", "text": '{"text":"ok","proposal":null}'}]},
        ],
        "usage": {"input_tokens": 1, "output_tokens": 1},
    }

    def handler(request):
        captured.append(json.loads(request.content))
        return httpx.Response(200, json=response)

    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(handler))
    legacy = catalog.profile_for_key("legacy-gpt-4.1-mini-2025-04-14")
    luna = catalog.profile_for_key("gpt-6-luna")
    await vendor.openai_reply("key", legacy, [])
    await vendor.openai_reply("key", luna, [])

    assert "reasoning" not in captured[0]
    assert captured[1]["reasoning"] == {"effort": "none"}


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("profile_key", "provider_model_id", "max_output_tokens", "reasoning_effort"),
    [
        ("legacy-gpt-4.1-mini-2025-04-14", "gpt-4.1-mini-2025-04-14", 800, None),
        ("gpt-6-luna", "gpt-6-luna", 800, "none"),
        ("gpt-6.1-sol", "gpt-6.1-sol", 1600, "low"),
        ("gpt-6-astra", "gpt-6-astra", 1600, "low"),
    ],
)
async def test_openai_contract_uses_every_active_catalog_profile(
    monkeypatch, profile_key, provider_model_id, max_output_tokens, reasoning_effort,
):
    from app.mentor import catalog, vendor

    captured = {}
    response = {
        "status": "completed",
        "output": [{"type": "message", "role": "assistant", "status": "completed", "content": [{"type": "output_text", "text": '{"text":"ok","proposal":null}'}]}],
        "usage": {"input_tokens": 1, "output_tokens": 1},
    }
    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(
        lambda request: (captured.update(json.loads(request.content)), httpx.Response(200, json=response))[1],
    ))

    await vendor.openai_reply("key", catalog.profile_for_key(profile_key), [])

    assert captured["model"] == provider_model_id
    assert captured["max_output_tokens"] == max_output_tokens
    if reasoning_effort is None:
        assert "reasoning" not in captured
    else:
        assert captured["reasoning"] == {"effort": reasoning_effort}


@pytest.mark.asyncio
async def test_client_disables_redirects_environment_proxies_and_uses_granular_timeouts():
    from app.mentor import vendor

    client = vendor._client()
    try:
        assert client.follow_redirects is False
        assert client._trust_env is False
        assert client.timeout.connect == 10
        assert client.timeout.read == 30
    finally:
        await client.aclose()


@pytest.mark.asyncio
@pytest.mark.parametrize("response", [
    {"status": "incomplete", "output": []},
    {"status": "completed", "output": [{"type": "message", "content": [{"type": "refusal", "refusal": "nie"}]}]},
    {"status": "completed", "output": [{"type": "message", "content": [{"type": "output_text", "text": "{}"}]}]},
    {"status": "completed", "output": [{"type": "function_call", "name": "tool", "arguments": "{}"}], "usage": {"input_tokens": 1, "output_tokens": 1}},
    {"status": "completed", "output": [{"type": "reasoning"}, {"type": "message", "role": "assistant", "status": "completed", "content": [{"type": "output_text", "text": '{"text":"ok","proposal":null}'}]}, {"type": "message", "role": "assistant", "status": "completed", "content": [{"type": "output_text", "text": '{"text":"again","proposal":null}'}]}], "usage": {"input_tokens": 1, "output_tokens": 1}},
])
async def test_openai_fails_closed_for_incomplete_refusal_or_malformed_output(monkeypatch, response):
    from app.mentor import catalog, vendor

    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(lambda request: httpx.Response(200, json=response)))
    with pytest.raises(HTTPException) as failure:
        await vendor.openai_reply("private-key", catalog.profile_for_key("legacy-gpt-4.1-mini-2025-04-14"), [])
    assert failure.value.status_code == 502
    assert failure.value.detail == "Mentor unavailable"


@pytest.mark.asyncio
async def test_openai_rejects_missing_output_tokens_even_with_valid_input_tokens(monkeypatch):
    from app.mentor import catalog, vendor

    response = {
        "status": "completed",
        "output": [{"type": "message", "role": "assistant", "status": "completed", "content": [{"type": "output_text", "text": '{"text":"ok","proposal":null}'}]}],
        "usage": {"input_tokens": 1},
    }
    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(
        lambda request: httpx.Response(200, json=response),
    ))

    with pytest.raises(HTTPException, match="Mentor unavailable"):
        await vendor.openai_reply("key", catalog.profile_for_key("legacy-gpt-4.1-mini-2025-04-14"), [])


@pytest.mark.asyncio
async def test_openai_rejects_malformed_reasoning_item(monkeypatch):
    from app.mentor import catalog, vendor

    response = {
        "status": "completed",
        "output": [
            {"type": "reasoning", "status": "in_progress", "unexpected": True},
            {"type": "message", "role": "assistant", "status": "completed", "content": [{"type": "output_text", "text": '{"text":"ok","proposal":null}'}]},
        ],
        "usage": {"input_tokens": 1, "output_tokens": 1},
    }
    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(
        lambda request: httpx.Response(200, json=response),
    ))

    with pytest.raises(HTTPException, match="Mentor unavailable"):
        await vendor.openai_reply("key", catalog.profile_for_key("legacy-gpt-4.1-mini-2025-04-14"), [])


@pytest.mark.asyncio
async def test_provider_does_not_follow_redirects(monkeypatch):
    from app.mentor import vendor

    calls = 0
    def handler(request):
        nonlocal calls
        calls += 1
        return httpx.Response(307, headers={"location": "https://attacker.invalid/"})
    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(handler))
    with pytest.raises(HTTPException):
        await vendor.list_voices("key")
    assert calls == 1


@pytest.mark.asyncio
async def test_elevenlabs_uses_fixed_paths_and_filters_voice_metadata(monkeypatch):
    from app.mentor import vendor

    requests = []
    def handler(request):
        requests.append(request)
        if request.url.path == "/v2/voices":
            return httpx.Response(200, json={"voices": [{"voice_id": "JBFqnCBsd6RMkjVDRZzb", "name": "Polski głos", "preview_url": "https://secret"}, {"voice_id": "bad/id", "name": "x"}]})
        return httpx.Response(200, content=b"mp3", headers={"content-type": "audio/mpeg"})

    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(handler))
    assert await vendor.list_voices("eleven-secret") == [{"voice_id": "JBFqnCBsd6RMkjVDRZzb", "name": "Polski głos"}]
    assert await vendor.speak("eleven-secret", "eleven_multilingual_v2", "JBFqnCBsd6RMkjVDRZzb", "Dzień dobry") == b"mp3"
    assert str(requests[0].url) == "https://api.elevenlabs.io/v2/voices?page_size=20&include_total_count=false"
    assert str(requests[1].url) == "https://api.elevenlabs.io/v1/text-to-speech/JBFqnCBsd6RMkjVDRZzb?output_format=mp3_44100_128"
    assert all("eleven-secret" not in request.content.decode(errors="ignore") for request in requests)


@pytest.mark.asyncio
async def test_vendor_rejects_oversized_audio_response(monkeypatch):
    from app.mentor import vendor

    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(lambda request: httpx.Response(200, content=b"x" * (2 * 1024 * 1024 + 1), headers={"content-type": "audio/mpeg"})))
    with pytest.raises(HTTPException) as failure:
        await vendor.speak("key", "eleven_multilingual_v2", "JBFqnCBsd6RMkjVDRZzb", "tekst")
    assert failure.value.status_code == 502


@pytest.mark.asyncio
async def test_transcribe_sends_only_fixed_multipart_fields_and_keeps_key_in_header(monkeypatch):
    from app.mentor import vendor

    captured = {}
    def handler(request):
        captured["request"] = request
        return httpx.Response(200, json={"text": "  gotowe  "})
    monkeypatch.setattr(vendor, "_transport", httpx.MockTransport(handler))
    assert await vendor.transcribe("eleven-private", "scribe_v2", b"audio", "audio/webm") == "gotowe"
    request = captured["request"]
    body = request.content.decode()
    assert str(request.url) == "https://api.elevenlabs.io/v1/speech-to-text"
    assert request.headers["xi-api-key"] == "eleven-private"
    assert "eleven-private" not in body
    for field in ("model_id", "language_code", "diarize", "tag_audio_events", "file_format", "audio"):
        assert field in body


def test_legacy_training_context_is_not_exported(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql+asyncpg://fit:fit@127.0.0.1:1/fit")
    from app.mentor import context

    assert not hasattr(context, "training_context")


def test_service_does_not_export_duplicate_voice_validator(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql+asyncpg://fit:fit@127.0.0.1:1/fit")
    from app.mentor import service

    assert not hasattr(service, "VOICE_ID")


def test_catalogue_is_a_verified_subset_of_public_exercise_asset():
    from app.mentor.context import CATALOGUE

    asset = json.loads((Path(__file__).resolve().parents[2] / "assets/data/exercises.json").read_text())
    actual = {item["id"]: item["nazwaPl"] for item in asset}
    assert 0 < len(CATALOGUE) <= 30
    assert CATALOGUE.items() <= actual.items()


def test_validate_audio_reads_mp4_movie_duration_and_rejects_malformed_data():
    from app.mentor.audio import validate_audio

    mvhd = b"\x00\x00\x00\x1c" + b"mvhd" + b"\x00\x00\x00\x00" + b"\x00" * 8 + (1000).to_bytes(4, "big") + (2500).to_bytes(4, "big")
    data = (len(mvhd) + 8).to_bytes(4, "big") + b"moov" + mvhd
    with pytest.raises(HTTPException):
        validate_audio(data, "audio/mp4")
    with pytest.raises(HTTPException):
        validate_audio(b"not-a-container", "audio/mp4")


def test_validate_audio_reads_unknown_size_webm_opus_block_timing():
    from app.mentor.audio import validate_audio

    def element(identifier, payload):
        return identifier + bytes([0x80 | len(payload)]) + payload
    def simple_block(relative_ms):
        return element(b"\xa3", b"\x81" + relative_ms.to_bytes(2, "big", signed=True) + b"\x80\xf8")
    info = element(b"\x15\x49\xa9\x66", element(b"\x2a\xd7\xb1", b"\x0f\x42\x40"))
    track = element(b"\xae", element(b"\xd7", b"\x01") + element(b"\x83", b"\x02") + element(b"\x86", b"A_OPUS"))
    tracks = element(b"\x16\x54\xae\x6b", track)
    cluster = element(b"\x1f\x43\xb6\x75", element(b"\xe7", b"\x00") + simple_block(0) + simple_block(20) + simple_block(40))
    webm = b"\x1a\x45\xdf\xa3\x80" + b"\x18\x53\x80\x67\xff" + info + tracks + cluster
    assert validate_audio(webm, "audio/webm") == pytest.approx(0.06)
