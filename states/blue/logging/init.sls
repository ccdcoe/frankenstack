{% if grains.kernel == 'Linux' %}
include:
  - blue.logging.rsyslog
{% elif grains.kernel == 'Windows'%}
include:
  - blue.logging.nxlog
{% endif %}
