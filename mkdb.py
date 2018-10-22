#!/usr/bin/env python3


import sys
import os
import re
import sqlite3
import traceback
import glob
import pprint

__version = "0.8"
__license__ = "GPL"
__author__ = "Eugen"
__date__ = "2018"


def parse(filename, conn):
    exptype = 0

    data = {}
    with open(filename, "r") as f:
        data["filename"] = filename
        for line in f:

             #COUNT:1#NN:1#PPN:4#API:POSIX#T:10485760.txt
            m = re.match("COUNT:([0-9]+)#NN:([0-9]+)#PPN:([0-9]+)#API:([\w]+)#T:([0-9]+).txt", os.path.basename(filename))

            if (m):
                data["count"] = int(m.group(1))
                data["nn"] = int(m.group(2)) 
                data["ppn"] = int(m.group(3)) 
                data["api"] = m.group(4) 
                data["tsize"] = m.group(5) 

            else:
                print('couldn\'t parse', os.path.basename(filename))
                print(data)
                quit()
                

            m = re.match("Command line used: .* -s[\s]+([0-9.]+)[\s]+-t[\s]+([0-9.]+)[\s]+-b[\s]+([0-9.]+)[\s]+-o.*", line)
            if (m):
                data["fsize"] = float(m.group(1)) * float(m.group(3)) * data["ppn"] * data["nn"]
                #print(data["fsize"], float(m.group(1)), float(m.group(3)), data["nn"], data["ppn"])
            #m = re.match("[\s]+aggregate filesize = ([0-9.]+)[\s]+.*", line)
            m = re.match("[\s]+aggregate filesize = (.*)", line)
            if (m):
                data["fsize_ctl"] = m.group(1)

            m = re.match("read[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]*$", line)
            if (m):
                data["read"] = float(m.group(1))
                data["ropen"] = float(m.group(4))
                data["rio"] = float(m.group(5))
                data["rclose"] = float(m.group(6))
                data["rtotal"] = float(m.group(7))
            m = re.match("write[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]*$", line)
            if (m):
                data["write"] = float(m.group(1))
                data["wopen"] = float(m.group(4))
                data["wio"] = float(m.group(5))
                data["wclose"] = float(m.group(6))
                data["wtotal"] = float(m.group(7))



        if len(data) == 28:
            print("Success")
            columns = ", ".join(data.keys())
            placeholders = ':' + ', :'.join(data.keys())
            try:
                conn.execute("INSERT INTO p (%s) VALUES (%s)" %(columns, placeholders), data)
            except sqlite3.IntegrityError as e:
                print("Already imported")
        else:
            print("Error in file %s with tuples %s size %d"% (filename, data, len(data)))

        exptype += 1;


#parse("./results/iozone/NP:2/C:0/T:100/output_app.txt", conn, style)
assert(3 == len(sys.argv))
folder = sys.argv[1]
dbname = sys.argv[2]

conn = sqlite3.connect(dbname)
try:
    tbl = 'CREATE TABLE p (\
            filename text, \
            count int, \
            app text, \
            nn int, \
            ppn int, \
            api text, \
            tsize float, \
            fsize float, \
            ropen float, \
            rio float, \
            rclose float, \
            rtotal float, \
            read float, \
            wopen float, \
            wio float, \
            wclose float, \
            wtotal float, \
            write float, \
            primary key(filename) \
            )'
    conn.execute(tbl)
except:
    print("could not create db")



for filename in glob.glob(folder + "/*"):
    #print("Parsing " + filename)
    parse(filename, conn)

conn.commit()
conn.close()
