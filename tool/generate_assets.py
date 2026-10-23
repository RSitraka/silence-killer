"""Génère les ressources embarquées du jeu (à lancer une seule fois) :

  • assets/sounds/*.wav      : petits effets sonores synthétisés (aucun droit d'auteur) ;
  • assets/icon/*.png        : icône de l'application (ninja qui fait un clin d'œil) ;
  • assets/fonts/Fredoka-*.ttf : police Fredoka (SIL OFL) en graisses statiques.

Dépendances : pip install pillow fonttools
Usage       : python tool/generate_assets.py
"""

import io
import math
import random
import struct
import urllib.request
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RATE = 22050


# ---------------------------------------------------------------- sons ----

def _write_wav(name, samples):
    path = ROOT / "assets" / "sounds" / f"{name}.wav"
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = 0.85 / peak
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * gain * 32767)) for s in samples))


def _tone(freq, dur, kind="sine", attack=0.005, decay=6.0, vibrato=0.0):
    out, phase = [], 0.0
    n = int(dur * RATE)
    for i in range(n):
        t = i / RATE
        f = freq(t) if callable(freq) else freq
        f *= 1 + vibrato * math.sin(2 * math.pi * 6 * t)
        phase += 2 * math.pi * f / RATE
        if kind == "sine":
            v = math.sin(phase)
        elif kind == "triangle":
            v = 2 / math.pi * math.asin(math.sin(phase))
        else:  # "soft" : sinus + harmonique, son de clochette
            v = math.sin(phase) + 0.3 * math.sin(2 * phase) + 0.1 * math.sin(3 * phase)
        env = min(1.0, t / attack) * math.exp(-decay * t)
        out.append(v * env)
    return out


def _seq(notes, gap=0.0):
    out = []
    for n in notes:
        out += n + [0.0] * int(gap * RATE)
    return out


def _mix(a, b):
    n = max(len(a), len(b))
    a = a + [0.0] * (n - len(a))
    b = b + [0.0] * (n - len(b))
    return [x + y for x, y in zip(a, b)]


def note(name):
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "F#": -3, "G": -2, "A": 0, "B": 2}
    pitch, octave = name[:-1], int(name[-1])
    return 440 * 2 ** ((names[pitch] + 12 * (octave - 4)) / 12)


def make_sounds():
    _write_wav("tap", _tone(lambda t: 520 + 2600 * t, 0.08, decay=40))
    _write_wav("reveal", _seq([_tone(note(n), 0.11, "soft", decay=14) for n in ["C6", "E6", "G6"]]))
    _write_wav("death", _tone(lambda t: 520 * math.exp(-2.6 * t), 0.55, "triangle", decay=3.5, vibrato=0.04))

    # Roulement de tambour : petits coups de bruit de plus en plus forts (2 s).
    rnd = random.Random(7)
    roll = []
    hits = 46
    for k in range(hits):
        length = int(RATE * 2.0 / hits)
        amp = 0.35 + 0.65 * k / hits
        roll += [amp * rnd.uniform(-1, 1) * math.exp(-28 * i / RATE)
                 * (0.6 + 0.4 * math.sin(2 * math.pi * 110 * i / RATE)) for i in range(length)]
    _write_wav("drumroll", roll)

    _write_wav("success", _mix(
        _seq([_tone(note(n), 0.12, "soft", decay=8) for n in ["C5", "E5", "G5"]]),
        [0.0] * int(0.36 * RATE) + _tone(note("C6"), 0.6, "soft", decay=4),
    ))
    _write_wav("fail", _seq([
        _tone(note("G4"), 0.3, "triangle", decay=2, vibrato=0.01),
        _tone(note("F#4"), 0.3, "triangle", decay=2, vibrato=0.01),
        _tone(note("F4"), 0.7, "triangle", decay=2.2, vibrato=0.025),
    ]))
    fanfare = _seq([_tone(note(n), d, "soft", decay=5) for n, d in
                    [("C5", 0.14), ("C5", 0.14), ("C5", 0.14), ("G5", 0.42), ("E5", 0.14), ("G5", 0.2)]])
    _write_wav("victory", _mix(fanfare, [0.0] * int(1.36 * RATE) + _tone(note("C6"), 0.9, "soft", decay=3)))


# --------------------------------------------------------------- icône ----

def _quad(p0, p1, p2, steps=24):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1])
            for t in (i / steps for i in range(steps + 1))]


