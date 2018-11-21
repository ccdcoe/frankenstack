include:
  - general.blockdev
  - general.docker

ela.fs.file-max:
  sysctl.present:
    - name: fs.file-max
    - value: 256000
    - config: '/etc/sysctl.conf'

ela.fs.max_map_count:
  sysctl.present:
    - name: vm.max_map_count
    - value: 262144
    - config: '/etc/sysctl.conf'

{% for params in pillar.elastic %}

ela.vol.data.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-ela-data
    - require:
      - service: docker

ela.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-{{params.id}}
    - hostname: {{params.name}}
    # TODO! Move image settings somewhere else
    - image:  docker.elastic.co/elasticsearch/elasticsearch-oss:{{params.version.kibana}}
    - log_driver: syslog
    - log_opt: "tag={{params.name}}"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - network_mode: {{params.network}}
    - binds:
      - {{params.name}}-ela-data:/usr/share/elasticsearch/data:rw
    - port_bindings:
      - {{params.ports.http}}:9200/tcp
    - environment: {{params.env}}
    - require:
      - docker_volume: ela.vol.data.{{params.name}}
      - sysctl: ela.fs.max_map_count

ela.kibana.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-{{params.id}}-kibana
    - hostname: {{params.name}}-kibana
    # TODO! Move image settings somewhere else
    - image:  docker.elastic.co/kibana/kibana-oss:{{params.version.kibana}}
    - log_driver: syslog
    - log_opt: "tag={{params.name}}-kibana"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - network_mode: {{params.network}}
    - port_bindings:
      - {{params.ports.kibana}}:5601/tcp
    - environment:
      - SERVER_NAME: {{params.name}}-kibana
      - ELASTICSEARCH_URL: http://{{params.name}}-{{params.id}}:{{params.ports.http}}
    - require:
      - docker_container: ela.{{params.name}}

{% endfor %}
