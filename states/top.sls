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

  # SERVERS
  'master.yellow.ex':
    - general.docker

  'test-site-*.yellow.ex':
    - general.docker

  'jumbo-*':
    - yellow.logserver
    - yellow.metrix
