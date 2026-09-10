PYTHON := python3
VENV_PYTHON := .venv/bin/python

.PHONY: test-health

# Creates an ignored Python 3.12 virtual environment before running the focused test.
test-health:
	@$(PYTHON) -c 'import sys; version = sys.version_info[:2]; assert version == (3, 12), f"Python 3.12 is required; found {version[0]}.{version[1]}"'
	@if [ ! -x $(VENV_PYTHON) ]; then $(PYTHON) -m venv .venv; fi
	@$(VENV_PYTHON) -c 'import sys; version = sys.version_info[:2]; assert version == (3, 12), f"Python 3.12 is required; found {version[0]}.{version[1]}"'
	$(VENV_PYTHON) -m pip install --require-hashes -r requirements-dev.lock
	$(VENV_PYTHON) -m pytest tests/test_health.py -q
