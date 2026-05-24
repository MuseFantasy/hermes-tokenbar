#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
main = root / "Sources" / "HermesTokenBar" / "main.swift"
text = main.read_text()

required = [
    'addDisabled("Today total: \\(formatMillions(stats.today.totalTokens)) tokens", tone: .today)',
    'addDisabled("  Input: \\(formatDetailTokens(stats.today.llmInputTokens)) tokens", tone: .input)',
    'addDisabled("  Output: \\(formatDetailTokens(stats.today.llmOutputTokens)) tokens", tone: .output)',
    'addDisabled("Month total: \\(formatMillions(stats.month.totalTokens)) tokens", tone: .month)',
    'addDisabled("  Input: \\(formatDetailTokens(stats.month.llmInputTokens)) tokens", tone: .input)',
    'addDisabled("  Output: \\(formatDetailTokens(stats.month.llmOutputTokens)) tokens", tone: .output)',
]
for needle in required:
    if needle not in text:
        raise SystemExit(f"FAIL: expected input/output breakdown not found: {needle}")

print("PASS: menu shows LLM input/output breakdown")
