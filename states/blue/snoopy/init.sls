hids.client.snoopy.config:
  file.managed:
    - name: /etc/snoopy.ini
    - source: salt:///blue/snoopy/config/config.ini

{% if (grains.os == 'Debian' and grains.osrelease == 'testing') or (grains.os == 'Ubuntu' and osmajorrelease >= 18) %}

hids.client.snoopy.install:
  pkg.latest:
    - name: snoopy
    - require:
      - file: hids.client.snoopy.config

{% else %}

hids.client.snoopy.install.dir:
  file.directory:
    - name: /var/cache/snoopy
    - require:
      - file: hids.client.snoopy.config

hids.client.snoopy.installer:
  file.managed:
    - name: /var/cache/snoopy/installer.sh
    - source: {{pillar.hids.snoopy.source}}
    - source_hash: {{pillar.hids.snoopy.source_hash}}
    - require:
      - file: hids.client.snoopy.install.dir

hids.client.snoopy.install:
  cmd.run:
    - name: bash /var/cache/snoopy/installer.sh stable
    - cwd: /var/cache/snoopy
    - onchanges:
      - file: hids.client.snoopy.installer
    - require:
      - file: hids.client.snoopy.installer

{% endif %}
