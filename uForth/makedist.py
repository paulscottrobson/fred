#
#	Makes the uForth base distributable.
#
import re

words = {}
																				# find all lines with [[ ]]
for l in [x for x in  open("uforth.lst").readlines() if x.find("[[") >= 0 and x.find("]]") >= 0]:
	m = re.search("[\\d+]\\/\\s*([0-9A-F]+).*\\[\\[(.*)\\]\\]",l)				# match against .lst format
	assert m is not None,l
	words[m.group(2).lower().strip()] = int(m.group(1),16)						# store in dictionary

core = [ord(x) for x in open("uforth.bin","rb").read(-1)]						# read core in
core = core[:words["$$topkernel"]]												# truncate at end of kernel.
while len(core) < 2048:															# pad out to 2k in size.
	core.append(0)

wordList = words.keys()															# sorted list of words
wordList.sort()
for w in wordList:																# for each word
	addr = words[w]																# write address high address low
	core.append(addr / 256)
	core.append(addr & 255)
	for c in w:																	# write name as ASCIIZ string
		core.append(ord(c))
	core.append(0)
core.append(0xFF)																# add end of dictionary marker.
core.append(0xFF)

while len(core) < 4096:															# pad out to 4k
	core.append(0xFF)

open("uforth.core","wb").write("".join([chr(x) for x in core]))					# write out core.			

print("uforth.core generated.")
print("Core size "+str(words["$$topkernel"])+" bytes.")
print("")
print("Vocabulary : "+" ".join(wordList))