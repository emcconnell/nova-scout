#!/usr/bin/env python3
"""Generate deterministic procedural music and SFX for NOVA SCOUT.

Dark Directive v2.0 soundscape (design/gdd/dark-directive.md §4.3):
low drones and sub-bass dread, irregular rhythms, phrygian and cluster
harmony, silence as a weapon, diegetic hardware sounds (relay clicks,
band-passed tracker pings), and one restrained dawn for the discovery
and ending themes. No external samples; everything is synthesized.

All output is deterministic (fixed RNG seed) so builds are reproducible.
"""
from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
MUSIC_DIR = ROOT / "assets" / "audio" / "music"
SFX_DIR = ROOT / "assets" / "audio" / "sfx"
SR = 44_100
RNG = np.random.default_rng(1979)  # The year the Nostromo flew

# Dark scale material
PHRYGIAN = [0, 1, 3, 5, 7, 8, 10]
MINOR = [0, 2, 3, 5, 7, 8, 10]
MAJOR = [0, 2, 4, 5, 7, 9, 11]


# ─── Primitive generators ────────────────────────────────────────────────────

def tsec(duration: float) -> np.ndarray:
    return np.arange(int(SR * duration), dtype=np.float32) / SR


def midi_to_hz(midi: float) -> float:
    return 440.0 * (2.0 ** ((midi - 69.0) / 12.0))


def adsr(n: int, attack=0.01, decay=0.05, sustain=0.7, release=0.08) -> np.ndarray:
    env = np.ones(n, dtype=np.float32) * sustain
    a = min(n, int(attack * SR))
    d = min(max(0, n - a), int(decay * SR))
    r = min(max(0, n - a - d), int(release * SR))
    if a > 0:
        env[:a] = np.linspace(0.0, 1.0, a, dtype=np.float32)
    if d > 0:
        env[a:a + d] = np.linspace(1.0, sustain, d, dtype=np.float32)
    if r > 0:
        env[-r:] *= np.linspace(1.0, 0.0, r, dtype=np.float32)
    return env


def sine(freq, duration, amp=1.0, phase=0.0, vibrato=0.0, vib_rate=5.0):
    t = tsec(duration)
    if vibrato:
        inst = freq * (1.0 + vibrato * np.sin(2 * np.pi * vib_rate * t))
        ph = 2 * np.pi * np.cumsum(inst) / SR + phase
        return amp * np.sin(ph)
    return amp * np.sin(2 * np.pi * freq * t + phase)


def saw(freq, duration, amp=1.0):
    t = tsec(duration)
    return amp * (2.0 * ((t * freq) % 1.0) - 1.0).astype(np.float32)


def square(freq, duration, amp=1.0, duty=0.5):
    t = tsec(duration)
    return amp * np.where((t * freq) % 1.0 < duty, 1.0, -1.0).astype(np.float32)


def noise(duration, amp=1.0):
    return amp * RNG.uniform(-1.0, 1.0, int(SR * duration)).astype(np.float32)


def soften(x: np.ndarray, drive=1.3) -> np.ndarray:
    return np.tanh(x * drive).astype(np.float32)


# ─── FFT filters (fast, smooth rolloff) ──────────────────────────────────────

def _fft_filter(x: np.ndarray, shaper) -> np.ndarray:
    spec = np.fft.rfft(x.astype(np.float64))
    freqs = np.fft.rfftfreq(len(x), 1.0 / SR)
    spec *= shaper(freqs)
    return np.fft.irfft(spec, n=len(x)).astype(np.float32)


def lowpass(x: np.ndarray, cutoff_hz: float, order: float = 2.0) -> np.ndarray:
    return _fft_filter(x, lambda f: 1.0 / (1.0 + (f / max(cutoff_hz, 1.0)) ** (2 * order)))


def highpass(x: np.ndarray, cutoff_hz: float, order: float = 2.0) -> np.ndarray:
    return _fft_filter(x, lambda f: 1.0 / (1.0 + (max(cutoff_hz, 1.0) / np.maximum(f, 1e-6)) ** (2 * order)))


