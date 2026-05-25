#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
main = root / "Sources" / "HermesTokenBar" / "main.swift"
text = main.read_text()

required = [
    'statusItem.button?.title = "0.0M"',
    'statusItem.button?.title = "D \\(formatMillions(stats.today.totalTokens))"',
    'addDisabled("Today total: \\(formatMillions(stats.today.totalTokens)) tokens", tone: .today)',
    'addDisabled("Month total: \\(formatMillions(stats.month.totalTokens)) tokens", tone: .month)',
    'addDisabled("  \\(item.model): \\(formatMillions(item.totalTokens))")',
    'formatter.numberStyle = .decimal',
    'return "\\(grouped)M"',
]
for needle in required:
    if needle not in text:
        raise SystemExit(f"FAIL: expected unified M formatting not found: {needle}")

for forbidden in [
    'formatThousands',
    '%.1fK',
    'formatFull(item.totalTokens)',
    'statusItem.button?.title = "0K"',
    'updated: Hermes',
]:
    if forbidden in text:
        raise SystemExit(f"FAIL: old token formatting residue found: {forbidden}")

print("PASS: unified M unit and grouped numeric formatting")
