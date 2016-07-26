import re

# ********************************************************************************************************************
#												Micro Forth Core Class
# ********************************************************************************************************************

class uForthCore:
	def __init__(self):
		self.core = [ord(x) for x in open("uforth.core").read(-1)]						# read in core file
		self.dictionary = {}															# extract dictionary.
		pos = 2048
		while self.core[pos] != 0xFF:													# keep going till done.
			addr = self.core[pos] * 256 + self.core[pos+1]								# word address.
			word = ""																	# extract ASCIIZ name
			pos += 2
			while self.core[pos] != 0:
				word = word + chr(self.core[pos])
				pos += 1
			pos += 1
			self.dictionary[word] = addr 												# store it.
		self.vocabulary = self.dictionary.keys()										# sorted vocab list
		self.vocabulary.sort()
	
	def getCore(self,address):
		return self.core[address]
	def getCoreSize(self):
		return self.dictionary["$$topkernel"]											# where code starts.
	def getVocabulary(self):
		return self.vocabulary
	def getWordAddress(self,word):
		return self.dictionary[word.lower()]

# ********************************************************************************************************************
#														Word source
# ********************************************************************************************************************

class WordStream:
	def __init__(self,fileList):
		self.words = []
		for f in fileList:																# for each file
			src = open(f).readlines()													# read in the source
			src = [x if x.find("//") < 0 else x[:x.find("//")] for x in src]			# remove comments
			src = " ".join(src).replace("\t"," ").replace("\n"," ").lower()				# one long string, no tab/return
			for w in src.split():														# split into words
				if w != "":																# append non null
					self.words.append(w)
		self.pointer = 0																# index into word stream

	def endOfStream(self):																# check end of stream
		return self.pointer >= len(self.words)
	def get(self):																		# get next word, "" if none.
		w = "" if self.endOfStream() else self.words[self.pointer]
		self.pointer += 1
		return w

# ********************************************************************************************************************
#														Compiler
# ********************************************************************************************************************

class Compiler:
	def __init__(self,wordStream):
		self.core = uForthCore()														# get the core object
		self.wordStream = wordStream 													# save reference to word stream.
		self.dictionary = {}															# copy it
		for word in self.core.getVocabulary():	
			self.dictionary[word] = self.core.getWordAddress(word)
		self.code = []																	# copy the core
		for i in range(0,self.core.getCoreSize()):
			self.code.append(self.core.getCore(i))
		self.pointer = self.core.getCoreSize() 											# next free address
		self.currentDefinition = None 													# current definition (for self)
		self.nextVariable = 0 															# next variable to be allocated
		self.pendingThen = None 														# no pending then
		self.isListing = True
		print("Loaded {0} bytes uForth core.".format(self.pointer))
		while not self.wordStream.endOfStream():
			self.compile(self.wordStream.get())

	def define(self,name,show = True):
		assert name != "","No name provided."											# check valid name
		self.dictionary[name] = self.pointer 											# remember pointer
		if self.isListing and show:
			print("{0:04x} ==== :{1} ====".format(self.pointer,name))

	def compile(self,word):
		if word == ':':																	# definition
			currentDefinition = self.pointer 
			self.define(self.wordStream.get())
		elif re.match("^\\-?\\d+$",word):												# decimal constant.
			self.compileConstant(int(word))
		elif re.match("^\\$[0-9a-f]+$",word):											# hexadecimal constant
			self.compileConstant(int(word[1:],16))
		else:
			assert word in self.dictionary,"Don't understand "+word 					# check the dictionary.
			self.compileWord(word)

	def compileConstant(self,constant):
		if str(constant) in self.dictionary:
			self.compileWord(str(constant))
		else:
			self.compileWord("literal")
			self.compileByte(constant,"("+str(constant)+")")

	def compileWord(self,word):
		assert word in self.dictionary,"Word "+word+" unknown."
		addr = self.dictionary[word]
		if addr < 0xF8:
			self.compileByte(addr,word)
		else:
			self.compileByte((addr >> 8) | 0xF8,word)
			self.compileByte(addr & 0xFF,"")

	def compileByte(self,byte,text):
		if self.isListing:
			print("{0:04x} {1:02x} {2}".format(self.pointer,byte,text))
		self.code.append(byte)
		self.pointer += 1
c = Compiler(WordStream(["test.u4"]))