metrix.client.tick.repo:
  pkgrepo.managed:
    - humanname: TICK stack repository from Influxdata
    - gpgkey: https://repos.influxdata.com/influxdb.key
    - baseurl: https://repos.influxdata.com/centos/$releasever/$basearch/stable
    - gpgcheck: 1
