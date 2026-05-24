#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "Sources" / "HermesTokenBar" / "main.swift"
source_text = source.read_text(errors="ignore")
files = [p for p in root.rglob("*") if p.is_file() and ".build" not in p.parts and ".git" not in p.parts and p.name != "check_release_hygiene.py"]
text_by_path = {p: p.read_text(errors="ignore") for p in files}
all_text = "\n".join(text_by_path.values())

required_in_source = [
    'ProcessInfo.processInfo.environment["HERMES_TOKENBAR_DB"]',
    'private let defaultDatabasePath = NSHomeDirectory() + "/.hermes/state.db"',
    'private var databasePathDisplay: String',
]
missing = [needle for needle in required_in_source if needle not in source_text]
if missing:
    print("FAIL: release hygiene requirement missing:")
    for needle in missing:
        print(f"- {needle}")
    raise SystemExit(1)

forbidden_user_path = "/Users/" + "muse"
forbidden_lab_path = "MUSE" + "_Pro_Lab"
forbidden_poc_home = "tokentracker" + "-poc-home"
forbidden_api_key = "API" + "_KEY="
forbidden_github_token = "GITHUB" + "_TOKEN="
for forbidden in [
    forbidden_user_path,
    forbidden_lab_path,
    forbidden_poc_home,
    forbidden_api_key,
    forbidden_github_token,
]:
    offenders = [str(p.relative_to(root)) for p, text in text_by_path.items() if forbidden in text]
    if offenders:
        print(f"FAIL: forbidden release text {forbidden!r} found in:")
        for offender in offenders:
            print(f"- {offender}")
        raise SystemExit(1)

print("PASS: release hygiene")
