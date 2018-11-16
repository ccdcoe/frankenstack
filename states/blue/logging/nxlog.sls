include:
  - blue.sysmon

nxlog:
  pkg.latest:
    - refresh: True
  file.managed:
    - name: {{pillar.logging.nxlog.deploy}}
    - source: {{pillar.logging.nxlog.template}}
    - template: jinja
    - defaults:
      params: {{pillar.logging.nxlog}}
      servers: {{pillar.logging.servers}}
  service.running:
    - enable: True
    - watch:
      - {{pillar.logging.nxlog.deploy}}
