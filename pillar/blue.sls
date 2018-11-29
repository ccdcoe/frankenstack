hids:
  sysmon:
    source: https://download.sysinternals.com/files/Sysmon.zip
    source_hash: fec68362c2eff86077bd7a2c84cf0b0c0f93d586
  snoopy:
    source: https://github.com/a2o/snoopy/raw/install/doc/install/bin/snoopy-install.sh
    source_hash: 428069bd7858e626a2dea50ed87b2d5bcfa4a411

metrix:
  config: salt:///blue/metrix/config/telegraf.conf
  windows:
    source: https://dl.influxdata.com/telegraf/releases/telegraf-1.9.0_windows_amd64.zip
    hash: b2444671ea0f31b85f443fcb81f8512632c0939ba682dffb4f6b7a102a217ab1
  winhash:
  hostname: {{grains.fqdn}}
  influx:
    - database: telegraf
      url:  http://192.168.0.100:8086

logging:
  servers:
    - proto: udp
      host: 192.168.0.3
      {% if grains.kernel == "Windows"%}
      port: 515
      {% else %}
      port: 514
      {% endif %}
  rsyslog:
    mainconf: salt:///blue/logging/config/rsyslog-main.conf
    clientconf: salt:///blue/logging/config/rsyslog-client.conf
    localconf: salt:///blue/logging/config/rsyslog-local.conf
  nxlog:
    template: salt:///blue/logging/nxlog-main.conf
    {% if grains.cpuarch == "x86" and grains.osrelease == "7" %}
    dir: 'C:\Program Files\nxlog'
    deploy: 'C:\Program Files\nxlog\conf\nxlog.conf'
    {% else %}
    dir: 'C:\Program Files (x86)\nxlog'
    deploy: 'C:\Program Files (x86)\nxlog\conf\nxlog.conf'
    {% endif %}
    channels:
      - name: Application
        value: '*' 
      - name: System
        value: '*'
      - name: Security
        value: '*'
      - name: Microsoft-Windows-Sysmon/Operational
        value: '*'
      - name: Microsoft-Windows-PowerShell/Operational
        value: '*'
      - name: Microsoft-Windows-NTLM/Operational
        value: '*'
      - name: Windows PowerShell
        value: '*'
      - name: Microsoft-Windows-Windows Defender/Operational
        value: '*'
      - name: Microsoft-Windows-GroupPolicy/Operational
        value: '*'
      - name: Microsoft-Windows-Dhcp-Client/Admin
        value: '*'
      - name: Microsoft-Windows-DeviceGuard/Operational
        value: '*'
      - name: "Microsoft-Windows-Windows Firewall With Advanced Security/Firewall"
        value: '*'
