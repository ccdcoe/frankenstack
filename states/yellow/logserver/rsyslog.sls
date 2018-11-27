include:
  - general.blockdev
  - general.docker

{% for params in pillar.logservers.rsyslog %}

logserver.{{params.name}}.{{params.host.config}}:
  file.directory:
    - name: {{params.host.config}}

logserver.{{params.name}}.inc.{{params.host.config}}:
  file.directory:
    - name: {{params.host.config}}/rsyslog.d
    - require:
      - file: logserver.{{params.name}}.{{params.host.config}}

logserver.{{params.name}}.parse.{{params.host.config}}:
  file.directory:
    - name: {{params.host.config}}/lognorm
    - require:
      - file: logserver.{{params.name}}.{{params.host.config}}

{% if 'lognorm' in params %}
{% for norm in params.lognorm %}
logserver.{{params.name}}.norm.{{norm.name}}:
  file.managed:
    - name: {{params.host.config}}/lognorm/{{norm.name}}.rulebase
    - source: {{norm.source}}
    - require:
      - file: logserver.{{params.name}}.parse.{{params.host.config}}
{% endfor %}
{% endif %}

{% for conf in params.configs %}

logserver.{{params.name}}.{{conf.destname}}:
  file.managed:
    - name: {{params.host.config}}/rsyslog.d/{{conf.destname}}
    - source: {{conf.frompath}}
    - template: jinja
    - defaults:
      params: {{params}}
    - require:
      - file: logserver.{{params.name}}.inc.{{params.host.config}}

logserver.{{params.name}}.check.config:
  cmd.run:
    - name: docker run --rm -v {{params.host.config}}/rsyslog.d:/etc/rsyslog.d --name {{params.name}}-test markuskont/rsyslog:latest -N 1
    - require:
      - pkg: docker
      - docker_container: logserver.{{params.name}}
      - file: logserver.{{params.name}}.{{conf.destname}}
      {% if 'lognorm' in params %}
      {% for norm in params.lognorm %}
      - file: logserver.{{params.name}}.norm.{{norm.name}}
      {% endfor %}
      {% endif %}
    - onchanges:
      - file: logserver.{{params.name}}.{{conf.destname}}

{% endfor %}

logserver.vol.{{params.name}}:
  docker_volume.present:
    - name: {{params.name}}-logs-data

logserver.{{params.name}}:
  docker_container.running:
    - name: {{params.name}}
    - hostname: {{params.name}}
    # TODO! Use a more official image
    - image: markuskont/rsyslog:latest
    - log_driver: syslog
    - log_opt: "tag={{params.name}}"
    {% if params.persist %}
    - restart-policy: always
    {% else %}
    - auto_remove: True
    {% endif %}
    - port_bindings:
      {% if 'tcp' in params.listeners %}
      {% for port in params.listeners.tcp %}
      - {{port.port}}:{{port.port}}/tcp
      {% endfor %}
      {% endif %}
      {% for port in params.listeners.udp %}
      - {{port.port}}:{{port.port}}/udp
      {% endfor %}
    - binds:
      - {{params.host.config}}/rsyslog.d/:/etc/rsyslog.d/:ro
      - {{params.host.config}}/lognorm/:/etc/lognorm/:ro
      - {{params.name}}-logs-data:/var/log/:rw
    - environment:
      - LIBLOGNORM_RULEBASES: "/etc/lognorm"
    - require:
      - pkg: docker
      - file: logserver.{{params.name}}.{{params.host.config}}
      - file: logserver.{{params.name}}.inc.{{params.host.config}}
      - file: logserver.{{params.name}}.parse.{{params.host.config}}
      - docker_volume: logserver.vol.{{params.name}}
      {% if 'lognorm' in params %}
      {% for norm in params.lognorm %}
      - file: logserver.{{params.name}}.norm.{{norm.name}}
      {% endfor %}
      {% endif %}
      {% for conf in params.configs %}
      - file: logserver.{{params.name}}.{{conf.destname}}
      {% endfor %}
    - watch:
      {% for conf in params.configs %}
      - file: logserver.{{params.name}}.{{conf.destname}}
      {% endfor %}
      {% if 'lognorm' in params %}
      {% for norm in params.lognorm %}
      - file: logserver.{{params.name}}.norm.{{norm.name}}
      {% endfor %}
      {% endif %}

{% endfor %}
