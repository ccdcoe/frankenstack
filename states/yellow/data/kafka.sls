include:
  - general.blockdev
  - general.docker

{% for params in pillar.kafka %}

zk.vol.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-zk-data
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
      - {{params.name}}-zk-data:/var/lib/zookeeper:rw
    - require:
      - docker_volume: zk.vol.{{params.name}}

{% endfor %}
