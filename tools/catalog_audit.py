"""Print raw anatomical fields for offline, human-reviewed catalog curation."""
import json
import hashlib
import sys
from pathlib import Path

if __name__ == "__main__":
    data = json.loads((Path(__file__).resolve().parents[1] / "assets/data/exercises.json").read_text())
    print('Legacy SHA256:', hashlib.sha256(json.dumps(data[:316], ensure_ascii=False, sort_keys=True).encode()).hexdigest())
    if '--digest' in sys.argv:
        sys.exit(0)
    for e in data:
        print(f'{e["id"]} {e["nazwaEn"]} | {e["partiaGlowna"]} | {", ".join(e["partieWspierajace"])} | {e["seriexPowtorzenia"]}')
