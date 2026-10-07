---
name: fit-ops-workflow
description: Uzywaj przy zmianach deploy, Compose, Caddy, FastAPI production, migracji lub backupow FitBirek.
---

# Operacje FitBirek

Przed zmiana przeczytaj `DEPLOY.md` i `AGENTS.md`. Edytuj szablony w `deploy/`, nie sekrety ani rozwinieta konfiguracje runtime. Do walidacji Compose uzyj `docker compose -f /docker/fit/compose.yaml config --quiet`; nie wyswietlaj rozwinietej konfiguracji. Nie instaluj hostowego Nginx ani Certbot i nie publikuj portow uslug Fit.
