import sys,base64
data=base64.b64decode(sys.argv[1])
open(sys.argv[2],"wb").write(data)
print("ok",len(data))
