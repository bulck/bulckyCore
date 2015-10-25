
import os, sys

libPath = os.path.dirname(os.path.realpath(__file__))

for directory in os.listdir(libPath):
    sys.path.append(os.path.join(libPath,directory))

