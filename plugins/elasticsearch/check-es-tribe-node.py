#!/usr/bin/env python

"""Sensu check script: Check if tribe nodes are reachable and recent 7 days es doc count are more then threshold.

This script is run by Sensu at regular intervals.
"""
from optparse import OptionParser
import socket
import sys
import httplib
import json
import datetime

CHECK_PASSING = 0
CHECK_WARNING = 1
CHECK_FAILING = 2

myname = socket.gethostname()

def check_tribe_node(cluster):
    conn = httplib.HTTPConnection(cluster)
    now = datetime.datetime.utcnow()
    output = []
    for i in range(0,7):
        dt = datetime.datetime(year=now.year, month=now.month, day=now.day) - datetime.timedelta(days=i)
        dt_str = dt.strftime("%Y-%m-%d")
        index = "adevents-" + dt_str
        try:
            conn.request("GET", "/%s/_count" % (index))
            resp = conn.getresponse()
            data = json.loads(resp.read())
            if resp.status == 200:
                if data['count'] < 100000000:
                    msg = "ES Doc Count for index= `%s` is `%d`, less then expected count." % (index, data['count'])
                    output.append(msg)
            else:
                msg = "Failed in getting ES Doc Count for index= `%s`. Reason: `%s`" % (index, data['error']['reason'])
                output.append(msg)
        except Exception, e:
            print " `check_tribe_node:` host= `%s`, Unable to connect tribe node. got exception: `%s`" % (myname, e)
            sys.exit(CHECK_FAILING) 
    conn.close()
    if len(output) > 0:
        print " `check_tribe_node:` Error on host= `%s` %s" % (myname, output)
        sys.exit(CHECK_WARNING)


if __name__ == '__main__':
    
    cluster = "localhost:9200"
    check_tribe_node(cluster)
    print " `check_tribe_node:` The tribe node is fine and reachable."
    sys.exit(CHECK_PASSING)
        
