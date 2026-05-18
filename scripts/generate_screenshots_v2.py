#!/usr/bin/env python3
"""
App Store スクショ v2:
  - 実スクショ 4 枚をリサイズ（1-4 番）
  - モック生成 6 枚（5-10 番）：実アプリの配色・レイアウトに近い
  - iPhone 6.5 (1284x2778) + iPad 13 (2048x2732)
"""
from __future__ import annotations

import textwrap
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as e:
    raise SystemExit("Pillow が必要です: pip install Pillow") from e

ROOT = Path(__file__).resolve().parents[1]
OUT_IPHONE = ROOT / "AppStoreMetadata" / "screenshots" / "iphone65"
OUT_IPAD = ROOT / "AppStoreMetadata" / "screenshots" / "ipad13"

IPHONE_SIZE = (1284, 2778)
IPAD_SIZE = (2048, 2732)

# 実スクショ（デスクトップから）
REAL_SCREENSHOTS = [
    Path.home() / "Desktop" / "IMG_6138.PNG",  # いまタブ上部
    Path.home() / "Desktop" / "IMG_6141.PNG",  # いまタブ下部（エール全文）
    Path.home() / "Desktop" / "IMG_6139.PNG",  # きろくタブ
    Path.home() / "Desktop" / "IMG_6140.PNG",  # マイページ
]

REAL_SLUGS = [
    "01_home_top",
    "02_home_yell",
    "03_history",
    "04_profile",
]

# アプリの配色
BG_TOP = (255, 247, 239)
BG_MID = (252, 230, 235)
BG_BOT = (245, 200, 218)
CARD_BG = (255, 255, 255, 235)
PINK = (220, 100, 140)
PINK_SOFT = (255, 182, 193)
GRAY = (120, 120, 120)
DARK = (45, 45, 45)
GREEN_CHECK = (34, 170, 34)

TABS = ("いま", "きろく", "マイページ")


def _font_candidates() -> list[Path]:
    home = Path.home()
    return [
        Path("/System/Library/Fonts/Supplemental/Arial Unicode.ttf"),
        Path("/System/Library/Fonts/Hiragino Sans GB.ttc"),
        Path("/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"),
        Path("/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"),
        Path("/Library/Fonts/Arial Unicode.ttf"),
        home / "Library/Fonts/NotoSansCJKjp-Regular.otf",
    ]


def load_jp_font(size: int) -> ImageFont.FreeTypeFont:
    for p in _font_candidates():
        if not p.exists():
            continue
        try:
            return ImageFont.truetype(str(p), size=size)
        except Exception:
            continue
    return ImageFont.load_default()


def lerp(a: tuple, b: tuple, t: float) -> tuple:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def draw_gradient(img: Image.Image) -> None:
    w, h = img.size
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        if t < 0.5:
            c = lerp(BG_TOP, BG_MID, t * 2)
        else:
            c = lerp(BG_MID, BG_BOT, (t - 0.5) * 2)
        for x in range(w):
            px[x, y] = c


def draw_status_bar(draw: ImageDraw.ImageDraw, w: int, s: float) -> None:
    font = load_jp_font(int(34 * s))
    draw.text((int(48 * s), int(36 * s)), "9:41", font=font, fill=(40, 40, 40))


def draw_tab_bar(draw: ImageDraw.ImageDraw, w: int, h: int, active: int, s: float) -> None:
    bar_h = int(140 * s)
    y0 = h - bar_h
    draw.rectangle([0, y0, w, h], fill=(255, 252, 252, 250))
    draw.line([0, y0, w, y0], fill=PINK_SOFT, width=2)
    tw = w // 3
    font = load_jp_font(int(30 * s))
    for i, label in enumerate(TABS):
        cx = i * tw + tw // 2
        color = PINK if i == active else GRAY
        bbox = draw.textbbox((0, 0), label, font=font)
        tx = cx - (bbox[2] - bbox[0]) // 2
        ty = y0 + (bar_h - (bbox[3] - bbox[1])) // 2
        draw.text((tx, ty), label, font=font, fill=color)


