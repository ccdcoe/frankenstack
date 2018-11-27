base:
  # CLIENT CONFIGS
  '*':
    - blue.logging

  'kernel:Linux':
    - match: grain
    - blue.snoopy

  'kernel:Windows':
    - match: grain
    - blue.metrix.win
    - blue.sysmon

  'os:(Debian|RedHat)':
    - match: grain_pcre
    - blue.metrix.linux

  # SERVERS
  'master.yellow.ex':
    - general.docker

  'jumbo-*':
    - yellow.alerts.alerta
    - yellow.metrix.tick
    - yellow.logserver.rsyslog

  'test-site-*.yellow.ex':
    - general.docker
    - general.blockdev
    - yellow.data.zookeeper
    - yellow.data.kafka
    - yellow.data.elastic
