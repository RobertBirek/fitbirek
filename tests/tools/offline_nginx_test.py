"""Actual Nginx template, isolated container, no published ports or production I/O."""
from pathlib import Path
import subprocess
import tempfile
import time
import unittest
import uuid


class OfflineNginxTest(unittest.TestCase):
    def test_missing_static_404_and_spa_html(self):
        with tempfile.TemporaryDirectory(prefix="fit-nginx-fixture-") as temporary:
            root = Path(temporary)
            root.chmod(0o755)
            (root / "index.html").write_text("<!doctype html><title>Fixture SPA</title>")
            (root / "offline_client.js").write_text("// fixture")
            name = "fit-offline-nginx-test-" + uuid.uuid4().hex[:12]
            config = Path("deploy/docker/web-nginx.conf").resolve()
            subprocess.run(["docker", "run", "--pull=never", "--detach", "--name", name,
                            "--network", "none", "-v", f"{root}:/usr/share/nginx/html:ro",
                            "-v", f"{config}:/etc/nginx/conf.d/default.conf:ro",
                            "nginx:alpine"], check=True, capture_output=True)
            try:
                def get(path):
                    return subprocess.run(["docker", "exec", name, "wget", "-S", "-O", "-",
                                           "http://127.0.0.1/" + path], capture_output=True, text=True)
                for _ in range(50):
                    if get("healthz").returncode == 0:
                        break
                    time.sleep(0.1)
                else:
                    self.fail("Nginx fixture failed to start")
                for path in ["assets/missing.png", "assets/missing.webp", "fonts/missing.woff2",
                             "fonts/missing.ttf", "missing.js", "missing.wasm", "missing.css"]:
                    with self.subTest(path=path):
                        response = get(path)
                        self.assertIn("HTTP/1.1 404", response.stderr)
                        self.assertNotIn("Fixture SPA", response.stdout)
                for path in ["", "today", "workout/session", "settings/offline"]:
                    response = get(path)
                    self.assertIn("HTTP/1.1 200", response.stderr)
                    self.assertIn("Fixture SPA", response.stdout)
                    self.assertIn("Cache-Control: no-cache", response.stderr)
                self.assertIn("Cache-Control: no-cache", get("offline_client.js").stderr)
            finally:
                subprocess.run(["docker", "rm", "-f", name], check=True, capture_output=True)


if __name__ == "__main__":
    unittest.main()
