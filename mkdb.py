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
__date__ = "2017"


def parse(filename, conn):
    exptype = 0

    data = {}
    ior_type = "ddn"
    with open(filename, "r") as f:
        data["filename"] = filename
        iotype = "write"
        for line in f:
                         #./output/PROG:benchtool#NN:2#PPN:2#TYPE:ind#CHUNKED:notset#FILLED:notset#UNLIMITED:notset#output:10:500:20:100.txt
                           #output COUNT:2       TAG:20171         #PROG:ior#    NN:12#      PPN:2#       TYPE:ind#    IFACE:mpio#   FS:lustre# CHUNKED:notset# FILLED:notset# UNLIMITED:notset #output:100:16:64:4.txt
            m = re.match("COUNT:([0-9]+)#TAG:([0-9]+_[0-9]+)#PROG:([\w]+)#NN:([0-9]+)#PPN:([0-9]+)#TYPE:([\w]+)#IFACE:([\w]+)#FS:([\w]+)#CHUNKED:([\w]+)#FILLED:([\w]+)#UNLIMITED:([\w]+)#output:([0-9]+):([0-9]+):([0-9]+):([0-9]+).txt", os.path.basename(filename))

            if (m):
                data["count"] = int(m.group(1))
                data["tag"] = m.group(2)
                data["app"] = m.group(3)
                data["nn"] = int(m.group(4)) 
                data["ppn"] = int(m.group(5)) 
                data["type"] = m.group(6) 
                data["iface"] = m.group(7) 
                data["fs"] = m.group(8) 
                data["chunked"] = m.group(9) 
                data["filled"] = m.group(10) 
                data["unlimited"] = m.group(11) 
                data["t"] = int(m.group(12)) 
                data["x"] = int(m.group(13)) 
                data["y"] = int(m.group(14)) 
                data["z"] = int(m.group(15)) 
            else:
                print('couldn\'t parse', os.path.basename(filename))
                print(data)
                quit()
                
#access    bw(MiB/s)  block(KiB) xfer(KiB)  open(s)    wr/rd(s)   close(s)   total(s)   iter
#------    ---------  ---------- ---------  --------   --------   --------   --------   ----
#write     1051.96    100.00     100.00     0.002366   0.006890   0.000023   0.009283   0   
#read      71.04      100.00     100.00     0.000605   0.136745   0.000111   0.137470   0   
#remove    -          -          -          -          -          -          0.005926   0   

#Max Write: 1051.96 MiB/sec (1103.06 MB/sec)
#Max Read:  71.04 MiB/sec (74.49 MB/sec)

#Summary of all tests:
#Operation   Max(MiB)   Min(MiB)  Mean(MiB)     StdDev    Mean(s) Test# #Tasks tPN reps fPP reord reordoff reordrand seed segcnt blksiz xsize aggsize API RefNum
#write        1051.96    1051.96    1051.96       0.00    0.00928 0 1 1 1 1 1 1 0 0 100 102400 102400 10240000 POSIX 0
#read           71.04      71.04      71.04       0.00    0.13747 0 1 1 1 1 1 1 0 0 100 102400 102400 10240000 POSIX 0

                #m = re.match("read[\s]+
                #([0-9.]+)[\s]+
                #([0-9.]+)[\s]+
                #([0-9.]+)[\s]+
                #([0-9.]+)[\s]+
                #([0-9.]+)[\s]+
                #([0-9.]+)[\s]+
                #([0-9.]+)[\s]+
                #([0-9.]+)[\s].", line)

            if ('ior' == data['app']):
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
                    ior_type = "default"
                m = re.match("write[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]*$", line)
                if (m):
                    data["write"] = float(m.group(1))
                    data["wopen"] = float(m.group(4))
                    data["wio"] = float(m.group(5))
                    data["wclose"] = float(m.group(6))
                    data["wtotal"] = float(m.group(7))
                    ior_type = "default"

                if ("ddn" == ior_type):
                   m = re.match("read[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s].*$", line)
                   if (m):
                       data["read"] = float(m.group(1))
                       data["ropen"] = -1
                       data["rio"] = data["fsize"] / 1024 / 1024 / data["read"] # approximation
                       data["rclose"] = -1
                       data["rtotal"] = data["fsize"] / 1024 / 1024 / data["read"]
                   m = re.match("write[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s]+([0-9.]+)[\s].*$", line)
                   if (m):
                       data["write"] = float(m.group(1))
                       data["wopen"] = -1
                       data["wio"] = data["fsize"] / 1024 / 1024 / data["write"] # approximation
                       data["wclose"] = -1
                       data["wtotal"] = data["fsize"] / 1024 / 1024 / data["write"]


            elif('benchtool' == data['app']):
                m = re.match("benchmark:write[\s]*Open time[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*secs ", line)
                if (m):
                    data["wopen"] = float(m.group(2))
                m = re.match("benchmark:write[\s]*I/O Performance \(w/o open/close\)[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*MiB/s ", line)
                if (m):
                    data["write"] = float(m.group(2))
                m = re.match("benchmark:write[\s]*Close time[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*secs ", line)
                if (m):
                    data["wclose"] = float(m.group(2))
                    data["wtotal"] = data["wopen"] + data["wclose"] + data["wio"]
                m = re.match("benchmark:write[\s]*I/O time[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*secs ", line)
                if (m):
                    data["wio"] = float(m.group(2))
                

                m = re.match("benchmark:read[\s]*Open time[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*secs ", line)
                if (m):
                    data["ropen"] = float(m.group(2))
                m = re.match("benchmark:read[\s]*I/O Performance \(w/o open/close\)[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*MiB/s ", line)
                if (m):
                    data["read"] = float(m.group(2))
                m = re.match("benchmark:read[\s]*Close time[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*secs ", line)
                if (m):
                    data["rclose"] = float(m.group(2))
                    data["rtotal"] = data["ropen"] + data["rclose"] + data["rio"]
                m = re.match("benchmark:read[\s]*I/O time[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*([0-9.]+)[\s]*secs ", line)
                if (m):
                    data["rio"] = float(m.group(2))


                m = re.match("Datasize[\s]+([0-9.]+)[\s]+bytes.*", line)
                if (m):
                    data["fsize"] = float(m.group(1))
                    data["fsize_ctl"] = m.group(1)

            elif('iozone' == data['app']):
                print("App is not supported:", app)
                quit()
                m = re.match("\s+\w+\s+see\w* throughput for  \d readers\s+=\s+([0-9.]+)\s+kB/sec", line)
                if (m):
                 data['read'] = float(m.group(1)) / 1024

                m = re.match("\s+\w+\s+see\w* throughput for  \d initial writers\s+=\s+([0-9.]+)\s+kB/sec", line)
                if (m):
                 data['write'] = float(m.group(1)) / 1024
            else:
                print("Error: Unknow app", app)
                quit()

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
            tag text, \
            app text, \
            nn int, \
            ppn int, \
            type text, \
            iface text, \
            fs text, \
            chunked boolean, \
            filled boolean, \
            unlimited boolean, \
            t float, \
            x float, \
            y float, \
            z float, \
            fsize float, \
            fsize_ctl text, \
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
