#!/usr/local/bin/python

#python script to parse and plot LNET self test numbers

from numpy import *
import matplotlib
#matplotlib.use('PS')
import matplotlib.pyplot as plt
import sys
import os
import argparse
import csv

def main(*args):

    datadir = '../../SandboxData/lst_logs/'
    csvwrite = csv.writer(open('./summary.csv', 'wb'),dialect='excel',delimiter=',')

    parser = argparse.ArgumentParser(description='This program should read in LNET self test \
                                     data and make plots\n The syntax is as follows:\n \
                                     plotlst.py <clients> <servers> <concurrency> \
                                     <distribution> <measurement_point>\n \n Both distribution \
                                     and measurement_point must be defined. Distribution can\n \
                                     take the values "1to1" or "1ton". Measurement point can be \
                                     "cli" or "srv".\n One of clients, servers, or concurrency \
                                     can be "*" the run of these values will\n be the x-axis. \
                                     The other two must be specified.\n')

    bad_srv_file=False
    filelist = os.listdir(datadir)

    for fname in filelist:
        params= fname.split("-")
        print params
        clinum = int(params[1].rstrip('cli'))
        srvnum = int(params[2].rstrip('srv'))
        concur = int(params[3].rstrip('concur'))
        dist = params[4].lstrip('dist1')

        if dist[1] == '1':
            distype = '1to1'
        else:
            distype = '1ton'
        if dist[-1] == 'i':
            clisrv = 'cli'
        else:
            clisrv = 'srv'

        entry= dict(clients=clinum, servers=srvnum, rpcs=concur, distrib=distype,
                    measure=clisrv)
        f = open(datadir+fname,'r')
        tmp_list = []
        if entry['measure'] == 'cli':
            numlines = entry['clients']
        else:
            numlines = entry['servers']
        allines = f.readlines()

        if entry['measure'] == 'cli':
            if len(allines) != 6*entry['clients']:
                continue
            
        for line in xrange(1,numlines+1):
            if entry['measure'] == 'srv':
                if line == 1:
                    testline = allines[4]
                else:
                    testline = allines[6*line-2]
                if testline.split()[2] < 0.0:
                    bad_srv_file = True
            else:
                if line == 1:
                    testline = allines[5]
                else:
                    testline = allines[6*line-1]
            rate = testline.split()
            tmp_list.append(float(rate[2]))
        if bad_srv_file:
            del entry
            bad_srv_file=False
            continue
        aggregate = array(tmp_list)
        print aggregate
        print sum(aggregate)
        entry['sum'] = sum(aggregate)/1024.0
        entry['avg'] = average(aggregate)/1024.0
        entry['stdev'] = std(aggregate)/1024.0
        row = [entry['clients'],entry['servers'],entry['rpcs'],entry['distrib'],
               entry['measure'],entry['sum'],entry['avg'],entry['stdev']]
        csvwrite.writerow(row)
        
        del entry
        del aggregate

    

if __name__ == "__main__":
    main()
    
