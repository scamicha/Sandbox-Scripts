#!/usr/local/bin/python

#python script to parse and plot LNET self test numbers

import numpy
import matplotlib
#matplotlib.use('PS')
import matplotlib.pyplot as plt
import sys
import os

def main(*args):

    datadir = '../../SandboxData/lst_logs_ic_sc/'

    filelist = os.listdir(datadir)

    for f in filelist:
        entry = []
        params= f.split("-")
        print params
        entry.append(int(params[1].rstrip('cli')))
        entry.append(int(params[2].rstrip('srv')))
        entry.append(int(params[3].rstrip('concur')))
        dist = params[4].lstrip('dist:')
        if dist[0] == '1':
            entry.append(1)
        else:
            entry.append(0)
        if dist[-1] == 'i':
            entry.append(1)
        else:
            entry.append(0)
        if params[0].find('read') != -1:
            entry.append(1)
        else:
            entry.append(0)

    print entry
    

if __name__ == "__main__":
    main()
    
