"""Mentor persona, model profile and context consents."""
from alembic import op
import sqlalchemy as sa

revision = "0010"
down_revision = "0009"
branch_labels = depends_on = None


DEFAULT_PERSONA = (
    "Jesteś Mentorem FitBirek, wspierającym i rzeczowym trenerem dla osoby ćwiczącej "
    "rekreacyjnie. Odpowiadaj po polsku, prosto i zwięźle. Najpierw pomagaj określić "
    "najbliższy bezpieczny krok; gdy brakuje danych, zadaj jedno konkretne pytanie. "
    "Zachęcaj bez oceniania i bez presji. Nie diagnozuj ani nie zastępuj lekarza lub "
    "fizjoterapeuty; przy bólu, urazie lub niepokojących objawach zalecaj przerwanie "
    "ćwiczeń i konsultację ze specjalistą. Propozycje treningu lub serii przedstawiaj "
    "jasno, ale nigdy nie zakładaj ich wykonania ani nie zapisuj bez potwierdzenia użytkownika."
)


_CONSENT_COLUMNS = (
    "consent_context_training",
    "consent_context_profile",
    "consent_context_weight",
    "consent_context_note",
    "consent_context_apple_health",
)


def upgrade():
    op.add_column(
        "mentor_usage",
        sa.Column("input_tokens", sa.Integer(), nullable=True, server_default=sa.text("0")),
    )
    op.add_column(
        "mentor_settings",
        sa.Column("persona", sa.Text(), nullable=True, server_default=DEFAULT_PERSONA),
    )
    op.add_column("mentor_settings", sa.Column("model_profile_key", sa.String(64), nullable=True))
    op.add_column(
        "mentor_settings",
        sa.Column("context_policy_version", sa.Integer(), nullable=True, server_default=sa.text("0")),
    )
    op.add_column(
        "mentor_settings",
        sa.Column("context_generation_digest", sa.String(64), nullable=True, server_default=""),
    )
    for column in _CONSENT_COLUMNS:
        op.add_column(
            "mentor_settings",
            sa.Column(column, sa.Boolean(), nullable=True, server_default=sa.false()),
        )

    op.execute(
        sa.text(
            "UPDATE mentor_settings SET "
            "persona = :persona, "
            "context_policy_version = 0, "
            "context_generation_digest = '', "
            "consent_context_training = false, "
            "consent_context_profile = false, "
            "consent_context_weight = false, "
            "consent_context_note = false, "
            "consent_context_apple_health = false, "
            "model_profile_key = CASE "
            "WHEN model IN ('gpt-4.1-mini', 'gpt-4.1-mini-2025-04-14') "
            "THEN 'legacy-gpt-4.1-mini-2025-04-14' "
            "ELSE NULL END"
        ).bindparams(persona=DEFAULT_PERSONA)
    )

    op.alter_column("mentor_settings", "persona", nullable=False)
    op.alter_column("mentor_settings", "context_policy_version", nullable=False)
    op.alter_column("mentor_settings", "context_generation_digest", nullable=False)
    for column in _CONSENT_COLUMNS:
        op.alter_column("mentor_settings", column, nullable=False)
    op.alter_column("mentor_usage", "input_tokens", nullable=False)


def downgrade():
    op.drop_column("mentor_usage", "input_tokens")
    for column in reversed(_CONSENT_COLUMNS):
        op.drop_column("mentor_settings", column)
    op.drop_column("mentor_settings", "context_generation_digest")
    op.drop_column("mentor_settings", "context_policy_version")
    op.drop_column("mentor_settings", "model_profile_key")
    op.drop_column("mentor_settings", "persona")
