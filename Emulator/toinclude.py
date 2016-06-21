#
#	Convert test.bin to include file
#
code = open("test.bin","rb").read(-1)
code = [str(ord(c)) for c in code]
open("__1801code.h","w").write(",".join(code))