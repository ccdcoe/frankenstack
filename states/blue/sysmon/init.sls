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

hids.client.tick.sysmon.config:
  file.managed:
    - name: C:\Program Files\sysmon\config.xml
    - source: salt:///blue/sysmon/swift-config/sysmonconfig-export.xml
    - require:
      - file: hids.client.tick.sysmon.dir

hids.client.tick.sysmon.install:
  cmd.run:
    - name: '"C:\Program Files\sysmon\Sysmon64.exe" -i "C:\Program Files\sysmon\config.xml" -accepteula'
    - unless: 'C:\windows\system32\cmd.exe /c sc.exe query Sysmon64'
    - require:
      - archive: hids.client.tick.sysmon.binary
      - file: hids.client.tick.sysmon.config

hids.client.tick.sysmon.update:
  cmd.run:
    - name: '"C:\Program Files\sysmon\Sysmon64.exe" -c "C:\Program Files\sysmon\config.xml"'
    - onlyif: 'C:\windows\system32\cmd.exe /c sc.exe query Sysmon64'
    - onchanges:
      - file: hids.client.tick.sysmon.config
      - archive: hids.client.tick.sysmon.binary
    - require:
      - archive: hids.client.tick.sysmon.binary
      - file: hids.client.tick.sysmon.config
