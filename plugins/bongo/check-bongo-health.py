#!/usr/bin/env python

import socket
import sys
import httplib
import json
import argparse

PASS = 0
FAIL = 1

def get_bongo_host(server, app):
    try:
        con = httplib.HTTPConnection(server, timeout=45)
        con.request("GET","/v2/apps/" + app)
        data = con.getresponse()
        if data.status >= 300:
            print "Recieved non-2xx response= %s" % (data.status)
            sys.exit(FAIL)
        json_data = json.loads(data.read())
        host = "%s:%s" % (json_data['app']['tasks'][0]['host'],json_data['app']['tasks'][0]['ports'][0])
        con.close()
        return host
    except Exception, e:
        print "%s :exception caught" % (e)
        sys.exit(FAIL)

def get_status(host, group):
    try:
        con = httplib.HTTPConnection(host,timeout=45)
        con.request("GET","/v1/kafka/health/" + group)
        data = con.getresponse()
        if data.status >= 300:
            print "Recieved non-2xx response= %s" % (data.status)
            sys.exit(FAIL)
        json_data = json.loads(data.read())
        if json_data['status'] == 1:
            print "%s" % (json_data['msg'])
            sys.exit(FAIL)
        else:
            print "Cluster is fine"
            sys.exit(PASS)
    except Exception, e:
        print "%s :exception caught" % (e)
        sys.exit(FAIL)


if __name__=="__main__":
    parser = argparse.ArgumentParser(description="Returns the health of cluster based on bongo metrics")
    parser.add_argument("-s", dest="server", action="store", default="localhost:8080", help="Marathon Cluster address with port no")
    parser.add_argument("-a", dest="app", action="store", default="bongo.useast.prod", help="App Id to retrieve the slave address")
    parser.add_argument("-c", dest="group", action="store", default="yield_secor", help="Name of Consumer Group")
    args = parser.parse_args()
    host = get_bongo_host(args.server, args.app)
    get_status(host, args.group)
