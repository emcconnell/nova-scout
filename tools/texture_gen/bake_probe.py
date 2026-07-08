"""Bake the light-probe dome texture (tools only, not shipped)."""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
from texlib import Canvas

OUT = os.path.join(os.path.dirname(__file__), "../../assets/textures/probe")
os.makedirs(OUT, exist_ok=True)

cv = Canvas(24, 24)
X, Y = cv.grid()
r = np.sqrt(X * X + Y * Y)
dome = np.clip(1.0 - (r / 10.0) ** 2, 0.0, 1.0)
inside = (r < 10.0).astype(np.float32)
cv.paint(inside, (128, 128, 128), spec=0.6)
cv.height += np.sqrt(np.clip(dome, 0, 1)) * 6.0 * inside
cv.bake(OUT, "dome", normal_strength=1.0, ao_in_albedo=False)
print("baked", OUT)
