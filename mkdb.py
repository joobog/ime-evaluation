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
    metadata = {}
    with open(filename, "r") as f:
        metadata["filename"] = filename
        for line in f:

             #COUNT:1#NN:1#PPN:4#API:POSIX#T:10485760.txt
             #merged_output/COUNT:1#NN:8#PPN:8#API:POSIX#T:16384#APP:ior-default#FS:lustre#IOTYPE:random#ACCESSTYPE:write#STRIPING:yes.txt

            m = re.match("COUNT:([0-9]+)#NN:([0-9]+)#PPN:([0-9]+)#API:([\w]+)#T:([0-9]+)#APP:([-\w]+)#FS:([\w]+)#IOTYPE:([\w]+)#ACCESSTYPE:([\w]+)#STRIPING:([\w]+).txt", os.path.basename(filename))

            if (m):
                metadata["count"] = int(m.group(1))
                metadata["nn"] = int(m.group(2)) 
                metadata["ppn"] = int(m.group(3)) 
                metadata["api"] = m.group(4) 
                metadata["tsize"] = m.group(5) 
                metadata["app"] = m.group(6)
                metadata["fs"] = m.group(7)
                metadata["iotype"] = m.group(8)
                metadata["accesstype"] = m.group(9)
                metadata["striping"] = m.group(10)

            else:
                print('couldn\'t parse', os.path.basename(filename))
                print(data)
                quit()
                

            m = re.match("Command line used: .* -s[\s]+([0-9.]+)[\s]+-t[\s]+([0-9.]+)[\s]+-b[\s]+([0-9.]+)[\s]+-o.*", line)
            if (m):
                metadata["fsize"] = float(m.group(1)) * float(m.group(3)) * data["ppn"] * data["nn"]

            m = re.match("[\s]+aggregate filesize = (.*)", line)
            if (m):
                metadata["fsize_ctl"] = m.group(1)

            m = re.match("(read|write)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]*$", line)
            if (m):
                if m.group(9) not in data:
                    data[m.group(9)] = dict()
                data[m.group(9)]["perf"] = float(m.group(2))
                data[m.group(9)]["open"] = float(m.group(5))
                data[m.group(9)]["io"] = float(m.group(6))
                data[m.group(9)]["close"] = float(m.group(7))
                data[m.group(9)]["total"] = float(m.group(8))
                data[m.group(9)]["iter"] = float(m.group(9))
                data[m.group(9)].update(metadata)



        for iteration,entry in data.items():
            if len(entry) == 18:
                print("Success")
                columns = ", ".join(entry.keys())
                placeholders = ':' + ', :'.join(entry.keys())
                try:
                    conn.execute("INSERT INTO p (%s) VALUES (%s)" %(columns, placeholders), entry)
                except sqlite3.IntegrityError as e:
                    print("Already imported")
            else:
                print("Error in file %s with tuples %s size %d"% (filename, entry, len(entry)))

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
            nn int, \
            ppn int, \
            api text, \
            tsize float, \
            app text, \
            fs text, \
            iotype text, \
            accesstype text, \
            striping text, \
            fsize float, \
            fsize_ctl txt, \
            open float, \
            io float, \
            close float, \
            total float, \
            perf float, \
            iter float, \
            primary key(filename, iter) \
            )'
    conn.execute(tbl)
except Exception as e:
    print("could not create db")
    print(e)



for filename in glob.glob(folder + "/*"):
    #print("Parsing " + filename)
    parse(filename, conn)

conn.commit()
conn.close()
