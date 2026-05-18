#!/usr/bin/env python3
"""
実機スクリーンレコードを App Store アプリプレビュー用 MP4 に変換する。

入力: プロジェクト直下の ScreenRecording_*.MP4（最新を既定）
      または --input で指定
出力:
  - AppStoreMetadata/app-previews/ja/
  - AppStoreMetadata/deliver/app-previews/ja/

1本の長い録画を 01_intro / 02_record / 03_yell の3区間に均等分割（各15〜30秒）。
iPad 用は iPhone 変換済みを 1200x1600 にレターボックス。
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "AppStoreMetadata" / "app-previews" / "ja"
DELIVER_DIR = ROOT / "AppStoreMetadata" / "deliver" / "app-previews" / "ja"
RAW_DIR = ROOT / "AppStoreMetadata" / "app-previews" / "raw"

IPHONE_SIZE = "886:1920"
IPAD_SIZE = "1200:1600"
FPS = 30
MIN_SEG = 15.0
MAX_SEG = 30.0

SEGMENTS = (
    ("01_intro", "はじめに"),
    ("02_record", "記録する"),
    ("03_yell", "エールを見る"),
)


def find_latest_recording(root: Path) -> Path:
    candidates = sorted(root.glob("ScreenRecording_*.MP4"), key=lambda p: p.stat().st_mtime)
    if not candidates:
        candidates = sorted(root.glob("ScreenRecording_*.mp4"), key=lambda p: p.stat().st_mtime)
    if not candidates:
        raise SystemExit(f"スクリーンレコードが見つかりません: {root}/ScreenRecording_*.MP4")
    return candidates[-1]


def probe_duration(path: Path) -> float:
    cmd = [
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        str(path),
    ]
    out = subprocess.check_output(cmd, text=True).strip()
    return float(out)


def convert_segment(
    source: Path,
    start: float,
    duration: float,
    output: Path,
    size: str,
) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    vf = (
        f"scale={size}:force_original_aspect_ratio=decrease,"
        f"pad={size}:(ow-iw)/2:(oh-ih)/2,format=yuv420p"
    )
    cmd = [
        "ffmpeg",
        "-y",
        "-ss",
        f"{start:.3f}",
        "-i",
        str(source),
        "-t",
        f"{duration:.3f}",
        "-r",
        str(FPS),
        "-vf",
        vf,
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
        "-movflags",
        "+faststart",
        str(output),
    ]
    subprocess.run(cmd, check=True, capture_output=True)


def segment_plan(total: float) -> list[tuple[str, float, float]]:
    """3等分し、各セグメントを 15〜30 秒に収める。"""
    n = len(SEGMENTS)
    raw = total / n
    duration = max(MIN_SEG, min(MAX_SEG, raw))
    plans: list[tuple[str, float, float]] = []
    for i, (slug, _) in enumerate(SEGMENTS):
        start = i * raw
        if i == n - 1:
            # 最後は残り全部（上限30秒）
            duration = min(MAX_SEG, max(MIN_SEG, total - start))
        plans.append((slug, start, duration))
    return plans


def verify(path: Path) -> None:
    cmd = [
        "ffprobe",
        "-v",
        "error",
        "-select_streams",
        "v:0",
        "-show_entries",
        "stream=width,height,r_frame_rate",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1",
        str(path),
    ]
    info = subprocess.check_output(cmd, text=True).strip().replace("\n", " ")
    print(f"  OK {path.name}: {info}")


def main() -> None:
    parser = argparse.ArgumentParser(description="スクリーンレコード → ASC アプリプレビュー")
    parser.add_argument("--input", type=Path, help="入力 MP4（未指定時は最新 ScreenRecording_*.MP4）")
    parser.add_argument("--no-deliver", action="store_true", help="deliver フォルダへコピーしない")
    args = parser.parse_args()

    source = args.input.expanduser().resolve() if args.input else find_latest_recording(ROOT)
    if not source.is_file():
        raise SystemExit(f"入力がありません: {source}")

    total = probe_duration(source)
    if total < MIN_SEG * len(SEGMENTS):
        raise SystemExit(f"動画が短すぎます（{total:.1f}s）。{MIN_SEG * len(SEGMENTS):.0f}秒以上必要です。")

    plans = segment_plan(total)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    DELIVER_DIR.mkdir(parents=True, exist_ok=True)
    RAW_DIR.mkdir(parents=True, exist_ok=True)

    # 元ファイルを raw に記録用コピー（既存ならスキップ可）
    raw_copy = RAW_DIR / f"latest_device{source.suffix.lower()}"
    if not raw_copy.exists() or raw_copy.stat().st_mtime < source.stat().st_mtime:
        shutil.copy2(source, raw_copy)

    print(f"入力: {source.name} ({total:.1f}s)")
    for slug, start, dur in plans:
        print(f"  {slug}: {start:.1f}s + {dur:.1f}s")

    for slug, start, dur in plans:
        iphone_out = OUT_DIR / f"{slug}_IPHONE_65.mp4"
        convert_segment(source, start, dur, iphone_out, IPHONE_SIZE)
        iphone67 = OUT_DIR / f"{slug}_IPHONE_67.mp4"
        shutil.copy2(iphone_out, iphone67)
        ipad_out = OUT_DIR / f"{slug}_IPAD_PRO_3GEN_129.mp4"
        convert_segment(source, start, dur, ipad_out, IPAD_SIZE)

        if not args.no_deliver:
            for out in (iphone_out, iphone67, ipad_out):
                shutil.copy2(out, DELIVER_DIR / out.name)

        verify(iphone_out)
        verify(ipad_out)

    print(f"\n完了: {OUT_DIR}")
    if not args.no_deliver:
        print(f"deliver: {DELIVER_DIR}")


if __name__ == "__main__":
    main()
