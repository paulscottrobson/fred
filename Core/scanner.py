# *********************************************************************************************************************
#
#		1801 Call System Scanner. Goes through source code looking for FUNC_xxxx and builds a data
#		segment where C_xxxx points to FUNC_xxxx
#
# *********************************************************************************************************************

scanQueue = ["test.asm"]														# list of files to process
functions = {} 																	# hash of functions (keys = function names)

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

h = open("core.mod","w")														# create the vector table.
for f in functions.keys():
	h.write("C_{0}:\n    dw {1}\n".format(f[5:],f))