hids.client.tick.sysmon.dir:
  file.directory:
    - name: 'C:\Program Files\sysmon'

hids.client.tick.sysmon.installer:
  file.managed:
    - name: 'C:\Program Files\sysmon\sysmon.zip'
    - source: {{pillar.hids.sysmon.source}}
    - source_hash:  {{pillar.hids.sysmon.source_hash}}
    - require:
      - file: hids.client.tick.sysmon.dir

hids.client.tick.sysmon.binary:
  archive.extracted:
    - name: 'C:\Program Files\sysmon\'
    - source: 'C:\Program Files\sysmon\sysmon.zip'
    #- source: {{pillar.hids.sysmon.source}}
    #- source_hash: {{pillar.hids.sysmon.source_hash}}
    - overwrite: True
    - enforce_toplevel: False
    - require:
      - file: hids.client.tick.sysmon.installer
    - onchanges:
      - file: hids.client.tick.sysmon.installer