def draw_rounded_card(draw: ImageDraw.ImageDraw, xy: tuple, radius: int, fill) -> None:
    draw.rounded_rectangle(xy, radius=radius, fill=fill)


def resize_real(src: Path, target_size: tuple) -> Image.Image:
    """実スクショを target_size にリサイズ（アスペクト比を保ちつつパディング）"""
    img = Image.open(src).convert("RGB")
    tw, th = target_size

    # アスペクト比を合わせてリサイズ
    ratio = min(tw / img.width, th / img.height)
    new_w = int(img.width * ratio)
    new_h = int(img.height * ratio)
    resized = img.resize((new_w, new_h), Image.LANCZOS)

    # 背景色（アプリのグラデーション上部色）でパディング
    canvas = Image.new("RGB", target_size, BG_TOP)
    x_off = (tw - new_w) // 2
    y_off = (th - new_h) // 2
    canvas.paste(resized, (x_off, y_off))
    return canvas


# --- モック画面定義（実アプリの UI に近いレイアウト） ---

def mock_diary_input(size: tuple, s: float) -> Image.Image:
    """日記入力画面"""
    w, h = size
    img = Image.new("RGB", (w, h))
    draw_gradient(img)
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    draw_status_bar(d, w, s)

    # タイトル
    title_font = load_jp_font(int(56 * s))
    d.text((int(56 * s), int(110 * s)), "いま", font=title_font, fill=DARK)

    # 日付
    date_font = load_jp_font(int(30 * s))
    d.text((int(56 * s), int(190 * s)), "May 12, 2026", font=date_font, fill=GRAY)

    # 日記カード
    mx = int(40 * s)
    cy = int(280 * s)
    cw = w - 2 * mx
    ch = int(400 * s)
    draw_rounded_card(d, (mx, cy, mx + cw, cy + ch), int(24 * s), CARD_BG)

    body_font = load_jp_font(int(34 * s))
    label_font = load_jp_font(int(28 * s))
    d.text((mx + int(30 * s), cy + int(20 * s)), "今日の記録", font=body_font, fill=DARK)
    d.text((mx + int(30 * s), cy + int(70 * s)), "今日はどんな一日でしたか？", font=label_font, fill=GRAY)

    # テキスト入力エリア
    input_y = cy + int(120 * s)
    input_h = int(200 * s)
    draw_rounded_card(d, (mx + int(20 * s), input_y, mx + cw - int(20 * s), input_y + input_h), int(16 * s), (248, 245, 245, 200))
    d.text((mx + int(40 * s), input_y + int(20 * s)), "今日は散歩に行けた。\n天気がよくて気持ちよかった。", font=label_font, fill=DARK)

    # できたことセクション
    cy2 = cy + ch + int(30 * s)
    d.text((mx + int(10 * s), cy2), "えらんだこと", font=label_font, fill=GRAY)
    chip_y = cy2 + int(50 * s)
    chips = ["朝起きられた", "散歩した", "水をよく飲んだ", "ご飯を食べた"]
    cx_pos = mx + int(10 * s)
    chip_font = load_jp_font(int(26 * s))
    for chip_text in chips:
        bbox = d.textbbox((0, 0), chip_text, font=chip_font)
        chip_w = bbox[2] - bbox[0] + int(36 * s)
        chip_h = int(48 * s)
        if cx_pos + chip_w > w - mx:
            cx_pos = mx + int(10 * s)
            chip_y += int(56 * s)
        draw_rounded_card(d, (cx_pos, chip_y, cx_pos + chip_w, chip_y + chip_h), int(20 * s), (255, 230, 238, 255))
        d.text((cx_pos + int(18 * s), chip_y + int(10 * s)), chip_text, font=chip_font, fill=PINK)
        cx_pos += chip_w + int(12 * s)

    draw_tab_bar(d, w, h, 0, s)
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    return img


