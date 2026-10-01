"""無人島に持っていくもの — 音楽と効果音をプログラムで合成して audio/ に WAV で書き出す。
    py -3.10 tools/gen_audio.py            （全部）
    py -3.10 tools/gen_audio.py ok pop     （名前を指定するとそれだけ）

bgm … 南国っぽい軽いウクレレ＋マリンバ（96BPM、C-Am-F-G、12小節=30秒ループ）
"""
import os
import sys
import wave
import numpy as np
from scipy import signal

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
rng = np.random.default_rng(20261001)
ONLY = set(sys.argv[1:])


def save(name, x, peak=0.85):
    if ONLY and name not in ONLY:
        return
    x = np.asarray(x, dtype=np.float64)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())
    print(f"{name:10s} {len(x) / SR:6.2f}s")


def T(d):
    return np.arange(int(d * SR)) / SR


def N(d):
    return rng.standard_normal(int(d * SR))


def lp(x, f, o=2):
    return signal.sosfilt(signal.butter(o, min(f, SR / 2 - 100) / (SR / 2), "low", output="sos"), x)


def hp(x, f, o=2):
    return signal.sosfilt(signal.butter(o, f / (SR / 2), "high", output="sos"), x)


def bp(x, lo, hi, o=2):
    return signal.sosfilt(signal.butter(o, [lo / (SR / 2), min(hi, SR / 2 - 100) / (SR / 2)], "band", output="sos"), x)


def att(x, a=0.003):
    t = T(len(x) / SR)
    return x * (1 - np.exp(-t / a))


def bell(f, d, tau=0.25, h=(1, 2.01, 3.2), amp=(1, 0.4, 0.2)):
    t = T(d)
    y = sum(a * np.sin(2 * np.pi * f * k * t) for k, a in zip(h, amp))
    return att(y * np.exp(-t / tau))


def pluck(f, d, vol=1.0):
    t = T(d)
    y = sum((1 / k ** 1.3) * np.sin(2 * np.pi * f * k * t) * np.exp(-t * (3.2 + 2.4 * k)) for k in range(1, 7))
    return att(y) * vol


def marimba(f, d, vol=1.0):
    t = T(d)
    y = np.sin(2 * np.pi * f * t) * np.exp(-t * 5.5) + 0.35 * np.sin(2 * np.pi * f * 4.0 * t) * np.exp(-t * 22)
    return att(y) * vol


def mix(buf, y, at):
    i = int(at * SR)
    n = min(len(y), len(buf) - i)
    if n > 0:
        buf[i:i + n] += y[:n]


# ---------------------------------------------------------------- 効果音
def want(n):
    return not ONLY or n in ONLY


if want("ok"):
    b = np.zeros(int(0.6 * SR))
    mix(b, bell(880, 0.5, 0.15), 0)
    mix(b, bell(1318, 0.5, 0.2), 0.09)
    save("ok", b)
if want("pop"):
    t = T(0.12)
    f = 300 * (1000 / 300) ** (t / 0.12)
    save("pop", np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.04))
if want("ding"):
    save("ding", bell(1568, 0.9, 0.3, (1, 2.76, 5.4), (1, 0.3, 0.1)))
if want("chop"):
    save("chop", att(bp(N(0.09), 900, 3500) * np.exp(-T(0.09) / 0.02), 0.001))
if want("whoosh"):
    t = T(0.4)
    save("whoosh", bp(N(0.4), 400, 4000) * np.sin(np.pi * t / 0.4) ** 2)
if want("splash"):
    t = T(0.6)
    save("splash", (lp(N(0.6), 3500) * np.exp(-t / 0.18) + 0.5 * bp(N(0.6), 1500, 6000) * np.exp(-t / 0.08)))
if want("flick"):
    b = np.zeros(int(0.5 * SR))
    for at in (0.0, 0.07, 0.14):
        mix(b, bp(N(0.03), 2500, 7000) * np.exp(-T(0.03) / 0.008), at)
    mix(b, lp(N(0.25), 3000) * np.exp(-T(0.25) / 0.09) * 0.7, 0.2)
    save("flick", b)
if want("crackle"):
    b = np.zeros(int(0.8 * SR))
    for _ in range(26):
        at = rng.uniform(0, 0.7)
        mix(b, bp(N(0.02), 1500, 6000) * np.exp(-T(0.02) / 0.005) * rng.uniform(0.3, 1.0), at)
    b += lp(N(0.8), 900) * 0.15
    save("crackle", b)
if want("growl"):
    t = T(1.2)
    f = 75 - 25 * t / 1.2
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * (0.6 + 0.4 * np.sin(2 * np.pi * 22 * t)) + 0.5 * lp(N(1.2), 300)
    y *= np.sin(np.pi * t / 1.2) ** 0.7
    save("growl", y)
if want("thud"):
    t = T(0.3)
    f = 110 * np.exp(-t / 0.08) + 40
    save("thud", np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.09) + 0.3 * lp(N(0.3), 600) * np.exp(-t / 0.03))
if want("page"):
    t = T(0.22)
    save("page", bp(N(0.22), 2000, 7000) * np.sin(np.pi * t / 0.22) ** 1.5)
if want("tada"):
    b = np.zeros(int(1.6 * SR))
    for i, f in enumerate((523, 659, 784, 1047)):
        mix(b, bell(f, 0.9 if i < 3 else 1.3, 0.35, (1, 2, 3), (1, 0.5, 0.25)), i * 0.11)
    save("tada", b)
