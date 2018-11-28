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
  cmd.run:
    - name: docker run -ti {%if params.persist%} -d --restart=always {%else%} --rm {%endif%} --name={{params.name}}-kafka-{{params.id}} --hostname={{params.name}}-kafka-{{params.id}} {%if 'network' in params%} --network={{params.network}}{%endif%} -v {{params.name}}-kafka-data:/kafka:rw -p {{params.port}}:9092/tcp {%for var in params.env%} -e "{{var}}" {%endfor%} --log-driver syslog --log-opt tag="{{params.name}}-kafka-{{params.id}}"  wurstmeister/kafka:latest
    - unless: docker ps | grep "{{params.name}}-kafka-{{params.id}}"
    - require:
      - docker_volume: kafka.vol.data.{{params.name}}

{% endfor %}
