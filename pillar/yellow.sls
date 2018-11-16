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
    - name: rsyslog-collector-blue
      persist: True
      host:
        config: /opt/rsyslog-config-blue
        data: /srv/rsyslog-data-blue
      rulesets:
        - name: targets-OLD
          hourly: True
          byhost: True
          json: True
        - name: targets-NEW
          hourly: True
          byhost: True
          json: True
      listeners:
        udp:
          - port: 514
            ruleset: targets-OLD
          - port: 6514
            ruleset: targets-NEW
        tcp:
          - port: 514
            ruleset: NEW-TCP
      configs:
        - frompath: salt:///yellow/logserver/config-rsyslog/001-basic.conf
          destname: 001-basic.conf
    - name: rsyslog-collector-yellow
      persist: True
      host:
        config: /opt/rsyslog-config-yellow/
        data: /srv/rsyslog-data-yellow
      rulesets:
        - name: yellow
          hourly: True
          byhost: True
          json: True
      listeners:
        udp:
          - port: 10514
            ruleset: yellow
      configs:
        - frompath: salt:///yellow/logserver/config-rsyslog/001-basic.conf
          destname: 001-basic.conf
