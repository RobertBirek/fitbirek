"""Run packaged migrations without putting a database credential in argv."""
import os
import re

from alembic import command
from alembic.config import Config
from sqlalchemy.engine import make_url

from app.config import settings

url = make_url(settings.database_url)
restore_database = os.environ.get("RESTORE_DATABASE")
if restore_database:
    if not re.fullmatch(r"fit_[a-z0-9_]+_(restore|test)|fit_restore", restore_database):
        raise SystemExit("Unsafe restore database name")
    url = url.set(database=restore_database)
config = Config("alembic.ini")
config.set_main_option("sqlalchemy.url", url.render_as_string(hide_password=False).replace("%", "%%"))
command.upgrade(config, "head")
