#!/usr/bin/env python

"""Sensu check script: to check if aggregation, hotevents and clodevents cluster can see index nodes

This script is run by Sensu at regular intervals.
"""
from optparse import OptionParser
import socket
import sys
import httplib
import json
import datetime

CHECK_PASSING = 0
CHECK_FAILING = 2

myname = socket.gethostname()


def check_tribe_node(cluster):
    now = datetime.datetime.utcnow()
    dt = datetime.datetime(year=now.year, month=now.month, day=now.day) - datetime.timedelta(days=7)
    dt_str = dt.strftime("%Y-%m-%d")
    index = "adevents-" + dt_str

    conn = httplib.HTTPConnection(cluster)
    conn.request("GET", "/" + index)
    res = conn.getresponse()
    conn.close()


if __name__ == '__main__':
    #check if scrit is able to connect tribe node
    try:
        cluster = "localhost:9200"
        check_tribe_node(cluster)
        print " `check_tribe_node:` The tribe node is fine and reachable."
        sys.exit(CHECK_PASSING)
    except Exception as e:
        print " `check_tribe_node:` host=%s, Unable to connect tribe node. got exception: %s" % (myname,e)
        sys.exit(CHECK_FAILING)
