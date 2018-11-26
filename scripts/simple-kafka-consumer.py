#!/usr/bin/env python3

# A simple python script for consuming kafka messages according to user-defined command line arguments
# Mainly for testing and reference when implementing custom consumers

import argparse
from kafka import KafkaConsumer

if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument("--brokers",
            dest="brokers",
            nargs = "+",
            default=["localhost:9092"],
            help="Kafka broker. Multiple can be defained separated by whitespace. Note that this option is only used for bootstrapping, so a single broker in cluster is enough.")

    parser.add_argument("--group-id",
            dest="groupid",
            default=None,
            help="Optional group id for committing offsets."
            )

    parser.add_argument("--no-consume",
            dest="noConsume",
            action="store_true",
            default=False,
            help="Only connect to brokers without consuming any messages. Useful for printing debug information.")

    parser.add_argument("--consume-topics",
            dest="topics",
            nargs = "+",
            default=None,
            help="Kafka topics to consume. Multiple can be defained separated by whitespace.")

    args = parser.parse_args()

    consumer = KafkaConsumer(
            bootstrap_servers=args.brokers,
            group_id=args.groupid,
            consumer_timeout_ms=60*1000)

    data = {}
    data["topics"] = consumer.topics()

    data["partitions"] = {}
    for topic in data["topics"]:
        data["partitions"][topic] = consumer.partitions_for_topic(topic)

    if not args.noConsume:
        consumer.subscribe(args.topics)
        data["consumed"] = 0
        try:
            for msg in consumer:
                print(msg)
                data["consumed"] += 1
        except KeyboardInterrupt as e:
                consumer.close(autocommit=False)

    print(data)
