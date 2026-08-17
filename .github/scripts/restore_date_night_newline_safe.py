from pathlib import Path

TARGETS = [
    Path("lib/screens/decide_screen.dart"),
    Path("functions/index.js"),
]

styles = {}
for path in TARGETS:
    raw = path.read_bytes()
    styles[path] = b"\r\n" if b"\r\n" in raw else b"\n"

script = Path(".github/scripts/restore_date_night.py").read_text(encoding="utf-8")
exec(compile(script, "restore_date_night.py", "exec"), {"__name__": "__main__"})

for path in TARGETS:
    raw = path.read_bytes().replace(b"\r\n", b"\n")
    if styles[path] == b"\r\n":
        raw = raw.replace(b"\n", b"\r\n")
    path.write_bytes(raw)
