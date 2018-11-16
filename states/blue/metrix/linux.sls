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
  service.running:
    - name: telegraf
    - enable: True
    - watch:
      - file: metrix.client.tick.telegraf
    - require:
      - file: metrix.client.tick.telegraf
  file.managed:
    - name: /etc/telegraf/telegraf.conf
    - source: {{pillar.metrix.config}}
    - template: jinja
    - defaults:
      outputs: {{pillar.metrix.influx}}
      hostname: {{pillar.metrix.hostname}}

