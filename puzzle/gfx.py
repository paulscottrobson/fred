gfx = """
FFFF
FFFF
FFFF
FFFF

FFFF
FFFF
FCF8
F0F0

FFFF
FFFF
3F1F
0F1F

F0F0
F8FC
FFFF
FFFF

0F0F
1F3F
FFFF
FFFF

F0F0
F8FC
3F1F
0F0F

0F0F
1F3F
FCF8
F0F0

0000
0000
0000
0000
"""
gfx = gfx.replace("\n","")
assert len(gfx) == 128

for addr in range(0x3C0,0x400):
	p = (addr - 0x3C0) * 2
	b = int(gfx[p:p+2],16)
	s = "{0:08b}".format(b).replace("0",".").replace("1","X")
	print("    db 0{0:02x}h ; {1}".format(b,s))
	if addr % 8 == 7:
		print("")