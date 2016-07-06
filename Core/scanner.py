# *********************************************************************************************************************
#
#		1801 Call System Scanner. Goes through source code looking for FUNC_xxxx and builds a data
#		segment where C_xxxx points to FUNC_xxxx
#
# *********************************************************************************************************************

import re

scanQueue = ["test.asm"]														# list of files to process
functions = {} 																	# hash of functions (keys = function names)
font = "" 																		# list of characters

while len(scanQueue) != 0:
	print("Scanning "+scanQueue[0])
	src = open(scanQueue[0]).readlines()										# read source in.	
	scanQueue = scanQueue[1:]													# pop from list.
	src = [x if x.find(";") < 0 else x[:x.find(";")] for x in src]				# remove comments
	src = [x.strip().replace("\t"," ") for x in src]							# tidy up tabs and spacing
	for l in src:
		if l.find("include") >= 0:												# do we have an include ?
			f = l[l.find("include")+7:].strip().replace('"',"").replace("'","")	# get the file name
			if f[-4:] != ".mod":
				scanQueue.append(f) 											# and append it if not a .MOD file.
		if l[:4] == "FUNC":														# function definition found ?
			f = l[:l.find(":")].strip() 										# found a function
			if f not in functions:												# new function ?
				print("    found "+f)
				functions[f] = True
		if l[:4] == "font":														# found a font statement
			m = re.match('font\\s*\\=\\s*\\"(.*)\\"',l)							# find the font characters.
			assert m is not None 												# add them individually checking for duplicates
			for c in m.group(1).upper():							
				if font.find(c) <= 0:
					font = font + c

h = open("vector.mod","w")														# create the vector table.
h.write(";\n; generated vector table\n;\n")
for f in functions.keys():
	h.write("C_{0}:\n    dw {1}\n".format(f[5:],f))
print("Created function vector table.")

fontData = [ None ] * 128														# read in font table
current = -1
for l in open("font.src").readlines():
	l = l.strip()

	if l[:1] == '[':
		current = ord(l[1].upper())
		assert fontData[current] is None
		fontData[current] = []

	if re.match("^[\\s\\.X]+$",l) is not None:
		fontData[current].append(l.replace(" ","."))

for i in range(0,128):															# make them all the same length
	if fontData[i] is not None:
		assert len(fontData[i]) == 7,chr(i)+" has wrong length"
		size = max([len(x) for x in fontData[i]])
		fontData[i] = [(x+".......")[:size] for x in fontData[i]]

h = open("font.mod","w")
h.write(";\n; generated fonts\n;\n")
h.write("__fontData:\n")
for ch in font:
	n = ord(ch)
	assert fontData[n] is not None,"Missing char "+ch

	data = [] 																	# byte data for given character
	for byte in range(0,len(fontData[n][0])):									# for each byte
		result = 0 																# bit 0 set on last. bit 1 top bit this col etc.
		for y in range(0,7):
			if fontData[n][y][byte] == 'X':
				result = result + (2 << y)
		data.append(result)
	data[len(fontData[n][0])-1] |= 1
	data = ["0{0:02x}h".format(n) for n in data]
	h.write("    db {0:32} ; '{1}' code {2}\n".format(",".join(data),ch,n))
h.close()	
print("Fonts generated ({0})".format(len(font)))