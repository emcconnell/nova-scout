"""World bakes — rocks, hazards, planets, backgrounds, light cookies.

Rocks lose their baked sun terminator on purpose: the DirectionalLight2D sun
now shades them via normal maps, and the DEAD ember rim is real red light.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
from PIL import Image
from texlib import Canvas, _gauss_blur
from bake_common import bake_dual, pal, TEX_ROOT


# ─── asteroids (3 seeded variants, baked at LARGE r=12, scaled per tier) ────
def make_rock(seed):
    def build(state):
        cv = Canvas(30, 30)
        X, Y = cv.grid()
        rng = np.random.default_rng(seed)
        k1, k2 = 2 + rng.integers(0, 2), 5 + rng.integers(0, 3)
        p1, p2 = rng.random() * np.pi * 2, rng.random() * np.pi * 2
        r = np.sqrt(X * X + Y * Y) + 1e-6
        a = np.arctan2(Y, X)
        # jagged silhouette: two harmonics + angular micro-jitter, hard edge
        jag = cv.fbm(seed * 5 + 9, octaves=3, base=16)
        f = 0.82 + 0.13 * np.sin(k1 * a + p1) + 0.07 * np.sin(k2 * a + p2)
        body = np.clip((12.0 * f - r + (jag - 0.5) * 1.6) * 6.0, 0, 1)
        hi, mid, lo = pal(state, "rock_hi"), pal(state, "rock_mid"), pal(state, "rock_lo")
        cv.paint(body, mid, spec=0.08, rough=0.9)
        # boulder dome + fractured macro relief (sharp tonal facets, not blobs)
        cv.height += _gauss_blur(body, cv.upx(2.2)) * 3.2
        macro = cv.fbm(seed * 3 + 1, octaves=6, base=7)
        cv.height += body * (macro - 0.5) * 2.2
        facet_hi = np.clip((macro - 0.58) * 5.0, 0, 1)
        facet_lo = np.clip((0.42 - macro) * 5.0, 0, 1)
        cv.tint(body * facet_hi, hi, 0.30)
        cv.tint(body * facet_lo, lo, 0.55)
        # regolith micro-noise
        micro = cv.fbm(seed * 3 + 2, octaves=6, base=30)
        cv.height += body * (micro - 0.5) * 0.7
        cv.tint(body * (micro > 0.72), hi, 0.18)
        cv.tint(body * (micro < 0.25), lo, 0.30)
        # craters: sharp bowls + thin rims (real shading via normals)
        crng = np.random.default_rng(seed * 7 + 3)
        for i in range(11):
            ca = crng.random() * np.pi * 2
            cd = crng.random() * 0.8
            cx, cy = np.cos(ca) * 12 * cd, np.sin(ca) * 12 * cd
            cr = 12 * (0.05 + crng.random() * 0.11)
            d2 = ((X - cx) / cr) ** 2 + ((Y - cy) / cr) ** 2
            bowl = np.clip((1 - d2) * 2.0, 0, 1) * body
            rim = np.clip(1 - np.abs(d2 - 1.1) * 4.0, 0, 1) * body
            cv.height += -bowl * cr * 0.30 + rim * cr * 0.10
            cv.tint(bowl, lo, 0.45)
            cv.tint(rim, hi, 0.25)
        return cv
    return build


# ─── space mine body (spikes/glow stay procedural) ──────────────────────────
def mine(state):
    cv = Canvas(16, 16)
    X, Y = cv.grid()
    body = cv.ellipse_mask((0, 0), 6.0, 6.0, feather=0.06)
    metal = pal(state, "hull_dark")
    cv.paint(body, metal, spec=0.5, rough=0.4)
    r2 = np.clip((X / 6.0) ** 2 + (Y / 6.0) ** 2, 0, 1)
    cv.height += body * np.sqrt(np.clip(1 - r2, 0, 1)) * 2.0
    cv.tint(body * np.clip(1 - r2 * 1.5, 0, 1), pal(state, "gray"), 0.4)
    # plating meridians
    for ang in np.linspace(0, np.pi, 4, endpoint=False):
        m = cv.line_mask((-6 * np.cos(ang), -6 * np.sin(ang)),
                         (6 * np.cos(ang), 6 * np.sin(ang)), 0.22,
                         feather=0.08) * body
        cv.add_height(m, -0.25)
        cv.tint(m, (0, 0, 0), 0.4)
    # rivet studs ring
    for ang in np.linspace(0, 2 * np.pi, 8, endpoint=False):
        s = cv.ellipse_mask((np.cos(ang) * 5.0, np.sin(ang) * 5.0), 0.5, 0.5,
                            feather=0.1)
        cv.add_height(s * body, 0.4)
        cv.tint(s * body, pal(state, "gray"), 0.5)
    # central detonator socket (red lens drawn procedurally on top)
    sock = cv.ellipse_mask((0, 0), 3.2, 3.2, feather=0.1)
    cv.add_height(sock * body, -0.8)
    cv.tint(sock * body, (8, 3, 3), 0.8)
    return cv


# ─── derelict probe wreck (hazard) ───────────────────────────────────────────
def derelict(state):
    cv = Canvas(48, 22)
    hull = cv.poly_mask([(-20, -4), (-6, -7), (14, -5), (21, -1), (18, 4),
                         (2, 7), (-14, 6), (-22, 2)], feather=0.12)
    cv.paint(hull, pal(state, "hull_dark"), spec=0.35, rough=0.6)
    cv.height += _gauss_blur(hull, cv.upx(1.4)) * 1.6
    X, Y = cv.grid()
    # battered plating
    seams = np.random.default_rng(5)
    for i in range(6):
        x = -18 + i * 7 + seams.random() * 3
        m = cv.line_mask((x, -7), (x + 1.5, 7), 0.3, feather=0.12) * hull
        cv.add_height(m, -0.4)
        cv.tint(m, (0, 0, 0), 0.5)
    grime = cv.fbm(83, octaves=5, base=12)
    cv.tint(hull * (grime > 0.6), (18, 16, 14), 0.5)
    cv.tint(hull * (grime < 0.3), pal(state, "gray"), 0.25)
    # hull breach — torn dark hole with crumpled rim
    hole = cv.ellipse_mask((4, 0), 4.5, 3.0, feather=0.15)
    cv.set_height(hole * hull, -1.5)
    cv.tint(hole * hull, (2, 2, 3), 0.95)
    rim = cv.ellipse_mask((4, 0), 5.2, 3.7, feather=0.1) * \
        (1 - cv.ellipse_mask((4, 0), 4.2, 2.7))
    cv.height += rim * hull * 0.7
    # snapped solar wing stub
    stub = cv.rect_mask(-20, -2.5, 6, 5, feather=0.08)
    cv.paint(stub, pal(state, "cell_lo"), spec=0.6)
    cv.add_height(stub, 0.25)
    return cv


# ─── planets (scan targets) ──────────────────────────────────────────────────
def make_planet(kind, seed):
    def build(state):
        cv = Canvas(30, 30)
        X, Y = cv.grid()
        r2 = (X / 13.0) ** 2 + (Y / 13.0) ** 2
        body = np.clip((1 - r2) * 24.0, 0, 1)
        z = np.sqrt(np.clip(1 - r2, 0, 1))
        cv.height += z * 10.0 * body          # true sphere normal
        n = cv.fbm(seed, octaves=6, base=6)
        n2 = cv.fbm(seed + 1, octaves=5, base=12)
        if kind == "habitable":
            cv.paint(body, (24, 60, 110), spec=0.5, rough=0.3)
            land = (n > 0.55).astype(np.float32) * body
            cv.tint(land, (58, 92, 48), 0.9)
            cv.tint(land * (n > 0.68), (120, 116, 74), 0.5)
            # latitude follows the sphere: project Y onto the ball's surface
            lat = np.abs(Y) / np.maximum(np.sqrt(np.clip(13.0 ** 2 - X * X, 1, None)), 1)
            polar = body * np.clip((lat - 0.72) * 8.0, 0, 1)
            cv.tint(polar, (235, 242, 248), 0.8)
            clouds = np.clip((n2 - 0.55) * 4.0, 0, 1) * body
            cv.tint(clouds, (250, 252, 255), 0.6)
        elif kind == "rocky":
            cv.paint(body, (128, 104, 86), spec=0.1, rough=0.9)
            cv.tint(body * (n > 0.6), (168, 142, 118), 0.6)
            cv.tint(body * (n < 0.4), (74, 58, 48), 0.6)
        elif kind == "gas":
            cv.paint(body, (140, 110, 150), spec=0.3, rough=0.5)
            bands = 0.5 + 0.5 * np.sin(Y * 0.9 + (n - 0.5) * 5.0)
            cv.tint(body * bands, (196, 170, 200), 0.55)
            cv.tint(body * (1 - bands) * (n2 > 0.5), (86, 60, 100), 0.5)
        elif kind == "gold":
            cv.paint(body, (196, 148, 40), spec=0.8, rough=0.2)
            cv.tint(body * (n > 0.55), (255, 215, 90), 0.65)
            cv.tint(body * (n2 < 0.4), (140, 96, 22), 0.5)
            clouds = np.clip((n2 - 0.58) * 3.2, 0, 1) * body
            cv.tint(clouds, (255, 240, 190), 0.5)
        return cv
    return build


# ─── single-state helpers (backgrounds, light cookies) ──────────────────────
def save_rgba(arr, path):
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(path)


def bake_starfield(seed, w=640, h=360, density=140):
    rng = np.random.default_rng(seed)
    img = np.zeros((h, w, 4), np.float32)
    for i in range(density):
        x, y = rng.integers(0, w), rng.integers(0, h)
        mag = rng.random()
        warm = rng.random() > 0.75
        col = np.array([1.0, 0.92, 0.82] if warm else [0.82, 0.90, 1.0])
        b = 0.25 + 0.75 * mag ** 3
        img[y, x, :3] = np.maximum(img[y, x, :3], col * b)
        img[y, x, 3] = max(img[y, x, 3], b)
        if mag > 0.93:   # bright star: soft 1px halo
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = (y + dy) % h, (x + dx) % w
                    img[yy, xx, :3] = np.maximum(img[yy, xx, :3], col * b * 0.30)
                    img[yy, xx, 3] = max(img[yy, xx, 3], b * 0.30)
    return img


def bake_nebula(seed, size=256):
    cv = Canvas(size / 12, size / 12)
    n = cv.fbm(seed, octaves=6, base=4)
    X, Y = cv.grid()
    ext = np.sqrt((X / (size / 26)) ** 2 + (Y / (size / 30)) ** 2)
    a = np.clip((n - 0.42) * 1.8, 0, 1) * np.clip(1.2 - ext, 0, 1)
    a = _gauss_blur(a, cv.upx(0.4))
    img = np.zeros((cv.h, cv.w, 4), np.float32)
    lum = 0.55 + 0.45 * n
    for c in range(3):
        img[..., c] = lum
    img[..., 3] = a * 0.9
    return np.asarray(Image.fromarray(
        (np.clip(img, 0, 1) * 255).astype(np.uint8), "RGBA").resize(
        (size, size), Image.LANCZOS), np.float32) / 255.0


def bake_light_cookies(out):
    # radial point-light cookie
    s = 256
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    d = np.sqrt((x - s / 2) ** 2 + (y - s / 2) ** 2) / (s / 2)
    a = np.clip(1 - d, 0, 1) ** 2.2
    img = np.ones((s, s, 4), np.float32)
    img[..., 3] = a
    save_rgba(img, f"{out}/light_radial.png")
    # flood cone cookie — apex at center, wedge pointing up (rotate at runtime)
    s = 512
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    dx, dy = x - s / 2, y - s / 2
    dist = np.sqrt(dx * dx + dy * dy) / (s / 2)
    ang = np.abs(np.arctan2(dx, -dy))          # 0 = straight up
    half, soft = np.deg2rad(17.0), np.deg2rad(8.0)
    angular = np.clip((half + soft - ang) / soft, 0, 1)
    radial = np.clip((1.0 - dist) / 0.45, 0, 1) * np.clip(dist * 14.0, 0, 1)
    img = np.ones((s, s, 4), np.float32)
    img[..., 3] = np.clip(angular * radial, 0, 1)
    save_rgba(img, f"{out}/light_cone.png")


if __name__ == "__main__":
    for i, sd in enumerate([31337, 7919, 65537]):
        bake_dual(make_rock(sd), "hazards", f"rock_{i}", normal_strength=1.0,
                  ao_strength=0.6)
    bake_dual(mine, "hazards", "mine", normal_strength=1.0)
    bake_dual(derelict, "hazards", "derelict", normal_strength=1.0)
    for kind, sd in [("habitable", 11), ("rocky", 13), ("gas", 17), ("gold", 19)]:
        bake_dual(make_planet(kind, sd), "world", f"planet_{kind}",
                  normal_strength=0.8, ao_strength=0.3)

    out = os.path.join(TEX_ROOT, "world")
    os.makedirs(out, exist_ok=True)
    for i, sd in enumerate([3, 5]):
        save_rgba(bake_starfield(sd, density=150 - i * 60),
                  f"{out}/starfield_{i}.png")
    for i, sd in enumerate([21, 22, 23]):
        save_rgba(bake_nebula(sd), f"{out}/nebula_{i}.png")
    bake_light_cookies(out)
    print("world assets baked")
