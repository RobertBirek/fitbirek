from dataclasses import dataclass


DEFAULT_PERSONA = (
    "Jesteś Mentorem FitBirek, wspierającym i rzeczowym trenerem dla osoby ćwiczącej "
    "rekreacyjnie. Odpowiadaj po polsku, prosto i zwięźle. Najpierw pomagaj określić "
    "najbliższy bezpieczny krok; gdy brakuje danych, zadaj jedno konkretne pytanie. "
    "Zachęcaj bez oceniania i bez presji. Nie diagnozuj ani nie zastępuj lekarza lub "
    "fizjoterapeuty; przy bólu, urazie lub niepokojących objawach zalecaj przerwanie "
    "ćwiczeń i konsultację ze specjalistą. Propozycje treningu lub serii przedstawiaj "
    "jasno, ale nigdy nie zakładaj ich wykonania ani nie zapisuj bez potwierdzenia użytkownika."
)


@dataclass(frozen=True)
class OpenAIModelProfile:
    key: str
    provider_model_id: str
    label: str
    quality_class: str
    cost_warning: str
    reasoning_effort: str | None
    max_input_tokens: int
    max_output_tokens: int
    enabled: bool


PROFILES = {
    "legacy-gpt-4.1-mini-2025-04-14": OpenAIModelProfile(
        "legacy-gpt-4.1-mini-2025-04-14",
        "gpt-4.1-mini-2025-04-14",
        "GPT-4.1 mini",
        "sprawdzony",
        "Profil legacy o niskim koszcie.",
        None,
        6000,
        800,
        True,
    ),
    "gpt-6-luna": OpenAIModelProfile(
        "gpt-6-luna",
        "gpt-6-luna",
        "GPT-6 Luna",
        "ekonomiczny",
        "Niski koszt; model do codziennych rozmów.",
        "none",
        6000,
        800,
        True,
    ),
    "gpt-6.1-sol": OpenAIModelProfile(
        "gpt-6.1-sol",
        "gpt-6.1-sol",
        "GPT-6.1 Sol",
        "zrównoważony",
        "Wyższy koszt niż Luna; używaj świadomie.",
        "low",
        6000,
        1600,
        True,
    ),
    "gpt-6-astra": OpenAIModelProfile(
        "gpt-6-astra",
        "gpt-6-astra",
        "GPT-6 Astra",
        "najwyższa jakość",
        "Najwyższy koszt; używaj tylko do złożonych pytań.",
        "low",
        6000,
        1600,
        True,
    ),
}


def public_profiles() -> list[dict[str, str]]:
    return [
        {
            "key": profile.key,
            "identifier": profile.provider_model_id,
            "label": profile.label,
            "quality_class": profile.quality_class,
            "cost_warning": profile.cost_warning,
        }
        for profile in PROFILES.values()
        if profile.enabled
    ]


def profile_for_key(key: str | None) -> OpenAIModelProfile | None:
    if not isinstance(key, str):
        return None
    profile = PROFILES.get(key)
    return profile if profile is not None and profile.enabled else None
