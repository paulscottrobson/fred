
import re

#
#	Base Class
#
class BaseLine:
	def __init__(self,address = -1):
		self.address = address
	def compileBytes(self,byteArray):
		pass

#
#	Blank Line
#
class BlankLine(BaseLine):
	def render(self):
		return ""

#
#	Stand alone comment
#
class CommentLine(BaseLine):
	def __init__(self,comment,address = -1):
		BaseLine.__init__(self,address)
		self.comment = comment;
	def render(self):
		if self.comment.find("*****") >= 0:
			return ";"+self.comment
		else:
			return ";   " + self.comment

#
#	Centred comment line
#
class CentreCommentLine(CommentLine):
	def __init__(self,comment,starWidth,address = -1):
		CommentLine.__init__(self,comment,address)
		self.starWidth = starWidth
	def render(self):
		spaces = self.starWidth / 2 - len(self.comment) / 2
		spaces = spaces if spaces > 0 else 0
		return ";"+(" "*spaces)+self.comment

#
#	Line of code.
#
class CodeLine(BaseLine):
	def __init__(self,line):
		self.byteData = []
		self.labelName = ""
		self.assemblerCode = ""
		self.comment = ""
		m = re.match("^([0-9A-F]+)\\s*(.*)$",line)
		assert m is not None,"Bad address"
		BaseLine.__init__(self,int(m.group(1),16))
		line = m.group(2)
		while re.match("^([0-9A-F][0-9A-F])\\s",line) is not None and line[:2] != "DB":
			self.byteData.append(int(line[:2],16))
			line = line[3:].strip()
		assert len(self.byteData) > 0,"No byte data"
		m = re.match("^([0-9A-Za-z_]+)\\:\\s*(.*)$",line)
		if m is not None:
			self.labelName = (m.group(1)+":").lower()
			line = m.group(2)
		if line.find(";") >= 0:
			n = line.find(";")
			self.comment = line[n+1:].strip()
			line = line[:n].strip()			
		assert line != "","No code in line"
		if line[:2] == "BT":
			line = "B"+line[2:]
		n = (line+" ").find(" ")
		line = (line[:n]+"         ")[:8]+(line[n:].strip())
		self.assemblerCode = line.lower().strip()

	def render(self):
		s = self.labelName+"\n" if self.labelName != "" else ""
		s = s +  "        {1:64} {2}".format(self.labelName,self.assemblerCode,"; "+self.comment if self.comment != "" else "")
		return s

	def compileBytes(self,byteArray):
		for i in range(0,len(self.byteData)):
			a = self.address + i 
			assert byteArray[a] is None,"Duplicate byte target"
			byteArray[a] = self.byteData[i]


class CodeTracker:
	def __init__(self):
		src = [x.strip().replace("\t"," ") for x in open("fel.src").readlines()]
		self.lines = []
		self.inStarBar = False
		self.starSize = 112
		for s in src:
			if s == "":
				self.lines.append(BlankLine())
			elif s[0] == ";":
				isStarBar = s.find("********") >= 0;
				if isStarBar:
					self.inStarBar = True
				if self.inStarBar:
					if isStarBar:
						self.lines.append(CommentLine("*" * self.starSize))
					else:
						self.lines.append(CentreCommentLine(s[1:].strip(),self.starSize))
				else: 
					self.lines.append(CommentLine(s[1:].strip()))

			else:
				self.inStarBar = False
				self.lines.append(CodeLine(s))

		h = open("fel.asm","w")
		included = False
		for d in self.lines:
			l =  d.render()+"\n"
			if l[0] != ';' and not included:
				included = True
				h.write("\n           include felinclude.inc\n")
			h.write(l)
		h.close()

		ocode = [ None ] * 1024
		for i in range(0x36F,1024):
			ocode[i] = 0x00
		for d in self.lines:
			d.compileBytes(ocode)
		for i in range(0,1024):
			if ocode[i] is None:
				print("No data at {0:x}".format(i))
		ocode = "".join([chr(x) for x in ocode])
		open("fel_src.bin","wb").write(ocode)

ct = CodeTracker()		