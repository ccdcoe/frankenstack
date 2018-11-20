include:
  - general.blockdev
  - general.docker

{% for params in pillar.kafka %}

kafka.{{params.name}}.config.dir:
  file.directory:
    - name: {{params.config}}

zk.{{params.name}}.config:
  file.managed:
    - name: {{params.config}}/zoo.cfg
    - source: salt:///yellow/data/configs/zoo.cfg
    - template: jinja
    - defaults:
      members: {{params.zk.members}}
    - require:
      - file: kafka.{{params.name}}.config.dir

zk.vol.data.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-zk-data
    - require:
      - service:  docker

zk.vol.wal.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-zk-wal
    - require:
      - service:  docker

zk.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-zk
    - hostname: {{params.name}}-zk
    # TODO! Move image settings somewhere else
    - image:  elevy/zookeeper:latest
    - log_driver: syslog
    - log_opt: "tag={{params.name}}-zk"
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
      - {{params.zk.ports.client}}:2181/tcp
      - {{params.zk.ports.follower}}:2888/tcp
      - {{params.zk.ports.server}}:3888/tcp
    - environment:
      - JVMFLAGS: {{params.zk.env.JVMFLAGS}}
      - MYID: {{params.zk.env.MYID}}
    - require:
      - docker_volume: zk.vol.data.{{params.name}}
      - docker_volume: zk.vol.wal.{{params.name}}
      - file: zk.{{params.name}}.config
    - watch:
      - file: zk.{{params.name}}.config

kafka.vol.data.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-kafka-data
    - require:
      - service: docker

kafka.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-kafka
    - hostname: {{params.name}}-kafka
    # TODO! Move image settings somewhere else
    - image:  wurstmeister/kafka:latest
    - log_driver: syslog
    - log_opt: "tag={{params.name}}-kafka"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - binds:
      - {{params.name}}-kafka-data:/kafka:rw
    - port_bindings:
      - {{params.kafka.port}}:9092/tcp
    - environment: {{params.kafka.env}}
    - require:
      - docker_volume: kafka.vol.data.{{params.name}}
      - docker_container: zk.{{params.name}}

{% endfor %}
