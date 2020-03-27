# Network monitoring singlehost meta role

This role is a wrapper around other NSM roles in frankenstack to create a deployable hardware-software solution for network analysis and forensics. In other words, it packages network monitoring tools, such as Suricata, Moloch, Zeek, Beats, Elastic stack, etc, and ties them together with preconfigured set of variables. Furthermore, users can override core variables to customize the stack according to their needs. For example, to change IDS rule sources, home network definitions, exposed ports, monitoring interfaces, etc.

It is meant for rapid deployment on commodity hardware or fresh virtual machines. A preconfigured network mirror can then be plugged into monitored network interface to gain instant visibility into a possibly compromised network, while allowing the user to customize it for their needs. It is not meant to be a fully-fledged operating system or a security appliance. All stack elements are deployed through docker containers. Monitoring stack is thus mostly agnostic to underlying operating system and can theoretically be deployed on any modern x86_64 GNU/Linux distribution. Do note, however, that stack is currently developed and tested on latest Debian Stable.

## Role layout

This role has no tasks. Rather, it includes tasks from other roles and overrides their varibles in `vars` folder. Ansible role `vars` takes precedence over most variable definiton sources, thus creating a skeleton that syncronizes variable usage across multiple modules. Some variables must be modified to make the stack work. Most critical being network capture interfaces and home network definitions. A override varible set can be found in `defaults` folder. 

## Getting started

Maintaining internal play that uses this public role can be difficult, as this role, along with included roles, is currently part of overall Frankenstack project. Users are therefore encouraged to copy default variable set to another git repository.

```
cp defaults/main.yml ~/Projects/ansible-internal-capture/vars.yml
```

Then edit variables as needed nad create an inventory file.

```
vim ~/Projects/ansible-internal-capture/inventory.ini
```

```
[capture]
HOST ansible_connection=local
```

Finally, execute the singlehost nsm deployment play in `ansible/` folder in frankenstack root directory, but override inventory and variables from command line. Note that absolute path must be used, otherwise ansible will search for files relative to frankenstack project.

```
ansible-playbook --inventory-file $HOME/Projects/ansible-internal-capture/inventory.ini --limit $HOST -e "@$HOME/Projects/ansible-internal-capture/vars.yml" play_deploy_singlehost.yml --become -K
```

## Limitations

TODO -
  * This role does not prepare the host with docker install, pcap dir creation, disk config, etc. See the other `bootstrap_` roles, host prep play and Vagrantfile in `ansible/` directory to create your host bootstrap;
  * Role is only tested on Debian 10 Buster so far;
  * This role currently does not implement log collection and correlation;
  * Old elasticsearch indices are not deleted and Suricata logs are not rotated, consider this when deploying on long-term systems;
  * Web interfaces are not deployed with TLS and many are missing authentication, do not expose to public network;
