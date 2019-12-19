include:
  - general.blockdev
  - general.docker

{% for params in pillar.alerta %}

alerta.server.network.{{params.name}}:
  docker_network.present:
    - name: {{params.name}}-net
    - containers:
      - {{params.name}}-mongo
      - {{params.name}}-api
    - require:
      - pkg: docker
      - docker_container: {{params.name}}-mongo
      - docker_container: {{params.name}}-api

alerta.server.mongo.vol.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-mongo-data

alerta.server.mongo.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-mongo
    - hostname: {{params.name}}-mongo
    # TODO! Move image settings somewhere else
    - image: mongo:latest
    - log_driver: syslog
    - log_opt: "tag={{params.name}}-mongo"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - binds:
      - {{params.name}}-mongo-data:/data/db:rw
    - require:
      - docker_volume: alerta.server.mongo.vol.{{params.name}}

alerta.server.uwsgi.socket.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-uwsgi-socket

alerta.server.api.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-api
    - hostname: {{params.name}}-api
    # TODO! Move image settings somewhere else
    - image: markuskont/alerta-api:latest
    - log_driver: syslog
    - log_opt: "tag={{params.name}}-api"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - binds:
      - {{params.name}}-uwsgi-socket:/var/alerta/run:rw
    - environment:
      - DATABASE_URL: "mongodb://{{params.name}}-mongo:27017/monitoring"
    - require:
      - docker_volume: alerta.server.uwsgi.socket.{{params.name}}
      - docker_container: alerta.server.mongo.{{params.name}}

alerta.server.proxy.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-proxy
    - hostname: {{params.name}}-proxy
    # TODO! Move image settings somewhere else
    - image: markuskont/alerta-proxy:latest
    - log_driver: syslog
    - log_opt: "tag={{params.name}}-proxy"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - binds:
      - {{params.name}}-uwsgi-socket:/var/alerta/run:rw
    - port_bindings:
      - {{params.port}}:80/tcp
    - require:
      - docker_volume: alerta.server.uwsgi.socket.{{params.name}}
      - docker_container: alerta.server.mongo.{{params.name}}
      - docker_container: alerta.server.api.{{params.name}}

{% endfor %}
