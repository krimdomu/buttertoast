# Buttertoast


## What is Buttertoast?

Buttertoast is a small container scheduler.

It is only a container scheduler. Nothing more. But you can easily build upon it and extend it to suite your needs.

## Warning

Buttertoast is in very early development stage. Not even pre alpha. This repo holds the current state of the code.

## Questions

If you have questions or want to help feel free to join the butter matrix channel (https://matrix.to/#/!PiRVVIdkswNXyVKaNy:matrix.org?via=matrix.org).

## Dependencies

Right now Buttertoast only needs an up-to-date perl 5 installation, a redis server and a haproxy.

* Perl
* Redis
* HAProxy
* nginx

## Architecture

Currently there are 2 services. *Butter* and *Marmelade*. To create a Buttertoast cluster you have to install the following services on a node.

* Buttertoast (The Butter service)
* Redis
* HAProxy

### Redis

Buttertoast use Redis to store internal runtime data and use the publish/subscribe interface to talk to its neighbours.

### HAProxy

On every host runs a HAProxy which is configured by Buttertoast. The HAProxy replaces the docker proxy. It makes the containers available to other hosts in the network. It is used only in *TCP proxy* mode.

### Butter

Butter is the scheduler itself. It manages the lifecycle of a container. (Start, Stop, ...). 


### Marmelade

This service is used on containers which are doing the ingress trafic handling. So if you want to make some services available to the public you have to run at least one ingress container with marmelade. Currently marmelade is using *nginx* to proxy the requests.


## Supported Containers

Buttertoast is designed to be easily extended to support different container formats. Currently it only supports *Docker*.

# Configuration

## Marmelade

You have 2 options to configure marmelade. One by a configuration file. The other via ENV variables.

### Configuration File

Right now, you have to place the configuration file inside your marmelade installation directory.

### Environ Variables

* MARMELADE_ENV_CONFIG : must be set to 1
* MARMELADE_REDIS_HOST : defaults to localhost
* MARMELADE_REDIS_PORT : defaults to 6379
* MARMELADE_ID : defaults to create a random uuid. after first start it is better to save it and to provide the same id on next startup.
* MARMELADE_DRIVER : which service it should handle, defaults to Nginx.
* MARMELADE_NGINX_CONFIG_PATH : defaults to /etc/nginx/conf.d/
