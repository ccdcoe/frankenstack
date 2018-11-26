include:
  - general.blockdev
  - general.docker

{% for params in pillar.kafka %}

kafka.{{params.name}}.config.dir:
  file.directory:
    - name: {{params.config}}

kafka.vol.data.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-kafka-data
    - require:
      - service: docker

kafka.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}-kafka-{{params.id}}
    - hostname: {{params.name}}-kafka-{{params.id}}
    # TODO! Move image settings somewhere else
    - image:  wurstmeister/kafka:latest
    - log_driver: syslog
    - log_opt: "tag={{params.name}}-kafka-{{params.id}}"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - binds:
      - {{params.name}}-kafka-data:/kafka:rw
    - port_bindings:
      - {{params.port}}:9092/tcp
    - environment: {{params.env}}
    - require:
      - docker_volume: kafka.vol.data.{{params.name}}

{% endfor %}
