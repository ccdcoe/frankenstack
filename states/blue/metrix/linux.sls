{% if grains.os_family == 'Debian' %}
include:
  - blue.metrix.debian
{% elif grains.os_family == 'RedHat' %}
include:
  - blue.metrix.redhat
{% endif %}

metrix.client.tick.telegraf:
  pkg.latest:
    - name: telegraf
    - refresh: True
    - require:
      - pkgrepo: metrix.client.tick.repo
  file.managed:
    - name: /etc/telegraf/telegraf.conf
    - source: salt:///blue/metrix/config/telegraf.conf
    - template: jinja
    - defaults:
      outputs: {{pillar.metrix.influx}}
      hostname: {{pillar.metrix.hostname}}

metrix.client.tick.telegraf.core.config:
  file.managed:
    - name: /etc/telegraf/telegraf.d/core.conf
    - source:  salt:///blue/metrix/config/telegraf-core.conf
    - template: jinja
    - defaults:
      outputs: {{pillar.metrix.influx}}
      hostname: {{pillar.metrix.hostname}}
    - require:
      - file: metrix.client.tick.telegraf

metrix.client.tick.telegraf.service:
  service.running:
    - name: telegraf
    - enable: True
    - watch:
      - file: metrix.client.tick.telegraf
      - file: metrix.client.tick.telegraf.core.config
    - require:
      - file: metrix.client.tick.telegraf
      - file: metrix.client.tick.telegraf.core.config
