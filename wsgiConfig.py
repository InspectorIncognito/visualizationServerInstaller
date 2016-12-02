import sys
import os

if len(sys.argv) < 2:
    pass
else:
    pathProject =  sys.argv[1]
    FILE = open(pathProject + '/visualization/visualization/wsgi.py','r')
 
    newLine = []
 
    for line in FILE:
         if "sys.path.append" in line:
               newLine.append('sys.path.append(\'' + pathProject + '/visualization\')\n')
         else:
               newLine.append(line)

    FILE.close()

    FILE = open(pathProject + '/visualization/visualization/wsgi.py','w')
    for line in newLine:
        FILE.write(line)
    FILE.close()
