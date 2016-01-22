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

OUTPUT = []

myname = socket.gethostname()

def check_aggregation_cluster(cluster):
    now = datetime.datetime.utcnow()
    conn = httplib.HTTPConnection(cluster)
    missing = ""
    indices = []
    for i in range(2):
        dt = datetime.datetime(year=now.year, month=now.month, day=now.day) - datetime.timedelta(days=(i*30))
        dt_str = dt.strftime("%Y-%m")
        indices.append("aggstats-" + dt_str)
    for i in range(len(indices)):
        conn.request("GET", "/" + indices[i])
        res = conn.getresponse()
        if res.status == 404:  # pylint: disable=E1101
            missing = missing + "%s," % (indices[i])
        elif res.status != 200:
            missing = ""
            OUTPUT.append("check_aggregation_cluster: host=%s received non-2xx resp=%s"%(myname, res.status))
            break
    if missing != "":
        OUTPUT.append("check_aggregation_cluster: Index %s is missing" % (missing))


def check_hotevents_cluster(cluster):
    now = datetime.datetime.utcnow()
    conn = httplib.HTTPConnection(cluster)
    missing = ""
    indices = []
    for i in range(2):
        dt = datetime.datetime(year=now.year, month=now.month, day=now.day) - datetime.timedelta(days=i)
        dt_str = dt.strftime("%Y-%m-%d")
        indices.append("adevents-" + dt_str)
        indices.append("pubevents-" + dt_str)
    for i in range(len(indices)):
        conn.request("GET", "/" + indices[i])
        res = conn.getresponse()
        if res.status == 404:  # pylint: disable=E1101
            missing = missing + "%s," % (indices[i])
        elif res.status != 200:
            missing = ""
            OUTPUT.append("check_hotevents_cluster: host=%s received non-2xx resp=%s"%(myname, res.status))
            break
    if missing != "":
        OUTPUT.append("check_hotevents_cluster: Index %s is missing" % (missing))

def check_coldevents_cluster(cluster):
    now = datetime.datetime.utcnow()
    conn = httplib.HTTPConnection(cluster)
    missing = ""
    indices = []
    for i in range(2):
        dt = datetime.datetime(year=now.year, month=now.month, day=now.day) - datetime.timedelta(days=(7+i))
        dt_str = dt.strftime("%Y-%m-%d")
        indices.append("adevents-" + dt_str)
        indices.append("pubevents-" + dt_str)
    for i in range(len(indices)):
        conn.request("GET", "/" + indices[i])
        res = conn.getresponse()
        if res.status == 404:  # pylint: disable=E1101
            missing = missing + "%s," % (indices[i])
        elif res.status != 200:
            missing = ""
            OUTPUT.append("check_coldevents_cluster: host=%s received non-2xx resp=%s"%(myname, res.status))
            break
    if missing != "":
        OUTPUT.append("check_coldevents_cluster: Index %s is missing" % (missing))

if __name__ == '__main__':
    OUTPUT = []

    #check if scrit is able to connect aggregation cluster
    try:
        cluster = "analytics-aggregation.elasticsearch.service.consul:9200"
        check_aggregation_cluster(cluster)
    except (TypeError, httplib.IncompleteRead) as e:
        OUTPUT.append("check_aggregation_cluster: host=%s, got exception: %s" % (myname,e))
    except Exception, e:
        OUTPUT.append("check_aggregation_cluster: host=%s, got exception: %s" % (myname,e))

    #check if scrit is able to connect hotevents cluster
    try:
        cluster = "analytics-hotevents.elasticsearch.service.consul:9200"
        check_hotevents_cluster(cluster)
    except (TypeError, httplib.IncompleteRead) as e:
        OUTPUT.append("check_hotevents_cluster: host=%s, got exception: %s" % (myname,e))
    except Exception, e:
        OUTPUT.append("check_hotevents_cluster: host=%s, got exception: %s" % (myname,e))

    #check if scrit is able to connect coldevents cluster
    try:
        cluster = "analytics-coldevents.elasticsearch.service.consul:9200"
        check_coldevents_cluster(cluster)
    except (TypeError, httplib.IncompleteRead) as e:
        OUTPUT.append("check_coldevents_cluster: host=%s, got exception: %s" % (myname,e))
    except Exception, e:
        OUTPUT.append("check_coldevents_cluster: host=%s, got exception: %s" % (myname,e))

    if len(OUTPUT)>0:
        for i in range(len(OUTPUT)):
            print OUTPUT[i]
        sys.exit(CHECK_FAILING)
    else:
        print "Indexing process on aggregation, hotevents and coldevents cluster is fine"
        sys.exit(CHECK_PASSING)
