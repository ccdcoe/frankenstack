# frankenstack

Busted. With duct tape, spit and tears. Brought to you by beer.

## A note about clustered components

Most components are self-contained with minimal need for containerized network bridges. However, some tools like elasticsearch, kafka, zookeepeer, etc are designed to scale horizontally. Deploying an elastic cluster on a single host would serve no purpose other than to stay below Java ~32GB heap rule. Since most components are, or will be, dockerized, then it's possible to leverage [docker overlay network](https://docs.docker.com/network/overlay/) to connect clustered images over multiple worker hosts. Creation of this network is not handled by states.

Firstly, initialize your docker swarm master. I would recommend doing this on your salt-master or main data collector server.

```
sudo docker swarm init --advertise-addr=<master-ip>
```

Secondly, join your docker workers to swarm. Doing it via salt is easiest.

```
salt 'test-site-*' cmd.run 'docker swarm join --token <master-token> <master-ip>:2377'
```

Finally, create attachable overlay network on swarm master. Name of this network can then be specified in pillar.

```
sudo docker network create -d overlay --attachable myoverlay
```

Note that cluster rebalance operations can be quite network-io intensive and we have not benchmarked this with large elastic or kafka deployments. Furthermore, salt dockerng state module had issues in our lab whereby containers were disconnected from network on second highstate runs. Expect state hacks to work around this issue.
