"""Bound bodies before FastAPI JSON parsing, including chunked uploads."""
import asyncio

from starlette.responses import JSONResponse


class MentorBoundary:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        path = scope.get("path", "")
        if scope["type"] != "http" or not (path == "/api/mentor" or path.startswith("/api/mentor/")):
            return await self.app(scope, receive, send)

        async def reject(code, detail):
            await JSONResponse({"detail": detail}, status_code=code,
                               headers={"Cache-Control": "no-store"})(scope, receive, send)

        if scope.get("scheme") != "https":
            return await reject(403, "HTTPS required")
        headers = {k.lower(): v for k, v in scope.get("headers", [])}
        limit = 2097152 if path.rstrip("/") == "/api/mentor/stt" else 32768
        try:
            declared = int(headers.get(b"content-length", b"0"))
            if declared < 0 or declared > limit:
                return await reject(413, "Request size limit")
        except ValueError:
            return await reject(400, "Invalid request")
        body = bytearray()
        try:
            async with asyncio.timeout(15):
                while True:
                    part = await receive()
                    if part["type"] == "http.disconnect":
                        return
                    chunk = part.get("body", b"")
                    if len(body) + len(chunk) > limit:
                        return await reject(413, "Request size limit")
                    body.extend(chunk)
                    if not part.get("more_body", False):
                        break
        except TimeoutError:
            return await reject(408, "Request timeout")
        delivered = False
        started = False

        async def bounded_receive():
            nonlocal delivered
            if delivered:
                return await receive()
            delivered = True
            return {"type": "http.request", "body": bytes(body), "more_body": False}

        async def private_send(message):
            nonlocal started
            if message["type"] == "http.response.start":
                started = True
                message["headers"] = [(k, v) for k, v in message.get("headers", []) if k.lower() != b"cache-control"] + [(b"cache-control", b"no-store")]
            await send(message)

        try:
            await self.app(scope, bounded_receive, private_send)
        except Exception:
            if not started:
                await reject(500, "Mentor unavailable")
        finally:
            body.clear()
