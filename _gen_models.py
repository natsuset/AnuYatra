#\!/usr/bin/env python3
import os, base64
B = os.path.dirname(os.path.abspath(__file__)) + "/lib/models"
def w(n, c): open(os.path.join(B, n), "w").write(c); print(f"Created {n}")
