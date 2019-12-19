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

  'jumbo-*.yellow.ex':
    - yellow.alerts.alerta
    - yellow.metrix.tick
    - yellow.logserver.rsyslog

  'broker-*.yellow.ex':
    - general.blockdev
    - general.docker
    - yellow.data.zookeeper
    - yellow.data.kafka

  'test-site-*.yellow.ex':
    - general.docker
    - general.blockdev
    - yellow.data.elastic
