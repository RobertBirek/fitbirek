"""Bounded timing validation, not a codec decoder, for browser audio containers.

Only a single audio track is supported. Unknown opaque metadata is skipped by
its validated length; unsupported timing constructs fail closed.
"""
from fastapi import HTTPException

_MAX_BYTES = 2 * 1024 * 1024
_MAX_WORK = 20000
_MAX_SAMPLES = 10000


def _invalid() -> HTTPException:
    return HTTPException(422, "Invalid audio")


def _mp4_duration(data: bytes) -> float:
    work = samples = 0

    def boxes(start, end):
        nonlocal work
        result = []
        while start < end:
            work += 1
            if work > _MAX_WORK or end - start < 8:
                raise _invalid()
            size = int.from_bytes(data[start:start + 4], 'big')
            kind = data[start + 4:start + 8]
            header = 8
            if size == 1:
                if end - start < 16:
                    raise _invalid()
                size = int.from_bytes(data[start + 8:start + 16], 'big')
                header = 16
            elif size == 0:
                size = end - start
            if size < header or start + size > end:
                raise _invalid()
            result.append((kind, start + header, start + size))
            start += size
        return result

    def one(items, kind):
        found = [(a, b) for k, a, b in items if k == kind]
        if len(found) != 1:
            raise _invalid()
        return found[0]

    def uint(pos, end, width=4):
        if pos + width > end:
            raise _invalid()
        return int.from_bytes(data[pos:pos + width], 'big')

    def full(a, b, versions=(0,)):
        if b - a < 4 or data[a] not in versions:
            raise _invalid()
        return uint(a + 1, b, 3)

    def sample_count(count):
        nonlocal samples
        samples += count
        if samples > _MAX_SAMPLES:
            raise _invalid()

    roots = boxes(0, len(data))
    moov = boxes(*one(roots, b'moov'))
    trak = boxes(*one(moov, b'trak'))
    a, b = one(trak, b'tkhd')
    full(a, b, (0, 1))
    if b - a != (84 if data[a] == 0 else 96):
        raise _invalid()
    track_id = uint(a + (12 if data[a] == 0 else 20), b)
    if not track_id:
        raise _invalid()
    mdia = boxes(*one(trak, b'mdia'))
    a, b = one(mdia, b'hdlr')
    full(a, b)
    if b - a < 24 or data[a + 8:a + 12] != b'soun':
        raise _invalid()
    a, b = one(mdia, b'mdhd')
    full(a, b, (0, 1))
    if b - a != (24 if data[a] == 0 else 36):
        raise _invalid()
    scale = uint(a + (12 if data[a] == 0 else 20), b)
    if not scale:
        raise _invalid()
    limit = 30 * scale
    movie_scale = None
    movie_headers = [(a, b) for k, a, b in moov if k == b'mvhd']
    if len(movie_headers) > 1:
        raise _invalid()
    if movie_headers:
        a, b = movie_headers[0]
        full(a, b, (0, 1))
        if b - a != (100 if data[a] == 0 else 112):
            raise _invalid()
        movie_scale = uint(a + (12 if data[a] == 0 else 20), b)
        if not movie_scale:
            raise _invalid()
    presentation = 0.0
    stbl = boxes(*one(boxes(*one(mdia, b'minf')), b'stbl'))
    # Composition offsets/edit lists could add unaccounted presentation time.
    if any(k in {b'ctts'} for k, _, _ in stbl):
        raise _invalid()
    # Browser edit lists are permitted only when they cannot extend the clip.
    for k, a, b in trak:
        if k == b'edts':
            for ek, x, y in boxes(a, b):
                if ek != b'elst':
                    raise _invalid()
                full(x, y, (0, 1))
                width = 20 if data[x] else 12
                count = uint(x + 4, y)
                if count != 1 or y - x != 8 + width:
                    raise _invalid()
                p = x + 8
                time_width = 8 if data[x] else 4
                if movie_scale is None:
                    raise _invalid()
                presentation = max(presentation, uint(p, y, time_width) / movie_scale)
                if presentation > 30:
                    raise _invalid()
                media_time = int.from_bytes(data[p + time_width:p + 2 * time_width], 'big', signed=True)
                if media_time < 0 or data[y - 4:y] != b'\x00\x01\x00\x00':
                    raise _invalid()
    a, b = one(stbl, b'stts')
    if full(a, b) != 0:
        raise _invalid()
    entries = uint(a + 4, b)
    if entries > _MAX_WORK or b - a != 8 + entries * 8:
        raise _invalid()
    total = 0
    for p in range(a + 8, b, 8):
        count, delta = uint(p, b), uint(p + 4, b)
        sample_count(count)
        if not count or not delta:
            raise _invalid()
        total += count * delta
    if total > limit:
        raise _invalid()
    default = None
    mvex = [(a, b) for k, a, b in moov if k == b'mvex']
    if len(mvex) > 1:
        raise _invalid()
    if mvex:
        a, b = one(boxes(*mvex[0]), b'trex')
        if full(a, b) or b - a != 24 or uint(a + 4, b) != track_id:
            raise _invalid()
        default = uint(a + 12, b)
    end_time = total
    max_end = total
    for k, a, b in roots:
        if k != b'moof':
            continue
        trafs = [(x, y) for kind, x, y in boxes(a, b) if kind == b'traf']
        if not trafs:
            raise _invalid()
        for x, y in trafs:
            items = boxes(x, y)
            a, b = one(items, b'tfhd')
            flags = full(a, b)
            if flags & ~0x03003B or uint(a + 4, b) != track_id:
                raise _invalid()
            p = a + 8
            duration = default
            for flag, width in ((1, 8), (2, 4), (8, 4), (16, 4), (32, 4)):
                if flags & flag:
                    value = uint(p, b, width)
                    if flag == 8:
                        duration = value
                    p += width
            if p != b or flags & 0x010000:
                raise _invalid()
            times = [(a, b) for k, a, b in items if k == b'tfdt']
            if len(times) > 1:
                raise _invalid()
            if times:
                a, b = times[0]
                if full(a, b, (0, 1)) or b - a != (12 if data[a] else 8):
                    raise _invalid()
                start = uint(a + 4, b, 8 if data[a] else 4)
                if start < end_time:
                    raise _invalid()
                end_time = start
            if end_time > limit:
                raise _invalid()
            runs = [(a, b) for k, a, b in items if k == b'trun']
            if not runs:
                raise _invalid()
            for a, b in runs:
                flags = full(a, b, (0, 1))
                if flags & ~0xF05:
                    raise _invalid()
                count = uint(a + 4, b)
                sample_count(count)
                p = a + 8 + (4 if flags & 1 else 0) + (4 if flags & 4 else 0)
                stride = 4 * sum(bool(flags & f) for f in (0x100, 0x200, 0x400, 0x800))
                if p + count * stride != b:
                    raise _invalid()
                for _ in range(count):
                    delta = uint(p, b) if flags & 0x100 else duration
                    if delta is None or delta <= 0:
                        raise _invalid()
                    if flags & 0x800 and uint(p + stride - 4, b) != 0:
                        raise _invalid()
                    total += delta
                    end_time += delta
                    if total > limit or end_time > limit:
                        raise _invalid()
                    p += stride
            max_end = max(max_end, end_time)
    if not total:
        raise _invalid()
    return max(total / scale, max_end / scale, presentation)


