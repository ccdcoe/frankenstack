#!/usr/bin/env python

import argparse
import json
import yaml

DEFAULT="""
{
  "default": {
    "order": 0,
    "version": 0,
    "index_patterns": [
      "events-*"
    ],
    "settings": {
      "index": {
        "number_of_shards": "3",
        "number_of_replicas": "0",
        "refresh_interval": "60s"
      }
    },
    "mappings": {
      "dynamic_templates": [
        {
          "message_field": {
            "path_match": "message",
            "mapping": {
              "norms": false,
              "type": "text"
            },
            "match_mapping_type": "string"
          }
        },
        {
          "string_fields": {
            "mapping": {
              "norms": false,
              "type": "text",
              "fields": {
                "keyword": {
                  "ignore_above": 256,
                  "type": "keyword"
                }
              }
            },
            "match_mapping_type": "string",
            "match": "*"
          }
        }
      ],
      "properties": {
        "@timestamp": {
          "type": "date"
        },
        "@version": {
          "type": "keyword"
        }
      }
    },
    "aliases": {}
  }
}
"""

WINDOWS="""
{
  "order": 15,
  "version": 0,
  "index_patterns": ["peek-windows-*", "peek-sysmon-*"],
  "mappings":{
      "properties": {
        "Keywords": {
          "type": "text"
        }
      }
    }
}
"""

SURICATA="""
{
  "order": 15,
  "version": 0,
  "index_patterns": "peek-suricata-*",
  "mappings":{
      "properties": {
        "src_ip": {
          "type": "ip",
          "fields": {
            "keyword" : { "type": "keyword", "ignore_above": 256 }
          }
        },
        "dest_ip": {
          "type": "ip",
          "fields": {
            "keyword" : { "type": "keyword", "ignore_above": 256 }
          }
        }
      }
    }
}
"""

TEMPLATES = {
    "core": json.loads(DEFAULT)["default"],
    "suricata": json.loads(SURICATA),
    "windows": json.loads(WINDOWS)
}

if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument("--base-patterns",
            dest="bpatterns",
            nargs = "+",
            default=["events", "rsyslog", "peek"],
            required=False,
            help="Base index patterns for all events")

    parser.add_argument("--suricata-patterns",
            dest="suripatterns",
            nargs = "+",
            default=["suricata", "meer", "meercat", "meerkat", "mob"],
            required=False,
            help="suricata index patterns")

    parser.add_argument("--windows-patterns",
            dest="winpatterns",
            nargs = "+",
            default=["windows", "eventlog", "sysmon", "winlogbeat"],
            required=False,
            help="suricata index patterns")

    args = parser.parse_args()

    tpl = { "elastic_templates": TEMPLATES }
    tpl['elastic_templates']['core']['index_patterns'] = ["{}-*".format(p) for p in args.bpatterns]

    tpl['elastic_templates']['core']["settings"]["index"]["routing.allocation.require.box_type"] = "hot"

    for key, arg in {'suricata': args.suripatterns, 'windows': args.winpatterns}.items():
        tpl['elastic_templates'][key]['index_patterns'] = ["*-{}-*".format(p) for p in arg]

    #print(yaml.safe_dump(tpl))
    print(json.dumps(tpl['elastic_templates']['core']))
