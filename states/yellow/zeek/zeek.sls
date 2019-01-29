git:
  pkg.installed

zeek-requirements:
  pkg.installed:
    - pkgs:
      - cmake
      - make
      - gcc
      - g++
      - flex
      - bison
      - libpcap-dev
      - libssl-dev
      - python-dev
      - python3-pip
      - python3-venv
      - swig
      - zlib1g-dev
      - librdkafka-dev
      - btest
      - libsnappy-dev
      - linux-headers-{{ grains.kernelrelease }}

zeek-clone:
  git.latest:
    - name: https://github.com/zeek/zeek.git
    - rev: release/2.6
    - submodules: True
    - target: /var/tmp/zeek
    - require:
      - pkg: git

zeek-deploy:
  cmd.run:
    - cwd: /var/tmp/zeek
    - name: |
        ./configure --prefix=/usr/local
        make -j 4
        make install
    - require:
      - git: https://github.com/zeek/zeek.git
    - onlyif: 'test ! -e /usr/local/bin/broctl'

zeek-kafka:
  git.latest:
    - name: https://github.com/apache/metron-bro-plugin-kafka
    - rev: master
    - target: /var/tmp/metron-bro-plugin-kafka
    - require:
      - pkg: git

zeek-kafka-deploy:
  cmd.run:
    - cwd: /var/tmp/metron-bro-plugin-kafka
    - name: |
        ./configure --bro-dist=/var/tmp/zeek
        make
        make install
    - require:
      - git: https://github.com/apache/metron-bro-plugin-kafka
    - onlyif: 'test ! -e /usr/local/lib/bro/plugins/APACHE_KAFKA'

zeek-af-packet:
  git.latest:
    - name: https://github.com/J-Gras/bro-af_packet-plugin
    - rev: master
    - target: /var/tmp/bro-af_packet-plugin
    - require:
      - pkg: git

zeek-node-cfg:
  file.managed:
    - name: /usr/local/etc/node.cfg
    - source: salt://node.cfg

zeek-af-packet-deploy:
  cmd.run:
    - cwd: /var/tmp/bro-af_packet-plugin
    - name: |
        ./configure --bro-dist=/var/tmp/zeek --with-kernel=/usr/src/linux-{{grains.kernelrelease}}/
        make
        make install
    - require:
      - git: https://github.com/J-Gras/bro-af_packet-plugin
    - onlyif: 'test ! -e /usr/local/lib/bro/plugins/Bro_AF_Packet/'

zeek-policy-kafka:
  file.managed:
    - name: /usr/local/share/bro/site/bro.bro
    - source: salt://zeeky/bro.bro

zeek-policy-packet:
  file.managed:
    - name: /usr/local/share/bro/site/packet_bin.bro
    - source: salt://zeeky/packet_bin.bro

zeek-policy-local:
  file.managed:
    - name: /usr/local/share/bro/site/local.bro
    - source: salt://zeeky/local.bro

zeek-beacons:
  file.managed:
    - name: /srv/cobalt-activity/beacons.py
    - source: salt://zeeky/beacons.py

zeek-run:
  cmd.run:
    - name: broctl deploy


/srv/cobalt-activity/venv:
  virtualenv.managed:
    - venv_bin: /usr/bin/pyvenv
    - system_site_packages: False
    - pip_pkgs: influxdb, numpy, scipy, kafka-python, python-snappy
