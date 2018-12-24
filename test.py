from serial import Serial
import random
from sys import argv

con = Serial(argv[1])

run = ''

while run == '':
    run = raw_input()
    
    inData_list = random.sample(range(1, 256), 16)
    inData_array = bytearray(inData_list)
    
    con.write(str(inData_array))
    con.flush()
    utData_array = con.read(16)
    utData_list = map(ord, list(utData_array))

    print "IN:  ", inData_list
    print "OUT: ", utData_list
    print "Equals: ", sorted(inData_list) == utData_list
    print "\n"

con.close()



