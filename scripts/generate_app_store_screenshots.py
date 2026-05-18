#!/usr/bin/env python3
"""
App Store Connect 用の静止画スクショを、Apple が求める解像度で PNG 出力します。

- iPhone 6.5 インチ（縦）: 1284 x 2778
- iPad 13 インチ（縦）: 2048 x 2732

アプリの配色・タブ構成に近い簡略レイアウトです。審査で実 UI との一致を求められた場合は、
シミュレータで同解像度のキャプチャに差し替えてください。
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

TABS = ("いま", "きろく", "マイページ")

# HomeView のグラデに近い色
C_TOP = (255, 247, 239)
C_MID = (252, 224, 230)
C_BOT = (245, 200, 218)
CARD = (255, 255, 255, 235)
PINK = (220, 100, 140)
PINK_SOFT = (255, 182, 193)


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
    last_err: Exception | None = None
    for p in _font_candidates():
        if not p.exists():
            continue
        try:
            return ImageFont.truetype(str(p), size=size)
        except Exception as e:
            last_err = e
    return ImageFont.load_default()


def lerp_color(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def draw_vertical_gradient(img: Image.Image) -> None:
    w, h = img.size
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        if t < 0.5:
            c = lerp_color(C_TOP, C_MID, t * 2)
        else:
            c = lerp_color(C_MID, C_BOT, (t - 0.5) * 2)
        for x in range(w):
            px[x, y] = c


def rounded_rectangle(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int, int, int],
    radius: int,
    fill: tuple[int, int, int, int] | tuple[int, int, int],
) -> None:
    draw.rounded_rectangle(xy, radius=radius, fill=fill)


def draw_tab_bar(
    draw: ImageDraw.ImageDraw,
    w: int,
    h: int,
    active: int,
    font: ImageFont.FreeTypeFont,
    scale: float,
) -> None:
    bar_h = int(140 * scale)
    y0 = h - bar_h
    draw.rectangle([0, y0, w, h], fill=(255, 252, 252, 250))
    draw.line([0, y0, w, y0], fill=PINK_SOFT, width=2)
    tw = w // 3
    for i, label in enumerate(TABS):
        x0 = i * tw
        cx = x0 + tw // 2
        is_on = i == active
        color = PINK if is_on else (120, 120, 120)
        bbox = draw.textbbox((0, 0), label, font=font)
        twt = bbox[2] - bbox[0]
        tht = bbox[3] - bbox[1]
        tx = cx - twt // 2
        ty = y0 + (bar_h - tht) // 2
        draw.text((tx, ty), label, font=font, fill=color)


def draw_status_bar(draw: ImageDraw.ImageDraw, w: int, scale: float) -> None:
    pad = int(48 * scale)
    t = "9:41"
    font = load_jp_font(int(34 * scale))
    draw.text((pad, int(36 * scale)), t, font=font, fill=(40, 40, 40))


def wrap_lines(text: str, width_chars: int) -> list[str]:
    lines: list[str] = []
    for para in text.split("\n"):
        para = para.strip()
        if not para:
            continue
        lines.extend(textwrap.wrap(para, width=width_chars))
    return lines


def render_one(
    size: tuple[int, int],
    scale: float,
    active_tab: int,
    headline: str,
    body: str,
    chip_hint: str | None = None,
) -> Image.Image:
    w, h = size
    img = Image.new("RGB", (w, h))
    draw_vertical_gradient(img)
    draw = ImageDraw.Draw(img)

    draw_status_bar(draw, w, scale)

    margin = int(56 * scale)
    top_card = int(120 * scale)
    bottom_reserve = int(200 * scale)
    card_w = w - 2 * margin
    card_h = h - top_card - bottom_reserve
    card_xy = (margin, top_card, margin + card_w, top_card + card_h)

    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    rounded_rectangle(od, card_xy, int(36 * scale), CARD)
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    draw = ImageDraw.Draw(img)

    title_font = load_jp_font(int(52 * scale))
    body_font = load_jp_font(int(34 * scale))
    small_font = load_jp_font(int(28 * scale))

    tx = margin + int(40 * scale)
    ty = top_card + int(44 * scale)
    draw.text((tx, ty), headline, font=title_font, fill=PINK)

    ty += int(72 * scale)
    wrap_w = max(14, int(22 * w / 1284))
    for line in wrap_lines(body, wrap_w):
        draw.text((tx, ty), line, font=body_font, fill=(45, 45, 45))
        ty += int(52 * scale)

    if chip_hint:
        ty += int(24 * scale)
        chip_y = ty
        chip_pad_x = int(28 * scale)
        chip_pad_y = int(16 * scale)
        bbox = draw.textbbox((0, 0), chip_hint, font=small_font)
        cw = bbox[2] - bbox[0] + chip_pad_x * 2
        ch = bbox[3] - bbox[1] + chip_pad_y * 2
        rounded_rectangle(
            draw,
            (tx, chip_y, tx + cw, chip_y + ch),
            int(20 * scale),
            (255, 230, 238),
        )
        draw.text((tx + chip_pad_x, chip_y + chip_pad_y), chip_hint, font=small_font, fill=PINK)

    tab_font = load_jp_font(int(30 * scale))
    draw_tab_bar(draw, w, h, active_tab, tab_font, scale)
    return img


SCREENS: list[dict] = [
    {
        "slug": "01_ima_welcome",
        "tab": 0,
        "headline": "今日の自分に、そっと寄り添う",
        "body": "日記と「今日できたこと」を、無理のないペースで残せます。\n書き終えたあと、やさしいエールがそっと届きます。",
    },
    {
        "slug": "02_diary",
        "tab": 0,
        "headline": "今日はどんな一日でしたか",
        "body": "長くなくて大丈夫です。\n思いついたことだけ、気持ちだけでも、あなたの言葉をそのまま置いておけます。",
    },
    {
        "slug": "03_wins_chips",
        "tab": 0,
        "headline": "小さな「できたこと」も大切に",
        "body": "タップで選べるチップから、今日の一歩を拾い上げられます。\nどれを選んでも、あなたのペースが正解です。",
        "chip": "朝起きられた",
    },
    {
        "slug": "04_yell_message",
        "tab": 0,
        "headline": "責めない言葉で、そっと包む",
        "body": "「よくがんばったね」「それでも前に進んでいる」\nそんなトーンで、心をなでるように返事が届きます。",
    },
    {
        "slug": "05_history",
        "tab": 1,
        "headline": "きろくで、過去の自分に会いに行く",
        "body": "日付ごとに振り返れます。\nあの日の自分が残した言葉は、いまのあなたの支えにもなります。",
    },
    {
        "slug": "06_entry_detail",
        "tab": 1,
        "headline": "その日の記録を、じっくり",
        "body": "日記・できたこと・届いたエールをまとめて確認。\n変化に気づくきっかけにもなります。",
    },
    {
        "slug": "07_profile",
        "tab": 2,
        "headline": "マイページ",
        "body": "表示やプラン、利用規約への導線はここから。\nアプリを、自分に合う形に少しずつ整えられます。",
    },
    {
        "slug": "08_premium",
        "tab": 2,
        "headline": "Premium で、エールをもっと深く",
        "body": "短く軽やかに、もう少し丁寧に、などモードを選べます。\n無理な課金は不要で、無料でも十分お楽しみいただけます。",
    },
    {
        "slug": "09_companion",
        "tab": 0,
        "headline": "相棒がそばにいる感覚",
        "body": "記録を重ねるほど、小さな相棒も一緒に成長していきます。\n一人じゃない、という小さな安心感を届けたいアプリです。",
    },
    {
        "slug": "10_closing",
        "tab": 0,
        "headline": "完璧じゃなくていい",
        "body": "エールミーは、あなたを変えようとするアプリではありません。\n今日をそのまま受け止め、明日を少しだけやわらかくする、そんな居場所です。",
    },
]


def main() -> None:
    OUT_IPHONE.mkdir(parents=True, exist_ok=True)
    OUT_IPAD.mkdir(parents=True, exist_ok=True)

    for spec in SCREENS:
        slug = spec["slug"]
        tab = spec["tab"]
        headline = spec["headline"]
        body = spec["body"]
        chip = spec.get("chip")

        im_phone = render_one(IPHONE_SIZE, 1.0, tab, headline, body, chip)
        im_phone.save(OUT_IPHONE / f"{slug}.png", optimize=True)

        # iPad は同じ構図でスケールアップ（解像度は IPAD_SIZE 固定）
        im_pad = render_one(IPAD_SIZE, 2048 / 1284, tab, headline, body, chip)
        im_pad.save(OUT_IPAD / f"{slug}.png", optimize=True)

    print("Wrote:")
    for d in (OUT_IPHONE, OUT_IPAD):
        for p in sorted(d.glob("*.png")):
            print(" ", p)


if __name__ == "__main__":
    main()
