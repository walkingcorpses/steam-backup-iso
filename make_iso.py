# make_iso.py - build a UDF ISO backup of a Steam game you own.
# The big game files come straight from the Steam install (read only);
# files ModPrep changed (steam_api*.dll, steam_settings\) come from the small
# prepped folder and replace the originals inside the image. This avoids a
# second full-size copy on disk.
# Usage: python -I make_iso.py <game folder> <prepped folder> <out.iso>
import os, sys, pycdlib

game, prepped, out = sys.argv[1:4]
TOP = os.path.basename(os.path.normpath(game))  # folder name inside the ISO
INSTALLER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "install.cmd")

# Map every relative path -> source file. Prepped files win over the originals.
files = {}
for base in (game, prepped):
    for root, _, names in os.walk(base):
        for n in names:
            full = os.path.join(root, n)
            files[os.path.relpath(full, base)] = full

iso = pycdlib.PyCdlib()
# ISO9660 level 4 + UDF 2.60: Windows mounts the UDF side, which keeps real names.
vol = "".join(c if c.isalnum() else "_" for c in TOP.upper())[:32]
iso.new(interchange_level=4, udf="2.60", vol_ident=vol)

def iso_name(rel):
    # ISO9660 side needs upper-case d-chars only; UDF side keeps the real name.
    return "/" + "/".join("".join(c if c.isalnum() or c == "_" else "_" for c in p.upper()) for p in rel.split("/"))

made = set()
def add_dirs(rel_dir):
    # Create each parent directory once, top-down.
    parts = rel_dir.split("/")
    for i in range(1, len(parts) + 1):
        d = "/".join(parts[:i])
        if d and d not in made:
            iso.add_directory(iso_name(d), udf_path="/" + d)
            made.add(d)

total = 0
for rel, src in sorted(files.items()):
    rel = TOP + "/" + rel.replace("\\", "/")
    add_dirs(rel.rsplit("/", 1)[0])
    # pycdlib keeps the path and reads the file only while writing the image.
    iso.add_file(src, iso_path=iso_name(rel) + ";1", udf_path="/" + rel)
    total += os.path.getsize(src)
iso.add_file(INSTALLER, iso_path="/INSTALL.CMD;1", udf_path="/install.cmd")

print(f"{len(files)} files, {total / 1e9:.1f} GB -> {out}", flush=True)
iso.write(out)
iso.close()
assert os.path.getsize(out) >= total, "ISO smaller than its contents"
print("done", flush=True)
