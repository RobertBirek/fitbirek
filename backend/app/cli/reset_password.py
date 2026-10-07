import asyncio
import getpass
import sys
import warnings

from app.database import session_factory
from app.identity.service import AccountNotFoundError, reset_password, validate_and_normalize_email


async def change_password(email: str, password: str) -> None:
    async with session_factory() as database:
        await reset_password(database, email, password)


def prompt_password(prompt: str) -> str:
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", getpass.GetPassWarning)
            return getpass.getpass(prompt)
    except getpass.GetPassWarning as error:
        raise SystemExit("Secure password input is unavailable") from error


def main() -> None:
    if not sys.stdin.isatty() or not sys.stderr.isatty():
        raise SystemExit("An interactive terminal is required")

    try:
        email = validate_and_normalize_email(input("Email: "))
        password = prompt_password("New password: ")
        confirmation = prompt_password("Confirm new password: ")
    except EOFError as error:
        raise SystemExit("Input cancelled") from error
    except ValueError as error:
        raise SystemExit(str(error)) from error

    if not password.strip():
        raise SystemExit("Password must not be blank")
    if password != confirmation:
        raise SystemExit("Passwords do not match")

    try:
        asyncio.run(change_password(email, password))
    except AccountNotFoundError as error:
        raise SystemExit("Account does not exist") from error


if __name__ == "__main__":
    main()
