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
            m = re.match("COUNT:([0-9]+)#NN:([0-9]+)#PPN:([0-9]+)#API:([\w]+)#T:([0-9]+).txt", os.path.basename(filename))

            if (m):
                metadata["count"] = int(m.group(1))
                metadata["nn"] = int(m.group(2)) 
                metadata["ppn"] = int(m.group(3)) 
                metadata["api"] = m.group(4) 
                metadata["tsize"] = m.group(5) 

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

            m = re.match("read[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]*$", line)
            if (m):
                if m.group(8) not in data:
                    data[m.group(8)] = dict()
                data[m.group(8)]["read"] = float(m.group(1))
                data[m.group(8)]["ropen"] = float(m.group(4))
                data[m.group(8)]["rio"] = float(m.group(5))
                data[m.group(8)]["rclose"] = float(m.group(6))
                data[m.group(8)]["rtotal"] = float(m.group(7))
                data[m.group(8)]["riter"] = float(m.group(8))
                data[m.group(8)].update(metadata)

            m = re.match("write[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]*$", line)
            if (m):
                if m.group(8) not in data:
                    data[m.group(8)] = dict()
                data[m.group(8)] = {}
                data[m.group(8)]["write"] = float(m.group(1))
                data[m.group(8)]["wopen"] = float(m.group(4))
                data[m.group(8)]["wio"] = float(m.group(5))
                data[m.group(8)]["wclose"] = float(m.group(6))
                data[m.group(8)]["wtotal"] = float(m.group(7))
                data[m.group(8)]["witer"] = float(m.group(8))
                data[m.group(8)].update(metadata)


        for iteration,entry in data.items():
            if len(entry) == 19:
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
            app text, \
            nn int, \
            ppn int, \
            api text, \
            tsize float, \
            fsize float, \
            fsize_ctl txt, \
            ropen float, \
            rio float, \
            rclose float, \
            rtotal float, \
            read float, \
            riter float, \
            wopen float, \
            wio float, \
            wclose float, \
            wtotal float, \
            write float, \
            witer float, \
            primary key(filename, witer, riter) \
            )'
    conn.execute(tbl)
except:
    print("could not create db")



for filename in glob.glob(folder + "/*"):
    #print("Parsing " + filename)
    parse(filename, conn)

conn.commit()
conn.close()
