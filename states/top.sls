base:
  # CLIENT CONFIGS
  '*':
    - blue.logging

  'os:(Debian|RedHat)':
    - match: grain_pcre
    - blue.metrix.linux

  'os:Windows':
    - match: grain
    - blue.metrix.win
    - blue.sysmon

  # SERVERS
  'master.yellow.ex':
    - general.docker
    - yellow.data.zookeeper

  'test-site-*.yellow.ex':
    - general.docker
    - general.blockdev
    - yellow.data.zookeeper
    - yellow.data.kafka
    - yellow.data.elastic

  'jumbo-*':
    - yellow.alerts.alerta
    - yellow.metrix.tick
    - yellow.logserver.rsyslog
    - yellow.data.zookeeper
