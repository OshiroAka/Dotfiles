#!/usr/bin/env python3
import json
import os
from pathlib import Path

cache = Path.home() / ".cache/shiraos/last_pywal_colors.env"
wal_json = Path.home() / ".cache/wal/colors.json"

def clean_hex(value, fallback):
    value = (value or fallback or "").strip()
    if not value.startswith("#"):
        value = "#" + value
    if len(value) != 7:
        return fallback
    try:
        int(value[1:], 16)
        return value.upper()
    except Exception:
        return fallback

def emit(data):
    for key in ["PRIMARY", "BG", "FG", "SURFACE", "SECONDARY"]:
        print(f"{key}={data[key]}")

def read_cache():
    if not cache.exists():
        return None
    out = {}
    for line in cache.read_text(errors="ignore").splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip()
    required = ["PRIMARY", "BG", "FG", "SURFACE", "SECONDARY"]
    if all(k in out for k in required):
        return out
    return None

try:
    d = json.loads(wal_json.read_text(errors="ignore"))
    sp = d.get("special", {}) or {}
    co = d.get("colors", {}) or {}
    data = {
        "PRIMARY": clean_hex(co.get("color4") or co.get("color5"), "#88AAFF"),
        "BG": clean_hex(sp.get("background") or co.get("color0"), "#0E1010"),
        "FG": clean_hex(sp.get("foreground") or co.get("color15"), "#E0E0E0"),
        "SURFACE": clean_hex(co.get("color0") or sp.get("background"), "#1A1A1A"),
        "SECONDARY": clean_hex(co.get("color5") or co.get("color6") or co.get("color4"), "#88AAFF"),
    }
    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_text("\n".join(f"{k}={v}" for k, v in data.items()) + "\n")
    emit(data)
except Exception:
    cached = read_cache()
    if cached:
        emit(cached)
