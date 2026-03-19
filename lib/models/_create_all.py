import os
B=os.path.dirname(os.path.abspath(__file__))
def w(name,content): open(os.path.join(B,name),"w").write(content); print(f"Created {name}")
