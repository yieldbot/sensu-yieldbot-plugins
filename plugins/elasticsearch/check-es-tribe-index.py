#!/usr/bin/env python

"""Sensu check script: to check if tribe node can see index nodes

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


# Print hostname so the alert will identify which cluster had the issue
# issue.
myname = socket.gethostname()

def check_es_tribe_ind(cluster):
    indarr = []
    now = datetime.datetime.utcnow()
    for i in range(1,3):
        dt = datetime.datetime(year=now.year, month=now.month, day=now.day) - datetime.timedelta(days=i)
        dt_str = dt.strftime("%Y-%m-%d")
        indarr.append("adevents-" + dt_str)
        indarr.append("pubevents-" + dt_str)
    conn = httplib.HTTPConnection(cluster)
    conn.request("GET", "/_cat/indices")
    r1 = conn.getresponse()
    if r1.status >= 300:  # pylint: disable=E1101
        msg = "check_es_tribe_index: host=%s received non-2xx resp=%s"%(myname, r1.status)
        print msg
        r1.raise_for_status()
    rarr = ((r1.read()).split("\n"))
    for ind in indarr:
        if not any (ind in r for r in rarr):
            print "check_es_tribe_index: host=%s Index %s is missing" % (myname,ind)
            sys.exit(CHECK_FAILING)


for i in range(3):  # set up to try thrice if needed
    try:
        tribe = "localhost:9200"
        check_es_tribe_ind(tribe)
        break
    except (TypeError, httplib.IncompleteRead) as e:
                msg = "check_es_tribe_index: host=%s, got exception, will try again: %s" % (myname,e)
                print msg
                # potential s3 timing issue, wait one minute and try again
                time.sleep(60)
    except Exception, e:
        print "%s : exception=%s"%(myname, e)
        sys.exit(CHECK_FAILING)

msg = "check_es_tribe_index: `tribe host=%s is fine now`"%(myname)
print msg
sys.exit(CHECK_PASSING)
