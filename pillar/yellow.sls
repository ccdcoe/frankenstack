alerta:
  - name: alerta-blue
    persist: True
    port: 8080
  - name: alerta-yellow
    persist: True
    port: 8081

metricserver:
  config:
    influx: salt:///yellow/metrix/config/influxdb.conf 
    kapacitor: salt:///yellow/metrix/config/kapacitor.conf
  tick:
    - name: influx-collector-blue
      persist: True
      host:
        config: /opt/influx-collector-blue
      listeners:
        udp: 
          port: 8089
          database: udp
        http: 
          port: 8086
      grafana:
        port: 3000
        admin:  stronk
      kapa:
        port: 9092
        localhost: True
      chrono:
        port: 8888
    - name: influx-collector-yellow
      persist: True
      host:
        config: /opt/influx-collector-yellow
      listeners:
        udp: 
          port: 8090
          database: udp
        http: 
          port: 8087
      grafana:
        port: 3001
        admin:  week
      kapa:
        port: 9093
        localhost: True
      chrono:
        port: 8889

logservers:
  name: rsyslog-collector-blue
  persist: True
  host:
    config: /opt/rsyslog-config-blue
    data: /srv/rsyslog-data-blue
  network: host
  rulesets:
    - name: linux
      hourly: False
      byhost: True
      normalize:
        - name: snoopy
          filter: '$programname contains "snoopy"'
          kafkaTopic: linux-snoopy
          elaIndex: linux-snoopy
          stop: True
      elastic:
        enabled: True
        indexBase: linux
        proxies:
          {% for i in range(10,12) %}
          - 192.168.0.{{i}}:9200
          {% endfor %}
      kafka:
        enabled: True
        topic: linux
        brokers:
          {% for i in range(20,24) %}
          - 192.168.0.{{i}}:9092
          {% endfor %}
    - name: windows
      hourly: False
      byhost: True
      elastic:
        enabled: True
        indexBase: windows
        proxies:
          {% for i in range(10,12) %}
          - 192.168.0.{{i}}:9200
          {% endfor %}
      kafka:
        enabled: True
        topic: windows
        brokers:
          {% for i in range(20,24) %}
          - 192.168.0.{{i}}:9092
          {% endfor %}
    - name: suricata
      hourly: True
      byhost: False
      elastic:
        enabled: True
        indexBase: suricata
        proxies:
          {% for i in range(10,12) %}
          - 192.168.0.{{i}}:9200
          {% endfor %}
      kafka:
        enabled: True
        topic: suricata
        brokers:
          {% for i in range(20,24) %}
          - 192.168.0.{{i}}:9092
          {% endfor %}
  listeners:
    udp:
      - port: 514
        ruleset: linux
      - port: 515
        ruleset: windows
      - port: 1514
        ruleset: suricata
  lognorm:
    - name: stdtypes
      source: salt:///yellow/logserver/config-rsyslog/stdtypes.rulebase
    - name: snoopy
      source: salt:///yellow/logserver/config-rsyslog/snoopy.rulebase
  configs:
    - frompath: salt:///yellow/logserver/config-rsyslog/010-rulesets.conf
      destname: 010-rulesets.conf

