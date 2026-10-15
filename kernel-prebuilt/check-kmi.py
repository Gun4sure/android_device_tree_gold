#!/usr/bin/env python3
# check-kmi.py <GKI Module.symvers> <module dir> <GKI module>...
#
# The modules shipped with Google's GKI kernel may use only what the GKI build
# exports, with its CRCs. For every module under <module dir> other than the
# GKI ones, each symbol it needs must be exported by the GKI build with the
# same CRC, or by another module there. Weak references may stay unresolved.
import os, struct, sys

gki = {}
for line in open(sys.argv[1]):
    f = line.rstrip('\n').split('\t')
    if len(f) >= 3:
        gki[f[1]] = int(f[0], 16)
gki_modules = set(sys.argv[3:])

def sections(d):
    shoff, = struct.unpack_from('<Q', d, 0x28)
    shentsize, shnum, shstrndx = struct.unpack_from('<HHH', d, 0x3a)
    secs = [struct.unpack_from('<IIQQQQIIQQ', d, shoff + i * shentsize) for i in range(shnum)]
    names = secs[shstrndx][4]
    return {d[names + s[0]:d.index(b'\0', names + s[0])].decode(): s for s in secs}, secs

exported, needed = set(), {}
for root, _, files in os.walk(sys.argv[2]):
    for name in files:
        if not name.endswith('.ko'):
            continue
        d = open(os.path.join(root, name), 'rb').read()
        by_name, secs = sections(d)
        s = by_name.get('__ksymtab_strings')
        if s:
            exported |= {x.decode() for x in d[s[4]:s[4] + s[5]].split(b'\0') if x}
        if name in gki_modules or '__versions' not in by_name:
            continue
        symtab = next(x for x in secs if x[1] == 2)
        strtab = secs[symtab[6]][4]
        weak = set()
        for i in range(symtab[5] // 24):
            st_name, info, _, shndx, _, _ = struct.unpack_from('<IBBHQQ', d, symtab[4] + i * 24)
            if shndx == 0 and info >> 4 == 2:
                weak.add(d[strtab + st_name:d.index(b'\0', strtab + st_name)].decode())
        v = by_name['__versions']
        for i in range(0, v[5], 64):
            crc = struct.unpack_from('<Q', d, v[4] + i)[0] & 0xffffffff
            sym = d[v[4] + i + 8:v[4] + i + 64].split(b'\0')[0].decode()
            if sym not in weak:
                needed.setdefault(name, []).append((sym, crc))

errors = []
for name, syms in sorted(needed.items()):
    for sym, crc in syms:
        if sym in gki:
            if gki[sym] != crc:
                errors.append('%s: %s has CRC %08x, GKI %08x' % (name, sym, crc, gki[sym]))
        elif sym not in exported:
            errors.append('%s: %s is not exported by GKI or by any module' % (name, sym))
for e in errors:
    print('check-kmi: ' + e, file=sys.stderr)
sys.exit(1 if errors else 0)
