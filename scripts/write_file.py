import sys, os, base64
path = sys.argv[1]
b64_str = sys.argv[2]
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w", encoding="utf-8") as out:
    out.write(base64.b64decode(b64_str).decode("utf-8"))
print(f"Wrote {path}")
