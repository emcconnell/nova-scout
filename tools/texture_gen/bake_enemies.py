"""Alien fleet body bakes — shared biomech chitin vocabulary (art bible v4.0).

Every creature bakes survey/dead/wet albedos + one normal map. Geometry
matches each enemy's _draw() silhouette so collision shapes and FX anchors
(eyes, veins, halos — still procedural overlays) stay aligned.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
from texlib import Canvas, _gauss_blur
from bake_common import bake_dual, pal

STATES = ("survey", "dead", "wet")


# ─── shared chitin toolkit ──────────────────────────────────────────────────
def chitin_base(cv: Canvas, mask: np.ndarray, state: str, seed: int,
                dome: float = 1.6, bump: float = 0.22):
    """Pillow-dome height + fBm chitin bumps + hi->lo vertical ramp."""
    X, Y = cv.grid()
    hi, mid, lo = pal(state, "alien_hi"), pal(state, "alien_mid"), pal(state, "alien_lo")
    if state == "wet":
        # wet chitin: dark base, warm highlights ride the relief only
        cv.paint(mask, pal("wet", "alien_lo"), spec=0.9, rough=0.1)
        mid = pal("wet", "alien_mid")
    else:
        # v3 parity: the hi violet is the dominant top-surface tone, not a
        # whisper — otherwise chitin vanishes into the void at game scale
        base = tuple(int(m + (h - m) * 0.45) for m, h in zip(mid, hi))
        cv.paint(mask, base, spec=0.25, rough=0.6)
    # dome: blurred silhouette reads as soft body volume
    cv.height += _gauss_blur(mask, cv.upx(1.6)) * dome
    # top-lit ramp baked into albedo (lights add the directional read)
    ny = (Y - Y.min()) / max(Y.max() - Y.min(), 1e-5)
    cv.tint(mask * np.clip((0.62 - ny) * 2.2, 0, 1), hi, 0.9)
    cv.tint(mask * np.clip(ny - 0.55, 0, 1), lo, 0.85)
    # organic bumps
    bumps = cv.fbm(seed, octaves=5, base=10)
    cv.height += mask * (bumps - 0.5) * bump * 2.0
    cv.tint(mask * (bumps > 0.68), hi, 0.30)
    cv.tint(mask * (bumps < 0.30), lo, 0.35)
    # sparse pale flecks (the seeded fleck field, now baked)
    fl = cv.fbm(seed + 31, octaves=6, base=26)
    cv.tint(mask * (fl > 0.78), (255, 230, 200), 0.10)


def ridge(cv: Canvas, mask: np.ndarray, pts, width: float = 0.5,
          depth: float = 0.45, state: str = "survey"):
    """Plate ridge groove along a polyline, echo highlight above it."""
    for i in range(len(pts) - 1):
        m = cv.line_mask(pts[i], pts[i + 1], width, feather=width * 0.4) * mask
        cv.add_height(m, -depth)
        cv.tint(m, (0, 0, 0), 0.45)
        ea = (pts[i][0], pts[i][1] - width * 1.6)
        eb = (pts[i + 1][0], pts[i + 1][1] - width * 1.6)
        me = cv.line_mask(ea, eb, width * 0.6, feather=width * 0.3) * mask
        cv.add_height(me, 0.18)
        cv.tint(me, pal(state, "alien_hi"), 0.35)


# ─── creatures ──────────────────────────────────────────────────────────────
def scout(state):
    cv = Canvas(26, 20)
    body = cv.poly_mask([(-10, 0), (-7, -3), (7, -3), (10, 0), (9, 3), (-9, 3)],
                        feather=0.12)
    chitin_base(cv, body, state, seed=11, dome=1.2)
    for dx in (-8.0, 0.0, 9.0):
        rr = (26 - abs(dx) * 1.7) * 0.35
        ridge(cv, body, [(dx * 0.35 - rr * 0.7, 0.8), (dx * 0.35, -0.6),
                         (dx * 0.35 + rr * 0.7, 0.8)], 0.35, 0.35, state)
    dome = cv.ellipse_mask((0, -4), 5.0, 5.0, feather=0.1)
    dm = dome * (cv.grid()[1] <= -1.2)
    cv.paint(dm, pal(state, "alien_hi"), spec=0.8, rough=0.15)
    X, Y = cv.grid()
    r2 = np.clip((X / 5.0) ** 2 + ((Y + 4) / 5.0) ** 2, 0, 1)
    cv.height += dm * np.sqrt(np.clip(1 - r2, 0, 1)) * 1.6
    cv.tint(dm * np.clip(1 - r2 * 1.5, 0, 1), (255, 255, 255), 0.10)
    return cv


def warrior(state):
    cv = Canvas(36, 98)
    sil = [(0, -46), (6, -40), (11, -30), (14, -18), (15, -4), (13, 10),
           (9, 24), (4, 36), (0, 46), (-4, 36), (-9, 24), (-13, 10),
           (-15, -4), (-14, -18), (-11, -30), (-6, -40)]
    body = cv.poly_mask(sil, feather=0.15)
    chitin_base(cv, body, state, seed=23, dome=2.2, bump=0.3)
    for i in range(-2, 3):
        yy = i * 13.0
        ridge(cv, body, [(-15, yy), (0, yy + 6), (15, yy)], 0.55, 0.5, state)
    spine = cv.line_mask((0, -44), (0, 44), 0.5, feather=0.2) * body
    cv.add_height(spine, -0.5)
    cv.tint(spine, (0, 0, 0), 0.5)
    for i in range(6):   # thorn barbs
        yy = -40.0 + i * 7.0
        barb = cv.line_mask((0, yy), (4, yy - 4), 0.4) * body
        cv.add_height(barb, 0.5)
        cv.tint(barb, pal(state, "alien_hi"), 0.5)
    return cv


def destroyer(state):
    cv = Canvas(40, 42)
    head = cv.poly_mask([(-8, -18), (8, -18), (12, -8), (-12, -8)], feather=0.1)
    thorax = cv.poly_mask([(-12, -8), (12, -8), (16, 2), (14, 8), (-14, 8),
                           (-16, 2)], feather=0.1)
    abdomen = cv.poly_mask([(-14, 8), (14, 8), (10, 16), (-10, 16)], feather=0.1)
    body = np.clip(head + thorax + abdomen, 0, 1)
    chitin_base(cv, body, state, seed=37, dome=2.0, bump=0.28)
    # carapace plate seams between segments
    ridge(cv, body, [(-11, -8), (11, -8)], 0.7, 0.6, state)
    ridge(cv, body, [(-15, 2), (15, 2)], 0.55, 0.5, state)
    ridge(cv, body, [(-13, 8), (13, 8)], 0.55, 0.5, state)
    for sx in (-6.0, 6.0):   # dorsal furrows
        f = cv.line_mask((sx, -16), (sx, 14), 0.3, feather=0.15) * body
        cv.add_height(f, -0.3)
        cv.tint(f, (0, 0, 0), 0.35)
    # weapon ports (dark bowls at thorax tips)
    for tx, ty in [(-13, 2), (13, 2), (0, -14)]:
        p = cv.ellipse_mask((tx, ty), 2.3, 2.3, feather=0.15)
        cv.add_height(p * body, -0.8)
        cv.tint(p * body, (5, 3, 6), 0.8)
    return cv


def elite_artillery(state):
    cv = Canvas(42, 36)
    body = cv.poly_mask([(-18, -8), (18, -8), (16, 10), (-16, 10)], feather=0.12)
    chitin_base(cv, body, state, seed=51, dome=1.8, bump=0.26)
    ridge(cv, body, [(-16, 0), (0, -3), (16, 0)], 0.5, 0.5, state)
    # twin mortar barrels protruding at the bottom
    for bx in (-9.0, 9.0):
        bar = cv.rect_mask(bx - 1.6, 8, 3.2, 7.5, feather=0.1)
        cv.paint(bar, pal(state, "alien_mid"), spec=0.4)
        X, _ = cv.grid()
        prof = np.sqrt(np.clip(1 - ((X - bx) / 1.8) ** 2, 0, 1))
        cv.height += bar * prof * 1.2
        muz = cv.ellipse_mask((bx, 15.2), 1.2, 1.0, feather=0.08)
        cv.add_height(muz, -0.7)
        cv.tint(muz, (5, 3, 6), 0.85)
    return cv


def elite_interceptor(state):
    cv = Canvas(40, 32)
    dart = cv.poly_mask([(0, -14), (10, 6), (0, 2), (-10, 6)], feather=0.1)
    wl = cv.poly_mask([(-10, 6), (-18, 10), (-12, 12), (-8, 8)], feather=0.08)
    wr = cv.poly_mask([(10, 6), (18, 10), (12, 12), (8, 8)], feather=0.08)
    body = np.clip(dart + wl + wr, 0, 1)
    chitin_base(cv, body, state, seed=53, dome=1.5, bump=0.22)
    ridge(cv, body, [(-8, 2), (0, -4), (8, 2)], 0.4, 0.45, state)
    spine = cv.line_mask((0, -13), (0, 2), 0.35, feather=0.15) * body
    cv.add_height(spine, 0.5)
    cv.tint(spine, pal(state, "alien_hi"), 0.4)
    return cv


def elite_swarm(state):
    cv = Canvas(34, 26)
    body = cv.poly_mask([(-12, -10), (12, -10), (14, 8), (-14, 8)], feather=0.12)
    chitin_base(cv, body, state, seed=57, dome=1.7, bump=0.26)
    ridge(cv, body, [(-13, -1), (0, 2), (13, -1)], 0.5, 0.5, state)
    # hatch bays (recessed brood doors)
    for bx in (-7.0, 7.0):
        bay = cv.rect_mask(bx - 3.0, 1.5, 6.0, 5.0, feather=0.15)
        cv.add_height(bay * body, -0.9)
        cv.tint(bay * body, (4, 2, 5), 0.75)
        rim = cv.rect_mask(bx - 3.3, 1.2, 6.6, 5.6, feather=0.06) * \
            (1 - cv.rect_mask(bx - 2.8, 1.7, 5.6, 4.6))
        cv.add_height(rim * body, 0.3)
    return cv


def silence(state):
    cv = Canvas(28, 26)
    sil = [(0, -11), (7, -3), (12, 2), (5, 4), (8, 10), (0, 6), (-9, 11),
           (-5, 3), (-12, 1), (-6, -4)]
    body = cv.poly_mask(sil, feather=0.08)
    chitin_base(cv, body, state, seed=61, dome=1.2, bump=0.4)
    # razor facets: hard radial creases from the center
    for px, py in sil[::2]:
        ridge(cv, body, [(0, -2), (px, py)], 0.3, 0.5, state)
    return cv


def drone(state):
    cv = Canvas(16, 16)
    X, Y = cv.grid()
    body = cv.ellipse_mask((0, 0), 6.0, 6.0, feather=0.08)
    cv.paint(body, pal(state, "alien_mid"), spec=0.8, rough=0.15)
    r2 = np.clip((X / 6.0) ** 2 + (Y / 6.0) ** 2, 0, 1)
    cv.height += body * np.sqrt(np.clip(1 - r2, 0, 1)) * 2.0
    cv.tint(body * np.clip(1 - r2 * 1.6, 0, 1), pal(state, "alien_hi"), 0.6)
    cv.tint(body * np.clip(r2 - 0.5, 0, 1), pal(state, "alien_lo"), 0.7)
    seg = cv.fbm(71, octaves=4, base=8)
    cv.height += body * (seg - 0.5) * 0.2
    return cv


def leviathan(state):
    cv = Canvas(26, 20)
    X, Y = cv.grid()
    # organic blob hide (r=10 x 0.7 aspect) — body pulses via sprite scale
    r = np.sqrt((X / 10.0) ** 2 + (Y / 7.0) ** 2)
    ang = np.arctan2(Y / 7.0, X / 10.0)
    wob = 1.0 + 0.12 * np.sin(ang * 5.0 + 1.3) + 0.07 * np.sin(ang * 9.0)
    body = np.clip((wob - r) * 14.0, 0, 1)
    chitin_base(cv, body, state, seed=77, dome=1.8, bump=0.5)
    membrane = np.clip((0.62 * wob - r) * 10.0, 0, 1)
    cv.tint(membrane, pal(state, "alien_hi"), 0.55)
    cv.height += membrane * 0.5
    return cv


def mothership(state):
    cv = Canvas(172, 44, px_per_unit=6)
    hull = cv.poly_mask([(-50, -18), (50, -18), (55, 10), (-55, 10)],
                        feather=0.2)
    pyl_l = cv.poly_mask([(-55, -5), (-80, 5), (-70, 15), (-50, 8)], feather=0.15)
    pyl_r = cv.poly_mask([(55, -5), (80, 5), (70, 15), (50, 8)], feather=0.15)
    body = np.clip(hull + pyl_l + pyl_r, 0, 1)
    chitin_base(cv, body, state, seed=91, dome=2.6, bump=0.35)
    ridge(cv, body, [(-48, -6), (0, -10), (48, -6)], 1.0, 0.8, state)
    ridge(cv, body, [(-40, 4), (0, 7), (40, 4)], 0.8, 0.6, state)
    # armored plate checker: staggered panel seams
    rng = np.random.default_rng(19)
    for yy in (-14.0, -2.0, 6.0):
        x = -52.0 + rng.random() * 6
        while x < 52:
            w = 9.0 + rng.random() * 8
            seam = cv.line_mask((x, yy - 4), (x, yy + 4), 0.5, feather=0.2) * hull
            cv.add_height(seam, -0.5)
            cv.tint(seam, (0, 0, 0), 0.4)
            x += w
    # launch ports along the top edge
    for px in (-30.0, -10.0, 10.0, 30.0):
        p = cv.ellipse_mask((px, -16), 3.6, 2.6, feather=0.2)
        cv.add_height(p * body, -1.0)
        cv.tint(p * body, (6, 3, 6), 0.8)
    # reactor bowl (glow itself stays procedural)
    bowl = cv.ellipse_mask((0, 0), 9.0, 7.0, feather=0.3)
    cv.add_height(bowl * body, -1.6)
    cv.tint(bowl * body, (10, 4, 6), 0.7)
    return cv


ALL = {
    "scout": scout, "warrior": warrior, "destroyer": destroyer,
    "elite_artillery": elite_artillery, "elite_interceptor": elite_interceptor,
    "elite_swarm": elite_swarm, "silence": silence, "drone": drone,
    "leviathan": leviathan, "mothership": mothership,
}

if __name__ == "__main__":
    only = sys.argv[1:] or ALL.keys()
    for name in only:
        bake_dual(ALL[name], "enemies", name, states=STATES,
                  normal_strength=0.9, ao_strength=0.5)
