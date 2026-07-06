#!/usr/bin/env python3
"""Generate deterministic procedural music and SFX for NOVA SCOUT.

The assets intentionally use analog-sci-fi ingredients from the audio GDD:
theremin-like sine leads, Moog-ish basses, ring modulation, filtered noise,
metallic impacts, pitch sweeps, and restrained stereo width. No external
samples are used.
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
RNG = np.random.default_rng(1957)

MOTIF = [0, 3, 7]
SCALE_MINOR = [0, 2, 3, 5, 7, 8, 10]
SCALE_MAJOR = [0, 2, 4, 5, 7, 9, 11]


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
        env[a:a+d] = np.linspace(1.0, sustain, d, dtype=np.float32)
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


def square(freq, duration, amp=1.0, duty=0.5):
    t = tsec(duration)
    return amp * np.where((t * freq) % 1.0 < duty, 1.0, -1.0).astype(np.float32)


def saw(freq, duration, amp=1.0):
    t = tsec(duration)
    return amp * (2.0 * ((t * freq) % 1.0) - 1.0).astype(np.float32)


def noise(duration, amp=1.0):
    return amp * RNG.uniform(-1.0, 1.0, int(SR * duration)).astype(np.float32)


def soften(x: np.ndarray, drive=1.3) -> np.ndarray:
    return np.tanh(x * drive).astype(np.float32)


def lowpass(x: np.ndarray, alpha=0.08) -> np.ndarray:
    y = np.empty_like(x, dtype=np.float32)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (float(v) - acc)
        y[i] = acc
    return y


def highpass(x: np.ndarray, alpha=0.96) -> np.ndarray:
    y = np.empty_like(x, dtype=np.float32)
    prev_y = 0.0
    prev_x = 0.0
    for i, v in enumerate(x):
        yv = alpha * (prev_y + float(v) - prev_x)
        y[i] = yv
        prev_y, prev_x = yv, float(v)
    return y


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
    if idx >= len(buf):
        return
    n = min(len(sig), len(buf) - idx)
    if sig.ndim == 1:
        l = sig[:n] * math.cos((pan + 1) * math.pi / 4)
        r = sig[:n] * math.sin((pan + 1) * math.pi / 4)
        buf[idx:idx+n, 0] += l
        buf[idx:idx+n, 1] += r
    else:
        buf[idx:idx+n] += sig[:n]


def chord(root_midi, degrees, duration, amp=0.12, wave='saw'):
    out = np.zeros(int(SR * duration), dtype=np.float32)
    for deg in degrees:
        f = midi_to_hz(root_midi + deg)
        tone = saw(f, duration, amp) if wave == 'saw' else sine(f, duration, amp)
        out += lowpass(tone, 0.025)
    return out * adsr(len(out), 0.8, 0.5, 0.75, 1.2)


def music_track(name: str, duration: float, root=45, bpm=96, mood='explore'):
    buf = np.zeros((int(SR * duration), 2), dtype=np.float32)
    beat = 60.0 / bpm
    scale = SCALE_MAJOR if mood in {'hope', 'victory'} else SCALE_MINOR
    progression = [0, 5, 3, 7] if mood != 'alien' else [0, 1, 6, 2]

    # Drones and pads.
    for i, deg in enumerate(progression * int(duration / (beat * 16) + 2)):
        st = i * beat * 4
        if st >= duration:
            break
        pad = chord(root + deg, [0, 7, 12, 15 if mood != 'alien' else 13], beat * 4.4, 0.055, 'saw')
        pad_t = np.arange(len(pad), dtype=np.float32) / SR
        pad *= 1.0 + 0.12 * np.sin(2 * np.pi * 0.11 * pad_t)
        mix_at(buf, st, pad, pan=-0.25 if i % 2 else 0.25)

    # Bass pulse / Moog line.
    steps = int(duration / (beat / 2))
    for s in range(steps):
        st = s * beat / 2
        deg = progression[(s // 8) % len(progression)]
        note = root - 12 + deg + (0 if s % 4 else 12)
        bass = lowpass(square(midi_to_hz(note), beat * 0.42, 0.18), 0.035)
        bass *= adsr(len(bass), 0.005, 0.08, 0.35, 0.06)
        if mood in {'combat', 'boss'} or (mood == 'alien' and s % 2 == 0):
            mix_at(buf, st, bass, pan=0.0)
        elif s % 4 == 0:
            mix_at(buf, st, bass * 0.6, pan=0.0)

    # Theremin motif / alien ring-mod line.
    phrase = MOTIF if mood != 'alien' else [0, 1, 6, 10]
    for i in range(int(duration / (beat * 2))):
        st = i * beat * 2 + beat * 0.35
        deg = phrase[i % len(phrase)]
        f = midi_to_hz(root + 24 + deg + (12 if mood == 'victory' and i % 5 == 4 else 0))
        lead = sine(f, beat * 1.35, 0.13, vibrato=0.012 if mood != 'alien' else 0.028, vib_rate=5.5)
        if mood == 'alien':
            lead *= sine(37 + (i % 3) * 11, beat * 1.35, 1.0)
        lead *= adsr(len(lead), 0.08, 0.15, 0.65, 0.2)
        mix_at(buf, st, lead, pan=-0.45 + 0.9 * ((i % 4) / 3.0))

    # Drums/noisy impacts.
    if mood in {'combat', 'boss', 'alien'}:
        for s in range(int(duration / beat)):
            st = s * beat
            kick = pitch_sweep(115, 42, 0.18, 0.42) * np.exp(-np.linspace(0, 7, int(SR * 0.18)))
            mix_at(buf, st, soften(kick), pan=0)
            if s % 2 == 1:
                sn = highpass(noise(0.13, 0.24), 0.82) * adsr(int(SR * 0.13), 0.002, 0.03, 0.15, 0.06)
                mix_at(buf, st + beat * 0.5, sn, pan=0.1)
        for s in range(int(duration / (beat / 2))):
            if s % 3 != 0:
                hat = highpass(noise(0.035, 0.08), 0.7) * adsr(int(SR * 0.035), 0.001, 0.008, 0.15, 0.02)
                mix_at(buf, s * beat / 2, hat, pan=-0.35 if s % 2 else 0.35)

    # Space texture.
    bed = lowpass(noise(duration, 0.025), 0.004)
    shimmer = highpass(noise(duration, 0.014), 0.995)
    buf += stereo(bed + shimmer, width=0.35, delay_ms=15)
    return soften(buf, 1.15)


def make_music():
    specs = {
        'mission_log': (34, 43, 72, 'explore'),
        'inner_rim': (38, 45, 100, 'hope'),
        'asteroid_fields': (34, 44, 118, 'explore'),
        'alien_combat': (32, 42, 142, 'combat'),
        'nebula_crossing': (36, 41, 66, 'explore'),
        'discovery': (15, 48, 76, 'victory'),
        'alien_territory': (36, 40, 116, 'alien'),
        'the_frontier': (40, 47, 124, 'victory'),
        'mothership_phase1': (32, 42, 138, 'boss'),
        'mothership_phase2': (32, 43, 152, 'alien'),
        'mothership_phase3': (34, 44, 160, 'boss'),
        'golden_shore': (45, 48, 82, 'victory'),
        'returning': (32, 45, 72, 'hope'),
    }
    for name, (dur, root, bpm, mood) in specs.items():
        data = music_track(name, dur, root=root, bpm=bpm, mood=mood)
        if name == 'discovery':
            # Add a warmer resolving swell.
            swell = np.zeros_like(data)
            for n, deg in enumerate([0, 3, 7, 12, 15, 19]):
                tone = sine(midi_to_hz(root + deg), dur, 0.07, vibrato=0.004, vib_rate=3.5)
                tone *= np.linspace(0, 1, len(tone)) ** 0.7
                swell += stereo(tone, width=0.2 + n * 0.025, delay_ms=5 + n)
            data += swell
        write_wav(MUSIC_DIR / f'{name}.wav', data, peak=0.82)


def impact(duration=0.4, low=90, high=900, amp=0.8):
    n = int(SR * duration)
    boom = pitch_sweep(low * 2.4, low, duration, amp * 0.75, curve=0.45) * np.exp(-np.linspace(0, 7, n))
    grit = lowpass(noise(duration, amp * 0.5), 0.12) * np.exp(-np.linspace(0, 5, n))
    crack = highpass(noise(min(0.08, duration), amp), 0.65) * adsr(int(SR * min(0.08, duration)), 0.001, 0.01, 0.2, 0.04)
    out = boom + grit
    out[:len(crack)] += crack
    return soften(out, 1.8)


def chime(notes, each=0.13, root=72, amp=0.45):
    dur = each * len(notes) + 0.25
    out = np.zeros(int(SR * dur), dtype=np.float32)
    for i, semis in enumerate(notes):
        sig = combine(
            sine(midi_to_hz(root + semis), each + 0.22, amp, vibrato=0.004, vib_rate=6),
            sine(midi_to_hz(root + semis + 12), each + 0.2, amp * 0.24),
        )
        sig *= adsr(len(sig), 0.004, 0.04, 0.45, 0.18)
        start = int(i * each * SR)
        out[start:start+len(sig)] += sig[:len(out)-start]
    return soften(out, 1.2)


def save_sfx(name, sig, peak=0.9, stereoize=False):
    data = stereo(sig, width=0.18, delay_ms=5) if stereoize else sig
    write_wav(SFX_DIR / f'{name}.wav', data, peak=peak)


def combine(*signals: np.ndarray) -> np.ndarray:
    n = max(len(s) for s in signals)
    out = np.zeros(n, dtype=np.float32)
    for s in signals:
        out[:len(s)] += s.astype(np.float32)
    return out


def make_sfx():
    # Weapons / player.
    save_sfx('laser_fire', pitch_sweep(1450, 460, 0.18, 0.7) * adsr(int(SR*.18), .002, .025, .35, .045) + highpass(noise(.18,.09),.88), .86)
    save_sfx('missile_launch', lowpass(noise(.55,.45),.05) * np.linspace(1,0,len(tsec(.55))) + pitch_sweep(110, 250, .55, .22), .84)
    save_sfx('emp_pulse', combine(pitch_sweep(220, 1900, .32, .55) * adsr(int(SR*.32), .01, .05, .65, .04), impact(.22, 55, amp=.45)), .86, True)
    save_sfx('emp_fire', pitch_sweep(180, 2100, .42, .55) * adsr(int(SR*.42), .02, .08, .65, .08) + highpass(noise(.42,.08),.92), .86, True)
    save_sfx('engine_boost', lowpass(saw(68,.75,.35)+saw(92,.75,.2),.03) * np.linspace(.25,1,len(tsec(.75))), .72)
    save_sfx('shield_hit', combine(chime([12, 7, 3], .06, 72, .38), highpass(noise(.45,.18),.93)), .84, True)
    save_sfx('hull_hit', impact(.34, 72, amp=.75), .88)
    save_sfx('hull_critical', combine(chime([0], .18, 48, .5), pitch_sweep(720, 520, .42, .24)), .82)
    save_sfx('craft_explosion', impact(1.3, 45, amp=1.0) + lowpass(noise(1.3,.28),.08) * np.exp(-np.linspace(0,3,int(SR*1.3))), .9, True)

    # Enemy actions.
    save_sfx('enemy_laser', pitch_sweep(620, 1250, .16, .62) * adsr(int(SR*.16), .001, .02, .5, .035) * sine(51,.16,1), .86)
    save_sfx('scout_fire', pitch_sweep(900, 1500, .18, .55) * sine(39,.18,1), .85)
    save_sfx('warrior_fire', np.concatenate([pitch_sweep(520,820,.11,.45), np.zeros(int(SR*.035)), pitch_sweep(500,760,.11,.45), np.zeros(int(SR*.035)), pitch_sweep(470,720,.11,.45)]), .86)
    save_sfx('enemy_spawn', pitch_sweep(170, 780, .42, .36) * sine(29,.42,1) + lowpass(noise(.42,.12),.05), .82, True)
    save_sfx('enemy_explode', impact(.62, 70, amp=.8), .88, True)
    save_sfx('scout_destroy', impact(.36, 120, amp=.56), .86)
    save_sfx('warrior_destroy', impact(.68, 82, amp=.78), .88, True)
    save_sfx('destroyer_destroy', impact(1.05, 48, amp=1.0), .9, True)
    for idx, nm in enumerate(['destroyer_attack_a','destroyer_attack_b','destroyer_attack_c','destroyer_attack_d','destroyer_attack_e']):
        save_sfx(nm, chime([idx*2, idx*2+5, idx*2+1], .11, 50, .42) * sine(23+idx*7, .58, 1), .84, True)
    save_sfx('elite_appear', combine(chime([12, 7, 3, 0], .16, 67, .46), pitch_sweep(1550, 220, .95, .28)), .86, True)
    save_sfx('elite_blink', pitch_sweep(1800, 380, .24, .56) * sine(64,.24,1), .84, True)
    save_sfx('mothership_phase_change', combine(impact(.7, 38, amp=.75), chime([0,6,13], .12, 43, .35)), .9, True)
    save_sfx('gravity_pulse', pitch_sweep(48, 33, .75, .8) * adsr(int(SR*.75), .005, .08, .7, .25), .88, True)
    save_sfx('desperation_charge', pitch_sweep(70, 1400, 1.1, .62) * adsr(int(SR*1.1), .04, .25, .8, .07), .88, True)

    # Impacts, hazards, environment.
    save_sfx('missile_explode', impact(.82, 58, amp=.9), .9, True)
    save_sfx('asteroid_small', impact(.24, 160, amp=.42), .82)
    save_sfx('asteroid_medium', impact(.44, 105, amp=.58), .84)
    save_sfx('asteroid_large', impact(.72, 64, amp=.78), .88, True)
    save_sfx('asteroid_break', impact(.48, 95, amp=.66), .84)
    save_sfx('mine_armed', combine(chime([0, -1], .09, 64, .35), pitch_sweep(620, 850, .26, .24)), .8)
    save_sfx('mine_explode', impact(.9, 52, amp=.92) + highpass(noise(.9,.12),.9), .9, True)
    save_sfx('sector_transition', pitch_sweep(95, 1220, 1.3, .42) + lowpass(noise(1.3,.18),.04), .86, True)
    save_sfx('star_cluster_arrive', chime([0,3,7,12], .1, 60, .42), .84, True)
    save_sfx('arena_clear', chime([0,4,7,12], .12, 62, .5), .86, True)
    save_sfx('wave_clear', chime([0,7,12], .1, 60, .42), .84, True)

    # Pickups/UI/scanning.
    save_sfx('collect_crystal', chime([0,7,12], .07, 78, .36), .82)
    save_sfx('collect_fuel', chime([0,4,7], .08, 67, .34), .82)
    save_sfx('collect_repair', combine(chime([0,3,7], .08, 65, .32), impact(.16, 220, amp=.18)), .8)
    save_sfx('collect_weapon', combine(impact(.16, 180, amp=.24), chime([0,5], .08, 62, .3)), .82)
    save_sfx('pickup_collect', chime([0,4,9], .07, 70, .33), .82)
    save_sfx('beacon_collected', chime([0,3,7,12,19], .16, 60, .5), .88, True)
    save_sfx('ui_navigate', highpass(noise(.045,.2),.85) + sine(880,.045,.16), .55)
    save_sfx('ui_confirm', chime([0,7], .07, 72, .3), .72)
    save_sfx('ui_cancel', chime([7,0], .08, 68, .28), .72)
    save_sfx('upgrade_select', combine(impact(.16, 190, amp=.2), chime([0,4,12], .08, 65, .35)), .78)
    save_sfx('typewriter_click', highpass(noise(.035,.24),.78), .48)
    save_sfx('scan_begin', pitch_sweep(330, 1250, .72, .42) * adsr(int(SR*.72), .02, .18, .7, .1), .82, True)
    save_sfx('scan_start', pitch_sweep(330, 1250, .72, .42) * adsr(int(SR*.72), .02, .18, .7, .1), .82, True)
    save_sfx('scan_complete', chime([0,4,7,12], .11, 72, .42), .84, True)
    save_sfx('scan_abort', combine(pitch_sweep(1150, 190, .65, .42), chime([5,1], .11, 58, .24)), .82, True)


def main():
    make_music()
    make_sfx()
    print(f"Generated {len(list(MUSIC_DIR.glob('*.wav')))} music WAVs and {len(list(SFX_DIR.glob('*.wav')))} SFX WAVs")


if __name__ == '__main__':
    main()

