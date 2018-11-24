#!/usr/bin/env python3

import argparse
import sys
import re
import yaml
import json

from elasticsearch import Elasticsearch
from jinja2 import Template, Undefined
from pprint import pprint

RED     = "\033[1;31m"
GREEN   = '\033[1;32m'
YELLOW  = '\033[1;33m'
BLUE    = "\033[1;34m"
RESET   = "\033[0;0m"

DEFAULT_SETTINGS = {
    "index": {
        "number_of_shards": 3,
        "number_of_replicas": 0,
        "refresh_interval": "30s"
    }
}

DEFAULT_PROPERTIES = {
    "@timestamp": {
        "type": "date",
        "format": "strict_date_optional_time||epoch_millis||date_time"
    },
    "@reported": {
        "type": "date",
        "format": "strict_date_optional_time||epoch_millis||date_time"
    },
    "@version": {
        "type": "keyword"
    },
    "ip": {
        "type": "ip"
    }
}

DEFAULT_MAPPINGS = {
    "_default_": {
        "dynamic_templates": [
            {
                "message_field": {
                    "path_match": "message",
                    "mapping": {
                        "norms": False,
                        "type": "text"
                    },
                    "match_mapping_type": "string"
                }
            },
            {
                "string_fields": {
                    "mapping": {
                        "norms": False,
                        "type": "text",
                        "fields": {
                            "keyword": {
                                "type": "keyword"
                            }
                        }
                    },
                    "match_mapping_type": "string",
                    "match": "*"
                }
            }
        ],
        "_all": {
            "norms": False,
            "enabled": False
        },
        "properties": DEFAULT_PROPERTIES
    }
}

DEFAULT_TEMPLATE = {
    "order": 0,
    "version": 0,
    "index_patterns": ["*"],
    "settings": DEFAULT_SETTINGS,
    "mappings": DEFAULT_MAPPINGS,
    "aliases": {}
}

IPV4 = r'^(?:(?:\d{1,3}\.){3}\d{1,3})$'

def regexValidatedIPv4Arg(s, pat=re.compile(IPV4)):
    if not pat.match(s):
        raise argparse.ArgumentTypeError('Value should be ipv4 address without port suffix')
    return s

def refreshIntervalArg(value):
    ivalue = int(value)
    if ivalue <= 0 or ivalue >= 60:
         raise argparse.ArgumentTypeError("refresh_interval should be between 1 and 60 seconds, is %s " % value)
    return ivalue

def settings(shards=3, repl=0, refr=30):
    return {
        "index": {
            "number_of_shards": shards,
            "number_of_replicas": repl,
            "refresh_interval": str(refr) + "s" 
        }
    }

def elaColor(col):
    return {
            'red': RED,
            'yellow': YELLOW,
            'green': GREEN,
            }.get(col, RESET)

def takeIndexKey(elem):
    return elem["index"]

class NullUndefined(Undefined):
    def __getattr__(self, key):
        return 'None'

