import struct
import pytest
from fastapi import HTTPException
from app.mentor.audio import validate_audio

def u32(n):
    return struct.pack('>I', n)

def box(kind, payload=b''):
    return u32(len(payload) + 8) + kind + payload

def full(kind, payload=b'', version=0, flags=0):
    return box(kind, bytes([version]) + flags.to_bytes(3, 'big') + payload)

def track(kind=b'soun', ticks=0, version=0):
    tkhd = full(b'tkhd', b'\0' * 8 + u32(1) + b'\0' * 68, version)
    mdhd = full(b'mdhd', b'\0' * 8 + u32(1000) + u32(ticks) + b'\0' * 4)
    stts = full(b'stts', u32(1 if ticks else 0) + (u32(1) + u32(ticks) if ticks else b''))
    return box(b'trak', tkhd + box(b'mdia', mdhd + full(b'hdlr', u32(0) + kind + b'\0' * 12) + box(b'minf', box(b'stbl', stts))))

def movie(ticks=0, extra=b'', trex=0, version=0):
    defaults = box(b'mvex', full(b'trex', u32(1) + u32(1) + u32(trex) + u32(0) * 2)) if trex else b''
    return box(b'moov', track(ticks=ticks, version=version) + extra + defaults)

def fragment(start=0, duration=1000, count=1, default=False, track_id=1):
    tfhd = full(b'tfhd', u32(track_id) + (u32(duration) if default else b''), flags=8 if default else 0)
    trun = full(b'trun', u32(count) + (b'' if default or duration is None else u32(duration) * count), flags=0 if default or duration is None else 0x100)
    return box(b'moof', box(b'traf', tfhd + full(b'tfdt', start.to_bytes(8, 'big'), version=1) + trun))

def invalid(data, mime='audio/mp4'):
    with pytest.raises(HTTPException) as error:
        validate_audio(data, mime)
    assert error.value.status_code == 422

def test_minimal_audio_and_fragment_defaults():
    assert validate_audio(movie(2500), 'audio/mp4') == 2.5
    assert validate_audio(movie() + fragment(default=True), 'audio/mp4') == 1
    assert validate_audio(movie(trex=1000) + fragment(duration=None), 'audio/mp4') == 1

@pytest.mark.parametrize('data', [
    box(b'moov', full(b'mvhd', b'\0' * 8 + u32(1000) + u32(2500))),
    movie(1000, extra=track(b'vide')),
    movie(1000, version=2),
    movie() + fragment(start=3600000),
    movie(20000) + fragment(start=20000, duration=20000),
    movie() + fragment(track_id=2),
    movie() + fragment(duration=0, count=100000, default=True) * 20,
    movie() + fragment() + b'\0\0\0\x07junk',
])
def test_mp4_adversarial(data):
    invalid(data)

def element(kind, payload):
    width = max(1, (len(payload).bit_length() + 7) // 7)
    return kind + ((1 << (7 * width)) | len(payload)).to_bytes(width, 'big') + payload

def cluster(timecode=0, relative=0, unknown=True):
    payload = element(b'\xe7', timecode.to_bytes(4, 'big')) + element(b'\xa3', b'\x81' + relative.to_bytes(2, 'big', signed=True) + b'\x80\xf8\x00')
    return b'\x1f\x43\xb6\x75\xff' + payload if unknown else element(b'\x1f\x43\xb6\x75', payload)

def webm(clusters, extra_track=b''):
    entry = element(b'\xae', element(b'\xd7', b'\x01') + element(b'\x83', b'\x02') + element(b'\x86', b'A_OPUS'))
    return element(b'\x1a\x45\xdf\xa3', b'') + b'\x18\x53\x80\x67\xff' + element(b'\x16\x54\xae\x6b', entry + extra_track) + clusters

def test_unknown_clusters_are_siblings():
    assert validate_audio(webm(cluster() + cluster(1000)), 'audio/webm') == pytest.approx(1.02)

@pytest.mark.parametrize('clusters', [cluster() + cluster(3600000), cluster(relative=-1), cluster(1000) + cluster(0), cluster() * 1501])
def test_webm_adversarial(clusters):
    invalid(webm(clusters), 'audio/webm')


def test_mp4_all_duration_sources_are_added():
    assert validate_audio(movie(1000) + fragment(start=1000), 'audio/mp4') == 2
    invalid(movie(20000) + fragment(start=20000, duration=20000))
    invalid(movie() + fragment(start=1000) + fragment(start=0))


@pytest.mark.parametrize('count', [10001, 100000, 0xFFFFFFFF])
def test_mp4_global_sample_budget(count):
    invalid(movie() + fragment(duration=1, count=count, default=True))


def test_mp4_many_small_runs_share_budget():
    invalid(movie() + b''.join(fragment(start=i * 1000, duration=1, count=1000, default=True) for i in range(11)))


@pytest.mark.parametrize('suffix', [b'x', u32(1) + b'junk', u32(100) + b'junk', u32(4) + b'junk'])
def test_mp4_malformed_unknown_box(suffix):
    invalid(movie(1000) + suffix)


def test_mp4_unknown_metadata_with_valid_size():
    assert validate_audio(movie(1000) + box(b'free', b'opaque'), 'audio/mp4') == 1


def test_mp4_truncated_and_invalid_fullboxes():
    for kind in (b'tkhd', b'mdhd', b'hdlr', b'stts', b'tfhd', b'tfdt', b'trun'):
        data = movie() + fragment()
        index = data.index(kind) + 4
        invalid(data[:index] + b'\x02' + data[index + 1:])
    data = movie() + fragment(default=True)
    # tfhd optional fields must fit within its own box, not the next box.
    index = data.index(b'tfhd') + 4
    invalid(data[:index + 3] + b'\x09' + data[index + 4:])


def test_webm_additional_tracks_and_nested_known_cluster():
    video = element(b'\xae', element(b'\xd7', b'\x02') + element(b'\x83', b'\x01'))
    invalid(webm(cluster(), video), 'audio/webm')
    invalid(webm(element(b'\x1f\x43\xb6\x75', cluster())), 'audio/webm')


def test_webm_late_tracks_cannot_hide_in_unknown_cluster():
    invalid(webm(cluster() + element(b'\x16\x54\xae\x6b', b'')), 'audio/webm')


def test_webm_work_budget_and_malformed_unknown_element():
    invalid(webm(cluster() + b'\xec\xff'), 'audio/webm')
    invalid(webm(cluster() + b'\xec\x80' * 21000), 'audio/webm')


def test_webm_exact_limit_includes_packet_duration():
    assert validate_audio(webm(cluster(29980)), 'audio/webm') == 30
    invalid(webm(cluster(29981)), 'audio/webm')


def test_mp4_exact_limit_and_tfdt_v0():
    tfhd = full(b'tfhd', u32(1) + u32(1000), flags=8)
    run = full(b'trun', u32(1))
    data = movie() + box(b'moof', box(b'traf', tfhd + full(b'tfdt', u32(29000)) + run))
    assert validate_audio(data, 'audio/mp4') == 30


def test_mp4_edit_list_cannot_extend_presentation():
    mvhd = full(b'mvhd', b'\0' * 8 + u32(1000) + u32(1000) + b'\0' * 80)
    edit = box(b'edts', full(b'elst', u32(1) + u32(3600000) + u32(0) + b'\0\x01\0\0'))
    audio_track = track(ticks=1000)
    invalid(box(b'moov', mvhd + box(b'trak', audio_track[8:] + edit)))
