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
  rsyslog:
    - name: rsyslog-collector-yellow
      persist: True
      host:
        config: /opt/rsyslog-config-yellow/
        data: /srv/rsyslog-data-yellow
      rulesets:
        - name: yellow
          hourly: True
          byhost: True
          elastic:
            enabled: True
            indexBase: yellow
            proxies:
              - 192.168.0.10:9200
          kafka:
            enabled: True
            topic: yellow
            brokers:
              - 192.168.0.10:9092
        - name: yellow-win
          hourly: True
          byhost: True
          elastic:
            enabled: True
            indexBase: yellow-win
            proxies:
              - 192.168.0.10:9200
          kafka:
            enabled: True
            topic: yellow-win
            brokers:
              - 192.168.0.10:9092
      listeners:
        udp:
          - port: 514
            ruleset: yellow
          - port: 515
            ruleset: yellow-win
      configs:
        - frompath: salt:///yellow/logserver/config-rsyslog/010-rulesets.conf
          destname: 010-rulesets.conf
