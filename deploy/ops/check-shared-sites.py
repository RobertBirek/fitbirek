"""Read-only baseline/comparison of every host in the shared Caddyfile."""
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import re
import subprocess
import sys

hosts = sorted(set(re.findall(r"(?m)^([a-z0-9][a-z0-9.-]+\.[a-z]+)(?=[, {])", Path("/docker/caddy/Caddyfile").read_text())))
# Also capture the second hostname on a single-line site declaration.
hosts += ["www.predikta.pl"] if "www.predikta.pl" not in hosts else []
hosts = sorted(set(hosts) - {"fit.birek.online"})


def probe(host):
    result = subprocess.run(["curl", "-sS", "--max-time", "20", "-o", "/dev/null", "-w", "%{http_code}", f"https://{host}/"], capture_output=True, text=True)
    return host, {"http": result.stdout, "curl_exit": result.returncode}


with ThreadPoolExecutor(max_workers=8) as executor:
    results = dict(executor.map(probe, hosts))
baseline = Path("/docker/fit/shared-sites-before.json")
if sys.argv[1] == "before":
    baseline.write_text(json.dumps(results, indent=2) + "\n")
    baseline.chmod(0o600)
else:
    before = json.loads(baseline.read_text())
    if before != results:
        print(json.dumps({host: {"before": before.get(host), "after": value} for host, value in results.items() if before.get(host) != value}, indent=2))
        raise SystemExit("Shared-site responses changed")
print(json.dumps(results, indent=2))
print("Shared-site check completed")