def _draw_assassin(img, cx, cy, size):
    """Même dessin que AssassinPainter (lib/widgets/role_icons.dart)."""
    from PIL import Image, ImageDraw

    s = size
    ox, oy = cx - s / 2, cy - s / 2

    def P(x, y):
        return (ox + x * s, oy + y * s)

    # Étoile 8 branches en dégradé violet → rouge.
    star = []
    for i in range(16):
        r = (0.49 if i % 2 == 0 else 0.36) * s
        a = -math.pi / 2 + i * math.pi / 8
        star.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    # Dégradé diagonal calculé en petit, puis agrandi sur la zone de l'étoile.
    stops = [(0xA7, 0x8B, 0xFA), (0x7C, 0x3A, 0xED), (0xE1, 0x1D, 0x48)]
    small = Image.new("RGBA", (128, 128))
    for y in range(128):
        for x in range(128):
            t = (x + y) / 254
            a, b, u = (stops[0], stops[1], t * 2) if t < 0.5 else (stops[1], stops[2], (t - 0.5) * 2)
            small.putpixel((x, y), tuple(int(a[k] + (b[k] - a[k]) * u) for k in range(3)) + (255,))
    grad = Image.new("RGBA", img.size)
    grad.paste(small.resize((int(s), int(s)), Image.BILINEAR), (int(ox), int(oy)))
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(star, fill=255)
    img.paste(grad, (0, 0), mask)

    d = ImageDraw.Draw(img)
    d.line(star + star[:2], fill="white", width=int(0.03 * s), joint="curve")

    red = (0xF4, 0x3F, 0x5E, 255)
    hood = (0x2E, 0x1A, 0x55, 255)
    ink = (0x3D, 0x2C, 0x5C, 255)
    # Rubans du bandeau.
    d.polygon(_quad(P(0.70, 0.38), P(0.82, 0.30), P(0.90, 0.24)) + _quad(P(0.90, 0.24), P(0.86, 0.34), P(0.74, 0.44)), fill=red)
    d.polygon(_quad(P(0.72, 0.42), P(0.86, 0.42), P(0.93, 0.38)) + _quad(P(0.93, 0.38), P(0.86, 0.48), P(0.72, 0.47)), fill=red)
    # Tête.
    hx, hy, hr = cx, oy + 0.52 * s, 0.25 * s
    d.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=hood)
    band = Image.new("L", img.size, 0)
    ImageDraw.Draw(band).ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=255)
    stripe = Image.new("L", img.size, 0)
    ImageDraw.Draw(stripe).rectangle([0, oy + 0.36 * s, img.size[0], oy + 0.41 * s], fill=255)
    from PIL import ImageChops
    img.paste(Image.new("RGBA", img.size, red), (0, 0), ImageChops.multiply(band, stripe))
    # Ouverture des yeux.
    d.rounded_rectangle([*P(0.30, 0.435), *P(0.70, 0.565)], radius=0.065 * s, fill=(0xFF, 0xE1, 0xC2, 255))
    r = 0.034 * s
    ex, ey = P(0.42, 0.50)
    d.ellipse([ex - r, ey - r, ex + r, ey + r], fill=ink)
    r2 = 0.011 * s
    ex, ey = P(0.43, 0.49)
    d.ellipse([ex - r2, ey - r2, ex + r2, ey + r2], fill="white")
    # Clin d'œil.
    d.line(_quad(P(0.54, 0.495), P(0.585, 0.535), P(0.63, 0.495)), fill=ink, width=int(0.03 * s), joint="curve")
    # Sourire espiègle.
    sx0, sy0 = P(0.45, 0.58)
    sx1, sy1 = P(0.59, 0.66)
    d.arc([sx0, sy0, sx1, sy1], start=18, end=162, fill=(0xFF, 0xB3, 0xC7, 255), width=int(0.03 * s))


def make_icon():
    from PIL import Image, ImageDraw

    out = ROOT / "assets" / "icon"
    out.mkdir(parents=True, exist_ok=True)
    big = 4096  # dessin en grand puis réduction = bords lisses

    # Icône classique : fond arrondi pastel + ninja.
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    bg = Image.new("RGBA", (big, big))
    bd = ImageDraw.Draw(bg)
    for y in range(big):
        u = y / big
        bd.line([(0, y), (big, y)], fill=(255, int(0xE8 - 0x18 * u), int(0xF1 + 0x0A * u), 255))
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, big - 1, big - 1], radius=big * 0.22, fill=255)
    img.paste(bg, (0, 0), mask)
    _draw_assassin(img, big / 2, big / 2, big * 0.86)
    img.resize((1024, 1024), Image.LANCZOS).save(out / "icon.png")

    # Premier plan de l'icône adaptative (Android 8+) : ninja dans la zone sûre.
    fg = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    _draw_assassin(fg, big / 2, big / 2, big * 0.60)
    fg.resize((1024, 1024), Image.LANCZOS).save(out / "icon_foreground.png")


# -------------------------------------------------------------- police ----

FREDOKA_URL = "https://github.com/google/fonts/raw/main/ofl/fredoka/Fredoka%5Bwdth,wght%5D.ttf"


def make_fonts():
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer

    out = ROOT / "assets" / "fonts"
    out.mkdir(parents=True, exist_ok=True)
    data = urllib.request.urlopen(FREDOKA_URL).read()
    for name, weight in [("Regular", 400), ("Medium", 500), ("SemiBold", 600), ("Bold", 700)]:
        font = TTFont(io.BytesIO(data))
        static = instancer.instantiateVariableFont(font, {"wght": weight, "wdth": 100})
        static.save(out / f"Fredoka-{name}.ttf")
    urllib.request.urlretrieve(
        "https://github.com/google/fonts/raw/main/ofl/fredoka/OFL.txt", out / "OFL.txt")


if __name__ == "__main__":
    make_sounds()
    print("sons OK")
    make_icon()
    print("icône OK")
    make_fonts()
    print("polices OK")
