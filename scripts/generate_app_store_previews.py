#!/usr/bin/env python3
"""
App Store「アプリプレビュー」用の短い MP4 を生成する（審査向け: 実アプリの機能説明に沿った販促スライド動画）。

Apple / fastlane が検証する代表解像度（縦）:
  - iPhone 6.5 / 6.7 / 6.9 プレビュー: 886 x 1920
  - iPad 13\" (IPAD_PRO_3GEN_129): 1200 x 1600

各ファイル 15 秒（5 秒スライド x3）。ファイル名にプレビュー種別トークンを含める（fastlane の discover 用）。

出力先: AppStoreMetadata/app-previews/ja/
  ffmpeg が PATH に必要（brew install ffmpeg）。
"""

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as e:
    raise SystemExit("Pillow が必要です: pip install Pillow") from e

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "AppStoreMetadata" / "app-previews" / "ja"

# App Store Connect プレビュー向け（fastlane Spaceship の canonical と一致）
IPHONE_PREVIEW = (886, 1920)
IPAD_PREVIEW = (1200, 1600)

# ポップ寄りのトーン（エールミー）
C_TOP = (255, 120, 160)
C_MID = (255, 200, 120)
C_BOT = (255, 235, 200)
ACCENT = (255, 255, 255)
SHADOW = (60, 20, 40)


def _font_candidates() -> list[Path]:
    home = Path.home()
    return [
        Path("/System/Library/Fonts/Supplemental/Arial Unicode.ttf"),
        Path("/System/Library/Fonts/Hiragino Sans GB.ttc"),
        Path("/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"),
        Path("/Library/Fonts/Arial Unicode.ttf"),
        home / "Library/Fonts/NotoSansCJKjp-Regular.otf",
    ]


def load_jp_font(size: int) -> ImageFont.FreeTypeFont:
    for p in _font_candidates():
        if not p.exists():
            continue
        try:
            return ImageFont.truetype(str(p), size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def draw_gradient(img: Image.Image) -> None:
    w, h = img.size
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        c = lerp(lerp(C_TOP, C_MID, min(1.0, t * 1.4)), C_BOT, max(0.0, (t - 0.35) / 0.65))
        for x in range(w):
            px[x, y] = c


def draw_slide(
    size: tuple[int, int],
    badge: str,
    title: str,
    subtitle: str,
    footer: str,
) -> Image.Image:
    w, h = size
    img = Image.new("RGB", (w, h))
    draw_gradient(img)
    d = ImageDraw.Draw(img)
    scale = w / 886

    # 装飾円（RGB のみ・プレビュー用）
    for cx, cy, r in (
        (int(w * 0.15), int(h * 0.12), int(90 * scale)),
        (int(w * 0.88), int(h * 0.22), int(120 * scale)),
        (int(w * 0.2), int(h * 0.78), int(140 * scale)),
    ):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 240, 248))

    f_badge = load_jp_font(int(34 * scale))
    f_title = load_jp_font(int(56 * scale))
    f_sub = load_jp_font(int(38 * scale))
    f_foot = load_jp_font(int(30 * scale))

    bx = int(48 * scale)
    by = int(56 * scale)
    d.rounded_rectangle(
        (bx, by, bx + int(220 * scale), by + int(56 * scale)),
        int(18 * scale),
        fill=(255, 255, 255),
    )
    d.text((bx + int(20 * scale), by + int(8 * scale)), badge, font=f_badge, fill=(230, 60, 120))

    tx = int(48 * scale)
    ty = int(150 * scale)
    for line in title.split("\n"):
        for dx, dy in ((3, 3), (0, 0)):
            d.text((tx + dx, ty + dy), line, font=f_title, fill=SHADOW if dx else ACCENT)
        bbox = d.textbbox((tx, ty), line, font=f_title)
        ty += bbox[3] - bbox[1] + int(12 * scale)

    ty += int(24 * scale)
    for line in subtitle.split("\n"):
        d.text((tx, ty), line, font=f_sub, fill=(50, 30, 40))
        bbox = d.textbbox((tx, ty), line, font=f_sub)
        ty += bbox[3] - bbox[1] + int(10 * scale)

    d.text((tx, h - int(100 * scale)), footer, font=f_foot, fill=(120, 60, 80))
    return img


