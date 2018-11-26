#!/usr/bin/env python3

# Read elasticsearch json search queries from directory
# Run queries sequentially against elastic cluster
# Push results to kafka topic where kafka key represents query filename
# Visualizers/analyzers can then consume these results

import argparse
import re
import json
import sys

from elasticsearch import Elasticsearch
from kafka import KafkaProducer

from glob import glob

from os import listdir
from os.path import isfile, join

EXAMPLE_QUERY = '''
{
  "size": 0,
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-1h",
        "lte": "now"
      }
    }
  },
  "aggs": {
    "hosts": {
      "terms": {
        "field": "host.keyword",
        "size": 150
      },
      "aggs": {
        "programs": {
          "terms": {
            "field": "program.keyword",
            "size": 100
          }
        }
      }
    }
  }
}
'''

if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument("--elastic-hosts",
            dest="elastic",
            nargs = "+",
            default=["localhost:9200"],
            help="Elastic http proxies. Multiple can be defained separated by whitespace, but one per cluster is enough")

    parser.add_argument("--kafka-brokers",
            dest="brokers",
            nargs = "+",
            default=["localhost:9092"],
            help="Kafka broker. Multiple can be defained separated by whitespace. Note that this option is only used for bootstrapping, so a single broker in cluster is enough.")

    parser.add_argument("--query-dir",
            dest="qdir",
            default=None,
            required=True,
            help="Directory that contains json query files. Filename should have .json suffix and name should correspond to query tag.")
    parser.add_argument("--elastic-index-pattern",
            dest="ipattern",
            default="events-2018.12.*",
            required=False,
            help="Limit the query to only indices matching specified pattern"
            )

    parser.add_argument("--kafka-topic",
            dest="topic",
            default="ela-aggregator",
            required=False,
            help="Destination kafka topic")

    args = parser.parse_args()

    qfiles = [f for f in listdir(args.qdir) if isfile(join(args.qdir, f)) and re.match('.+\.json$', f)]

    queries = {}
    for qfile in qfiles:
        with open(join(args.qdir, qfile), 'r') as f:
            try:
                queries[qfile] = json.loads(f.read())
            except Exception as e:
                print("unable to load %s" % f)
                print(e)

    es = Elasticsearch(args.elastic)

    producer = KafkaProducer(bootstrap_servers=args.brokers,
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=str.encode)

    resps = {}
    for name, q in queries.items():
        data = es.search(index=args.ipattern, body=q)
        data = data["aggregations"]["hosts"]["buckets"] 
        resps[name] = data

    for name, resp in resps.items():
        resp = producer.send(args.topic, 
                value=resp,
                key=name)

    producer.flush()
