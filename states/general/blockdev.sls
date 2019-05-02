{% if 'blockdev' in pillar and pillar.blockdev.name in grains.disks %}
{% set supported_fs = ["ext4", "xfs", "btrfs"]%}
{% if 'filesystem' in pillar.blockdev and pillar.blockdev.filesystem == 'btrfs' %}
btrfs-tools:
  pkg.latest:
    - pkgs:
      - btrfs-tools
{% endif %}

lvm2:
  pkg.installed: []

/dev/{{pillar.blockdev.name}}:
  lvm.pv_present:
    - require: 
      - pkg: lvm2

DATA:
  lvm.vg_present:
    - devices: /dev/{{pillar.blockdev.name}}

MAIN:
  lvm.lv_present:
    - vgname: DATA
    - extents: '100%FREE'

/dev/DATA/MAIN:
  blockdev.formatted:
    {% if 'filesystem' in pillar.blockdev and pillar.blockdev.filesystem in supported_fs %}
    - fs_type: {{pillar.blockdev.filesystem}}
    {% else %}
    - fs_type: ext4 
    {% endif %}

general.datadir:
  mount.mounted:
    - name: {{pillar.blockdev.path}}
    - device: /dev/DATA/MAIN
    {% if 'filesystem' in pillar.blockdev and pillar.blockdev.filesystem in supported_fs %}
    - fstype: {{pillar.blockdev.filesystem}}
    {% if pillar.blockdev.filesystem == 'btrfs' %}
    - opts: compress=zstd
    {% endif %}
    {% else %}
    - fstype: ext4 
    {% endif %}
    - persist: True
    - mkmnt: True
    - require:
      - blockdev: /dev/DATA/MAIN

{% endif %}
