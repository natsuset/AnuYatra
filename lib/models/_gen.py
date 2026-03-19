import sys,base64,os
base=os.path.dirname(os.path.abspath(__file__))
b64file=os.path.join(base,"_b64data.txt")
lines=open(b64file).read().strip().split("---")
for entry in lines:
  parts=entry.strip().split("|",1)
  if len(parts)==2:
    fname,b64=parts
    fpath=os.path.join(base,fname.strip())
    open(fpath,"wb").write(base64.b64decode(b64.strip()))
    print("Created:",fname.strip())