if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument("--proxy",
            dest="proxy",
            type=regexValidatedIPv4Arg,
            help="IPv4 address of elastic proxy host. Without port suffix.")

    parser.add_argument("--pillar",
            dest="pillar",
            default="pillar/worker.sls",
            help="Location of salt pillar file that specifies elasticsearch clusters and their respective proxy ports")

    parser.add_argument("--show-existing-template",
            dest="showExisting",
            action="store_true",
            default=False,
            help="Print content of existing template if it exists")

    parser.add_argument("--show-nodes",
            dest="showNodes",
            action="store_true",
            default=False,
            help="Print cluster node info")

    parser.add_argument("--update-template",
            dest="updateTpl",
            action="store_true",
            default=False,
            help="Should template be updated if it already exists")

    parser.add_argument("--update-replicas",
            dest="updateRepl",
            action="store_true",
            default=False,
            help="Should existing indices be reconfigured with new replica count")

    parser.add_argument("--shards",
            dest="shards",
            type=int,
            default=3,
            help="Set the number of elastic shards. Only applies in template, existing indices cannot be changed without reindex")

    parser.add_argument("--replicas",
            dest="replicas",
            type=int,
            default=0,
            help="Set the number of elastic replicas. Applies in template and existing indices can be reconfigured if --update-shard-replicas is used. Can be combined with --index-pattern as updating all replicas may cause heavy rebalance IO load.")

    parser.add_argument("--refresh-interval",
            dest="refreshInterval",
            type=refreshIntervalArg,
            default=30,
            help="Refresh interval, or how often elasticsearch does bulk indexing. Higher value is better for throughput, but introduces delay util documents become availeble for searching. Defaults to 30 seconds. More thant 60 seconds is likely unresonable, so tool will not allow higher values.")

    parser.add_argument("--index-pattern",
            dest="indexPattern",
            default=None,
            help="Regex pattern used for update operations and check operations.")

    parser.add_argument("--show-indices",
            dest="checkIndices",
            action="store_true",
            default=False,
            help="Print the health state of indices to stdout. --index-pattern is respected")

    parser.add_argument("--index-health",
            dest="health",
            choices=["all", "green", "yellow", "red"],
            default="all",
            help="Apply operations on indices with chosen health state. By defalt all will be selected")

    parser.add_argument("--verbose",
            dest="verb",
            action="store_true",
            default=False,
            help="Print additional debug info")

    args = parser.parse_args()

    with open(args.pillar, 'r') as f:
        tpl = f.read()

    tpl = Template(tpl, undefined=NullUndefined)

    try:
        clusters = yaml.safe_load(tpl.render())
    except yaml.YAMLError as e:
        print(e)
        sys.exit(2)

    if 'elastic' not in clusters or len(clusters) == 0:
        print("elastic cluster key not defined or missing definitions")
        sys.exit(2)

    templates = { "default": DEFAULT_TEMPLATE }
    templates["default"]["settings"] = settings(shards=args.shards, repl=args.replicas, refr=args.refreshInterval)

    if args.indexPattern: updateExpr = re.compile(args.indexPattern)

    for cluster in clusters["elastic"]:
        connect = args.proxy + ":" + str(cluster["ports"]["http"])
        es = Elasticsearch(connect)
        state = es.cluster.stats()

        name = state["cluster_name"]
        state = state["status"]

        print( BLUE,
                connect, name, ":", RESET, elaColor(state), state,
                RESET)

        if args.showNodes:
            for node in es.cat.nodes(format="json"):
                heap = int(node['heap.percent'])
                color = RED if heap > 50 else YELLOW

                print(color, 
                        "-", node['name'], ":", node['heap.percent'], 
                        RESET)

                if args.verb: pprint(node)

        indices = es.cat.indices(format="json")
        if args.health != "all":
            indices = [idx for idx in indices if idx["health"] == args.health ]

        if args.indexPattern:
            indices = [ idx for idx in indices if updateExpr.match(idx["index"]) ]

        indices = sorted(indices, key=takeIndexKey)

        for index in indices:
            if args.checkIndices:
                print(elaColor(index["health"]), 
                        "*", index["index"], "-", index["rep"], "-", index["status"],
                        RESET)

        indices = [ data["index"] for data in indices ]

        for name, template in templates.items():
            exists = es.indices.exists_template(name) 
            old = es.indices.get_template(name) if exists else None
            if exists and args.showExisting: print(old)

            if not exists or args.updateTpl: 
                print("updating template %s" % name )
                template["version"] = 0 if not exists else old[name]["version"] + 1
                resp = es.indices.put_template(name, body=template)

                if args.verb: print(resp)
                if not resp["acknowledged"]: sys.exit(2)

            if args.updateRepl:
                update = ','.join(indices)

                if len(indices) > 0:
                    print("updating %s with new replica count" % update)
                    resp = es.indices.put_settings(
                            {
                                "index": {
                                    "number_of_replicas": args.replicas,
                                    "refresh_interval": str(args.refreshInterval) + "s"
                                }
                            }, update)

                    if args.verb or not resp["acknowledged"]: print(resp)

