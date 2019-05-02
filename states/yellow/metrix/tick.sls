include:
  - general.blockdev
  - general.docker

{% for params in pillar.metricserver.tick %}
metrix.server.{{params.name}}.config.{{params.host.config}}:
  file.directory:
    - name: {{params.host.config}}

metrix.server.{{params.name}}.main:
  file.managed:
    - name: {{params.host.config}}/influxdb.conf
    - source: {{pillar.metricserver.config.influx}}
    - template: jinja
    - defaults:
      listeners: {{params.listeners}}

metrix.server.network.{{params.name}}:
  docker_network.present:
    - name: {{params.name}}-net
    - containers:
      - {{params.name}}
      {% if 'grafana' in params %}
      - {{params.name}}-grafana
      {% endif %}
      {% if 'kapa' in params %}
      - {{params.name}}-kapa
      {% endif %}
      {% if 'chrono' in params %}
      - {{params.name}}-chrono
      {% endif %}
    - require:
      - pkg: docker
      - docker_container: {{params.name}}
      {% if 'grafana' in params %}
      - docker_container: {{params.name}}-grafana
      {% endif %}
      {% if 'kapa' in params %}
      - docker_container: {{params.name}}-kapa
      {% endif %}
      {% if 'chrono' in params %}
      - docker_container: {{params.name}}-chrono
      {% endif %}

metrix.server.volume.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-data

metrix.server.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}
    - hostname: {{params.name}}
    # TODO! Move image settings somewhere else
    - image: influxdb:alpine
    - log_driver: syslog
    - log_opt: "tag={{params.name}}"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    {% if 'listeners' in params %}
    - port_bindings:
      {% if 'udp' in params.listeners %}
      - {{params.listeners.udp.port}}:{{params.listeners.udp.port}}/udp
      {% endif %}
      {% if 'http' in params.listeners %}
      - {{params.listeners.http.port}}:8086/tcp
      {% endif %}
      {% if 'graphite' in params.listeners %}
      - {{params.listeners.graphite.port}}:2003/tcp
      {% endif %}
    - binds:
      - {{params.host.config}}/influxdb.conf:/etc/influxdb/influxdb.conf:ro
      - {{params.name}}-data:/var/lib/influxdb:rw
    - require:
      - pkg: docker
      - file: metrix.server.{{params.name}}.config.{{params.host.config}}
      - docker_volume: {{params.name}}-data
    - watch:
      - file: metrix.server.{{params.name}}.main

    {% endif %}

{% if 'grafana' in params %}

metrix.server.grafana.volume.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-grafana-data

metrix.server.grafana.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-grafana
    - hostname: {{params.name}}-grafana
    - image: grafana/grafana:latest
    #- network_mode: {{params.name}}
    - log_driver: syslog
    - log_opt: "tag={{params.name}}-grafana"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - port_bindings:
      - {{params.grafana.port}}:3000/tcp
    - environment:
      {% if 'url' in params.grafana %}
      - GF_SERVER_ROOT_URL: {{params.grafana.url}}
      {% endif %}
      - GF_SECURITY_ADMIN_PASSWORD: {{params.grafana.admin}}
    - binds:
      - {{params.name}}-grafana-data:/var/lib/grafana:rw
    - require:
      - docker_container: {{params.name}}
      - docker_volume:  metrix.server.grafana.volume.{{params.name}}

{% endif %}

{% if 'kapa' in params %}

metrix.server.kapa.{{params.name}}.main:
  file.managed:
    - name: {{params.host.config}}/kapacitor.conf
    - source: {{pillar.metricserver.config.kapacitor}}
    - template: jinja
    - defaults:
      hostname: {{params.name}}-kapa
      influx: {{params.name}}
      listeners: {{params.listeners}}

metrix.server.kapa.volume.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-kapa-data

metrix.server.kapa.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-kapa
    - hostname: {{params.name}}-kapa
    - image: kapacitor:alpine
    #- network_mode: {{params.name}}
    - log_driver: syslog
    - log_opt: "tag={{params.name}}-kapa"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - port_bindings:
      - {%if params.kapa.localhost%}127.0.0.1:{%endif%}{{params.kapa.port}}:9092/tcp
    - binds:
      - {{params.host.config}}/kapacitor.conf:/etc/kapacitor/kapacitor.conf:ro
      - {{params.name}}-kapa-data:/var/lib/kapacitor:rw
    - require:
      - file: metrix.server.kapa.{{params.name}}.main
      - docker_container: {{params.name}}
      - docker_volume: metrix.server.kapa.volume.{{params.name}}
    - watch:
      - file: metrix.server.kapa.{{params.name}}.main

{% endif %}

{% if 'chrono' in params %}

metrix.server.chrono.volume.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-chrono-data

metrix.server.chrono.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-chrono
    - hostname: {{params.name}}-chrono
    - image: chronograf:alpine
    - log_driver: syslog
    - log_opt: "tag={{params.name}}-chrono"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - environment:
      - INFLUXDB_URL: http://{{params.name}}:8086
      {% if 'kapa in params'%}
      - KAPACITOR_URL: http://{{params.name}}-kapa:9092
      {% endif %}
    - port_bindings:
      - {{params.chrono.port}}:8888/tcp
    - binds:
      - {{params.name}}-chrono-data:/var/lib/chronograf:rw
    - require:
      - docker_container: {{params.name}}
      {% if 'kapa in params'%}
      - docker_container: {{params.name}}-kapa
      {% endif %}
      - docker_volume: metrix.server.chrono.volume.{{params.name}}

{% endif %}

{% endfor %}
