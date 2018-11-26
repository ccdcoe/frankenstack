include:
  - general.blockdev
  - general.docker

{% for params in pillar.zookeeper %}

zk.{{params.name}}.config.dir:
  file.directory:
    - name: {{params.config}}

zk.{{params.name}}.config:
  file.managed:
    - name: {{params.config}}/zoo.cfg
    - source: salt:///yellow/data/configs/zoo.cfg
    - template: jinja
    - defaults:
      members: {{params.members}}
    - require:
      - file: zk.{{params.name}}.config.dir

zk.vol.data.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-zk-data
    - require:
      - service: docker

zk.vol.wal.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-zk-wal
    - require:
      - service: docker

zk.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-zk-{{params.env.MYID}}
    - hostname: {{params.name}}-zk-{{params.env.MYID}}
    # TODO! Move image settings somewhere else
    - image:  elevy/zookeeper:latest
    - log_driver: syslog
    - log_opt: "tag={{params.name}}-zk-{{params.env.MYID}}"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - binds:
      - {{params.name}}-zk-data:/zookeeper/data:rw
      - {{params.name}}-zk-wal:/zookeeper/wal:rw
      - {{params.config}}/zoo.cfg:/zookeeper/conf/zoo.cfg:ro
    - port_bindings:
      - {{params.ports.client}}:2181/tcp
      - {{params.ports.follower}}:2888/tcp
      - {{params.ports.server}}:3888/tcp
    - environment:
      - JVMFLAGS: {{params.env.JVMFLAGS}}
      - MYID: {{params.env.MYID}}
    - require:
      - docker_volume: zk.vol.data.{{params.name}}
      - docker_volume: zk.vol.wal.{{params.name}}
      - file: zk.{{params.name}}.config
    - watch:
      - file: zk.{{params.name}}.config

{% endfor %}
