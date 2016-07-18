#
#	Generate assembler for font.
#
def writeAssembler(fileName,binaryData,origin,startBin,endBin):
	h = open(fileName,"wb")
	h.write(";\n; automatically generated font data and/or index file.\n;\n")
	h.write("    org 0{0:04X}H\n".format(origin))
	for offset in range(startBin,endBin+1):
		h.write("    db 0{0:02X}H\n".format(binaryData[offset]))
	h.close()

src = [x.strip().upper() for x in open("font.txt").readlines()]
src = [x for x in src if x != ""]
current = -1

page3 = [ None ] * 256
charAddr = [ None ] * 128
page6 = [ None ] * 64

for l in src:
	#print(l)
	if l.find("/") >= 0:
		l1 = l.split("/")
		current = int(l1[0],16)
		ascCode = ord((l1[1]+" ")[0])
		if l[-2:] == "//":
			ascCode = 47
		assert charAddr[ascCode] is None
		charAddr[ascCode] = current
		if (ascCode >= 48 and ascCode <= 57) or (ascCode >= 65 and ascCode <= 70):
			n = int(chr(ascCode),16)
			assert page3[n] is None
			page3[n] = current	
	else:
		assert len(l) == 5
		value = int(l.replace(".","0").replace("X","1"),2) << 2
		assert page3[current] is None or page3[current] == value,"Value is {1:x} {0:05b} writing {2:05b}".format(page3[current],current,value)
		page3[current] = value
		current += 1

for i in range(32,96):
	assert charAddr[i] is not None,str(i)+" "+chr(i)+" missing."
	page6[i & 0x3F] = charAddr[i]

for i in range(0,256):
	if page3[i] is None:
		page3[i] = 0xFF

writeAssembler("basicFont.inc",page3,0x300,0x00,0x6E)				# the basic font from 300-36E
writeAssembler("extendedFont.inc",page3,0x36F,0x6F,0xFF)			# the extended font from 36E - 3FF
writeAssembler("extendedIndex.inc",page6,0x6B0,0x00,0x3F)			# the extended font index from 6B0-6EF
