# Ansible

Ansible playbooks for deploying frankenstack

## Playbooks

 * play\_deploy\_stack.yml - Primary playbook to orchestrate the correct deployment sequence of the entire stack

### Supporting playbooks

 * play\_basic\_prep\_vm.yml - Basic prep for VM (timezone, standard packages, disk, turn off swap, setup docker)
 * play\_basic\_update\_and\_reboot.yml - Update all packages and reboot
 * play\_bootstrap\_swarm.yml - Deploy and configure docker swarm
 * play\_bootstrap\_vsphere.yml - Clone VMs and run post-deployment procedures (configure networking, etc.)
 * play\_deploy\_nsm.yml - Deploy NSM tools (Moloch, Suricata)
 * play\_undeploy\_vsphere.yml - Remove existing inventory VMs

## Private vars

You are inevitably going to have to define a whole bunch of variables that are specific to your organization, infrastucture and environment.

To name a few examples in our case:

 * VMware URLs, credentials, directory structure, networks, datastore, etc.
 * DNS for the stack
 * Users, passwords, keys, hashes
 * Optionally your known assets for NSM tagging

## Getting started

```
ansible-playbook -i inventory/yellow.ini play_deploy_stack.yml
```