def mock_yell_detail(size: tuple, s: float) -> Image.Image:
    """エール詳細画面"""
    w, h = size
    img = Image.new("RGB", (w, h))
    draw_gradient(img)
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    draw_status_bar(d, w, s)

    title_font = load_jp_font(int(56 * s))
    d.text((int(56 * s), int(110 * s)), "いま", font=title_font, fill=DARK)

    # エールカード
    mx = int(40 * s)
    cy = int(250 * s)
    cw = w - 2 * mx
    ch = int(600 * s)
    draw_rounded_card(d, (mx, cy, mx + cw, cy + ch), int(24 * s), (255, 245, 250, 240))

    heart_font = load_jp_font(int(40 * s))
    d.text((mx + int(30 * s), cy + int(20 * s)), "エールが届きました", font=heart_font, fill=PINK)

    body_font = load_jp_font(int(32 * s))
    yell_text = (
        "今日、散歩に出かけられたんだね。\n\n"
        "天気のいい日に外に出るって、\n"
        "それだけで素敵なこと。\n\n"
        "朝ちゃんと起きて、水も飲んで、\n"
        "ご飯も食べて。\n\n"
        "全部ちゃんと自分を大切に\n"
        "できた一日だったんだね。\n\n"
        "よくがんばったね。"
    )
    ty = cy + int(80 * s)
    for line in yell_text.split("\n"):
        d.text((mx + int(30 * s), ty), line, font=body_font, fill=DARK)
        ty += int(44 * s)

    draw_tab_bar(d, w, h, 0, s)
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    return img


def mock_history_detail(size: tuple, s: float) -> Image.Image:
    """きろく詳細画面"""
    w, h = size
    img = Image.new("RGB", (w, h))
    draw_gradient(img)
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    draw_status_bar(d, w, s)

    title_font = load_jp_font(int(56 * s))
    d.text((int(56 * s), int(110 * s)), "きろく", font=title_font, fill=DARK)

    date_font = load_jp_font(int(30 * s))
    d.text((int(56 * s), int(190 * s)), "May 12, 2026", font=date_font, fill=GRAY)

    mx = int(40 * s)
    body_font = load_jp_font(int(32 * s))
    label_font = load_jp_font(int(28 * s))

    # 日記セクション
    cy = int(270 * s)
    cw = w - 2 * mx
    draw_rounded_card(d, (mx, cy, mx + cw, cy + int(220 * s)), int(24 * s), CARD_BG)
    d.text((mx + int(30 * s), cy + int(20 * s)), "日記", font=body_font, fill=PINK)
    d.text((mx + int(30 * s), cy + int(70 * s)), "今日は散歩に行けた。", font=label_font, fill=DARK)
    d.text((mx + int(30 * s), cy + int(110 * s)), "天気がよくて気持ちよかった。", font=label_font, fill=DARK)

    # できたこと
    cy2 = cy + int(250 * s)
    draw_rounded_card(d, (mx, cy2, mx + cw, cy2 + int(180 * s)), int(24 * s), CARD_BG)
    d.text((mx + int(30 * s), cy2 + int(20 * s)), "できたこと", font=body_font, fill=PINK)
    chips = ["朝起きられた", "散歩した", "水をよく飲んだ"]
    chip_font = load_jp_font(int(24 * s))
    cx_pos = mx + int(30 * s)
    chip_y = cy2 + int(80 * s)
    for ct in chips:
        bbox = d.textbbox((0, 0), ct, font=chip_font)
        cw2 = bbox[2] - bbox[0] + int(30 * s)
        draw_rounded_card(d, (cx_pos, chip_y, cx_pos + cw2, chip_y + int(42 * s)), int(16 * s), (255, 230, 238, 255))
        d.text((cx_pos + int(15 * s), chip_y + int(8 * s)), ct, font=chip_font, fill=PINK)
        cx_pos += cw2 + int(10 * s)

    # エール
    cy3 = cy2 + int(210 * s)
    draw_rounded_card(d, (mx, cy3, mx + w - 2 * mx, cy3 + int(300 * s)), int(24 * s), (255, 245, 250, 240))
    d.text((mx + int(30 * s), cy3 + int(20 * s)), "エール", font=body_font, fill=PINK)
    d.text((mx + int(30 * s), cy3 + int(70 * s)), "今日、散歩に出かけられたんだね。", font=label_font, fill=DARK)
    d.text((mx + int(30 * s), cy3 + int(110 * s)), "それだけで素敵なこと。", font=label_font, fill=DARK)
    d.text((mx + int(30 * s), cy3 + int(150 * s)), "よくがんばったね。", font=label_font, fill=DARK)

    draw_tab_bar(d, w, h, 1, s)
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    return img


