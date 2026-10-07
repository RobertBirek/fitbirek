import json
import math
from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from sqlalchemy import delete, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.identity.service import AuthenticatedSession, require_authenticated
from app.security.csrf import require_csrf
from . import service
from .models import MentorCredential, MentorMessage, MentorRequest, MentorSession
from .schemas import KeyInput, MessageInput, RequestInput, SessionInput, SettingsUpdate

router = APIRouter(prefix="/api/mentor", tags=["mentor"])
Provider = Literal["openai", "elevenlabs"]


@router.get("/settings")
async def get_settings(db: AsyncSession = Depends(get_session),
                       auth: AuthenticatedSession = Depends(require_authenticated)):
    await service.lock_user(db, auth.account.id)
    row = await service.user_settings(db, auth.account.id)
    usage = await service.usage_for(db, auth.account.id, service.now().date())
    result = {"available": service.available(),
        "openai_configured": await service.configured(db, auth.account.id, "openai"),
        "elevenlabs_configured": await service.configured(db, auth.account.id, "elevenlabs"),
        **{key: getattr(row, key) for key in SettingsUpdate.model_fields},
        "models": service.MODELS, "tts_models": service.TTS_MODELS, "stt_models": service.STT_MODELS,
        "voices": [service.DEFAULT_VOICE] + [v for v in row.voices if v["voice_id"] != service.DEFAULT_VOICE["voice_id"]],
        "limits": service.LIMITS, "usage": {key: getattr(usage, key) for key in service.LIMITS}}
    await db.commit()
    return result


@router.put("/settings")
async def put_settings(payload: SettingsUpdate, db: AsyncSession = Depends(get_session),
                       auth: AuthenticatedSession = Depends(require_csrf)):
    await service.lock_user(db, auth.account.id)
    row = await service.user_settings(db, auth.account.id)
    voices = {v["voice_id"] for v in row.voices} | {service.DEFAULT_VOICE["voice_id"]}
    if payload.voice_id not in voices:
        raise HTTPException(422, "Select an available voice")
    await service.reject_credentials(db, auth.account.id, payload.memory)
    for key, value in payload.model_dump().items():
        setattr(row, key, value)
    await service.invalidate_pending(db, auth.account.id)
    await db.commit()
    return await get_settings(db, auth)


@router.put("/keys/{provider}")
async def put_key(provider: Provider, payload: KeyInput, db: AsyncSession = Depends(get_session),
                  auth: AuthenticatedSession = Depends(require_csrf)):
    envelope = json.dumps({"user": str(auth.account.id), "provider": provider,
                           "key": payload.key.get_secret_value()}).encode()
    encrypted = service.cipher().encrypt(envelope)
    await service.lock_user(db, auth.account.id)
    record = await db.get(MentorCredential, {"user_id": auth.account.id, "provider": provider})
    if record is None:
        db.add(MentorCredential(user_id=auth.account.id, provider=provider, encrypted_key=encrypted))
    else:
        record.encrypted_key = encrypted
    await service.invalidate_pending(db, auth.account.id)
    await db.commit()
    return {"configured": True}


@router.delete("/keys/{provider}")
async def delete_key(provider: Provider, db: AsyncSession = Depends(get_session),
                     auth: AuthenticatedSession = Depends(require_csrf)):
    await service.lock_user(db, auth.account.id)
    await db.execute(delete(MentorCredential).where(MentorCredential.user_id == auth.account.id,
                                                   MentorCredential.provider == provider))
    await service.invalidate_pending(db, auth.account.id)
    if provider == "elevenlabs":
        row = await service.user_settings(db, auth.account.id)
        row.voices = []
        row.voice_id = service.DEFAULT_VOICE["voice_id"]
    await db.commit()
    return {"configured": False}


@router.get("/sessions")
async def sessions(db: AsyncSession = Depends(get_session),
                   auth: AuthenticatedSession = Depends(require_authenticated)):
    rows = (await db.scalars(select(MentorSession).where(MentorSession.user_id == auth.account.id,
        MentorSession.deleted_at.is_(None)).order_by(MentorSession.created_at.desc()).limit(20))).all()
    return {"sessions": [{"id": str(x.id), "created_at": x.created_at.isoformat()} for x in rows]}


@router.get("/operations")
async def operations(session_id: UUID | None = None, subject_id: UUID | None = None,
                     kind: Literal["message", "tts", "stt", "voices", "test_openai", "test_elevenlabs"] | None = None,
                     db: AsyncSession = Depends(get_session),
                     auth: AuthenticatedSession = Depends(require_authenticated)):
    query = select(MentorRequest).where(MentorRequest.user_id == auth.account.id)
    if session_id is not None:
        query = query.where(MentorRequest.session_id == session_id)
    if subject_id is not None:
        subject = MentorRequest.subject_id == subject_id
        if kind == "tts":
            # Legacy unknown subjects must require explicit regeneration, not
            # disappear behind pagination and look like never-billed speech.
            subject = or_(subject, MentorRequest.subject_id.is_(None))
        query = query.where(subject)
    if kind is not None:
        query = query.where(MentorRequest.kind == kind)
    rows = (await db.scalars(query.order_by(MentorRequest.created_at.desc(), MentorRequest.id.desc()).limit(100))).all()
    return {"operations": [await service.operation_status(db, auth.account.id, row) for row in rows]}


