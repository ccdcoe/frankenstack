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

{% set zooName = [params.name, "zk", params.id|string]|join("-")%}
zk.{{params.name}}:
  cmd.run:
    - name: docker run -ti {%if params.persist%} -d --restart=always {%else%} --rm {%endif%} --name={{zooName}} --hostname={{zooName}} {%if 'network' in params%} --network={{params.network}}{%endif%} -v {{params.name}}-zk-data:/zookeeper/data:rw -v {{params.name}}-zk-wal:/zookeeper/wal:rw -v {{params.config}}/zoo.cfg:/zookeeper/conf/zoo.cfg:ro -p {{params.ports.client}}:2181/tcp {%for var in params.env%} -e "{{var}}" {%endfor%} --log-driver syslog --log-opt tag="{{zooName}}" elevy/zookeeper:latest
    - unless: docker ps | grep "{{zooName}}"
    - require:
      - file: zk.{{params.name}}.config
      - docker_volume: zk.vol.data.{{params.name}}
      - docker_volume: zk.vol.wal.{{params.name}}

zk.start.{{params.name}}:
  cmd.run:
    - name: docker container start {{zooName}}
    - onlyif: docker ps --filter "status=exited" | grep {{zooName}}
    - require:
      - cmd: zk.{{params.name}}

{% endfor %}
