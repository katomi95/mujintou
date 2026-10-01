"""shots/ep<N>_<time>.png を話ごとに 2 列の一覧にまとめて shots/sheet_<N>.png へ。"""
import glob
import os
import re
from PIL import Image, ImageDraw

root = os.path.join(os.path.dirname(__file__), "..", "shots")
groups = {}
for p in sorted(glob.glob(os.path.join(root, "ep*_*.png"))):
    m = re.match(r"ep(\d+)_([\d.]+)\.png", os.path.basename(p))
    if m:
        groups.setdefault(int(m.group(1)), []).append((float(m.group(2)), p))
for ep, items in groups.items():
    items.sort()
    w, h = 640, 360
    cols = 2
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGB", (w * cols, h * rows), "black")
    for i, (t, p) in enumerate(items):
        im = Image.open(p).convert("RGB").resize((w, h))
        ImageDraw.Draw(im).text((8, 6), f"t={t}", fill="white")
        sheet.paste(im, ((i % cols) * w, (i // cols) * h))
    out = os.path.join(root, f"sheet_{ep}.png")
    sheet.save(out)
    print(out, len(items))
