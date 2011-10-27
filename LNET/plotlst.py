#!/usr/local/bin/python

#python script to parse and plot LNET self test numbers

import numpy
import matplotlib
#matplotlib.use('PS')
import matplotlib.pyplot as plt
import sys
import os

def main(*args):

    datadir = './'

    filelist = listdir(datadir)
    
