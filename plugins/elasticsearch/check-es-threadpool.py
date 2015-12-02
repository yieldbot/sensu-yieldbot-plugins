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
        msg = "check_es_threadpool: host=%s received non-2xx resp=%s"%(myname, r1.status)
        print msg
        sys.exit(CHECK_FAILING)
    masterjson = json.loads(r1.read())
    conn.request("GET", "/_nodes/_local/info")
    r1 = conn.getresponse()
    if r1.status >= 300:  # pylint: disable=E1101
        msg = "check_es_threadpool: host=%s received non-2xx resp=%s"%(myname, r1.status)
        print msg
        sys.exit(CHECK_FAILING)
    localjson = json.loads(r1.read())
    if localjson["nodes"].keys()[0] == masterjson["master_node"]:
        nodename = masterjson["master_node"]
        return nodename

def get_threadpool_status(tpool, wt, ct):
    try:
        conn = httplib.HTTPConnection("localhost:9200")
        nodename = is_master(conn)
        if not nodename:
            print "Not master"
            sys.exit(CHECK_PASSING)
        conn.request("GET", "/_nodes/" + nodename + "/stats/thread_pool/")

        r1 = conn.getresponse()
        if r1.status >= 300:  # pylint: disable=E1101
            msg = "check_es_threadpool: host=%s received non-2xx resp=%s"%(myname, r1.status)
            print msg
            sys.exit(CHECK_FAILING)
        respjson = json.loads(r1.read())
        threadcnt = 0
        threadcnt = respjson["nodes"][nodename]["thread_pool"][tpool]["active"]
        if threadcnt >= ct:
            sys.exit(CHECK_FAILING)
        elif threadcnt >= wt:
            sys.exit(CHECK_WARNING)
        print "Thread_pool count for " + tpool +" = " + str(threadcnt)
        sys.exit(CHECK_PASSING)
    except Exception, e:
        print "%s : exception=%s"%(myname, e)
        sys.exit(CHECK_FAILING)

if __name__=="__main__":
    usage = """Usage: %prog threadpool warning_threshold warning_threshold"""
    parser = OptionParser(usage=usage)
    parser.add_option("-t", dest="threadpool", action="store", default="", help="threadpool name e.g. index,search,bulk")
    parser.add_option("-w", dest="warn_th", type="int", action="store", default="500", help="warning_threshold")
    parser.add_option("-c", dest="crit_th", type="int", action="store", default="800", help="critical_threshold")

    (options, args) = parser.parse_args()
    if options.threadpool not in ['index', 'search', 'bulk']:
        parser.error("invalid thread_pool: %s" % options.threadpool)
    get_threadpool_status(options.threadpool, options.warn_th, options.crit_th)
