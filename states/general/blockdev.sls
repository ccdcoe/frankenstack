{% if pillar.blockdev.name in grains.disks %}

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
    - fs_type: ext4 

general.datadir:
  mount.mounted:
    - name: {{pillar.blockdev.path}}
    - device: /dev/DATA/MAIN
    - fstype: ext4 
    - persist: True
    - mkmnt: True
    - require:
      - blockdev: /dev/DATA/MAIN

{% endif %}
