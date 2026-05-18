#!/usr/bin/env python3
"""
iCloud 写真フォルダの実機スクショを App Store Connect 用サイズに変換する。

入力: プロジェクト直下の iCloud写真/（または --input）
出力:
  - AppStoreMetadata/screenshots/iphone65/  1284 x 2778
  - AppStoreMetadata/screenshots/ipad13/    2048 x 2732（レターボックス）
  - AppStoreMetadata/deliver/screenshots/ja/  fastlane 用コピー

審査向け: 6194 は開発者向け UI を除外してクロップ。
"""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

try:
    from PIL import Image
except ImportError as e:
    raise SystemExit("Pillow が必要です: python3 -m venv .venv-screenshots && .venv-screenshots/bin/pip install Pillow") from e

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "iCloud写真"
OUT_IPHONE = ROOT / "AppStoreMetadata" / "screenshots" / "iphone65"
OUT_IPAD = ROOT / "AppStoreMetadata" / "screenshots" / "ipad13"
DELIVER_IPHONE = ROOT / "AppStoreMetadata" / "deliver" / "screenshots" / "ja" / "iPhone XS Max"
DELIVER_IPAD = (
    ROOT
    / "AppStoreMetadata"
    / "deliver"
    / "screenshots"
    / "ja"
    / "iPad Pro (12.9-inch) (3rd generation)"
)

IPHONE_SIZE = (1284, 2778)
IPAD_SIZE = (2048, 2732)
BG = (255, 247, 239)  # アプリ背景に近い色

# (ソースファイル名, 出力スラッグ, 6194のみプラン欄クロップ比率)
SCREEN_MAP: list[tuple[str, str, float | None]] = [
    ("IMG_6187.PNG", "01_home_top", None),
    ("IMG_6188.PNG", "02_home_input", None),
    ("IMG_6189.PNG", "03_home_modes", None),
    ("IMG_6190.PNG", "04_history", None),
    ("IMG_6191.PNG", "05_history_detail", None),
    ("IMG_6192.PNG", "06_yell_feedback", None),
    ("IMG_6193.PNG", "07_profile", None),
    ("IMG_6194.PNG", "08_premium", 0.56),  # 「開発」セクション手前まで
]


def fit_on_canvas(src: Image.Image, target_size: tuple[int, int], bg: tuple[int, int, int]) -> Image.Image:
    tw, th = target_size
    img = src.convert("RGB")
    ratio = min(tw / img.width, th / img.height)
    nw, nh = int(img.width * ratio), int(img.height * ratio)
    resized = img.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGB", target_size, bg)
    canvas.paste(resized, ((tw - nw) // 2, (th - nh) // 2))
    return canvas


def load_source(path: Path, crop_ratio: float | None) -> Image.Image:
    img = Image.open(path)
    if crop_ratio is not None:
        h = int(img.height * crop_ratio)
        img = img.crop((0, 0, img.width, max(1, h)))
    return img


def clear_png_dir(directory: Path) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    for f in directory.glob("*.png"):
        f.unlink()


def copy_deliver(iphone_dir: Path, ipad_dir: Path) -> None:
    clear_png_dir(DELIVER_IPHONE)
    clear_png_dir(DELIVER_IPAD)
    for src in sorted(iphone_dir.glob("*.png")):
        shutil.copy2(src, DELIVER_IPHONE / src.name)
    for src in sorted(ipad_dir.glob("*.png")):
        shutil.copy2(src, DELIVER_IPAD / src.name)


def main() -> None:
    parser = argparse.ArgumentParser(description="iCloud 写真から ASC 用スクショを生成")
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT, help="入力フォルダ")
    parser.add_argument("--no-deliver", action="store_true", help="deliver 用コピーをスキップ")
    args = parser.parse_args()
    input_dir: Path = args.input

    if not input_dir.is_dir():
        raise SystemExit(f"入力フォルダがありません: {input_dir}")

    clear_png_dir(OUT_IPHONE)
    clear_png_dir(OUT_IPAD)

    for filename, slug, crop_ratio in SCREEN_MAP:
        src = input_dir / filename
        if not src.exists():
            print(f"  SKIP (not found): {src}")
            continue
        raw = load_source(src, crop_ratio)
        phone = fit_on_canvas(raw, IPHONE_SIZE, BG)
        pad = fit_on_canvas(raw, IPAD_SIZE, BG)
        phone.save(OUT_IPHONE / f"{slug}.png", optimize=True)
        pad.save(OUT_IPAD / f"{slug}.png", optimize=True)
        note = f" crop={crop_ratio:.0%}" if crop_ratio else ""
        print(f"  OK: {slug} <- {filename}{note}")

    if not args.no_deliver:
        copy_deliver(OUT_IPHONE, OUT_IPAD)
        print(f"\ndeliver 配置: {DELIVER_IPHONE.parent}")

    count = len(list(OUT_IPHONE.glob("*.png")))
    print(f"\n完了: iPhone {count} 枚 ({IPHONE_SIZE[0]}x{IPHONE_SIZE[1]}), iPad {count} 枚 ({IPAD_SIZE[0]}x{IPAD_SIZE[1]})")


if __name__ == "__main__":
    main()
