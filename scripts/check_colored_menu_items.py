#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "Sources" / "HermesTokenBar" / "main.swift"
text = source.read_text()

required = [
    "enum MenuTone",
    "case today",
    "case input",
    "case output",
    "case month",
    "case secondary",
    "addDisabled(\"Today total: \\(formatMillions(stats.today.totalTokens)) tokens\", tone: .today)",
    "addDisabled(\"  Input: \\(formatDetailTokens(stats.today.llmInputTokens)) tokens\", tone: .input)",
    "addDisabled(\"  Output: \\(formatDetailTokens(stats.today.llmOutputTokens)) tokens\", tone: .output)",
    "addDisabled(\"Month total: \\(formatMillions(stats.month.totalTokens)) tokens\", tone: .month)",
    "addDisabled(\"  Input: \\(formatDetailTokens(stats.month.llmInputTokens)) tokens\", tone: .input)",
    "addDisabled(\"  Output: \\(formatDetailTokens(stats.month.llmOutputTokens)) tokens\", tone: .output)",
    "item.attributedTitle = attributedMenuTitle(title, tone: tone)",
    "NSAttributedString.Key.foregroundColor",
    "NSColor.systemBlue",
    "NSColor.systemGreen",
    "NSColor.systemOrange",
    "NSColor.systemPurple",
    "NSColor.secondaryLabelColor",
]

missing = [needle for needle in required if needle not in text]
if missing:
    print("FAIL: expected colored menu item implementation not found:")
    for needle in missing:
        print(f"- {needle}")
    raise SystemExit(1)

print("PASS: colored menu item implementation")
