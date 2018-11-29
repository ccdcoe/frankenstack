hids.client.sysmon.dir:
  file.directory:
    - name: 'C:\Program Files\sysmon'

hids.client.sysmon.installer:
  file.managed:
    - name: 'C:\Program Files\sysmon\sysmon.zip'
    - source: {{pillar.hids.sysmon.source}}
    - source_hash:  {{pillar.hids.sysmon.source_hash}}
    - require:
      - file: hids.client.sysmon.dir

hids.client.sysmon.binary:
  archive.extracted:
    - name: 'C:\Program Files\sysmon\'
    - source: 'C:\Program Files\sysmon\sysmon.zip'
    #- source: {{pillar.hids.sysmon.source}}
    #- source_hash: {{pillar.hids.sysmon.source_hash}}
    - overwrite: True
    - enforce_toplevel: False
    - require:
      - file: hids.client.sysmon.installer
    - onchanges:
      - file: hids.client.sysmon.installer

hids.client.sysmon.config:
  file.managed:
    - name: C:\Program Files\sysmon\config.xml
    - source: salt:///blue/sysmon/swift-config/sysmonconfig-export.xml
    - require:
      - file: hids.client.sysmon.dir

hids.client.sysmon.install:
  cmd.run:
    {% if grains.cpuarch == "AMD64"%}
    - name: '"C:\Program Files\sysmon\Sysmon64.exe" -i "C:\Program Files\sysmon\config.xml" -accepteula'
    {% else %}
    - name: '"C:\Program Files\sysmon\Sysmon.exe" -i "C:\Program Files\sysmon\config.xml" -accepteula'
    {% endif %}
    - unless: 'C:\windows\system32\cmd.exe /c sc.exe query Sysmon64'
    - require:
      - archive: hids.client.sysmon.binary
      - file: hids.client.sysmon.config

hids.client.sysmon.update:
  cmd.run:
    - name: '"C:\Program Files\sysmon\Sysmon64.exe" -c "C:\Program Files\sysmon\config.xml"'
    - onlyif: 'C:\windows\system32\cmd.exe /c sc.exe query Sysmon64'
    - onchanges:
      - file: hids.client.sysmon.config
      - archive: hids.client.sysmon.binary
    - require:
      - archive: hids.client.sysmon.binary
      - file: hids.client.sysmon.config
