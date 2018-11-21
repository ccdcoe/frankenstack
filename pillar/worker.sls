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

kafka:
  - name: kafka-central
    persist: True
    config: /opt/kafka-central
    zk:
      ports: 
        client: 2181
        follower: 2888
        server: 3888
      members:
        - id: 10
          addr: 192.168.0.10
          follower: 2888
          server: 3888
        - id: 11
          addr: 192.168.0.11
          follower: 2888
          server: 3888
        - id: 12
          addr: 192.168.0.12
          follower: 2888
          server: 3888
      env:
        JVMFLAGS: "-Xmx1g"
        MYID: {{grains.ipv4[0].split('.')[3]}}
    kafka:
      port: 9092
      env:
        # REPLACE GRAIN POSITION
        # see salt '*' grains.get ipv4
        # do not use ip as broker id when deploying multiple clusters on same host
        - KAFKA_BROKER_ID: {{grains.ipv4[1].split('.')[3]}}
        - KAFKA_ADVERTISED_HOST_NAME: {{grains.ipv4[1]}}
        - KAFKA_ADVERTISED_PORT: 9092
        - KAFKA_LOG_RETENTION_HOURS: 168
        - KAFKA_ZOOKEEPER_CONNECT: 192.168.0.10:2181,192.168.0.11:2181,192.168.0.12:2181
