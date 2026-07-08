"""SP-7 survey probe body bake — the hero asset (art bible v4.0 'probe4' geometry).

Geometry matches PlayerRenderer's unit-space layout exactly (hull ±3.4 wide,
nose -12, tail +7, wings to ±10, dish up-right, whip antenna up-left) so the
collision footprint and every FX anchor stay valid. Emissive/dynamic elements
(plume, glints, beacon, shield, muzzle) remain procedural overlays in-engine.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
from texlib import Canvas, brushed_metal, panel_seams, rivet_row
from bake_common import bake_dual, pal

HULL_W = 3.4
NOSE_Y, TAIL_Y = -12.0, 7.0
WING_X0, WING_X1 = 3.4, 10.0
WING_Y0, WING_Y1 = -6.0, 8.0
COLS, ROWS = 3, 4


def hull_silhouette():
    """Rounded capsule polygon — nose apex, shoulder curve, straight flanks."""
    pts = [(0.0, NOSE_Y)]
    # nose shoulder curve (right side)
    for t in np.linspace(0.12, 1.0, 8):
        x = HULL_W * np.sin(t * np.pi / 2)
        y = NOSE_Y + 2.3 * (1 - np.cos(t * np.pi / 2))
    # simpler: parametric quarter-ellipse from apex to shoulder
    pts = [(0.0, NOSE_Y)]
    for t in np.linspace(0, 1, 10):
        pts.append((HULL_W * np.sin(t * np.pi / 2),
                    NOSE_Y + 2.3 * (1 - np.cos(t * np.pi / 2))))
    pts += [(HULL_W, TAIL_Y), (-HULL_W, TAIL_Y)]
    for t in np.linspace(1, 0, 10):
        pts.append((-HULL_W * np.sin(t * np.pi / 2),
                    NOSE_Y + 2.3 * (1 - np.cos(t * np.pi / 2))))
    return pts


def build(state: str) -> Canvas:
    cv = Canvas(28, 34)
    X, Y = cv.grid()

    # ── solar wings ────────────────────────────────────────────────────────
    for side in (-1, 1):
        x0 = WING_X0 if side > 0 else -WING_X1
        w = WING_X1 - WING_X0
        backing = cv.rect_mask(x0 - 0.25, WING_Y0 - 0.25, w + 0.5,
                               (WING_Y1 - WING_Y0) + 0.5)
        cv.paint(backing, pal(state, "backing"), spec=0.1)
        cv.add_height(backing, 0.30)
        # spars from hull to wingtip
        for sy in (-1.5, 3.0):
            spar = cv.line_mask((side * HULL_W, sy), (side * WING_X1, sy), 0.30)
            cv.paint(spar, pal(state, "spar"), spec=0.5)
            cv.add_height(spar, 0.22)
        # cell grid — beveled glass cells, seeded hi/lo pattern
        rng = np.random.default_rng(7 if side > 0 else 8)
        cw, chh = w / COLS, (WING_Y1 - WING_Y0) / ROWS
        for c in range(COLS):
            for r in range(ROWS):
                cx = x0 + c * cw + 0.14
                cy = WING_Y0 + r * chh + 0.14
                cell = cv.rect_mask(cx, cy, cw - 0.28, chh - 0.28,
                                    feather=0.05)
                hi = rng.random() > 0.45
                col = pal(state, "cell_hi" if hi else "cell_lo")
                cv.paint(cell, col, spec=0.85, rough=0.15)
                cv.add_height(cell, 0.16)
                # subtle diagonal iridescence within each cell
                grad = np.clip((X - cx) / max(cw, 0.01) +
                               (Y - cy) / max(chh, 0.01), 0, 1) * cell
                cv.tint(grad, tuple(min(255, int(v * 1.5)) for v in col), 0.35)
        # gold bus lines every 2nd column boundary
        c = 2
        while c < COLS:
            lx = x0 + c * cw
            bus = cv.line_mask((lx, WING_Y0), (lx, WING_Y1), 0.14)
            cv.paint(bus, pal(state, "gold"), alpha=0.75, spec=0.7)
            c += 2

    # ── whip antenna (up-left) ─────────────────────────────────────────────
    ant = cv.line_mask((-2.5, NOSE_Y + 3.0), (-6.5, NOSE_Y - 4.5), 0.16)
    cv.paint(ant, pal(state, "spar"), spec=0.4)
    cv.add_height(ant, 0.18)
    tip = cv.ellipse_mask((-6.5, NOSE_Y - 4.5), 0.32, 0.32, feather=0.08)
    cv.paint(tip, pal(state, "white"), spec=0.6)
    cv.add_height(tip, 0.3)

    # ── main fuselage ──────────────────────────────────────────────────────
    hull = cv.poly_mask(hull_silhouette())
    brushed_metal(cv, hull, pal(state, "hull_mid"), seed=41, wear=0.45)
    # half-cylinder height profile + nose taper
    prof = np.sqrt(np.clip(1.0 - (X / (HULL_W + 0.15)) ** 2, 0, 1))
    nose_fade = np.clip((Y - NOSE_Y) / 2.6, 0, 1)
    tail_fade = np.clip((TAIL_Y - Y) / 1.6, 0, 1) * 0.35 + 0.65
    cv.height += hull * prof * nose_fade * tail_fade * 2.2
    # key-side tone: hull ramp brightens toward -X (matches concept sun)
    lateral = np.clip(0.5 - X / (2 * HULL_W), 0, 1) * hull
    cv.tint(lateral, pal(state, "white"), 0.28)
    cv.tint(hull * np.clip((X - HULL_W * 0.35) / HULL_W, 0, 1),
            pal(state, "hull_deep"), 0.4)

    # panel seams + rivet rows
    seams_y = [NOSE_Y + 19.0 * f for f in (0.16, 0.30, 0.46, 0.60, 0.78)]
    panel_seams(cv, hull, [((-HULL_W, yy), (HULL_W, yy)) for yy in seams_y],
                depth=0.4, width=0.13)
    for yy in seams_y[1::2]:
        rivet_row(cv, (-HULL_W + 0.5, yy - 0.55), (HULL_W - 0.5, yy - 0.55), 5,
                  r=0.13, height=0.35)

    # ID stripe near the nose
    stripe = cv.rect_mask(-HULL_W, -9.6, 2 * HULL_W, 0.7) * hull
    cv.paint(stripe, pal(state, "accent"), alpha=0.8, spec=0.4)

    # "SP-7" registry marking — hand-drawn strokes, lower hull, port side
    mk = pal(state, "hull_dark") if state == "survey" else pal(state, "gray")
    sx, sy_, sc = -2.3, -1.0, 0.30   # origin + stroke scale
    strokes = [
        # S
        ((1.2, 0.0), (0.0, 0.0)), ((0.0, 0.0), (0.0, 1.0)),
        ((0.0, 1.0), (1.2, 1.0)), ((1.2, 1.0), (1.2, 2.0)),
        ((1.2, 2.0), (0.0, 2.0)),
        # P
        ((1.8, 2.0), (1.8, 0.0)), ((1.8, 0.0), (3.0, 0.0)),
        ((3.0, 0.0), (3.0, 1.0)), ((3.0, 1.0), (1.8, 1.0)),
        # dash
        ((3.6, 1.0), (4.4, 1.0)),
        # 7
        ((5.0, 0.0), (6.2, 0.0)), ((6.2, 0.0), (5.4, 2.0)),
    ]
    for a, b in strokes:
        m = cv.line_mask((sx + a[0] * sc, sy_ + a[1] * sc),
                         (sx + b[0] * sc, sy_ + b[1] * sc), 0.14)
        cv.tint(m * hull, mk, 0.85)

    # ── radiator strip ─────────────────────────────────────────────────────
    rad = cv.rect_mask(-HULL_W + 0.3, -3.0, 2 * HULL_W - 0.6, 2.0)
    cv.paint(rad, pal(state, "radiator"), spec=0.25, rough=0.7)
    cv.add_height(rad, 0.12)
    for i in range(6):
        fx = -HULL_W + 0.3 + i * (2 * HULL_W - 0.6) / 5.0
        fin = cv.line_mask((fx, -3.0), (fx, -1.0), 0.10)
        cv.add_height(fin, -0.18)
        cv.tint(fin, (20, 24, 29), 0.55)

    # ── kapton foil band (gold, wrinkled, high spec) ───────────────────────
    kap = cv.rect_mask(-HULL_W, 1.5, 2 * HULL_W, 4.5) * hull
    kgrad = np.clip((Y - 1.5) / 4.5, 0, 1)
    cv.paint(kap, pal(state, "kapton_hi"), spec=0.8, rough=0.2)
    cv.tint(kap * kgrad, pal(state, "kapton_lo"), 0.85)
    wr = cv.fbm(101, octaves=5, base=26)
    cv.height += kap * (wr - 0.5) * 0.5          # crinkled foil relief
    cv.tint(kap * (wr > 0.64), (255, 236, 160), 0.12)
    cv.tint(kap * (wr < 0.34), (36, 24, 4), 0.22)

    # ── hazard chevrons near the tail ──────────────────────────────────────
    hz = 4.5
    for i in range(-1, 5):
        x0 = -HULL_W + i * 1.6
        band = cv.poly_mask([(x0, hz), (x0 + 1.6, hz),
                             (x0 + 0.5, hz + 1.6), (x0 - 1.1, hz + 1.6)])
        col = pal(state, "chevron_dark") if i % 2 == 0 else pal(state, "chevron")
        cv.tint(band * hull, col, 0.95)

    # ── RCS thruster quads ─────────────────────────────────────────────────
    for ox, oy in [(-HULL_W - 0.55, -4.6), (HULL_W + 0.55, -4.6),
                   (-HULL_W - 0.55, 4.4), (HULL_W + 0.55, 4.4)]:
        q = cv.rect_mask(ox - 0.42, oy - 0.62, 0.84, 1.24, feather=0.05)
        cv.paint(q, pal(state, "spar"), spec=0.5)
        cv.add_height(q, 0.5)
        nz = cv.ellipse_mask((ox + (0.55 if ox > 0 else -0.55), oy), 0.24,
                             0.28, feather=0.06)
        cv.paint(nz, pal(state, "backing"), spec=0.2)
        cv.add_height(nz, -0.3)

    # ── engine bell ────────────────────────────────────────────────────────
    bell = cv.poly_mask([(-2.5, 5.0), (2.5, 5.0), (2.0, 7.2), (-2.0, 7.2)])
    cv.paint(bell, hx_mix(pal(state, "hull_dark"), pal(state, "backing"), 0.5),
             spec=0.45, rough=0.35)
    bellp = np.sqrt(np.clip(1.0 - (X / 2.5) ** 2, 0, 1))
    cv.height += bell * bellp * 0.9
    for yy in (5.7, 6.4):
        rib = cv.line_mask((-2.3, yy), (2.3, yy), 0.10) * bell
        cv.add_height(rib, 0.14)
        cv.tint(rib, (255, 255, 255), 0.10)

    # ── canopy dome (glass) ────────────────────────────────────────────────
    ccx, ccy, crx, cry = 0.0, -9.0, 2.6, 2.3
    dome = cv.ellipse_mask((ccx, ccy), crx, cry)
    # top-half only, like the draw pass
    dome = dome * (Y <= ccy + 0.15)
    cv.paint(dome, pal(state, "canopy_mid"), spec=0.95, rough=0.05)
    r2 = np.clip(((X - ccx) / crx) ** 2 + ((Y - ccy) / cry) ** 2, 0, 1)
    cv.tint(dome * np.clip(1 - r2 * 1.4, 0, 1), pal(state, "canopy_hi"), 0.7)
    cv.tint(dome * np.clip(r2 - 0.45, 0, 1), pal(state, "canopy_lo"), 0.8)
    cv.height += dome * np.sqrt(np.clip(1 - r2, 0, 1)) * 1.5
    frame = cv.ellipse_mask((ccx, ccy), crx + 0.12, cry + 0.12) * \
        (1 - cv.ellipse_mask((ccx, ccy), crx - 0.12, cry - 0.12)) * (Y <= ccy)
    cv.paint(frame, pal(state, "spar"), spec=0.5)

    # ── high-gain dish (up-right, concave bowl) ────────────────────────────
    dcx, dcy, drx, dry = 9.9, -9.0, 2.6, 1.7
    strut = cv.line_mask((HULL_W + 1.0, -6.0), (dcx - 0.8, dcy + 1.2), 0.18)
    cv.paint(strut, pal(state, "spar"), spec=0.5)
    cv.add_height(strut, 0.25)
    dish = cv.ellipse_mask((dcx, dcy), drx, dry)
    cv.paint(dish, pal(state, "white"), spec=0.6, rough=0.3)
    dr2 = np.clip(((X - dcx) / drx) ** 2 + ((Y - dcy) / dry) ** 2, 0, 1)
    cv.tint(dish * np.clip(dr2 * 1.15, 0, 1), pal(state, "hull_dark"), 0.55)
    cv.height += dish * (-(1 - dr2) * 0.9)     # concave
    rim = cv.ellipse_mask((dcx, dcy), drx, dry) * \
        (1 - cv.ellipse_mask((dcx, dcy), drx - 0.22, dry - 0.22))
    cv.add_height(rim, 0.35)
    cv.tint(rim, pal(state, "white"), 0.4)
    # feed horn
    horn = cv.ellipse_mask((dcx + 0.6, dcy - 0.9), 0.4, 0.4, feather=0.08)
    cv.paint(horn, pal(state, "spar"), spec=0.5)
    cv.add_height(horn, 0.8)

    return cv


def hx_mix(a, b, t):
    return tuple(int(av + (bv - av) * t) for av, bv in zip(a, b))


if __name__ == "__main__":
    bake_dual(build, "player", "sp7", normal_strength=1.0)
    print("SP-7 baked ->", os.path.join(os.path.dirname(__file__),
                                        "../../assets/textures/player"))
