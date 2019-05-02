include:
  - general.python
  - general.blockdev

{% if grains.oscodename == 'Debian GNU/Linux buster/sid' %}
  {% set oscode = 'buster'%}
{% else %}
  {% set oscode = grains.oscodename %}
{% endif %}


docker:
  pkgrepo.managed:
    - humanname: Docker Package Repository
    - name: deb https://download.docker.com/linux/{{grains.os|lower}} {{ oscode }} stable
    - key_url: https://download.docker.com/linux/debian/gpg
    - file: /etc/apt/sources.list.d/docker.list
    - refresh_db: True
  pkg.latest:
    - pkgs:
      - docker-ce
      - python-docker
      - python3-docker
      - python-backports.ssl-match-hostname
      {% if 'blockdev' in pillar and pillar.blockdev.name in grains.disks %}
      - mount: general.datadir
      {% endif %}
  service.running:
    - name: docker
    - enable: True
    {% if 'docker' in pillar %}
    - watch:
      - file: docker
      - pkg: docker
    - require:
      - file: docker
      - pkg: docker
    {% endif %}
{% if 'docker' in pillar %}
  file.serialize:
    - name: /etc/docker/daemon.json
    - mode: 644
    - dataset: {{pillar.docker}}
    - formatter: json
    - require:
      - pkg: docker
{% endif %}
