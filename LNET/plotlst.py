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

    for fname in filelist:
        params= fname.split("-")
        print params
        clinum = int(params[1].rstrip('cli'))
        srvnum = int(params[2].rstrip('srv'))
        concur = int(params[3].rstrip('concur'))
        dist = params[4].lstrip('dist:')
        if dist[0] == '1':
            distype = '1to1'
        else:
            distype = '1ton'
        if dist[-1] == 'i':
            clisrv = 'cli'
        else:
            clisrv = 'srv'

        entry= dict(clients=clinum, servers=srvnum, rpcs=concur, distrib=distype,
                    measure=clisrv)
        f = open(fname,'r')
        aggregate = array([])
        if entry['measure'] == 'cli':
            numlines = entry['clients']
        else:
            numlines = entry['servers']
        allines = f.readlines()
        for line in xrange(1,numlines):
            if line == 1:
                if entry['measure'] == 'srv':
                    testline = allines[4]
                else:
                    testline = allines[5]
            else:
                if entry['measure'] == 'srv':
                    testline = allines[6*line-2]
                else:
                    testline = allines[6*line-1]
            aggregate.append(testline.split()[2])
        entry['sum'] = aggregate.sum()
        entry['stdev'] = aggregate.std()
        
        del entry

    

if __name__ == "__main__":
    main()
    
