#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
main = root / "Sources" / "HermesTokenBar" / "main.swift"
text = main.read_text()
for forbidden in ["NSPanel", "setupFloatingPanel", "panelLabel", "togglePanel", "Hide Floating Badge", "orderFrontRegardless", ".screenSaver"]:
    if forbidden in text:
        raise SystemExit(f"FAIL: floating window residue found: {forbidden}")
print("PASS: no floating window code")
