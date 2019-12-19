metrix.client.apt-transport-https:
  pkg.installed:
    - name: apt-transport-https

metrix.client.tick.repo:
  pkgrepo.managed:
    - humanname: TICK stack repository from Influxdata
    - name: deb https://repos.influxdata.com/{{grains.os|lower}} {{grains.oscodename}} stable
    - key_url: https://repos.influxdata.com/influxdb.key
    - file: /etc/apt/sources.list.d/influxdata.list
    - clean_file: True
    - require:
      - pkg: metrix.client.apt-transport-https

