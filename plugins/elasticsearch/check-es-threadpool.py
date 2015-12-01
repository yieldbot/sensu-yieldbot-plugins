#!/usr/bin/env python

#Sensu check script: to check threadpool.
from optparse import OptionParser
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


def is_master(conn):
    nodename = ""
    conn.request("GET", "/_cluster/state/master_node")
    r1 = conn.getresponse()
    if r1.status >= 300:  # pylint: disable=E1101
        msg = "check_es_indexstatus: host=%s received non-2xx resp=%s"%(myname, r1.status)
        print msg
        sys.exit(CHECK_FAILING)
    masterjson = json.loads(r1.read())
    conn.request("GET", "/_nodes/_local/info")
    r1 = conn.getresponse()
    if r1.status >= 300:  # pylint: disable=E1101
        msg = "check_es_indexstatus: host=%s received non-2xx resp=%s"%(myname, r1.status)
        print msg
        sys.exit(CHECK_FAILING)
    localjson = json.loads(r1.read())
    if localjson["nodes"].keys()[0] == masterjson["master_node"]:
        nodename = masterjson["master_node"]
        return nodename

def get_threadpool_status(tpool):
    try:
        conn = httplib.HTTPConnection("localhost:9200")
        nodename = is_master(conn)
        if not nodename:
            print "Not master"
            sys.exit(CHECK_PASSING)
        conn.request("GET", "/_nodes/" + nodename + "/stats/thread_pool")
        
        r1 = conn.getresponse()
        if r1.status >= 300:  # pylint: disable=E1101
            msg = "check_es_threadpool: host=%s received non-2xx resp=%s"%(myname, r1.status)
            print msg
            sys.exit(CHECK_FAILING)
        respjson = json.loads(r1.read())
        threadcnt = {}
        threadcnt["generic"] = respjson["nodes"][nodename]["thread_pool"]["generic"]["active"]
        threadcnt["index"] = respjson["nodes"][nodename]["thread_pool"]["index"]["active"]
        threadcnt["search"] = respjson["nodes"][nodename]["thread_pool"]["search"]["active"]
        if threadcnt["search"] >= 800:
            sys.exit(CHECK_WARNING)
        elif threadcnt["search"] >= 1000:
            sys.exit(CHECK_FAILING)
        threadcnt["suggest"] = respjson["nodes"][nodename]["thread_pool"]["suggest"]["active"]
        threadcnt["get"] = respjson["nodes"][nodename]["thread_pool"]["get"]["active"]
        threadcnt["bulk"] = respjson["nodes"][nodename]["thread_pool"]["bulk"]["active"]
        threadcnt["percolate"] = respjson["nodes"][nodename]["thread_pool"]["percolate"]["active"]
        threadcnt["snapshot"] = respjson["nodes"][nodename]["thread_pool"]["snapshot"]["active"]
        threadcnt["warmer"] = respjson["nodes"][nodename]["thread_pool"]["warmer"]["active"]
        threadcnt["refresh"] = respjson["nodes"][nodename]["thread_pool"]["refresh"]["active"]
        threadcnt["listener"] = respjson["nodes"][nodename]["thread_pool"]["listener"]["active"]
        if tpool == "all":
            print "Thread_pool active counts "
            print threadcnt
            sys.exit(CHECK_PASSING)
        else:
            print "Thread_pool count for " + tpool +" = " + threadcnt[tpool]
            sys.exit(CHECK_PASSING)
    except Exception, e:
        print "%s : exception=%s"%(myname, e)
        sys.exit(CHECK_FAILING)

if __name__=="__main__":
    parser = OptionParser()
    parser.add_option("-t", dest="threadpool", action="store", default="all", help="threadpool name e.g. generic,index,search,suggest,get,bulk,precolate,snapshot,warmer,refresh,listener")
    (options, args) = parser.parse_args()
    get_threadpool_status(options.threadpool)

