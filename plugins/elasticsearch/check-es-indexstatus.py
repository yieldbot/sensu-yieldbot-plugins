#!/usr/bin/env python

"""Sensu check script: to see if any index is in non-green state.
This is a special check script to be executed only on
the coldevents cluster. We want to exclude indices for
day-2 , since they are in the process of being restored
nightly in coldevents cluster. During this process the cluster
state is red/yellow.

This script is run by Sensu at regular intervals.
"""

import socket
import sys
import httplib
import json
import datetime

CHECK_PASSING = 0
CHECK_WARNING = 1
CHECK_FAILING = 2


# Print hostname so the alert will identify which cluster had the issue
# issue.
myname = socket.gethostname()


try:
    conn = httplib.HTTPConnection("localhost:9200")
    conn.request("GET", "/_cluster/health?pretty&level=indices")
    r1 = conn.getresponse()
    if r1.status >= 300:  # pylint: disable=E1101
        msg = "check_es_indexstatus: host=%s received non-2xx resp=%s"%(myname, r1.status)
        print msg
        sys.exit(CHECK_FAILING)
    respjson = json.loads(r1.read())
    now = datetime.datetime.utcnow()
    twodaysago = datetime.datetime(year=now.year, month=now.month, day=now.day) - datetime.timedelta(days=2)
    twodays_str = twodaysago.strftime("%Y-%m-%d")
    for index in respjson["indices"]:
        if respjson["indices"][index]["status"] == "yellow":
            if twodays_str in index :
                continue
            msg = "check_es_indexstatus: host=%s index=%s status=YELLOW"%(myname, index)
            print msg
            sys.exit(CHECK_WARNING)
        elif respjson["indices"][index]["status"] == "red":
            if twodays_str in index :
                continue
            msg = "check_es_indexstatus: host=%s index=%s status=RED"%(myname, index)
            print msg
            sys.exit(CHECK_FAILING)
except Exception, e:
    print "%s : exception=%s"%(myname, e)
    sys.exit(CHECK_FAILING)


sys.exit(CHECK_PASSING)
