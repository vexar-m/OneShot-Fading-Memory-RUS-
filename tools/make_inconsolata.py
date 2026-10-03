from fontTools.ttLib import TTFont
import sys
src, dst = sys.argv[1], sys.argv[2]
f = TTFont(src)
for rec in f["name"].names:
    if rec.nameID in (1, 3, 4, 6, 16, 17, 21, 22):
        rec.string = "Inconsolata"
f.save(dst)
print("saved", dst)