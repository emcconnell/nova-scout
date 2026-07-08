"""Shared palettes + dual-state bake helper for NOVA SCOUT texture recipes.

Every asset recipe is a function `build(state) -> Canvas` where state is
"survey" | "dead" (| "wet" for creatures). Geometry/height must be identical
across states — only paint colors change (art bible: one geometry, two lights).
bake_dual() writes:  <name>_survey.png  <name>_dead.png  <name>_normal.png
(+ <name>_wet.png, <name>_spec.png when present).
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image

import texlib
from texlib import Canvas

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), "../.."))
TEX_ROOT = os.path.join(REPO, "assets/textures")


def hx(code: str):
    code = code.lstrip("#")
    return tuple(int(code[i : i + 2], 16) for i in (0, 2, 4))


# ─── master palettes (VisualState / art bible v3 hex values) ────────────────
PAL = {
    "survey": {
        "white": hx("F4F7FA"), "gray": hx("9AA3AE"), "gold": hx("E3B341"),
        "panel": hx("1B3B73"), "accent": hx("00D5FF"),
        "hull_dark": hx("2E333B"), "hull_mid": hx("AEB7C2"),
        "hull_deep": hx("232830"), "spar": hx("7E8894"),
        "backing": hx("0A0D12"), "cell_hi": hx("1B3B73"), "cell_lo": hx("0C1F42"),
        "kapton_hi": hx("E8BB4A"), "kapton_lo": hx("6E5210"),
        "radiator": (237, 245, 250), "chevron": hx("C9921E"),
        "chevron_dark": hx("14161C"),
        "canopy_hi": hx("EAF2FA"), "canopy_mid": hx("9FB4C8"),
        "canopy_lo": hx("22303E"),
        "alien_hi": hx("3E2F50"), "alien_mid": hx("171122"),
        "alien_lo": hx("05040A"),
        "rock_hi": (214, 208, 194), "rock_mid": (142, 135, 123),
        "rock_lo": (61, 56, 50),
    },
    "dead": {
        "white": hx("101216"), "gray": hx("4E565F"), "gold": hx("7A0E12"),
        "panel": hx("101216"), "accent": hx("FF2A1D"),
        "hull_dark": hx("0A0C10"), "hull_mid": hx("343A42"),
        "hull_deep": hx("0A0C10"), "spar": hx("343A42"),
        "backing": hx("07090C"), "cell_hi": hx("0E141C"), "cell_lo": hx("070B10"),
        "kapton_hi": hx("4A360C"), "kapton_lo": hx("1A1204"),
        "radiator": (97, 107, 120), "chevron": hx("4A3A14"),
        "chevron_dark": hx("0C0E12"),
        "canopy_hi": hx("22262C"), "canopy_mid": hx("343A42"),
        "canopy_lo": hx("0A0C10"),
        "alien_hi": hx("161014"), "alien_mid": hx("070406"),
        "alien_lo": hx("010101"),
        "rock_hi": (58, 28, 20), "rock_mid": (24, 12, 9),
        "rock_lo": (6, 3, 2),
    },
    "wet": {   # beam-lit chitin ramp (creatures only; other keys fall back)
        "alien_hi": hx("8A7458"), "alien_mid": hx("4A3A28"),
        "alien_lo": hx("140E08"),
    },
}


def pal(state: str, key: str):
    p = PAL.get(state, {})
    if key in p:
        return p[key]
    return PAL["survey" if state == "wet" else "survey"][key]


def bake_dual(build, family: str, name: str, states=("survey", "dead"),
              normal_strength: float = 1.0, ao_strength: float = 0.55):
    """Bake one asset in multiple palette states sharing one normal map."""
    out = os.path.join(TEX_ROOT, family)
    os.makedirs(out, exist_ok=True)
    first: Canvas | None = None
    for state in states:
        cv: Canvas = build(state)
        albedo = cv.albedo.copy()
        occ = cv.ao(strength=ao_strength)
        albedo *= (1.0 - occ * 0.65)[..., None]
        rgba = np.concatenate([albedo, cv.alpha[..., None]], axis=-1)
        img = Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")
        img = img.resize((cv.w // texlib.SS, cv.h // texlib.SS), Image.LANCZOS)
        img.save(f"{out}/{name}_{state}.png")
        if first is None:
            first = cv
    # one shared normal map (geometry identical across states)
    n = first.normal_map(normal_strength)
    a3 = first.alpha[..., None]
    n = n * a3 + np.asarray([0.5, 0.5, 1.0], np.float32) * (1 - a3)
    nimg = Image.fromarray((np.clip(n, 0, 1) * 255).astype(np.uint8), "RGB")
    nimg = nimg.resize((first.w // texlib.SS, first.h // texlib.SS), Image.LANCZOS)
    nimg.save(f"{out}/{name}_normal.png")
    if first.spec.max() > 0.001:
        simg = Image.fromarray(
            (np.clip(first.spec * first.alpha, 0, 1) * 255).astype(np.uint8), "L")
        simg = simg.resize((first.w // texlib.SS, first.h // texlib.SS), Image.LANCZOS)
        simg.save(f"{out}/{name}_spec.png")
    print(f"baked {family}/{name}: {', '.join(states)} + normal "
          f"({first.w // texlib.SS}x{first.h // texlib.SS})")
