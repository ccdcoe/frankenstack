elastic:
  - name: elastic-central
    persist: True
    version:
      ela: 6.5.1
      kibana: 6.5.1
    ports:
      http: 9200
      kibana: 5601
    id: {{grains.ipv4[0].split('.')[3]}}
    network: myoverlay
    env:
      - "cluster.name=josephine"
      - "node.name={{grains.fqdn}}"
      - "discovery.zen.ping.unicast.hosts=elastic-central-10-ela"
      - "ES_JAVA_OPTS=-Xms8g -Xmx8g" 

zookeeper:
  - name: zookeeper-central
    persist: True
    config: /opt/zookeeper-central
    network: central-overlay
    id: {{grains.ipv4[0].split('.')[3]}}
    ports: 
      client: 2181
    members:
      {% for i in range(5)%}
      - id: 2{{i}}
        addr: zookeeper-central-zk-2{{i}}
      {% endfor %}
    env:
      - "JVMFLAGS=-Xmx2g"
      - "MYID={{grains.ipv4[0].split('.')[3]}}"

kafka:
  - name: kafka-central
    persist: True
    config: /opt/kafka-central
    port: 9092
    id: {{grains.ipv4[0].split('.')[3]}}
    network: central-overlay
    env:
      - "KAFKA_BROKER_ID={{grains.ipv4[0].split('.')[3]}}"
      - "KAFKA_ADVERTISED_PORT=9092"
      - "KAFKA_ADVERTISED_HOST_NAME={{grains.ipv4[1]}}"
      - "KAFKA_LOG_RETENTION_HOURS=168"
      - "KAFKA_ZOOKEEPER_CONNECT=zookeeper-central-zk-20,zookeeper-central-zk-21,zookeeper-central-zk-22"
      - "KAFKA_NUM_PARTITIONS=1"
      - "KAFKA_DEFAULT_REPLICATION_FACTOR=3"