def mock_premium(size: tuple, s: float) -> Image.Image:
    """プレミアム案内画面"""
    w, h = size
    img = Image.new("RGB", (w, h))
    draw_gradient(img)
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    draw_status_bar(d, w, s)

    title_font = load_jp_font(int(56 * s))
    d.text((int(56 * s), int(110 * s)), "マイページ", font=title_font, fill=DARK)

    mx = int(40 * s)
    cw = w - 2 * mx

    # プランカード
    cy = int(240 * s)
    draw_rounded_card(d, (mx, cy, mx + cw, cy + int(500 * s)), int(24 * s), CARD_BG)

    plan_font = load_jp_font(int(44 * s))
    d.text((mx + int(30 * s), cy + int(30 * s)), "Premium プラン", font=plan_font, fill=PINK)

    body_font = load_jp_font(int(30 * s))
    features = [
        "エールが1日3回まで（Freeは1回）",
        "コンパニオンの着せ替え",
        "月次レポートのダウンロード",
        "エールの深さ・モードを選べる",
    ]
    fy = cy + int(100 * s)
    for feat in features:
        d.text((mx + int(50 * s), fy), f"・{feat}", font=body_font, fill=DARK)
        fy += int(52 * s)

    # ボタン
    btn_y = fy + int(30 * s)
    btn_h = int(64 * s)
    draw_rounded_card(d, (mx + int(60 * s), btn_y, mx + cw - int(60 * s), btn_y + btn_h), int(32 * s), (PINK[0], PINK[1], PINK[2], 255))
    btn_font = load_jp_font(int(30 * s))
    btn_text = "Premium を始める"
    bbox = d.textbbox((0, 0), btn_text, font=btn_font)
    btx = mx + (cw - (bbox[2] - bbox[0])) // 2
    d.text((btx, btn_y + int(16 * s)), btn_text, font=btn_font, fill=(255, 255, 255))

    draw_tab_bar(d, w, h, 2, s)
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    return img


def mock_companion(size: tuple, s: float) -> Image.Image:
    """コンパニオン成長画面"""
    w, h = size
    img = Image.new("RGB", (w, h))
    draw_gradient(img)
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    draw_status_bar(d, w, s)

    title_font = load_jp_font(int(56 * s))
    d.text((int(56 * s), int(110 * s)), "いま", font=title_font, fill=DARK)

    # コンパニオンエリア
    cx = w // 2
    cy = int(400 * s)
    r = int(160 * s)

    # 成長リング
    d.arc((cx - r, cy - r, cx + r, cy + r), 0, 270, fill=PINK, width=int(8 * s))
    # たまご
    egg_r = int(100 * s)
    d.ellipse((cx - egg_r, cy - int(egg_r * 1.1), cx + egg_r, cy + int(egg_r * 0.9)), fill=(255, 230, 235))
    d.ellipse((cx - int(egg_r * 0.8), cy - int(egg_r * 0.9), cx + int(egg_r * 0.8), cy + int(egg_r * 0.7)), fill=(255, 245, 248))

    name_font = load_jp_font(int(38 * s))
    d.text((cx - int(40 * s), cy + r + int(20 * s)), "たまご", font=name_font, fill=DARK)

    stat_font = load_jp_font(int(26 * s))
    d.text((cx - int(90 * s), cy + r + int(70 * s)), "累計 2 XP ・ 続いている日 2", font=stat_font, fill=GRAY)

    # メッセージカード
    mx = int(40 * s)
    my = cy + r + int(140 * s)
    cw = w - 2 * mx
    draw_rounded_card(d, (mx, my, mx + cw, my + int(260 * s)), int(24 * s), CARD_BG)
    body_font = load_jp_font(int(32 * s))
    d.text((mx + int(30 * s), my + int(20 * s)), "相棒がそばにいる感覚", font=load_jp_font(int(40 * s)), fill=PINK)
    d.text((mx + int(30 * s), my + int(80 * s)), "記録を重ねるほど、", font=body_font, fill=DARK)
    d.text((mx + int(30 * s), my + int(120 * s)), "小さな相棒も一緒に成長します。", font=body_font, fill=DARK)
    d.text((mx + int(30 * s), my + int(180 * s)), "一人じゃない安心感を届けたい。", font=body_font, fill=DARK)

    draw_tab_bar(d, w, h, 0, s)
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    return img