def _ebml_vint(data: bytes, offset: int, *, identifier=False):
    if offset >= len(data):
        raise _invalid()
    first, length = data[offset], 1
    while length <= 8 and not first & (1 << (8 - length)):
        length += 1
    if length > (4 if identifier else 8) or offset + length > len(data):
        raise _invalid()
    raw = int.from_bytes(data[offset:offset + length], 'big')
    value = raw if identifier else raw & ((1 << (7 * length)) - 1)
    return value, length, not identifier and value == (1 << (7 * length)) - 1


def _webm_duration(data: bytes) -> float:
    work = 0
    segment_ids = {0x114D9B74, 0x1549A966, 0x1654AE6B, 0x1F43B675, 0x1C53BB6B, 0x1941A469, 0x1043A770, 0x1254C367}

    def header(pos, end):
        nonlocal work
        work += 1
        if work > _MAX_WORK:
            raise _invalid()
        kind, n, _ = _ebml_vint(data, pos, identifier=True)
        size, m, unknown = _ebml_vint(data, pos + n)
        a = pos + n + m
        if a > end or (not unknown and a + size > end):
            raise _invalid()
        return kind, a, end if unknown else a + size, unknown

    def elements(start, end, level='metadata'):
        while start < end:
            kind, a, b, unknown = header(start, end)
            if unknown:
                if kind == 0x18538067 and level == 'root':
                    pass
                elif kind == 0x1F43B675 and level == 'segment':
                    # Find the next level-1 sibling by walking *element* lengths,
                    # never scanning packet bytes or recursively nesting clusters.
                    p = a
                    while p < end:
                        child, x, y, live = header(p, end)
                        if child in segment_ids:
                            break
                        if live:
                            raise _invalid()
                        p = y
                    b = p
                else:
                    raise _invalid()
            yield kind, a, b
            start = b

    def integer(a, b):
        if not 1 <= b - a <= 8:
            raise _invalid()
        return int.from_bytes(data[a:b], 'big')

    def opus(packet):
        if not packet:
            raise _invalid()
        config, code = packet[0] >> 3, packet[0] & 3
        ms = ([10, 20, 40, 60][config % 4] if config < 12 else [10, 20][config % 2] if config < 16 else [2.5, 5, 10, 20][config % 4])
        frames = 1 if code == 0 else 2 if code in (1, 2) else packet[1] & 63 if len(packet) >= 2 else 0
        if not 1 <= frames <= 48 or frames * ms > 120:
            raise _invalid()
        return int(frames * ms * 1_000_000)

    if not data.startswith(b'\x1a\x45\xdf\xa3'):
        raise _invalid()
    roots = list(elements(0, len(data), 'root'))
    segments = [(a, b) for k, a, b in roots if k == 0x18538067]
    if len(segments) != 1:
        raise _invalid()
    scale, track = 1_000_000, None
    frame_sum = timeline = 0
    last_start = -1
    seen_info = seen_tracks = False
    for kind, a, b in elements(*segments[0], 'segment'):
        if kind == 0x1549A966:
            if seen_info or frame_sum:
                raise _invalid()
            seen_info = True
            scales = [(x, y) for k, x, y in elements(a, b) if k == 0x2AD7B1]
            if len(scales) > 1:
                raise _invalid()
            if scales:
                scale = integer(*scales[0])
            if not scale:
                raise _invalid()
        elif kind == 0x1654AE6B:
            if seen_tracks:
                raise _invalid()
            seen_tracks = True
            entries = [(x, y) for k, x, y in elements(a, b) if k == 0xAE]
            if len(entries) != 1:
                raise _invalid()
            fields = {}
            for k, x, y in elements(*entries[0]):
                if k in (0xD7, 0x83, 0x86):
                    if k in fields:
                        raise _invalid()
                    fields[k] = data[x:y] if k == 0x86 else integer(x, y)
            track = fields.get(0xD7)
            if not track or fields.get(0x83) != 2 or fields.get(0x86) != b'A_OPUS':
                raise _invalid()
        elif kind == 0x1F43B675:
            if track is None:
                raise _invalid()
            timecode = None
            for k, x, y in elements(a, b):
                if k == 0xE7:
                    if timecode is not None:
                        raise _invalid()
                    timecode = integer(x, y)
                elif k == 0xA3:
                    number, n, unknown = _ebml_vint(data, x)
                    if timecode is None or unknown or number != track or x + n + 3 >= y:
                        raise _invalid()
                    relative = int.from_bytes(data[x + n:x + n + 2], 'big', signed=True)
                    if data[x + n + 2] & 6:
                        raise _invalid()
                    duration = opus(data[x + n + 3:y])
                    start = (timecode + relative) * scale
                    if start < 0 or start < last_start:
                        raise _invalid()
                    last_start = start
                    frame_sum += duration
                    timeline = max(timeline, start + duration)
                    if max(frame_sum, timeline) > 30_000_000_000:
                        raise _invalid()
                elif k not in (0xA7, 0xAB, 0xEC, 0xBF):
                    # Includes unsupported BlockGroup, nested known Cluster,
                    # and any element that might hide unaccounted blocks.
                    raise _invalid()
    if not frame_sum or not timeline:
        raise _invalid()
    return max(frame_sum, timeline) / 1_000_000_000


def validate_audio(audio: bytes, content_type: str) -> float:
    if not isinstance(audio, bytes) or not audio or len(audio) > _MAX_BYTES:
        raise _invalid()
    if content_type == 'audio/mp4':
        duration = _mp4_duration(audio)
    elif content_type == 'audio/webm':
        duration = _webm_duration(audio)
    else:
        raise _invalid()
    if not 0 < duration <= 30:
        raise _invalid()
    return duration