@router.get("/operations/{request_id}")
async def operation(request_id: UUID, db: AsyncSession = Depends(get_session),
                    auth: AuthenticatedSession = Depends(require_authenticated)):
    row = await db.scalar(select(MentorRequest).where(MentorRequest.user_id == auth.account.id,
                                                     MentorRequest.request_id == request_id))
    if row is None:
        raise HTTPException(404, "Operation unavailable")
    return await service.operation_status(db, auth.account.id, row)


@router.post("/sessions")
async def create_session(payload: SessionInput, db: AsyncSession = Depends(get_session),
                         auth: AuthenticatedSession = Depends(require_csrf)):
    await service.lock_user(db, auth.account.id)
    row = await db.get(MentorSession, payload.id)
    if row is None:
        count = await db.scalar(select(func.count()).select_from(MentorSession).where(
            MentorSession.user_id == auth.account.id, MentorSession.deleted_at.is_(None)))
        if count >= 20:
            raise HTTPException(409, "Delete an old conversation first")
        db.add(MentorSession(id=payload.id, user_id=auth.account.id, created_at=service.now()))
        await db.commit()
    elif row.user_id != auth.account.id or row.deleted_at is not None:
        raise HTTPException(404, "Session unavailable")
    return {"id": str(payload.id)}


@router.delete("/sessions/{session_id}")
async def delete_session(session_id: UUID, db: AsyncSession = Depends(get_session),
                         auth: AuthenticatedSession = Depends(require_csrf)):
    await service.lock_user(db, auth.account.id)
    row = await db.get(MentorSession, session_id, populate_existing=True)
    if row is None or row.user_id != auth.account.id:
        raise HTTPException(404, "Session unavailable")
    row.deleted_at = service.now()
    await db.execute(delete(MentorMessage).where(MentorMessage.session_id == session_id))
    pending = (await db.scalars(select(MentorRequest).where(MentorRequest.user_id == auth.account.id,
                                                           MentorRequest.session_id == session_id))).all()
    for item in pending:
        item.state, item.response = "cancelled", None
    await db.commit()
    return {"deleted": True}


@router.get("/sessions/{session_id}/messages")
async def messages(session_id: UUID, db: AsyncSession = Depends(get_session),
                   auth: AuthenticatedSession = Depends(require_authenticated)):
    await service.owned_session(db, auth.account.id, session_id)
    rows = list((await db.scalars(select(MentorMessage).where(MentorMessage.session_id == session_id)
        .order_by(MentorMessage.created_at.desc(), MentorMessage.id.desc()).limit(40))).all())[::-1]
    return {"messages": [service.message_dict(x) for x in rows]}


@router.post("/sessions/{session_id}/messages")
async def create_message(session_id: UUID, payload: MessageInput, db: AsyncSession = Depends(get_session),
                         auth: AuthenticatedSession = Depends(require_csrf)):
    return await service.reply(db, auth.account.id, session_id, payload.request_id, payload.text, auth.session.id)


@router.post("/voices")
async def voices(payload: RequestInput, db: AsyncSession = Depends(get_session),
                 auth: AuthenticatedSession = Depends(require_csrf)):
    return await service.voice_operation(db, auth.account.id, payload.request_id, "voices", auth_session_id=auth.session.id)


@router.post("/test/{provider}")
async def test_provider(provider: Provider, payload: RequestInput, db: AsyncSession = Depends(get_session),
                        auth: AuthenticatedSession = Depends(require_csrf)):
    return await service.voice_operation(db, auth.account.id, payload.request_id, "test_" + provider, auth_session_id=auth.session.id)


@router.post("/stt")
async def stt(request: Request, db: AsyncSession = Depends(get_session),
              auth: AuthenticatedSession = Depends(require_csrf)):
    content_type = request.headers.get("content-type", "").split(";", 1)[0]
    if content_type not in {"audio/webm", "audio/mp4"}:
        raise HTTPException(415, "Unsupported audio")
    try:
        request_id = UUID(request.headers["x-request-id"])
        seconds = float(request.headers["x-audio-duration"])
        if not math.isfinite(seconds) or not 0.1 <= seconds <= 30:
            raise ValueError()
    except (KeyError, ValueError):
        raise HTTPException(422, "Invalid audio request") from None
    audio = await request.body()
    if not audio or len(audio) > 2097152:
        raise HTTPException(413, "Audio size limit")
    return await service.voice_operation(db, auth.account.id, request_id, "stt",
                                          audio=audio, content_type=content_type, auth_session_id=auth.session.id)


@router.post("/messages/{message_id}/tts")
async def tts(message_id: UUID, payload: RequestInput, db: AsyncSession = Depends(get_session),
              auth: AuthenticatedSession = Depends(require_csrf)):
    audio = await service.voice_operation(db, auth.account.id, payload.request_id, "tts", message_id=message_id, auth_session_id=auth.session.id)
    return Response(content=audio, media_type="audio/mpeg", headers={"Cache-Control": "no-store"})
