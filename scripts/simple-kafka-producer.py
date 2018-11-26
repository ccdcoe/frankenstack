#!/usr/bin/env python3

import argparse
from kafka import KafkaProducer


if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument("--brokers",
            dest="brokers",
            nargs = "+",
            default=["localhost:9092"],
            help="Kafka broker. Multiple can be defained separated by whitespace. Note that this option is only used for bootstrapping, so a single broker in cluster is enough.")

    parser.add_argument("--topic",
            dest="topic",
            default="test123",
            help="topic to send messages to")

    parser.add_argument("--count",
            dest="count",
            default=10,
            type=int,
            help="how many test messages to send")

    args = parser.parse_args()

    producer = KafkaProducer(bootstrap_servers=args.brokers)

    for i in range(args.count):
        msg = "message %s" % (i)
        resp = producer.send(args.topic, bytes(msg, encoding='utf-8'))
