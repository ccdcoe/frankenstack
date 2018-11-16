rsyslog:
  {%if grains['oscodename'] == 'precise'%}
  pkgrepo.managed:
    - ppa: adiscon/v8-stable
  {%endif%}
  pkg.latest:
    - refresh: True
    - pkgs:
      - rsyslog
  service.running:
    - name: rsyslog
    - enable: True
    - require:
      - file: /etc/rsyslog.conf
      - file: /etc/rsyslog.d/60-remote.conf
    - watch:
      - file: /etc/rsyslog.conf
      - file: /etc/rsyslog.d/60-remote.conf

/etc/rsyslog.conf:
  file.managed:
    - source: {{pillar.logging.rsyslog.mainconf}}
    - mode: 640
    - require:
      - pkg: rsyslog

/etc/rsyslog.d/60-remote.conf:
  file.managed:
    - source: {{pillar.logging.rsyslog.clientconf}}
    - template: jinja
    - mode: 640
    - defaults:
      servers: {{pillar.logging.servers}}
    - require:
      - pkg: rsyslog

