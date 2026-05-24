#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
main = root / "Sources" / "HermesTokenBar" / "main.swift"
text = main.read_text()

required = [
    'addDisabled("  Input: \\(formatDetailTokens(stats.today.llmInputTokens)) tokens", tone: .input)',
    'addDisabled("  Output: \\(formatDetailTokens(stats.today.llmOutputTokens)) tokens", tone: .output)',
    'addDisabled("  Input: \\(formatDetailTokens(stats.month.llmInputTokens)) tokens", tone: .input)',
    'addDisabled("  Output: \\(formatDetailTokens(stats.month.llmOutputTokens)) tokens", tone: .output)',
    'private func formatDetailTokens(_ value: Int64) -> String',
    'return "\\(grouped)K"',
]
for needle in required:
    if needle not in text:
        raise SystemExit(f"FAIL: expected adaptive detail token formatting not found: {needle}")

for forbidden in [
    'Input: \\(formatMillions(stats.today.llmInputTokens))',
    'Output: \\(formatMillions(stats.today.llmOutputTokens))',
    'Input: \\(formatMillions(stats.month.llmInputTokens))',
    'Output: \\(formatMillions(stats.month.llmOutputTokens))',
]:
    if forbidden in text:
        raise SystemExit(f"FAIL: detail row still uses coarse M formatter: {forbidden}")

print("PASS: adaptive detail token formatting")
