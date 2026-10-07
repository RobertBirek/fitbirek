"""RFC 8291 encryption and RFC 8292 VAPID, with a pinned-IP HTTPS transport.

No requests/urllib redirects or environment proxies. DNS is resolved once;
every answer must be public, and the connected socket uses that exact IP.
"""
import asyncio
import base64
import ipaddress
import json
import socket
import ssl
import time
from pathlib import Path
from urllib.parse import urlsplit

import http_ece
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
from py_vapid import Vapid02

from app.push.schemas import decode_key, validate_endpoint


TOTAL_TIMEOUT_SECONDS = 10
CONNECT_TIMEOUT_SECONDS = 3


def load_vapid(settings):
    # Never generate a key, including when configuration is missing/invalid.
    if not settings.push_enabled:
        raise ValueError("Push disabled")
    path = Path(settings.push_vapid_private_key_file)
    if not path.is_absolute() or not settings.push_vapid_subject.startswith(("mailto:", "https://")):
        raise ValueError("Incomplete VAPID configuration")
    vapid = Vapid02.from_pem(path.read_bytes())
    if not isinstance(vapid.private_key.curve, ec.SECP256R1):
        raise ValueError("VAPID requires P-256")
    public = base64.urlsafe_b64encode(vapid.public_key.public_bytes(Encoding.X962, PublicFormat.UncompressedPoint)).decode().rstrip("=")
    if public != settings.push_vapid_public_key:
        raise ValueError("VAPID key mismatch")
    # Validate subject/signing before publishing a healthy sender heartbeat.
    vapid.sign({"aud": "https://fcm.googleapis.com", "sub": settings.push_vapid_subject})
    return vapid


def encrypt_payload(public_key, auth, payload):
    data = json.dumps(payload, separators=(",", ":"), ensure_ascii=True).encode()
    if len(data) > 3000:
        raise ValueError("Push payload too large")
    return http_ece.encrypt(data, private_key=ec.generate_private_key(ec.SECP256R1()),
                            dh=decode_key(public_key, 65), auth_secret=decode_key(auth, 16), version="aes128gcm")


def validate_addresses(addresses):
    if not addresses:
        raise ValueError("No push provider addresses")
    for value in addresses:
        address = ipaddress.ip_address(value)
        if not address.is_global or address.is_multicast or address.is_reserved or (
            isinstance(address, ipaddress.IPv6Address) and (
                address.ipv4_mapped or address.sixtofour or address.teredo or address.is_site_local
                or address in ipaddress.ip_network("64:ff9b::/96")
                or address in ipaddress.ip_network("64:ff9b:1::/48")
            )
        ):
            raise ValueError("Non-public push provider address")


async def post_pinned(endpoint, headers, body):
    validate_endpoint(endpoint)
    url = urlsplit(endpoint)
    loop = asyncio.get_running_loop()
    writer = None
    sock = None
    try:
        async with asyncio.timeout(TOTAL_TIMEOUT_SECONDS):
            answers = await loop.getaddrinfo(url.hostname, 443, type=socket.SOCK_STREAM, proto=socket.IPPROTO_TCP)
            validate_addresses([answer[4][0] for answer in answers])
            context = ssl.create_default_context()
            failure = None
            seen = set()
            for family, kind, protocol, _, address in answers:
                if (family, address) in seen:
                    continue
                seen.add((family, address))
                try:
                    # A black-holed first address must leave time for fallback.
                    # The outer deadline includes DNS and ALL TCP/TLS attempts.
                    async with asyncio.timeout(CONNECT_TIMEOUT_SECONDS):
                        sock = socket.socket(family, kind, protocol)
                        sock.setblocking(False)
                        # Numeric sockaddr: no second hostname lookup / rebinding.
                        await loop.sock_connect(sock, address)
                        reader, writer = await asyncio.open_connection(
                            sock=sock, ssl=context, server_hostname=url.hostname, limit=8192,
                        )
                        sock = None  # stream now owns it
                except (OSError, TimeoutError) as error:
                    failure = error
                    if sock is not None:
                        sock.close()
                        sock = None
                    continue
                break
            else:
                raise failure or OSError("No usable push provider address")

            # Once a TLS connection is established, submit exactly one POST.
            # Write/drain/read errors (including ambiguous results) escape this
            # function; they must never cause an immediate POST to another IP.
            path = url.path + ("?" + url.query if url.query else "")
            request_headers = {"Host": url.hostname, "Connection": "close", "Content-Length": str(len(body)), **headers}
            wire = f"POST {path} HTTP/1.1\r\n" + "".join(f"{key}: {value}\r\n" for key, value in request_headers.items()) + "\r\n"
            writer.write(wire.encode("ascii") + body)
            await writer.drain()
            status = (await reader.readline()).decode("ascii").strip().split(" ", 2)
            if len(status) < 2 or status[0] not in ("HTTP/1.1", "HTTP/1.0") or not status[1].isdigit():
                raise ValueError("Invalid push response")
            # Read no body or Location; redirects are returned as terminal errors.
            return int(status[1])
    finally:
        if sock is not None:
            sock.close()
        if writer is not None:
            writer.close()
            try:
                async with asyncio.timeout(1):
                    await writer.wait_closed()
            except (TimeoutError, OSError):
                pass


class PushTransport:
    def __init__(self, settings):
        self.vapid = load_vapid(settings)
        self.subject = settings.push_vapid_subject

    async def __call__(self, subscription, payload, ttl):
        validate_endpoint(subscription.endpoint)
        host = urlsplit(subscription.endpoint).hostname
        headers = self.vapid.sign({"aud": f"https://{host}", "sub": self.subject, "exp": int(time.time()) + 3600})
        headers.update({"TTL": str(max(0, min(ttl, 3600))), "Content-Encoding": "aes128gcm", "Content-Type": "application/octet-stream", "Urgency": "normal"})
        return await post_pinned(subscription.endpoint, headers, encrypt_payload(subscription.p256dh, subscription.auth, payload))