def bandpass(x: np.ndarray, low_hz: float, high_hz: float) -> np.ndarray:
    return highpass(lowpass(x, high_hz), low_hz)


def pitch_sweep(start_hz, end_hz, duration, amp=1.0, curve=1.0):
    t = tsec(duration)
    u = np.linspace(0, 1, len(t), dtype=np.float32) ** curve
    freqs = start_hz * ((end_hz / start_hz) ** u)
    ph = 2 * np.pi * np.cumsum(freqs) / SR
    return amp * np.sin(ph)


def stereo(mono: np.ndarray, width=0.15, delay_ms=7.0) -> np.ndarray:
    d = int(SR * delay_ms / 1000.0)
    right = np.roll(mono, d) * (1.0 - width)
    right[:d] = 0
    left = mono * (1.0 + width)
    return np.stack([left, right], axis=1).astype(np.float32)


def normalize(x: np.ndarray, peak=0.86) -> np.ndarray:
    m = float(np.max(np.abs(x))) if x.size else 0.0
    if m > 0:
        x = x * (peak / m)
    return np.clip(x, -0.98, 0.98).astype(np.float32)


def fade_edges(x: np.ndarray, fade=0.025) -> np.ndarray:
    n = len(x)
    f = min(n // 2, int(SR * fade))
    if f <= 0:
        return x
    ramp = np.linspace(0, 1, f, dtype=np.float32)
    x[:f] *= ramp[..., None] if x.ndim == 2 else ramp
    x[-f:] *= ramp[::-1][..., None] if x.ndim == 2 else ramp[::-1]
    return x


def write_wav(path: Path, data: np.ndarray, peak=0.86):
    path.parent.mkdir(parents=True, exist_ok=True)
    data = fade_edges(normalize(data, peak=peak).copy())
    if data.ndim == 1:
        data = data[:, None]
    pcm = (data * 32767).astype('<i2')
    with wave.open(str(path), 'wb') as wf:
        wf.setnchannels(data.shape[1])
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(pcm.tobytes())


def mix_at(buf: np.ndarray, start: float, sig: np.ndarray, pan=0.0):
    idx = int(start * SR)
    if idx >= len(buf) or idx < 0:
        return
    n = min(len(sig), len(buf) - idx)
    if sig.ndim == 1:
        l = sig[:n] * math.cos((pan + 1) * math.pi / 4)
        r = sig[:n] * math.sin((pan + 1) * math.pi / 4)
        buf[idx:idx + n, 0] += l
        buf[idx:idx + n, 1] += r
    else:
        buf[idx:idx + n] += sig[:n]


def combine(*signals: np.ndarray) -> np.ndarray:
    n = max(len(s) for s in signals)
    out = np.zeros(n, dtype=np.float32)
    for s in signals:
        out[:len(s)] += s.astype(np.float32)
    return out


# ─── Music building blocks ───────────────────────────────────────────────────

def drone_bed(duration: float, root_midi: float, amp=0.16, movement=0.06) -> np.ndarray:
    """Detuned saw + sub sine drone, slow breathing amplitude. The floor of dread."""
    f = midi_to_hz(root_midi)
    t = tsec(duration)
    voices = (
        lowpass(saw(f, duration, 0.5), f * 3.2) +
        lowpass(saw(f * 1.004, duration, 0.42), f * 2.6) +
        lowpass(saw(f * 0.996, duration, 0.42), f * 2.6) +
        sine(f * 0.5, duration, 0.85)                      # sub, felt not heard
    )
    breath = 1.0 + movement * np.sin(2 * np.pi * 0.045 * t) \
                 + movement * 0.6 * np.sin(2 * np.pi * 0.013 * t + 1.7)
    return (voices * breath * amp).astype(np.float32)


def tape_hiss(duration: float, amp=0.012) -> np.ndarray:
    """Analog medium noise — darkness needs texture, silence needs a floor."""
    return highpass(lowpass(noise(duration, amp), 7000), 900)


def cluster_pad(duration: float, root_midi: float, amp=0.05) -> np.ndarray:
    """Semitone-stacked cluster that beats against itself. Wrongness as harmony."""
    out = np.zeros(int(SR * duration), dtype=np.float32)
    for semi in (0, 1, 6, 13):
        f = midi_to_hz(root_midi + semi)
        out += lowpass(saw(f, duration, 0.3), f * 2.2)
    env = adsr(len(out), duration * 0.35, 0.1, 0.85, duration * 0.4)
    return out * env * amp


def whale_tone(duration: float, start_hz: float, end_hz: float, amp=0.09) -> np.ndarray:
    """Distant rising/falling tone — something very large, very far away."""
    n = int(SR * duration)
    body = pitch_sweep(start_hz, end_hz, duration, amp, curve=0.7)
    body += pitch_sweep(start_hz * 2.01, end_hz * 1.99, duration, amp * 0.2, curve=0.7)
    return (body * adsr(n, duration * 0.4, 0.1, 0.8, duration * 0.5)).astype(np.float32)


def low_tom(freq=68.0, duration=0.24, amp=0.5) -> np.ndarray:
    n = int(SR * duration)
    body = pitch_sweep(freq * 2.1, freq, duration, amp, curve=0.4)
    body *= np.exp(-np.linspace(0, 6.5, n))
    return soften(body, 1.6)


def klaxon_stab(root_hz=190.0, duration=0.30, amp=0.30) -> np.ndarray:
    """Minor-second dyad stab — an alarm that learned to be music."""
    n = int(SR * duration)
    dyad = square(root_hz, duration, 0.55) + square(root_hz * (2 ** (1 / 12.0)), duration, 0.5)
    dyad = lowpass(dyad, root_hz * 6.0)
    return (dyad * adsr(n, 0.004, 0.06, 0.5, 0.08) * amp).astype(np.float32)


def metal_tick(amp=0.2) -> np.ndarray:
    """Relay click / hull tick for irregular ambience."""
    dur = float(RNG.uniform(0.03, 0.09))
    body = bandpass(noise(dur, amp), 1400, 5200)
    return body * adsr(int(SR * dur), 0.001, 0.01, 0.3, 0.02)


def sparse_motif(buf: np.ndarray, duration: float, root_midi: float, scale,
                 note_len=1.6, gap_range=(4.0, 11.0), amp=0.075, vibrato=0.01):
    """Lone phrygian lead notes with long uneasy gaps between them."""
    tpos = float(RNG.uniform(2.0, 5.0))
    while tpos < duration - note_len:
        deg = int(RNG.choice(scale))
        octave = int(RNG.choice([12, 24]))
        f = midi_to_hz(root_midi + deg + octave)
        note = sine(f, note_len, amp, vibrato=vibrato, vib_rate=4.2)
        note *= adsr(len(note), 0.35, 0.2, 0.7, 0.6)
        mix_at(buf, tpos, note, pan=float(RNG.uniform(-0.5, 0.5)))
        tpos += note_len + float(RNG.uniform(*gap_range))


def irregular_ticks(buf: np.ndarray, duration: float, density=(5.0, 14.0), amp=0.16):
    """Randomized hull ticks/knocks — predictable pulses become wallpaper."""
    tpos = float(RNG.uniform(1.5, 4.0))
    while tpos < duration - 0.2:
        mix_at(buf, tpos, metal_tick(amp), pan=float(RNG.uniform(-0.7, 0.7)))
        tpos += float(RNG.uniform(*density))


def heartbeat_unit(amp=0.5) -> np.ndarray:
    """Lub-dub — two soft sub thumps."""
    lub = pitch_sweep(88, 42, 0.14, amp) * np.exp(-np.linspace(0, 7, int(SR * 0.14)))
    dub = pitch_sweep(76, 38, 0.12, amp * 0.75) * np.exp(-np.linspace(0, 7, int(SR * 0.12)))
    gap = np.zeros(int(SR * 0.16), dtype=np.float32)
    return soften(np.concatenate([lub, gap, dub]), 1.5)


# ─── Music tracks ────────────────────────────────────────────────────────────

def new_buf(duration: float) -> np.ndarray:
    return np.zeros((int(SR * duration), 2), dtype=np.float32)


def track_dark_ambient(duration, root, whales=False, clusters=False,
                       motif_scale=PHRYGIAN, motif_amp=0.075, tick_amp=0.16):
    """Shared skeleton for exploration-state tracks: drone + hiss + sparse events."""
    buf = new_buf(duration)
    buf += stereo(drone_bed(duration, root), width=0.3, delay_ms=13)
    buf += stereo(tape_hiss(duration), width=0.4, delay_ms=19)
    sparse_motif(buf, duration, root, motif_scale, amp=motif_amp)
    irregular_ticks(buf, duration, amp=tick_amp)
    if whales:
        for _ in range(max(2, int(duration / 15))):
            st = float(RNG.uniform(3.0, duration - 9.0))
            a, b = sorted(RNG.uniform(52, 130, size=2))
            direction = RNG.choice([1, -1])
            tone = whale_tone(8.0, a if direction > 0 else b, b if direction > 0 else a)
            mix_at(buf, st, stereo(tone, width=0.45, delay_ms=23))
    if clusters:
        tpos = float(RNG.uniform(4.0, 8.0))
        while tpos < duration - 8.0:
            mix_at(buf, tpos, stereo(cluster_pad(7.0, root + 12), width=0.35, delay_ms=17))
            tpos += float(RNG.uniform(9.0, 15.0))
    return soften(buf, 1.1)


def track_combat(duration, root, bpm, phase=0):
    """Driving dark combat: low toms, phrygian sub-bass ostinato, klaxon stabs.
    phase 0 = arena combat; 1..3 = mothership escalation."""
    buf = new_buf(duration)
    beat = 60.0 / bpm
    buf += stereo(drone_bed(duration, root, amp=0.10), width=0.25, delay_ms=11)
    buf += stereo(tape_hiss(duration, 0.008), width=0.4, delay_ms=19)

    # Tom pattern — drops beats irregularly so it never settles
    steps = int(duration / beat)
    for s in range(steps):
        if RNG.random() < (0.12 if phase < 3 else 0.05):
            continue  # dropped beat — the lurch
        accent = 1.25 if s % 4 == 0 else 1.0
        mix_at(buf, s * beat, low_tom(64 if s % 8 else 52, amp=0.5 * accent), pan=0.0)
        if phase >= 2 and s % 2 == 1:
            mix_at(buf, s * beat + beat * 0.5, low_tom(96, 0.16, amp=0.3), pan=float(RNG.uniform(-0.3, 0.3)))

    # Sub-bass ostinato: root, b2, root, b7 — phrygian menace
    pattern = [0, 1, 0, -2]
    for s in range(int(duration / (beat / 2))):
        st = s * beat / 2
        deg = pattern[(s // 2) % len(pattern)]
        f = midi_to_hz(root - 12 + deg)
        bass = lowpass(square(f, beat * 0.4, 0.30), f * 4.0)
        bass *= adsr(len(bass), 0.004, 0.05, 0.4, 0.05)
        mix_at(buf, st, bass, pan=0.0)

    # Klaxon stabs on offbeats, denser per phase
    stab_every = max(2, 8 - phase * 2)
    for s in range(steps):
        if s % stab_every == stab_every - 1:
            mix_at(buf, s * beat + beat * 0.5,
                   klaxon_stab(midi_to_hz(root + 24), amp=0.16 + 0.04 * phase),
                   pan=float(RNG.uniform(-0.5, 0.5)))

    # Phase 2+: siren sweeps; phase 3: heartbeat under everything
    if phase >= 2:
        for _ in range(int(duration / 8)):
            st = float(RNG.uniform(0, duration - 3.5))
            mix_at(buf, st, stereo(pitch_sweep(420, 980, 3.0, 0.05, curve=0.6), width=0.5, delay_ms=27))
    if phase >= 3:
        tpos = 0.5
        while tpos < duration - 1.0:
            mix_at(buf, tpos, heartbeat_unit(0.4))
            tpos += 0.72
    return soften(buf, 1.25)


def track_dawn(duration, root, weary=True):
    """The one dawn — restrained warmth. Brighter because the void got darker."""
    buf = new_buf(duration)
    buf += stereo(tape_hiss(duration, 0.009), width=0.4, delay_ms=19)
    # Low warm pad: root, 5th, maj7, 9 — hope without triumph
    degrees = [0, 7, 11, 14] if not weary else [0, 7, 9, 14]
    for i, deg in enumerate(degrees):
        f = midi_to_hz(root + deg)
        tone = sine(f, duration, 0.10, vibrato=0.004, vib_rate=3.2)
        rise = np.linspace(0, 1, len(tone), dtype=np.float32) ** 0.6
        tone *= rise if duration < 20 else adsr(len(tone), duration * 0.3, 0.2, 0.85, duration * 0.3)
        buf += stereo(tone, width=0.2 + i * 0.05, delay_ms=7 + i * 4)
    buf += stereo(drone_bed(duration, root - 12, amp=0.08, movement=0.03), width=0.25, delay_ms=13)
    # Slow melody: 1 5 6 5 — a hymn hummed by tired lungs
    melody = [0, 7, 9, 7, 12, 9, 7, 4]
    beat = duration / (len(melody) + 2)
    for i, deg in enumerate(melody):
        f = midi_to_hz(root + 12 + deg)
        note = sine(f, beat * 1.4, 0.085, vibrato=0.006, vib_rate=4.5)
        note *= adsr(len(note), 0.3, 0.2, 0.75, 0.5)
        mix_at(buf, beat * (i + 1), note, pan=math.sin(i) * 0.3)
    return soften(buf, 1.1)


def make_music():
    specs = {
        # name: (builder, kwargs)
        'mission_log':       (track_dark_ambient, dict(duration=34, root=33)),
        'inner_rim':         (track_dark_ambient, dict(duration=38, root=38, motif_scale=MINOR, motif_amp=0.09, tick_amp=0.10)),
        'asteroid_fields':   (track_dark_ambient, dict(duration=34, root=36, tick_amp=0.22)),
        'nebula_crossing':   (track_dark_ambient, dict(duration=36, root=31, whales=True, motif_amp=0.05)),
        'alien_territory':   (track_dark_ambient, dict(duration=36, root=34, clusters=True, motif_amp=0.06)),
        'the_frontier':      (track_combat,       dict(duration=40, root=36, bpm=84, phase=0)),
        'alien_combat':      (track_combat,       dict(duration=32, root=33, bpm=132, phase=1)),
        'mothership_phase1': (track_combat,       dict(duration=32, root=33, bpm=120, phase=1)),
        'mothership_phase2': (track_combat,       dict(duration=32, root=32, bpm=140, phase=2)),
        'mothership_phase3': (track_combat,       dict(duration=34, root=31, bpm=156, phase=3)),
        'discovery':         (track_dawn,         dict(duration=15, root=48, weary=False)),
        'golden_shore':      (track_dawn,         dict(duration=45, root=45)),
        'returning':         (track_dawn,         dict(duration=32, root=43)),
    }
    for name, (builder, kwargs) in specs.items():
        write_wav(MUSIC_DIR / f'{name}.wav', builder(**kwargs), peak=0.80)


# ─── SFX ─────────────────────────────────────────────────────────────────────

def impact(duration=0.4, low=90, amp=0.8, sub=0.5):
    """Heavy hit: sub thump + grit + crack. More bass than before — bass is felt."""
    n = int(SR * duration)
    boom = pitch_sweep(low * 2.4, low, duration, amp * 0.75, curve=0.45) * np.exp(-np.linspace(0, 6.5, n))
    subosc = pitch_sweep(low * 0.9, low * 0.5, duration, amp * sub, curve=0.5) * np.exp(-np.linspace(0, 5, n))
    grit = lowpass(noise(duration, amp * 0.5), 900) * np.exp(-np.linspace(0, 5, n))
    crack = highpass(noise(min(0.07, duration), amp), 2800) * adsr(int(SR * min(0.07, duration)), 0.001, 0.01, 0.2, 0.03)
    out = boom + subosc + grit
    out[:len(crack)] += crack
    return soften(out, 1.8)


def chime(notes, each=0.13, root=72, amp=0.45, dark=True):
    """Instrument chime — darker roots, quicker decay than v1. Diegetic hardware."""
    dur = each * len(notes) + 0.25
    out = np.zeros(int(SR * dur), dtype=np.float32)
    for i, semis in enumerate(notes):
        f = midi_to_hz(root + semis)
        sig = combine(
            sine(f, each + 0.18, amp, vibrato=0.003, vib_rate=6),
            sine(f * 2.0, each + 0.14, amp * (0.16 if dark else 0.3)),
        )
        sig *= adsr(len(sig), 0.004, 0.05, 0.4, 0.14)
        start = int(i * each * SR)
        out[start:start + len(sig)] += sig[:len(out) - start]
    return soften(out, 1.2)


def relay_click(pitch_hz=760.0, dur=0.05, amp=0.5) -> np.ndarray:
    """Dry mechanical UI click — a switch on a 70-year-old console."""
    click = bandpass(noise(dur, amp), 900, 4800) * adsr(int(SR * dur), 0.001, 0.012, 0.2, 0.02)
    blip = sine(pitch_hz, dur, amp * 0.35) * adsr(int(SR * dur), 0.001, 0.02, 0.3, 0.02)
    return combine(click, blip)


def save_sfx(name, sig, peak=0.9, stereoize=False):
    data = stereo(sig, width=0.18, delay_ms=5) if stereoize else sig
    write_wav(SFX_DIR / f'{name}.wav', data, peak=peak)


def make_sfx():
    # ── Weapons / player — thinner, sharper; capacitor snap not "pew" ──
    laser = pitch_sweep(1750, 420, 0.13, 0.62, curve=0.6) * adsr(int(SR * .13), .001, .02, .3, .04)
    laser += bandpass(noise(.13, .22), 2400, 9000) * adsr(int(SR * .13), .001, .015, .2, .03)
    save_sfx('laser_fire', soften(laser, 1.5), .84)
    save_sfx('missile_launch', lowpass(noise(.55, .5), 1400) * np.linspace(1, 0, len(tsec(.55))) + pitch_sweep(95, 230, .55, .25), .86)
    save_sfx('emp_pulse', combine(pitch_sweep(220, 1900, .32, .55) * adsr(int(SR * .32), .01, .05, .65, .04), impact(.22, 55, amp=.5)), .86, True)
    save_sfx('emp_fire', pitch_sweep(180, 2100, .42, .55) * adsr(int(SR * .42), .02, .08, .65, .08) + highpass(noise(.42, .1), 3200), .86, True)
    save_sfx('engine_boost', lowpass(saw(62, .75, .4) + saw(87, .75, .22), 900) * np.linspace(.25, 1, len(tsec(.75))), .74)
    save_sfx('shield_hit', combine(chime([10, 4], .06, 69, .34), bandpass(noise(.4, .22), 1200, 6000) * np.exp(-np.linspace(0, 6, int(SR * .4)))), .84, True)
    save_sfx('hull_hit', impact(.4, 62, amp=.85, sub=.7), .9)
    save_sfx('hull_critical', combine(klaxon_stab(178, .5, .8), pitch_sweep(660, 480, .5, .2)), .84)
    save_sfx('craft_explosion', impact(1.5, 42, amp=1.0, sub=.8) + lowpass(noise(1.5, .3), 700) * np.exp(-np.linspace(0, 3, int(SR * 1.5))), .92, True)

    # ── Enemy actions ──
    save_sfx('enemy_laser', pitch_sweep(560, 1150, .15, .6) * adsr(int(SR * .15), .001, .02, .5, .03) * sine(47, .15, 1), .84)
    save_sfx('scout_fire', pitch_sweep(820, 1400, .16, .55) * sine(39, .16, 1), .83)
    save_sfx('warrior_fire', np.concatenate([pitch_sweep(500, 780, .1, .48), np.zeros(int(SR * .03)), pitch_sweep(480, 740, .1, .48), np.zeros(int(SR * .03)), pitch_sweep(450, 700, .1, .48)]), .86)
    save_sfx('enemy_spawn', pitch_sweep(150, 720, .45, .38) * sine(29, .45, 1) + lowpass(noise(.45, .14), 500), .82, True)
    save_sfx('enemy_explode', impact(.62, 66, amp=.8), .88, True)
    save_sfx('scout_destroy', impact(.36, 110, amp=.6), .86)
    save_sfx('warrior_destroy', impact(.68, 76, amp=.8), .88, True)
    save_sfx('destroyer_destroy', impact(1.1, 46, amp=1.0, sub=.8), .92, True)
    for idx, nm in enumerate(['destroyer_attack_a', 'destroyer_attack_b', 'destroyer_attack_c', 'destroyer_attack_d', 'destroyer_attack_e']):
        save_sfx(nm, chime([idx * 2, idx * 2 + 1, idx * 2 - 3], .11, 47, .42) * sine(23 + idx * 7, .58, 1), .84, True)
    save_sfx('elite_appear', combine(cluster_pad(1.1, 55, 3.2)[:int(SR * 1.1)], pitch_sweep(1450, 190, .95, .3)), .86, True)
    save_sfx('elite_blink', pitch_sweep(1800, 340, .22, .56) * sine(64, .22, 1), .84, True)
    save_sfx('mothership_phase_change', combine(impact(.8, 36, amp=.8, sub=.9), klaxon_stab(160, .6, .5)), .92, True)
    save_sfx('gravity_pulse', pitch_sweep(46, 30, .8, .85) * adsr(int(SR * .8), .005, .08, .7, .25), .9, True)
    save_sfx('desperation_charge', pitch_sweep(64, 1350, 1.15, .62) * adsr(int(SR * 1.15), .04, .25, .8, .07) + tape_hiss(1.15, .05), .88, True)

    # ── The Silence (stalker) ──
    shriek = pitch_sweep(240, 2400, .7, .5, curve=1.8) * sine(31, .7, 1.0)
    shriek += pitch_sweep(180, 1100, .7, .3, curve=2.2)
    shriek = combine(soften(shriek, 2.2) * adsr(int(SR * .7), .05, .1, .85, .12), impact(.3, 44, amp=.5, sub=.8))
    save_sfx('stalker_decloak', shriek, .9, True)
    drone = sine(38, 2.2, .6) + sine(38.7, 2.2, .5) + sine(57, 2.2, .18, vibrato=.02, vib_rate=.8)
    save_sfx('stalker_drone', (drone * adsr(int(SR * 2.2), .6, .2, .8, .8)), .78, True)

    # ── Dread layer ──
    ping = bandpass(sine(1180, .11, .9) * adsr(int(SR * .11), .012, .03, .5, .06), 700, 2400)
    echo = np.zeros(int(SR * .36), dtype=np.float32)
    echo[:len(ping)] = ping
    echo[int(SR * .18):int(SR * .18) + len(ping)] += ping * 0.28
    save_sfx('tracker_ping', echo, .8)
    save_sfx('heartbeat', heartbeat_unit(0.85), .8)
    groan = lowpass(saw(52, 1.5, .5) + saw(57.3, 1.5, .4), 220)
    groan *= adsr(int(SR * 1.5), .5, .2, .8, .55)
    groan += bandpass(noise(1.5, .12), 300, 1400) * adsr(int(SR * 1.5), .6, .2, .5, .5)
    save_sfx('hull_groan', soften(groan, 1.6), .74, True)
    save_sfx('graze_spark', bandpass(noise(.05, .8), 3200, 10000) * adsr(int(SR * .05), .001, .01, .3, .02) + sine(2300, .05, .2), .55)
    carrier = sine(720, .9, .3, vibrato=.06, vib_rate=11)
    static = bandpass(noise(.9, .5), 400, 3000) * (RNG.random(int(SR * .9)) > 0.35)
    save_sfx('derelict_log', (carrier + static.astype(np.float32) * .4) * adsr(int(SR * .9), .02, .1, .7, .3), .68, True)
    alarm = np.concatenate([klaxon_stab(196, .28, .9), np.zeros(int(SR * .07), dtype=np.float32), klaxon_stab(139, .32, .9)])
    save_sfx('alarm_danger', alarm, .78)

    # ── Hazards / environment ──
    save_sfx('missile_explode', impact(.85, 54, amp=.9, sub=.65), .9, True)
    save_sfx('asteroid_small', impact(.24, 150, amp=.45, sub=.2), .8)
    save_sfx('asteroid_medium', impact(.44, 100, amp=.6, sub=.35), .84)
    save_sfx('asteroid_large', impact(.72, 60, amp=.8, sub=.55), .88, True)
    save_sfx('asteroid_break', impact(.48, 90, amp=.68, sub=.3), .84)
    save_sfx('mine_armed', combine(relay_click(900, .07, .7), pitch_sweep(600, 840, .28, .26)), .78)
    save_sfx('mine_explode', impact(.95, 48, amp=.95, sub=.7) + highpass(noise(.95, .12), 2600), .9, True)
    save_sfx('sector_transition', pitch_sweep(85, 1150, 1.35, .42) + lowpass(noise(1.35, .2), 600) + sine(43, 1.35, .3), .86, True)
    save_sfx('star_cluster_arrive', combine(chime([0, 3, 7], .12, 57, .4), sine(38, .8, .3) * adsr(int(SR * .8), .1, .1, .8, .3)), .84, True)
    save_sfx('arena_clear', chime([0, 3, 7, 10], .12, 59, .48), .86, True)
    save_sfx('wave_clear', chime([0, 7, 10], .1, 57, .4), .84, True)

    # ── Pickups / UI / scanning — dry hardware, not toy chimes ──
    save_sfx('collect_crystal', chime([0, 7], .07, 74, .34), .8)
    save_sfx('collect_fuel', chime([0, 5], .08, 64, .32), .8)
    save_sfx('collect_repair', combine(chime([0, 3], .08, 62, .3), relay_click(500, .06, .4)), .78)
    save_sfx('collect_weapon', combine(relay_click(420, .07, .5), chime([0, 5], .08, 59, .28)), .8)
    save_sfx('pickup_collect', chime([0, 5], .07, 67, .3), .78)
    save_sfx('beacon_collected', chime([0, 3, 7, 12, 19], .15, 57, .5, dark=False), .88, True)
    save_sfx('ui_navigate', relay_click(820, .045, .55), .5)
    save_sfx('ui_confirm', combine(relay_click(660, .06, .5), sine(660, .09, .12) * adsr(int(SR * .09), .002, .03, .4, .04)), .68)
    save_sfx('ui_cancel', relay_click(340, .07, .5), .66)
    save_sfx('upgrade_select', combine(relay_click(540, .07, .5), chime([0, 7], .08, 62, .3)), .76)
    save_sfx('typewriter_click', bandpass(noise(.03, .35), 1500, 6500), .46)
    scan_up = pitch_sweep(310, 1180, .75, .4) * adsr(int(SR * .75), .02, .18, .7, .1) + tape_hiss(.75, .04)
    save_sfx('scan_begin', scan_up, .8, True)
    save_sfx('scan_start', scan_up, .8, True)
    save_sfx('scan_complete', chime([0, 4, 7, 12], .11, 69, .42, dark=False), .84, True)
    save_sfx('scan_abort', combine(pitch_sweep(1100, 170, .6, .42), relay_click(300, .08, .5)), .82, True)


def main():
    make_music()
    make_sfx()
    print(f"Generated {len(list(MUSIC_DIR.glob('*.wav')))} music WAVs and {len(list(SFX_DIR.glob('*.wav')))} SFX WAVs")


if __name__ == '__main__':
    main()
