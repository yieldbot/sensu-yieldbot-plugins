#!/usr/bin/env python

from optparse import OptionParser
import socket
import sys
import httplib
import json

PASS = 0
WARNING = 1
CRITICAL = 2

def get_bongo_host(server, app):
    try:
        con = httplib.HTTPConnection(server, timeout=45)
        con.request("GET","/v2/apps/" + app)
        data = con.getresponse()
        if data.status >= 300:
            print "eventanomaly check get_bongo_host= Recieved non-2xx response= %s" % (data.status)
            sys.exit(WARNING)
        json_data = json.loads(data.read())
        host = json_data['app']['tasks'][0]['host']
        port = json_data['app']['tasks'][0]['ports'][0]
        con.close()
        return host, port
    except Exception, e:
        print "eventanomaly check get_bongo_host= %s Exception caught" % (e)
        sys.exit(WARNING)

def get_status(host, group, time):
    try:
        con = httplib.HTTPConnection(host,timeout=45)
        con.request("GET","/v1/eventdrop/" + group + "/" + time)
        data = con.getresponse()
        if data.status >= 300:
            print "Event Anomaly Check Status= Recieved non-2xx response= %s" % (data.status)
            sys.exit(WARNING)
        json_data = json.loads(data.read())
        con.close()

        if json_data['status'] == 2:
            print "Event Anomaly Check Status for `%s` = %s" % (time,json_data['msg'])
            sys.exit(CRITICAL)
        elif json_data['status'] == 1:
            print "Event Anomaly Check Status for `%s` = %s" % (time,json_data['msg'])
            sys.exit(WARNING)
        else:
            print "Event Anomaly Check Status for `%s` = %s" % (time,json_data['msg'])
            sys.exit(PASS)
    except Exception, e:
        print "Event Anomaly Check Status= %s Exception caught" % (e)
        sys.exit(WARNING)

if __name__=="__main__":
    parser = OptionParser()
    parser.add_option("-s", dest="server", action="store", default="localhost:8080", help="Marathon Cluster address with port no")
    parser.add_option("-a", dest="app", action="store", default="bongo.useast.prod", help="App Id to retrieve the slave address")
    parser.add_option("-g", dest="group", action="store", default="pmi", help="The group of event pmi or adevents")
    parser.add_option("-t", dest="time", action="store", default="10min", help="The time gap for which the difference is to be calculated")
    (options, args) = parser.parse_args()
    if "useast" in options.app:
        host, port = get_bongo_host(options.server, options.app)
        host = host.rsplit("prd",1)
        consul_host = "%snode.us-east-1.consul:%s" % (host[0], port)
    else:
        consul_host = options.server
    get_status(consul_host, options.group, options.time)
