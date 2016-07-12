#
#	Generate assembler for font.
#
src = [x.strip().upper() for x in open("font.txt").readlines()]
pendingLabel = ""
offset = 0x10
hexTable = [ None ] * 16
data = []

for l in src:
	if l[0] == '@':
		l = (l + " ")[:2]
		pendingLabel = l[1]
		if len(l) > 1 and "0123456789ABCDEF".find(l[1]) >= 0:
			hexTable[int(pendingLabel,16)] = offset
	else:
		data.append([0 if pendingLabel == "" else offset,"."+l+".."])
		offset += 1
		pendingLabel = ""

for i in range(0,16):
	print("{2:04X} {1:02X}   DB L{0:04X} & 255".format(hexTable[i]+0x300,hexTable[i] & 0xFF,i+0x300))

n = 0x310
for d in data:
	b = int(d[1].replace(".","0").replace("X","1"),2)
	l = "L{0:04X}".format(n)+":" if d[0] != 0 else ""
	print("{0:04X} {1:02X} {2:6}  DB 0{1:02X}H ; {3}".format(n,b,l,d[1]))
	n += 1
