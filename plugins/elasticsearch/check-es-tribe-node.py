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
import re

CHECK_PASSING = 0
CHECK_WARNING = 1
CHECK_FAILING = 2

myname = socket.gethostname()

nodes = {}

nodes["coldevents"] = ["analytics-coldevents-0",
                       "analytics-coldevents-1",
                       "analytics-coldevents-2",
                       "analytics-coldevents-3",
                       "analytics-coldevents-4",
                       "analytics-coldevents-5",
                       "analytics-coldevents-6",
                       "analytics-coldevents-7",
                       "analytics-coldevents-8",
                       "analytics-coldevents-9",
                       "analytics-coldevents-10",
                       "analytics-coldevents-11",
                       "analytics-coldevents-12",
                       "analytics-coldevents-13",
                       "analytics-coldevents-14",
                       "analytics-coldevents-15",
                       "analytics-coldevents-16",
                       "analytics-coldevents-17",
                       "analytics-coldevents-18",
                       "analytics-coldevents-19",
                       "analytics-coldevents-20",
                       "analytics-tribe-0/coldevents",
                       "analytics-tribe-1/coldevents",
                       "analytics-tribe-2/coldevents"]

nodes["hotevents"] = ["analytics-hotevents-0",
                       "analytics-hotevents-1",
                       "analytics-hotevents-2",
                       "analytics-hotevents-3",
                       "analytics-hotevents-4",
                       "analytics-hotevents-5",
                       "analytics-hotevents-6",
                       "analytics-hotevents-7",
                       "analytics-hotevents-8",
                       "analytics-tribe-0/hotevents",
                       "analytics-tribe-1/hotevents",
                       "analytics-tribe-2/hotevents"]

nodes["aggregation"] = ["analytics-aggregation-0",
                        "analytics-aggregation-1",
                        "analytics-aggregation-2",
                        "analytics-aggregation-3",
                        "analytics-aggregation-4",
                        "analytics-aggregation-5",
                        "analytics-aggregation-6",
                        "analytics-aggregation-7",
                        "analytics-aggregation-8",
                        "analytics-aggregation-9",
                        "analytics-aggregation-10",
                        "analytics-aggregation-11",
                        "analytics-tribe-0/aggregation",
                        "analytics-tribe-1/aggregation",
                        "analytics-tribe-2/aggregation"]

def check_tribe_node(cluster):
    conn = httplib.HTTPConnection(cluster)
    now = datetime.datetime.utcnow()
    output = []
    for i in range(1,7):
        dt = datetime.datetime(year=now.year, month=now.month, day=now.day) - datetime.timedelta(days=i)
        dt_str = dt.strftime("%Y-%m-%d")
        index = "adevents-" + dt_str
        try:
            conn.request("GET", "/%s/_count" % (index))
            resp = conn.getresponse()
            data = json.loads(resp.read())
            if resp.status == 200:
                if data['count'] < 1000000:
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


def check_nodes(cluster, name):
    conn = httplib.HTTPConnection(cluster)
    conn.request("GET", "/_cat/nodes?h=n")
    resp = conn.getresponse()
    data = resp.read()
    output = ""
    active = re.split("\s+",data)
    for i in range(len(nodes[name])):
        if nodes[name][i] not in active:
            output = output + nodes[name][i] + ","
    if output != "":
        output = "`" + output + "` node/s for " + name + " cluster are down or not reachable.\n"
    return output


if __name__ == '__main__':
    
    cluster = "localhost:9200"
    check_tribe_node(cluster)

    try:
        coldevents = check_nodes("analytics-coldevents.elasticsearch.service.us-east-1.consul:9200","coldevents")

        hotevents = check_nodes("analytics-hotevents.elasticsearch.service.us-east-1.consul:9200","hotevents")

        aggregation = check_nodes("analytics-aggregation.elasticsearch.service.us-east-1.consul:9200","aggregation")
    except Exception, e:
        print " `check_tribe_node:` host= `%s`, got exception: `%s`" % (myname, e)
        sys.exit(CHECK_FAILING) 

    if coldevents == "" and hotevents == "" and aggregation == "":
        print " `check_tribe_node:` The tribe node is fine and reachable."
        sys.exit(CHECK_PASSING)
    else:
        print " `check_tribe_node:` %s %s %s" % (coldevents, hotevents, aggregation)
        sys.exit(CHECK_WARNING)
        
