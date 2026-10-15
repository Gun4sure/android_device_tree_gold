#!/usr/bin/env python3
# gen-stock-symvers.py <gold-kernel dir> <built Module.symvers>... > stock.symvers
#
# Source-built modules that call into a stock module (GOLD_STOCK_MODULES, or a
# GOLD_STOCK_REPLACEMENTS file) need the stock CRCs at modpost time. This lists
# what the stock modules in the Makefile's lists export (CRCs read from their
# __kcrctab*), leaving out symbols a source-built module already exports.
import os, re, struct, sys

def exports(path):
    d = open(path, 'rb').read()
    shoff, = struct.unpack_from('<Q', d, 0x28)
    shentsize, shnum, shstrndx = struct.unpack_from('<HHH', d, 0x3a)
    secs = [struct.unpack_from('<IIQQQQIIQQ', d, shoff + i * shentsize) for i in range(shnum)]
    def name(off, tab):
        return d[tab + off:d.index(b'\0', tab + off)].decode()
    symtab = next(s for s in secs if s[1] == 2)
    strtab = secs[symtab[6]][4]
    for i in range(symtab[5] // 24):
        st_name, _, _, shndx, value, _ = struct.unpack_from('<IBBHQQ', d, symtab[4] + i * 24)
        n = name(st_name, strtab)
        if n.startswith('__crc_') and 0 < shndx < shnum and secs[shndx][1] != 8:
            yield n[6:], struct.unpack_from('<I', d, secs[shndx][4] + value)[0]

here = os.path.dirname(os.path.abspath(__file__))
mk = open(os.path.join(here, 'Makefile')).read()
mods = []
for var in ('GOLD_STOCK_MODULES', 'GOLD_STOCK_REPLACEMENTS'):
    m = re.search(var + r' := \\\n((?:    \S+\.ko(?: \\)?\n)+)', mk)
    mods += re.findall(r'(\S+\.ko)', m.group(1))
built = set()
for f in sys.argv[2:]:
    built |= {l.split('\t')[1] for l in open(f) if '\t' in l}
seen = set()
for m in sorted(mods):
    for sub in ('vendor_ramdisk', 'vendor_dlkm'):
        p = os.path.join(sys.argv[1], sub, m)
        if os.path.exists(p):
            break
    for sym, crc in sorted(exports(p)):
        if sym not in built and sym not in seen:
            seen.add(sym)
            print('0x%08x\t%s\t%s\tEXPORT_SYMBOL\t' % (crc, sym, m[:-3]))
