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

# NOTE! This is a hack to work around dockerng state issue in our environment
# See commented dockerng states for proper deployment
{% if "split_roles" in params and params.split_roles %}

{% for role in ["master", "proxy", "worker"] %}
{% set elaName = [params.name, params.id|string, role]|join("-")%}

{% if role == "master" %}

{% set ela_heap = params.master_heap %}
{% set role_config = "-e node.master=true -e node.ingest=false -e node.data=false"%}

{% elif role == "proxy" %}

{% set ela_heap = params.proxy_heap %}
{% set role_config = "-e node.master=false -e node.ingest=false -e node.data=false"%}

{% elif role == "worker" %}

{% set ela_heap = params.worker_heap %}
{% set role_config = "-e node.master=false -e node.ingest=true -e node.data=true"%}

{% endif %}

ela.{{params.name}}.{{role}}:
  cmd.run:
    - name: docker run -ti {%if params.persist%} -d --restart=always {%else%} --rm {%endif%} --name={{elaName}} --hostname={{elaName}} {%if 'network' in params%}--network={{params.network}}{%endif%} {%if role == "worker"%}-v {{params.name}}-ela-data:/usr/share/elasticsearch/data:rw{%endif%} {%if role == "proxy"%} -p {{params.ports.http}}:9200/tcp{%endif%} -e "ES_JAVA_OPTS=-Xms{{ela_heap}} -Xmx{{ela_heap}}" -e "cluster.name={{params.name}}" -e "node.name={{grains.fqdn}}-{{elaName}}" {{role_config}} {%for var in params.env%} -e "{{var}}" {%endfor%} --log-driver syslog --log-opt tag="{{elaName}}" docker.elastic.co/elasticsearch/elasticsearch-oss:{{params.version.ela}}
    - unless: docker ps -a | grep "{{elaName}}"
    - require: [ docker_volume: ela.vol.data.{{params.name}}, sysctl: ela.fs.max_map_count ]

ela.start.{{params.name}}.{{role}}:
  cmd.run:
    - name: docker container start {{elaName}}
    - onlyif: docker ps --filter "status=exited" | grep {{elaName}}
    - require: 
      - cmd: ela.{{params.name}}.{{role}}

{% endfor %}

{% set kibanaName = [params.name, params.id|string, "kibana"]|join("-")%}
ela.kibana.{{params.name}}:
  cmd.run:
    - name: docker run -ti {%if params.persist%} -d --restart=always {%else%} --rm {%endif%} --name={{kibanaName}} --hostname={{kibanaName}} {%if 'network' in params%}--network={{params.network}}{%endif%} -p {{params.ports.kibana}}:5601/tcp -e "SERVER_NAME={{kibanaName}}" -e "ELASTICSEARCH_URL=http://{{params.name}}-{{params.id}}-proxy:9200" --log-driver syslog --log-opt tag="{{kibanaName}}" docker.elastic.co/kibana/kibana-oss:{{params.version.kibana}}
    - unless: docker ps -a | grep "{{kibanaName}}"
    - require: [ cmd: ela.{{params.name}}.proxy ]

ela.kibana.start.{{params.name}}:
  cmd.run:
    - name: docker container start {{kibanaName}}
    - onlyif: docker ps --filter "status=exited" | grep {{kibanaName}}
    - require: 
      - cmd: ela.kibana.{{params.name}}

{% else %}
{% set elaName = [params.name, params.id|string, "ela"]|join("-")%}
ela.{{params.name}}:
  cmd.run:
    - name: docker run -ti {%if params.persist%} -d --restart=always {%else%} --rm {%endif%} --name={{elaName}} --hostname={{elaName}} {%if 'network' in params%}--network={{params.network}}{%endif%} -v {{params.name}}-ela-data:/usr/share/elasticsearch/data:rw -p {{params.ports.http}}:9200/tcp {%if "java_heap" in params%} -e "ES_JAVA_OPTS=-Xms{{params.java_heap}} -Xmx{{params.java_heap}}" {%endif%} {%for var in params.env%} -e "{{var}}" {%endfor%} --log-driver syslog --log-opt tag="{{elaName}}" docker.elastic.co/elasticsearch/elasticsearch-oss:{{params.version.ela}}
    - unless: docker ps -a | grep "{{elaName}}"
    - require: [ docker_volume: ela.vol.data.{{params.name}}, sysctl: ela.fs.max_map_count ]

ela.start.{{params.name}}:
  cmd.run:
    - name: docker container start {{elaName}}
    - onlyif: docker ps --filter "status=exited" | grep {{elaName}}
    - require: 
      - cmd: ela.{{params.name}}

{% set kibanaName = [params.name, params.id|string, "kibana"]|join("-")%}
ela.kibana.{{params.name}}:
  cmd.run:
    - name: docker run -ti {%if params.persist%} -d --restart=always {%else%} --rm {%endif%} --name={{kibanaName}} --hostname={{kibanaName}} {%if 'network' in params%}--network={{params.network}}{%endif%} -p {{params.ports.kibana}}:5601/tcp -e "SERVER_NAME={{kibanaName}}" -e "ELASTICSEARCH_URL=http://{{elaName}}:9200" --log-driver syslog --log-opt tag="{{kibanaName}}" docker.elastic.co/kibana/kibana-oss:{{params.version.kibana}}
    - unless: docker ps -a | grep "{{kibanaName}}"
    - require: [ cmd: ela.{{params.name}} ]

ela.kibana.start.{{params.name}}:
  cmd.run:
    - name: docker container start {{kibanaName}}
    - onlyif: docker ps --filter "status=exited" | grep {{kibanaName}}
    - require: 
      - cmd: ela.kibana.{{params.name}}
{% endif %}

{% endfor %}