# 3 本の動画テーマ（各 3 スライド）
STORIES: list[dict] = [
    {
        "slug": "01_intro",
        "badge": "はじめまして",
        "slides": [
            ("エールミー", "日記と「できたこと」で\n今日の自分をそっと残す", "責めない、やさしい世界へようこそ"),
            ("まずは一行から", "長く書けなくても大丈夫\n思いついたことだけでOK", "あなたのペースが正解です"),
            ("記録が育つと…", "相棒キャラがそっと成長\nひとりじゃない感覚を届けます", "いま・きろく・マイページの3タブ"),
        ],
    },
    {
        "slug": "02_record",
        "badge": "かんたん記録",
        "slides": [
            ("いまタブでメモ", "今日の出来事を短く\n気持ちをそのまま書けるよ", "日記はプライベートに保管"),
            ("できたことチップ", "タップするだけでチェック\n小さな一歩もちゃんと拾う", "「朝起きられた」も立派な記録"),
            ("きろくで振り返り", "過去の日付から読み返せる\nあの日の自分が応援になる", "エールも一緒に保存"),
        ],
    },
    {
        "slug": "03_yell",
        "badge": "やさしいエール",
        "slides": [
            ("届くのは「エール」", "責めない言葉で包み込む\n完璧じゃなくていい、を伝える", "気持ちが軽くなるトーンで"),
            ("モードを選べる（Premium）", "短め・しっかりなど\n自分に合う深さに調整", "無料でも十分楽しめます"),
            ("今日をそのまま受け止める", "がんばった日も、そうでない日も\n日々のセルフケアのお供に", "エールミー — 今日をほどく日記アプリ"),
        ],
    },
]


def _run_ffmpeg_concat(
    png_paths: list[Path],
    out_mp4: Path,
    size: tuple[int, int],
    sec_per_slide: float = 5.0,
) -> None:
    w, h = size
    if len(png_paths) != 3:
        raise ValueError("3 slides expected")

    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".txt", delete=False, encoding="utf-8"
    ) as listf:
        for p in png_paths:
            # concat demuxer は絶対パスが安全
            listf.write(f"file '{p.resolve().as_posix()}'\n")
            listf.write(f"duration {sec_per_slide}\n")
        listf.write(f"file '{png_paths[-1].resolve().as_posix()}'\n")
        list_path = Path(listf.name)

    total_duration = sec_per_slide * len(png_paths)

    try:
        cmd = [
            "ffmpeg",
            "-y",
            "-f",
            "concat",
            "-safe",
            "0",
            "-i",
            str(list_path),
            # 無音オーディオトラックを追加（ASC が要求）
            "-f",
            "lavfi",
            "-i",
            f"anullsrc=channel_layout=stereo:sample_rate=44100:duration={total_duration}",
            "-r",
            "30",
            "-vf",
            f"scale={w}:{h}:force_original_aspect_ratio=decrease,"
            f"pad={w}:{h}:(ow-iw)/2:(oh-ih)/2,format=yuv420p",
            "-c:v",
            "libx264",
            "-profile:v",
            "high",
            "-pix_fmt",
            "yuv420p",
            "-c:a",
            "aac",
            "-b:a",
            "128k",
            "-shortest",
            "-movflags",
            "+faststart",
            str(out_mp4),
        ]
        r = subprocess.run(cmd, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
        if r.returncode != 0:
            sys.stderr.write(r.stderr or "")
            raise subprocess.CalledProcessError(r.returncode, cmd)
    finally:
        list_path.unlink(missing_ok=True)


def render_story_mp4(story: dict, size: tuple[int, int], out_path: Path) -> None:
    with tempfile.TemporaryDirectory(prefix="yellme_preview_") as td:
        tdir = Path(td)
        paths: list[Path] = []
        for i, (title, sub, foot) in enumerate(story["slides"]):
            badge = story["badge"]
            img = draw_slide(size, badge, title, sub, foot)
            p = tdir / f"s{i}.png"
            img.save(p, optimize=True)
            paths.append(p)
        _run_ffmpeg_concat(paths, out_path, size)


def main() -> None:
    if not shutil.which("ffmpeg"):
        raise SystemExit("ffmpeg が見つかりません。例: brew install ffmpeg")

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # iPhone 6.5 / 6.7 / 6.9 は同じ 886x1920 系として 3 本ずつ（ファイル名で種別を区別）
    for story in STORIES:
        slug = story["slug"]
        render_story_mp4(story, IPHONE_PREVIEW, OUT_DIR / f"{slug}_IPHONE_65.mp4")
        render_story_mp4(story, IPHONE_PREVIEW, OUT_DIR / f"{slug}_IPHONE_67.mp4")
        render_story_mp4(story, IPAD_PREVIEW, OUT_DIR / f"{slug}_IPAD_PRO_3GEN_129.mp4")

    print(f"生成完了: {OUT_DIR} （各 {len(STORIES)} 本 x 3 種類 = 9 ファイル）")


if __name__ == "__main__":
    main()
