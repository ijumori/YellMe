#!/usr/bin/env python3
"""
App Store Connect API で「日本語ローカライズ」の description / promotionalText だけを更新する。
キーワード・サブタイトル等は送らないため、他フィールドは ASC 上の既存値のまま。

必要な環境変数（archive-export-appstore.sh --upload と同じ）:
  ASC_API_ISSUER_ID   Issuer ID
  ASC_API_KEY_ID      鍵 ID（10桁）
  ASC_API_KEY_PATH    AuthKey_XXX.p8 のパス（リポジトリ外推奨）

任意:
  ASC_BUNDLE_ID   既定 com.takahiro.yellme
  ASC_LOCALE      既定 ja
  ASC_TEXT_ROOT   既定 <リポジトリ>/AppStoreMetadata/ja
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

import jwt
import requests

API = "https://api.appstoreconnect.apple.com/v1"


def make_token(issuer_id: str, key_id: str, key_path: Path) -> str:
    now = int(time.time())
    payload = {"iss": issuer_id, "iat": now, "exp": now + 19 * 60, "aud": "appstoreconnect-v1"}
    headers = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    raw = key_path.read_bytes()
    return jwt.encode(payload, raw, algorithm="ES256", headers=headers)


def get_json(session: requests.Session, url: str, params: dict | None = None) -> dict:
    r = session.get(url, params=params, timeout=120)
    if r.status_code >= 400:
        sys.stderr.write(f"GET {url} -> {r.status_code}\n{r.text}\n")
        r.raise_for_status()
    return r.json()


def patch_json(session: requests.Session, url: str, body: dict) -> dict:
    r = session.patch(url, json=body, timeout=120)
    if r.status_code >= 400:
        sys.stderr.write(f"PATCH {url} -> {r.status_code}\n{r.text}\n")
        r.raise_for_status()
    return r.json()


def find_app_id(session: requests.Session, bundle_id: str) -> str:
    data = get_json(session, f"{API}/apps", {"filter[bundleId]": bundle_id, "limit": 200})
    rows = data.get("data") or []
    if not rows:
        raise SystemExit(f"アプリが見つかりません: bundleId={bundle_id}")
    return rows[0]["id"]


def pick_ios_version_id(session: requests.Session, app_id: str) -> tuple[str, str]:
    """編集可能な iOS バージョンを1つ選ぶ。(version_id, version_string)"""
    data = get_json(
        session,
        f"{API}/apps/{app_id}/appStoreVersions",
        {"filter[platform]": "IOS", "limit": 50},
    )
    rows = data.get("data") or []
    preferred = [
        "PREPARE_FOR_SUBMISSION",
        "METADATA_REJECTED",
        "DEVELOPER_REJECTED",
        "REJECTED",
        "WAITING_FOR_REVIEW",
        "INVALID_BINARY",
    ]
    for st in preferred:
        for r in rows:
            if r["attributes"].get("appStoreState") == st:
                return r["id"], r["attributes"].get("versionString", "?")
    if rows:
        r = rows[0]
        return r["id"], r["attributes"].get("versionString", "?")
    raise SystemExit("appStoreVersions が空です。App Store Connect で iOS バージョンを作成してください。")


def find_localization_id(session: requests.Session, version_id: str, locale: str) -> str:
    data = get_json(session, f"{API}/appStoreVersions/{version_id}/appStoreVersionLocalizations", {"limit": 50})
    for row in data.get("data") or []:
        if row.get("attributes", {}).get("locale") == locale:
            return row["id"]
    locs = [r.get("attributes", {}).get("locale") for r in data.get("data") or []]
    raise SystemExit(f"locale={locale} のローカライズがありません。存在する locale: {locs}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="PATCH せず内容だけ表示")
    args = ap.parse_args()

    repo = Path(__file__).resolve().parents[1]
    bundle = os.environ.get("ASC_BUNDLE_ID", "com.takahiro.yellme")
    locale = os.environ.get("ASC_LOCALE", "ja")
    text_root = Path(os.environ.get("ASC_TEXT_ROOT", repo / "AppStoreMetadata" / "ja"))

    issuer = os.environ["ASC_API_ISSUER_ID"]
    kid = os.environ["ASC_API_KEY_ID"]
    key_path = Path(os.environ["ASC_API_KEY_PATH"]).expanduser()
    if not key_path.is_file():
        raise SystemExit(f"鍵ファイルがありません: {key_path}")

    desc = (text_root / "description.txt").read_text(encoding="utf-8").strip()
    promo = (text_root / "promotional.txt").read_text(encoding="utf-8").strip()
    if len(promo) > 170:
        raise SystemExit(f"promotionalText が170文字超: {len(promo)} 文字")

    token = make_token(issuer, kid, key_path)
    session = requests.Session()
    session.headers.update({"Authorization": f"Bearer {token}"})

    app_id = find_app_id(session, bundle)
    vid, vstr = pick_ios_version_id(session, app_id)
    loc_id = find_localization_id(session, vid, locale)

    print(f"app={bundle} appId={app_id}")
    print(f"version={vstr} versionId={vid} localizationId={loc_id} locale={locale}")

    body = {
        "data": {
            "type": "appStoreVersionLocalizations",
            "id": loc_id,
            "attributes": {"description": desc, "promotionalText": promo},
        }
    }

    if args.dry_run:
        print("--- dry-run: PATCH しません ---")
        print(json.dumps(body, ensure_ascii=False, indent=2)[:2000])
        return

    patch_json(session, f"{API}/appStoreVersionLocalizations/{loc_id}", body)
    print("PATCH 完了: description / promotionalText を更新しました。")


if __name__ == "__main__":
    main()
