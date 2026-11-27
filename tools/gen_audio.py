#!/usr/bin/env python3
"""Gera os sons provisórios de BENTEVI por síntese (sem samples de terceiros).

Uso: python3 tools/gen_audio.py   (precisa de numpy e ffmpeg com libvorbis)
Saída: assets/audio/*.ogg
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(1924)


def t(seconds):
    return np.arange(int(SR * seconds)) / SR


def env(n, attack=0.005, release=0.2, total=None):
    total = total or n / SR
    x = np.arange(n) / SR
    a = np.clip(x / max(attack, 1e-4), 0, 1)
    r = np.clip((total - x) / max(release, 1e-4), 0, 1)
    return a * r


def decay(n, rate):
    return np.exp(-np.arange(n) / SR * rate)


def noise(seconds):
    return rng.uniform(-1, 1, int(SR * seconds))


def lowpass(x, cutoff):
    # Filtro de 1 polo, suficiente para sons de ambiente.
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def bandpass(x, low, high):
    return lowpass(x, high) - lowpass(x, low)


def brown(seconds):
    w = noise(seconds)
    b = np.cumsum(w)
    b -= lowpass(b, 2.0)
    return b / (np.max(np.abs(b)) + 1e-9)


def bell(freq, seconds, rate=3.0, partials=((1, 1), (2.76, 0.5), (5.4, 0.25), (8.9, 0.12))):
    x = t(seconds)
    s = sum(a * np.sin(2 * np.pi * freq * m * x) * decay(len(x), rate * (1 + m * 0.4)) for m, a in partials)
    return s * env(len(x), 0.002, 0.05)


def music_box(freq, seconds):
    x = t(seconds)
    s = np.sin(2 * np.pi * freq * x) + 0.3 * np.sin(4 * np.pi * freq * x) + 0.08 * np.sin(6.3 * np.pi * freq * x)
    return s * decay(len(x), 2.2) * env(len(x), 0.003, 0.3)


def chirp(f0, f1, seconds, amp=1.0):
    x = t(seconds)
    f = np.linspace(f0, f1, len(x))
    phase = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(phase) + 0.25 * np.sin(2 * phase)
    return amp * s * np.sin(np.pi * np.linspace(0, 1, len(x))) ** 0.6


def place(dst, src, at):
    i = int(at * SR)
    end = min(len(dst), i + len(src))
    dst[i:end] += src[: end - i]
    return dst


def silence(seconds):
    return np.zeros(int(SR * seconds))


def normalize(x, peak=0.85):
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def loopable(x, fade=1.5):
    # Funde o fim no começo para o laço não ter emenda audível.
    n = int(fade * SR)
    head, body, tail = x[:n], x[n:-n], x[-n:]
    ramp = np.linspace(0, 1, n)
    return np.concatenate([tail * (1 - ramp) + head * ramp, body])


def save(name, x, quality=4):
    os.makedirs(OUT, exist_ok=True)
    data = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        path = tmp.name
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    out = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-c:a", "libvorbis", "-q:a", str(quality), out], check=True)
    os.remove(path)
    print("ok", name, f"{len(x) / SR:.1f}s")


# --- Efeitos --------------------------------------------------------------

def sfx_click():
    n = noise(0.05) * decay(int(SR * 0.05), 120)
    return normalize(bandpass(n, 800, 4000) + 0.3 * bell(1400, 0.05, 60), 0.5)


def sfx_pickup():
    rustle = bandpass(noise(0.25), 1500, 7000) * env(int(SR * 0.25), 0.02, 0.15) * 0.4
    s = place(silence(0.7), rustle, 0)
    s = place(s, 0.5 * bell(1318, 0.5, 6), 0.08)
    s = place(s, 0.4 * bell(1760, 0.45, 6), 0.18)
    return normalize(s, 0.6)


def sfx_shutter():
    s = silence(0.6)
    s = place(s, bandpass(noise(0.03), 2000, 9000) * 1.2, 0)
    s = place(s, 0.6 * bell(2400, 0.06, 80), 0)
    whir = bandpass(noise(0.25), 300, 1200) * env(int(SR * 0.25), 0.05, 0.1) * 0.35
    s = place(s, whir, 0.06)
    s = place(s, bandpass(noise(0.025), 2000, 9000), 0.32)
    s = place(s, 0.5 * bell(1900, 0.06, 80), 0.32)
    return normalize(s, 0.7)


def sfx_enter_past():
    d = 2.2
    swell = bandpass(noise(d), 200, 3000) * np.linspace(0, 1, int(SR * d)) ** 2 * env(int(SR * d), 0.01, 0.25)
    s = 0.6 * swell
    s = place(s, 0.7 * bell(523, 1.8, 1.5), 0.9)
    s = place(s, 0.4 * bell(784, 1.6, 1.8), 1.0)
    return normalize(s, 0.75)


def sfx_leave_past():
    d = 1.4
    sweep = bandpass(noise(d), 150, 2000) * np.linspace(1, 0, int(SR * d)) ** 1.5
    s = 0.6 * sweep
    s = place(s, 0.5 * bell(392, 1.3, 2.5), 0.0)
    return normalize(s, 0.6)


def sfx_lock_open():
    s = silence(0.5)
    for at, f in ((0.0, 3200), (0.12, 2600), (0.2, 1800)):
        s = place(s, 0.6 * bell(f, 0.15, 40), at)
        s = place(s, bandpass(noise(0.02), 2000, 8000) * 0.5, at)
    return normalize(s, 0.6)


def sfx_lock_fail():
    x = t(0.35)
    thud = np.sin(2 * np.pi * 90 * x) * decay(len(x), 18)
    rattle = bandpass(noise(0.15), 1500, 5000) * decay(int(SR * 0.15), 30) * 0.4
    return normalize(place(thud, rattle, 0.02), 0.6)


def sfx_drawer():
    d = 0.7
    x = t(d)
    grain = bandpass(noise(d), 120, 900) * (0.6 + 0.4 * np.sin(2 * np.pi * 23 * x)) * env(len(x), 0.05, 0.15)
    s = place(silence(0.9), grain, 0)
    s = place(s, np.sin(2 * np.pi * 110 * t(0.2)) * decay(int(SR * 0.2), 25) * 0.8, 0.66)
    return normalize(s, 0.6)


def sfx_bird():
    # Bem-te-vi: três sílabas, "bem — te — VI".
    s = silence(1.3)
    s = place(s, chirp(2600, 3300, 0.16, 0.8), 0.0)
    s = place(s, chirp(3000, 2700, 0.12, 0.7), 0.24)
    s = place(s, chirp(2400, 3900, 0.28, 1.0), 0.44)
    return normalize(s, 0.7)


def sfx_tick():
    s = bandpass(noise(0.03), 1500, 6000) * decay(int(SR * 0.03), 150)
    return normalize(s + 0.4 * bell(2200, 0.03, 120), 0.5)


def sfx_chime():
    s = silence(3.5)
    for i in range(3):
        s = place(s, bell(220, 2.4, 1.4), i * 0.9)
    return normalize(s, 0.7)


def sfx_match():
    s = silence(1.2)
    strike = bandpass(noise(0.18), 1500, 8000) * env(int(SR * 0.18), 0.005, 0.1)
    s = place(s, strike, 0)
    flame = lowpass(noise(0.9), 600) * env(int(SR * 0.9), 0.05, 0.6) * 2.5
    s = place(s, flame, 0.15)
    return normalize(s, 0.6)


def sfx_whistle():
    d = 2.6
    x = t(d)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * x)
    tone = sum(np.sin(2 * np.pi * f * vib * x) for f in (392, 494, 587)) / 3
    air = bandpass(noise(d), 400, 3000) * 0.25
    return normalize((tone + air) * env(len(x), 0.15, 0.8), 0.6)


def sfx_page():
    d = 0.35
    s = bandpass(noise(d), 1000, 6000) * env(int(SR * d), 0.03, 0.2) * (0.5 + 0.5 * np.sin(np.pi * np.linspace(0, 1, int(SR * d))))
    return normalize(s, 0.45)


def sfx_reveal():
    s = silence(1.6)
    for i, f in enumerate((659, 784, 988, 1319)):
        s = place(s, 0.5 * bell(f, 1.0, 3), i * 0.12)
    return normalize(s, 0.6)


def sfx_name():
    s = silence(3.0)
    s = place(s, bell(147, 2.8, 1.1), 0)
    s = place(s, 0.4 * bell(220, 2.4, 1.4), 0.05)
    return normalize(s, 0.6)


def sfx_coffin():
    s = silence(2.5)
    creak = chirp(180, 90, 1.4, 0.6) + bandpass(noise(1.4), 200, 1200) * 0.3
    s = place(s, creak * env(len(creak), 0.2, 0.4), 0)
    s = place(s, np.sin(2 * np.pi * 60 * t(0.6)) * decay(int(SR * 0.6), 8), 1.4)
    return normalize(s, 0.7)


# --- Ambientes e música ----------------------------------------------------

def amb_1924():
    d = 34
    x = t(d)
    wind = lowpass(brown(d), 500) * (0.55 + 0.45 * np.sin(2 * np.pi * x / 11.0) ** 2)
    drone = (np.sin(2 * np.pi * 55 * x) + 0.6 * np.sin(2 * np.pi * 55.4 * x) + 0.3 * np.sin(2 * np.pi * 82.5 * x)) * 0.12
    s = wind * 0.8 + drone
    for at in (5.0, 17.5, 26.0):
        s = place(s, 0.08 * bell(880, 2.0, 2.0), at)
    return normalize(loopable(s), 0.5)


def amb_1899():
    d = 34
    x = t(d)
    room = lowpass(brown(d), 900) * 0.25
    pad = sum(a * np.sin(2 * np.pi * f * x) for f, a in ((110, 0.5), (165, 0.35), (220, 0.25), (277.2, 0.15)))
    pad *= 0.12 * (0.7 + 0.3 * np.sin(2 * np.pi * x / 9.0))
    s = room + pad
    for at in (3.0, 12.0, 21.5, 29.0):
        s = place(s, 0.15 * chirp(3200, 3800, 0.1), at)
        s = place(s, 0.12 * chirp(3600, 3000, 0.08), at + 0.15)
    return normalize(loopable(s), 0.45)


def music_menu():
    # Caixinha de música em lá menor, lenta e um pouco desafinada.
    beat = 0.5
    progression = [
        (220, (440, 523, 659, 523)), (175, (440, 523, 698, 523)),
        (196, (392, 494, 587, 494)), (165, (415, 494, 659, 494)),
    ]
    bars = progression * 2
    d = len(bars) * 4 * beat + 2.0
    s = silence(d)
    for b, (bass, notes) in enumerate(bars):
        at = b * 4 * beat
        s = place(s, 0.5 * music_box(bass, 2.2), at)
        for i, f in enumerate(notes):
            detune = 1 + rng.uniform(-0.003, 0.003)
            s = place(s, 0.35 * music_box(f * detune, 1.4), at + i * beat)
    s = s + lowpass(brown(d), 300) * 0.04
    return normalize(loopable(s, 2.0), 0.5)


if __name__ == "__main__":
    for name, fn in [
        ("click", sfx_click), ("pickup", sfx_pickup), ("shutter", sfx_shutter),
        ("enter_past", sfx_enter_past), ("leave_past", sfx_leave_past),
        ("lock_open", sfx_lock_open), ("lock_fail", sfx_lock_fail), ("drawer", sfx_drawer),
        ("bird", sfx_bird), ("tick", sfx_tick), ("chime", sfx_chime), ("match", sfx_match),
        ("whistle", sfx_whistle), ("page", sfx_page), ("reveal", sfx_reveal),
        ("name", sfx_name), ("coffin", sfx_coffin),
    ]:
        save(name, fn())
    save("amb_1924", amb_1924(), 3)
    save("amb_1899", amb_1899(), 3)
    save("music_menu", music_menu(), 3)