if want("boing"):
    t = T(0.45)
    f = 220 + 280 * np.sin(np.pi * t / 0.45) ** 0.6 + 10 * np.sin(2 * np.pi * 28 * t)
    save("boing", np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.25))
if want("skip"):
    b = np.zeros(int(0.8 * SR))
    for i, f in enumerate((784, 988, 1175, 1568, 1976)):
        mix(b, bell(f, 0.4, 0.12), i * 0.055)
    save("skip", b * 0.8)
if want("glint"):
    b = np.zeros(int(1.4 * SR))
    mix(b, bell(3136, 1.2, 0.4, (1, 1.5, 2.0), (1, 0.6, 0.4)), 0)
    mix(b, bell(4186, 1.0, 0.3), 0.04)
    mix(b, bell(2093, 1.0, 0.3), 0.02)
    save("glint", b)
if want("beep"):
    t = T(0.3)
    y = np.sign(np.sin(2 * np.pi * 330 * t)) * 0.4 * (t < 0.12) + np.sign(np.sin(2 * np.pi * 250 * t)) * 0.4 * (t > 0.16) * (t < 0.28)
    save("beep", lp(y, 2500))
if want("chime"):
    b = np.zeros(int(1.2 * SR))
    for i, f in enumerate((1046, 1318, 1568)):
        mix(b, bell(f, 0.7, 0.2), i * 0.1)
    save("chime", b)
if want("blip"):
    t = T(0.05)
    save("blip", np.sin(2 * np.pi * 620 * t) * np.exp(-t / 0.02))
if want("rain"):
    d = 4.0
    y = bp(N(d), 2500, 9000) + 0.4 * lp(N(d), 1200)
    n = int(0.3 * SR)
    y[:n] = y[:n] * np.linspace(0, 1, n) + y[-n:] * np.linspace(1, 0, n)  # ループの継ぎ目をならす
    save("rain", y, 0.5)
if want("thunder"):
    d = 2.6
    t = T(d)
    y = lp(N(d), 220, 3) * (1 - np.exp(-t / 0.05)) * np.exp(-t / 0.9)
    y += 0.5 * lp(N(d), 900) * np.exp(-t / 0.08)
    save("thunder", y)
if want("pon"):
    t = T(0.18)
    save("pon", np.sin(2 * np.pi * 180 * t) * np.exp(-t / 0.05) + 0.3 * np.sin(2 * np.pi * 360 * t) * np.exp(-t / 0.03))

# ---------------------------------------------------------------- BGM
if want("bgm"):
    BEAT = 60 / 96
    BAR = BEAT * 4
    BARS = 12
    total = BAR * BARS
    buf = np.zeros(int((total + 2.0) * SR))
    chords = {
        "C": ([261.6, 329.6, 392.0, 523.3], 130.8, 196.0),
        "Am": ([220.0, 261.6, 329.6, 440.0], 110.0, 164.8),
        "F": ([174.6, 261.6, 349.2, 440.0], 87.3, 130.8),
        "G": ([196.0, 293.7, 392.0, 493.9], 98.0, 146.8),
    }
    prog = ["C", "Am", "F", "G"] * 3
    # ウクレレのストローク（8分音符）: 0=ダウン 1=アップ
    strum = {0: (0, 1.0), 2: (0, 0.7), 3: (1, 0.6), 5: (1, 0.6), 6: (0, 0.8), 7: (1, 0.5)}
    for bi, ch in enumerate(prog):
        notes, root, fifth = chords[ch]
        t0 = bi * BAR
        for e, (dirn, vol) in strum.items():
            at = t0 + e * BEAT / 2
            order = notes if dirn == 0 else notes[::-1]
            for k, f in enumerate(order):
                mix(buf, pluck(f, 0.7, 0.16 * vol), at + k * 0.012)
        mix(buf, pluck(root, 0.9, 0.5), t0)
        mix(buf, pluck(fifth, 0.7, 0.38), t0 + 2 * BEAT)
        mix(buf, pluck(root, 0.6, 0.3), t0 + 3.5 * BEAT)
        for e in (1, 3, 5, 7):  # シェイカー
            mix(buf, hp(N(0.05), 6000) * np.exp(-T(0.05) / 0.012) * 0.07, t0 + e * BEAT / 2)
    # マリンバのメロディ（5〜12小節）。ペンタトニック
    scale = [523.3, 587.3, 659.3, 784.0, 880.0, 1046.5, 1174.7]
    mrng = np.random.default_rng(5)
    idx = 2
    for bi in range(4, BARS):
        t0 = bi * BAR
        pos = 0.0
        while pos < 4.0 - 1e-6:
            dur = float(mrng.choice([0.5, 0.5, 1.0, 1.0, 1.5]))
            dur = min(dur, 4.0 - pos)
            idx = int(np.clip(idx + mrng.choice([-2, -1, -1, 0, 1, 1, 2]), 0, len(scale) - 1))
            if mrng.random() > 0.15:
                mix(buf, marimba(scale[idx], 0.6, 0.30), t0 + pos * BEAT)
            pos += dur
    mix(buf, marimba(784.0, 1.4, 0.3), (BARS - 1) * BAR + 3 * BEAT)
    # ループ：末尾の余韻を頭へ折り返す
    n = int(total * SR)
    head = buf[:n].copy()
    tail = buf[n:]
    head[:len(tail)] += tail
    save("bgm", head, 0.8)
