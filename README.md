# Buttertoast


## What is Buttertoast?

Buttertoast is a small container scheduler.

It is only a container scheduler. Nothing more. But you can easily build upon it and extend it to suite your needs.

## Warning

Buttertoast is in very early development stage. Not even pre alpha. This repo holds the current state of the code.

## Questions

If you have questions or want to help feel free to join the buttertoast matrix channel (https://matrix.to/#/!PiRVVIdkswNXyVKaNy:matrix.org?via=matrix.org).

## Dependencies

Right now Buttertoast only needs an up-to-date perl 5 installation, a redis server and a haproxy.

* Perl
* Redis
* HAProxy
* nginx

## Architecture

Currently there are 2 services. *Buttertoast* and *Marmelade*. To create a Buttertoast cluster you have to install the following services on a node.

* Buttertoast
* Redis
* HAProxy

### Redis

Buttertoast use Redis to store internal runtime data and use the publish/subscribe interface to talk to its neighbours.

### HAProxy

On every host runs a HAProxy which is configured by Buttertoast. The HAProxy replaces the docker proxy. It makes the containers available to other hosts in the network. It is used only in *TCP proxy* mode.

### Buttertoast

Buttertoast is the scheduler itself. It manages the lifecycle of a container. (Start, Stop, ...). 


### Marmelade

This service is used on containers which are doing the ingress trafic handling. So if you want to make some services available to the public you have to run at least one ingress container with marmelade. Currently marmelade is using *nginx* to proxy the requests.


## Supported Containers

Buttertoast is designed to be easily extended to support different container formats. Currently it only supports *Docker*.

