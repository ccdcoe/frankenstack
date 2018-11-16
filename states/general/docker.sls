include:
  - general.python

{% if grains.oscodename == 'Debian GNU/Linux buster/sid' %}
  {% set oscode = 'buster'%}
{% else %}
  {% set oscode = grains.oscodename %}
{% endif %}

{% if 'docker' in pillar %}
docker.config:
  file.serialize:
    - name: /etc/docker/daemon.json
    - mode: 644
    - dataset: {{pillar.docker}}
    - formatter: json
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
  service.running:
    - name: docker
    - enable: True
    {% if 'docker' in pillar %}
    - watch:
      - file: docker.config
    - require:
      - file: docker.config
    {% endif %}
#  pip.installed:
#    - name: docker
#    #- bin_env: '/opt/salt/venv/bin/pip'
#    - require:
#      - pkg: python-pip

