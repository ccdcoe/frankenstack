metrix.client.tick.telegraf.dir:
  file.directory:
    - name: 'C:\Program Files\Telegraf'

metrix.client.tick.telegraf.installer:
  file.managed:
    - name: 'C:\Program Files\Telegraf\telegraf.zip'
    - source: {{pillar.metrix.windows.source}}
    - source_hash:  {{pillar.metrix.windows.hash}}
    - require:
      - file: metrix.client.tick.telegraf.dir

metrix.client.tick.telegraf.binary:
  archive.extracted:
    - name: 'C:\Program Files\Telegraf\'
    - source: 'C:\Program Files\Telegraf\telegraf.zip'
    - overwrite: True
    - onchanges:
      - file: metrix.client.tick.telegraf.installer
    - require:
      - file: metrix.client.tick.telegraf.installer

metrix.client.tick.telegraf.remove:
  service.dead:
    - name: telegraf
    - onlyif: 'C:\windows\system32\cmd.exe /c sc.exe query telegraf'
    - onchanges:
      - archive: metrix.client.tick.telegraf.binary
    - require:
      - archive: metrix.client.tick.telegraf.binary
  cmd.run:
    - name: '"C:\Program Files\Telegraf\telegraf\telegraf.exe" --service uninstall'
    - onlyif: 'C:\windows\system32\cmd.exe /c sc.exe query telegraf'
    - onchanges:
      - archive: metrix.client.tick.telegraf.binary
    - require:
      - archive: metrix.client.tick.telegraf.binary
      - service: metrix.client.tick.telegraf.remove

metrix.client.tick.telegraf:
  cmd.run:
    - name: '"C:\Program Files\Telegraf\telegraf\telegraf.exe" --service install --config "C:\Program Files\Telegraf\telegraf.conf"'
    - unless: 'C:\windows\system32\cmd.exe /c sc.exe query telegraf'
    - shell: 'windows'
    - require:
      - archive: metrix.client.tick.telegraf.binary
      - cmd: metrix.client.tick.telegraf.remove
  service.running:
    - name: telegraf
    - enable: True
    - require:
      - cmd:  metrix.client.tick.telegraf
      - file:  metrix.client.tick.telegraf
    - watch:
      - file:  metrix.client.tick.telegraf
  file.managed:
    - name: 'C:\Program Files\Telegraf\telegraf.conf'
    - source: {{pillar.metrix.config}}
    - template: jinja
    - defaults:
      outputs: {{pillar.metrix.influx}}
      hostname: {{pillar.metrix.hostname}}
