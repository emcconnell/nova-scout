"""texlib — NOVA SCOUT texture baking library (art bible v4.0).

Height-field driven asset baking: recipes compose height + albedo layers at
SS×supersampled resolution; normals are derived from the height field (Sobel),
ambient occlusion from local height contrast, and everything is downsampled
for anti-aliasing. Output convention (matches Godot 4 CanvasTexture):

    <name>_albedo.png   RGBA color, straight alpha
    <name>_normal.png   RGB, +X right (R), +Y **down** is checked by the light
                        probe at bake time — flip via NORMAL_Y_DOWN
    <name>_spec.png     optional grayscale specular mask

All coordinates in recipe space are "game units" (the 320×180 canvas px);
PX_PER_UNIT controls bake density.
"""
from __future__ import annotations

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

PX_PER_UNIT = 12          # bake density: game-unit -> texture px
SS = 2                    # supersample factor on top of PX_PER_UNIT
# Godot 4 canvas lighting samples normal maps with +Y pointing *down* in
# screen space (verified by tools/texture_gen light probe on 4.6).
NORMAL_Y_DOWN = True


def _gauss_blur(a: np.ndarray, sigma: float) -> np.ndarray:
    """Separable float Gaussian blur (PIL can't blur mode-F images)."""
    if sigma <= 0.1:
        return a
    radius = max(1, int(sigma * 3))
    x = np.arange(-radius, radius + 1, dtype=np.float32)
    k = np.exp(-(x * x) / (2 * sigma * sigma))
    k /= k.sum()
    pad = np.pad(a, ((0, 0), (radius, radius)), mode="edge")
    out = np.apply_along_axis(lambda r: np.convolve(r, k, "valid"), 1, pad)
    pad = np.pad(out, ((radius, radius), (0, 0)), mode="edge")
    return np.apply_along_axis(lambda c: np.convolve(c, k, "valid"), 0, pad)