def mock_closing(size: tuple, s: float) -> Image.Image:
    """クロージング画面"""
    w, h = size
    img = Image.new("RGB", (w, h))
    draw_gradient(img)
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    # 中央に大きなメッセージ
    mx = int(80 * s)
    cy = int(h * 0.3)

    title_font = load_jp_font(int(64 * s))
    body_font = load_jp_font(int(36 * s))

    d.text((mx, cy), "完璧じゃなくていい", font=title_font, fill=PINK)

    ty = cy + int(100 * s)
    lines = [
        "エールミーは、",
        "あなたを変えようとする",
        "アプリではありません。",
        "",
        "今日をそのまま受け止め、",
        "明日を少しだけやわらかくする、",
        "そんな居場所です。",
    ]
    for line in lines:
        if line:
            d.text((mx, ty), line, font=body_font, fill=DARK)
        ty += int(56 * s)

    # アプリ名
    app_font = load_jp_font(int(44 * s))
    d.text((mx, ty + int(40 * s)), "エールミー", font=app_font, fill=PINK)
    sub_font = load_jp_font(int(28 * s))
    d.text((mx, ty + int(100 * s)), "— 今日をほどく日記アプリ", font=sub_font, fill=GRAY)

    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    return img


MOCK_SCREENS = [
    ("05_diary_input", mock_diary_input),
    ("06_yell_detail", mock_yell_detail),
    ("07_history_detail", mock_history_detail),
    ("08_premium", mock_premium),
    ("09_companion", mock_companion),
    ("10_closing", mock_closing),
]


def main() -> None:
    OUT_IPHONE.mkdir(parents=True, exist_ok=True)
    OUT_IPAD.mkdir(parents=True, exist_ok=True)

    # 既存ファイルをクリア
    for d in (OUT_IPHONE, OUT_IPAD):
        for f in d.glob("*.png"):
            f.unlink()

    # 1. 実スクショをリサイズ
    for src, slug in zip(REAL_SCREENSHOTS, REAL_SLUGS):
        if not src.exists():
            print(f"  SKIP (not found): {src}")
            continue
        im_phone = resize_real(src, IPHONE_SIZE)
        im_phone.save(OUT_IPHONE / f"{slug}.png", optimize=True)
        im_pad = resize_real(src, IPAD_SIZE)
        im_pad.save(OUT_IPAD / f"{slug}.png", optimize=True)
        print(f"  Real: {slug}")

    # 2. モック画面を生成
    for slug, func in MOCK_SCREENS:
        im_phone = func(IPHONE_SIZE, 1.0)
        im_phone.save(OUT_IPHONE / f"{slug}.png", optimize=True)
        im_pad = func(IPAD_SIZE, 2048 / 1284)
        im_pad.save(OUT_IPAD / f"{slug}.png", optimize=True)
        print(f"  Mock: {slug}")

    print(f"\n完了: iPhone {len(list(OUT_IPHONE.glob('*.png')))}枚, iPad {len(list(OUT_IPAD.glob('*.png')))}枚")


if __name__ == "__main__":
    main()
