import argparse
import asyncio
import getpass

from app.database import session_factory
from app.identity.service import (
    InitialAccountAlreadyExistsError,
    create_initial_account,
    validate_and_normalize_email,
)


async def create_account(email: str, password: str) -> None:
    async with session_factory() as database:
        await create_initial_account(database, email, password)


def main() -> None:
    parser = argparse.ArgumentParser(description="Create the one-time FitBirek account")
    parser.add_argument("--email", required=True)
    arguments = parser.parse_args()

    try:
        email = validate_and_normalize_email(arguments.email)
    except ValueError as error:
        parser.error(str(error))

    password = getpass.getpass("Password: ")
    password_confirmation = getpass.getpass("Confirm password: ")
    if not password.strip():
        parser.error("Password must not be blank")
    if password != password_confirmation:
        parser.error("Passwords do not match")

    try:
        asyncio.run(create_account(email, password))
    except InitialAccountAlreadyExistsError:
        parser.error("An initial account already exists")


if __name__ == "__main__":
    main()