class Canvas:
    """A height + albedo + alpha + emission workspace in supersampled px."""

    def __init__(self, w_units: float, h_units: float,
                 px_per_unit: int | None = None):
        self.ppu = px_per_unit or PX_PER_UNIT
        self.scale = self.ppu * SS
        self.w = int(round(w_units * self.scale))
        self.h = int(round(h_units * self.scale))
        self.ox = self.w / 2.0            # origin at center
        self.oy = self.h / 2.0
        self.height = np.zeros((self.h, self.w), np.float32)
        self.albedo = np.zeros((self.h, self.w, 3), np.float32)
        self.alpha = np.zeros((self.h, self.w), np.float32)
        self.spec = np.zeros((self.h, self.w), np.float32)
        self.rough = np.full((self.h, self.w), 0.5, np.float32)

    # ─── coordinate helpers ────────────────────────────────────────────────
    def px(self, p):
        """Game-unit (x, y) -> supersampled px (x, y)."""
        return (self.ox + p[0] * self.scale, self.oy + p[1] * self.scale)

    def upx(self, v: float) -> float:
        return v * self.scale

    def grid(self):
        """Return (X, Y) unit-space coordinate grids for vectorized layers."""
        ys, xs = np.mgrid[0 : self.h, 0 : self.w].astype(np.float32)
        return (xs - self.ox) / self.scale, (ys - self.oy) / self.scale

    # ─── mask rasterizers (PIL, uint8 L — mode F can't GaussianBlur) ───────
    def _mask_img(self):
        return Image.new("L", (self.w, self.h), 0)

    @staticmethod
    def _finish_mask(img, blur_px: float) -> np.ndarray:
        if blur_px > 0:
            img = img.filter(ImageFilter.GaussianBlur(blur_px))
        return np.asarray(img, np.float32) / 255.0

    def poly_mask(self, pts, feather: float = 0.0) -> np.ndarray:
        img = self._mask_img()
        d = ImageDraw.Draw(img)
        d.polygon([self.px(p) for p in pts], fill=255)
        return self._finish_mask(img, self.upx(feather))

    def ellipse_mask(self, center, rx, ry, feather: float = 0.0) -> np.ndarray:
        img = self._mask_img()
        d = ImageDraw.Draw(img)
        cx, cy = self.px(center)
        d.ellipse([cx - self.upx(rx), cy - self.upx(ry),
                   cx + self.upx(rx), cy + self.upx(ry)], fill=255)
        return self._finish_mask(img, self.upx(feather))

    def rect_mask(self, x, y, w, h, feather: float = 0.0) -> np.ndarray:
        return self.poly_mask([(x, y), (x + w, y), (x + w, y + h), (x, y + h)],
                              feather)

    def line_mask(self, a, b, width: float, feather: float = 0.0) -> np.ndarray:
        img = self._mask_img()
        d = ImageDraw.Draw(img)
        d.line([self.px(a), self.px(b)], fill=255,
               width=max(1, int(round(self.upx(width)))))
        return self._finish_mask(img, self.upx(feather))

    # ─── layer ops ─────────────────────────────────────────────────────────
    def add_height(self, mask: np.ndarray, amount: float):
        self.height += mask * amount

    def set_height(self, mask: np.ndarray, amount: float):
        self.height = self.height * (1 - mask) + amount * mask

    def paint(self, mask: np.ndarray, color, alpha: float = 1.0,
              spec: float | None = None, rough: float | None = None):
        """Composite color over albedo where mask > 0; unions coverage alpha."""
        m = np.clip(mask * alpha, 0.0, 1.0)[..., None]
        col = np.asarray(color, np.float32) / 255.0
        self.albedo = self.albedo * (1 - m) + col * m
        self.alpha = np.maximum(self.alpha, m[..., 0])
        if spec is not None:
            self.spec = self.spec * (1 - m[..., 0]) + spec * m[..., 0]
        if rough is not None:
            self.rough = self.rough * (1 - m[..., 0]) + rough * m[..., 0]

    def tint(self, mask: np.ndarray, color, alpha: float):
        """Multiply-free overlay tint that does NOT extend coverage."""
        m = np.clip(mask * alpha, 0.0, 1.0)[..., None] * self.alpha[..., None]
        col = np.asarray(color, np.float32) / 255.0
        self.albedo = self.albedo * (1 - m) + col * m

    # ─── procedural noise ──────────────────────────────────────────────────
    def fbm(self, seed: int, octaves: int = 4, base: int = 8) -> np.ndarray:
        """Value-noise fBm in [0,1] at canvas resolution."""
        rng = np.random.default_rng(seed)
        out = np.zeros((self.h, self.w), np.float32)
        amp, total = 1.0, 0.0
        for o in range(octaves):
            gw = max(2, base * (2 ** o))
            gh = max(2, int(gw * self.h / max(self.w, 1)))
            g = rng.random((gh, gw), np.float32)
            layer = np.asarray(
                Image.fromarray((g * 255).astype(np.uint8), "L")
                .resize((self.w, self.h), Image.BICUBIC), np.float32) / 255.0
            out += layer * amp
            total += amp
            amp *= 0.5
        return out / total

    # ─── finishing ─────────────────────────────────────────────────────────
    def normal_map(self, strength: float = 1.0) -> np.ndarray:
        """Sobel-derived tangent-space normal map (H, W, 3) in [0,1]."""
        h = _gauss_blur(self.height, SS * 0.75)
        gy, gx = np.gradient(h)
        # height is in game units, gradient is per-px: convert to true slope
        k = strength * self.scale
        del h
        nx = -gx * k
        ny = -gy * k
        if not NORMAL_Y_DOWN:
            ny = -ny
        nz = np.ones_like(nx)
        norm = np.sqrt(nx * nx + ny * ny + nz * nz)
        n = np.stack([nx / norm, ny / norm, nz / norm], axis=-1)
        return n * 0.5 + 0.5

    def ao(self, radius: float = 1.2, strength: float = 0.55) -> np.ndarray:
        """Cheap AO: how far below the local height average a pixel sits."""
        blur = _gauss_blur(self.height, self.upx(radius))
        occ = np.clip((blur - self.height) * strength, 0.0, 1.0)
        return occ

    def bake(self, out_dir, name: str, normal_strength: float = 1.0,
             ao_strength: float = 0.55, ao_in_albedo: bool = True):
        """Downsample and write albedo/normal(/spec) PNG triplet."""
        albedo = self.albedo.copy()
        if ao_in_albedo:
            occ = self.ao(strength=ao_strength)
            albedo *= (1.0 - occ * 0.65)[..., None]
        target = (self.w // SS, self.h // SS)

        rgba = np.concatenate([albedo, self.alpha[..., None]], axis=-1)
        img = Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")
        img = img.resize(target, Image.LANCZOS)
        img.save(f"{out_dir}/{name}_albedo.png")

        n = self.normal_map(normal_strength)
        # neutralize normals outside coverage so edges don't sparkle
        a3 = self.alpha[..., None]
        n = n * a3 + np.asarray([0.5, 0.5, 1.0], np.float32) * (1 - a3)
        nimg = Image.fromarray((np.clip(n, 0, 1) * 255).astype(np.uint8), "RGB")
        nimg = nimg.resize(target, Image.LANCZOS)
        nimg.save(f"{out_dir}/{name}_normal.png")

        if self.spec.max() > 0.001:
            simg = Image.fromarray(
                (np.clip(self.spec * self.alpha, 0, 1) * 255).astype(np.uint8), "L")
            simg = simg.resize(target, Image.LANCZOS)
            simg.save(f"{out_dir}/{name}_spec.png")
        return img


# ─── shared surface treatments ──────────────────────────────────────────────
def brushed_metal(cv: Canvas, mask: np.ndarray, base, seed: int,
                  wear: float = 0.35, streak_axis: str = "y"):
    """Weathered hull plating: base color + anisotropic streaks + wear flecks."""
    cv.paint(mask, base, spec=0.55, rough=0.45)
    streaks = cv.fbm(seed, octaves=3, base=6)
    if streak_axis == "y":
        streaks = np.asarray(
            Image.fromarray((streaks * 255).astype(np.uint8), "L")
            .resize((cv.w, max(2, cv.h // 8)), Image.BILINEAR)
            .resize((cv.w, cv.h), Image.BILINEAR), np.float32) / 255
    cv.tint(mask * streaks, (255, 255, 255), 0.06 * wear * 2)
    grime = cv.fbm(seed + 7, octaves=5, base=16)
    cv.tint(mask * (grime > 0.66) * grime, (30, 32, 38), 0.22 * wear)
    flecks = cv.fbm(seed + 13, octaves=5, base=24)
    cv.tint(mask * (flecks > 0.74), (210, 218, 228), 0.25 * wear)


def panel_seams(cv: Canvas, mask: np.ndarray, seams, depth: float = 0.5,
                width: float = 0.14):
    """Recessed seam lines (list of ((x0,y0),(x1,y1)) unit-space pairs)."""
    for a, b in seams:
        m = cv.line_mask(a, b, width, feather=width * 0.5) * mask
        cv.add_height(m, -depth)
        cv.tint(m, (8, 10, 14), 0.5)


def rivet_row(cv: Canvas, a, b, count: int, r: float = 0.16,
              height: float = 0.5):
    ax, ay = a
    bx, by = b
    for i in range(count):
        t = i / max(count - 1, 1)
        p = (ax + (bx - ax) * t, ay + (by - ay) * t)
        m = cv.ellipse_mask(p, r, r, feather=r * 0.6)
        cv.add_height(m, height)
        cv.tint(m, (235, 240, 248), 0.30)
