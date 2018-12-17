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

{% set kafkaName = [params.name, "kafka", params.id|string]|join("-")%}
kafka.{{params.name}}:
  cmd.run:
    - name: docker run -ti {%if params.persist%} -d --restart=always {%else%} --rm {%endif%} --name={{kafkaName}} --hostname={{kafkaName}} {%if 'network' in params%} --network={{params.network}}{%endif%} -v {{params.name}}-kafka-data:/kafka:rw -p {{params.port}}:9092/tcp {%for var in params.env%} -e "{{var}}" {%endfor%} --log-driver syslog --log-opt tag="{{kafkaName}}"  wurstmeister/kafka:latest
    - unless: docker ps | grep "{{params.name}}-kafka-{{params.id}}"
    - require:
      - docker_volume: kafka.vol.data.{{params.name}}

kafka.start.{{params.name}}:
  cmd.run:
    - name: docker container start {{kafkaName}}
    - onlyif: docker ps --filter "status=exited" | grep {{kafkaName}}
    - require:
      - cmd: kafka.{{params.name}}

{% endfor %}
