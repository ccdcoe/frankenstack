hids:
  sysmon:
    source: https://download.sysinternals.com/files/Sysmon.zip
    source_hash: fec68362c2eff86077bd7a2c84cf0b0c0f93d586

metrix:
  config: salt:///blue/metrix/config/telegraf.conf
  windows:
    source: https://dl.influxdata.com/telegraf/releases/telegraf-1.8.3_windows_amd64.zip
    hash: b779d2413371587bfa9f53acf62a7f55aeb516ce415a14f8f03909b5b49b7744
    #source: https://dl.influxdata.com/telegraf/releases/telegraf-1.9.0~rc2_windows_amd64.zip
    #hash: e6f2cd81f4b44e45d9040304226141cb366724b6d7071b60b820b01840acb9ad
  winhash:
  hostname: {{grains.fqdn}}
  influx:
    - database: telegraf
      url:  http://192.168.0.100:8086

logging:
  servers:
    - proto: udp
      host: 192.168.0.100
      port: 514
  rsyslog:
    mainconf: salt:///blue/logging/rsyslog-main.conf
    clientconf: salt:///blue/logging/rsyslog-client.conf
  nxlog:
    template: salt:///blue/logging/nxlog-main.conf
    dir: 'C:\Program Files (x86)\nxlog'
    deploy: 'C:\Program Files (x86)\nxlog\conf\nxlog.conf'
