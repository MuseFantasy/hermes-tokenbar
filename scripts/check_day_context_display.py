#!/usr/bin/env python3
from pathlib import Path

source = Path("Sources/HermesTokenBar/main.swift").read_text()

checks = [
    ('status bar uses D prefix', 'statusItem.button?.title = "D \\(formatMillions(stats.today.totalTokens))"'),
    ('menu shows Date row', 'addDisabled("Date: \\(formatDay(stats.refreshedAt))", tone: .today)'),
    ('menu shows Since row', 'addDisabled("Since: 00:00 local", tone: .secondary)'),
    ('formatDay helper exists', 'private func formatDay(_ date: Date) -> String'),
]

missing = [name for name, needle in checks if needle not in source]
if missing:
    print('FAIL: missing day context display checks:')
    for name in missing:
        print(f'  - {name}')
    raise SystemExit(1)

print('PASS: day context display is explicit')
