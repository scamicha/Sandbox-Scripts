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
from operator import itemgetter

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

    alldata = []
    possible_clients = []
    possible_servers = []
    possible_rpcs    = []
    colors           = ['k','r','g','b']

    for fname in filelist:
        params= fname.split("-")
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
        if clinum not in possible_clients:
            possible_clients.append(clinum)
        if srvnum not in possible_servers:
            possible_servers.append(srvnum)
        if concur not in possible_rpcs:
            possible_rpcs.append(concur)
        aggregate = array(tmp_list)
        entry['sum'] = sum(aggregate)
        entry['avg'] = average(aggregate)
        entry['stdev'] = std(aggregate)
        row = [entry['clients'],entry['servers'],entry['rpcs'],entry['distrib'],
               entry['measure'],entry['sum'],entry['avg'],entry['stdev']]
        csvwrite.writerow(row)
        alldata.append(entry)
        
        del entry
        del aggregate
        
    clireq = 'secondary'
    rpcreq = 'primary'
    srvreq = 8
    distreq = '1ton'

    if clireq == 'primary':
        client_request = possible_clients
        primary = 'clients'
    elif clireq == 'secondary':
        client_request = possible_clients
        secondary = 'clients'
    else:
        client_request = [clireq]

    if srvreq == 'primary':
        server_request = possible_servers
        primary = 'servers'
    elif srvreq == 'secondary':
        server_request = possible_servers
        secondary = 'servers'
    else:
        server_request = [srvreq]
    
    if rpcreq == 'primary':
        concur_request = possible_rpcs
        primary = 'rpcs'
    elif rpcreq == 'secondary':
        concur_request = possible_rpcs
        secondary = 'rpcs'
    else:
        concur_request = [rpcreq]

    if distreq == 'secondary':
        distrib_request = ['1to1','1ton']
        secondary = 'distrib'
    else:
        distrib_request = [distreq]

    requested_data = []

    for d in alldata:
       for c in client_request:
           for s in server_request:
               for r in concur_request:
                   for dr in distrib_request:
                       if (d['clients'] == c and d['servers'] == s and d['rpcs'] == r
                           and d['distrib'] == dr and d['measure'] == 'srv'):
                           requested_data.append(d)

    #print possible_clients
    #print possible_rpcs
    #print requested_data        

    primary_lookup = dict([('clients',client_request),('servers',server_request),
                      ('rpcs',concur_request),('distrib',distrib_request)])
    
    #print primary_lookup[primary]
    #print primary_lookup[secondary]
    primary_returned = primary_lookup[primary]
    for i in primary_returned:
        found = False
        for j in requested_data:
            if j[primary] == i:
                found = True
                break
        if not found:
            primary_returned.remove(i)
        else:
            found = False
            
    requested_data_sorted = sorted(requested_data, key=itemgetter(primary))
    for k,i in enumerate(primary_lookup[secondary]):
        y_values = []
        x_values = []
        for j in requested_data_sorted:
            if j[secondary] == i:
                y_values.append(j['sum'])
                x_values.append(j[primary])

        ci = k%4
        print x_values
        print y_values
        plt.plot(x_values,y_values,color=colors[ci],marker='o')

    plt.show()       

if __name__ == "__main__":
    main()
    
