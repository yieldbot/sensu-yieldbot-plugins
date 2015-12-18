#!/usr/bin/env python

from optparse import OptionParser
import socket
import sys
import httplib
import json

PASS = 0
FAIL = 1

cgnodes = {}
cgnodes["east"] = ["prd-useast-choose-goose-01.prd.yb0t.cc",
                  "prd-useast-choose-goose-02.prd.yb0t.cc",
                  "prd-useast-choose-goose-03.prd.yb0t.cc",
                  "prd-useast-choose-goose-04.prd.yb0t.cc",
                  "prd-useast-choose-goose-05.prd.yb0t.cc",
                  "prd-useast-choose-goose-06.prd.yb0t.cc",
                  "prd-useast-choose-goose-07.prd.yb0t.cc",
                  "prd-useast-choose-goose-08.prd.yb0t.cc",
                  "prd-useast-choose-goose-09.prd.yb0t.cc",
                  "prd-useast-choose-goose-10.prd.yb0t.cc",
                  "prd-useast-choose-goose-11.prd.yb0t.cc",
                  "prd-useast-choose-goose-12.prd.yb0t.cc",
                  "prd-useast-choose-goose-13.prd.yb0t.cc",
                  "prd-useast-choose-goose-14.prd.yb0t.cc",
                  "prd-useast-choose-goose-15.prd.yb0t.cc"]

cgnodes["west"] = ["prd-uswest-choose-goose-01.prd.yb0t.cc",
                  "prd-uswest-choose-goose-02.prd.yb0t.cc",
                  "prd-uswest-choose-goose-03.prd.yb0t.cc",
                  "prd-uswest-choose-goose-04.prd.yb0t.cc",
                  "prd-uswest-choose-goose-05.prd.yb0t.cc",
                  "prd-uswest-choose-goose-06.prd.yb0t.cc",
                  "prd-uswest-choose-goose-07.prd.yb0t.cc",
                  "prd-uswest-choose-goose-08.prd.yb0t.cc",
                  "prd-uswest-choose-goose-09.prd.yb0t.cc",
                  "prd-uswest-choose-goose-10.prd.yb0t.cc",
                  "prd-uswest-choose-goose-11.prd.yb0t.cc",
                  "prd-uswest-choose-goose-12.prd.yb0t.cc",
                  "prd-uswest-choose-goose-13.prd.yb0t.cc",
                  "prd-uswest-choose-goose-14.prd.yb0t.cc",
                  "prd-uswest-choose-goose-15.prd.yb0t.cc"]

def get_bongo_host(server, app):
    try:
        con = httplib.HTTPConnection(server, timeout=45)
        con.request("GET","/v2/apps/" + app)
        data = con.getresponse()
        if data.status >= 300:
            print "get_bongo_host: Recieved non-2xx response= %s" % (data.status)
            sys.exit(FAIL)
        json_data = json.loads(data.read())
        host = "%s:%s" % (json_data['app']['tasks'][0]['host'],json_data['app']['tasks'][0]['ports'][0])
        con.close()
        return host
    except Exception, e:
        print "get_bongo_host: %s :exception caught" % (e)
        sys.exit(FAIL)

def get_status(host, region):
    try:
        output = "\n"
        con = httplib.HTTPConnection(host,timeout=45)
        for i in range(len(cgnodes[region])):
            con.request("GET","/v1/choose-goose/health/" + cgnodes[region][i])
            data = con.getresponse()
            if data.status >= 300:
                output = output + "%s status: Recieved non-2xx response= %s \n" % (cgnodes[region][i], data.status)
            else:
                json_data = json.loads(data.read())
                if json_data['status'] == 1:
                    output = output + "%s status: %s \n" % (cgnodes[region][i], json_data['msg'])
        con.close()
        if output == "\n":
            print "mirror-maker on choose-goose nodes are fine"
            sys.exit(PASS)
        else:
            print output
            sys.exit(FAIL)
    except Exception, e:
        print "get_status: %s :exception caught" % (e)
        sys.exit(FAIL)


if __name__=="__main__":
    parser = OptionParser()
    parser.add_option("-s", dest="server", action="store", default="localhost:8080", help="Marathon Cluster address with port no")
    parser.add_option("-a", dest="app", action="store", default="bongo.useast.prod", help="App Id to retrieve the slave address")
    parser.add_option("-r", dest="region", action="store", default="east", help="Region for which choose-goose node health has to be checked")
    (options, args) = parser.parse_args()
    host = get_bongo_host(options.server, options.app)
    get_status(host, options.region)
