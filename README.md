# docker-dev-env

The shell script intended to simplify creation of developing environments in the Docker especially on a Mac OS. This script does not do much on a Linux OS but is compatible because this is just convenient to use the same script on both OSes.

![](script.gif)

## What this script does?

* Configures the Dnsmasq to resolve containers hostnames on a host OS and containers (if the dnsmasq is installed on a container).
* Adds containers hostnames to the /etc/hosts file in all running containers.
* Mac OS: Configures a network bridge in a VirtualBox and adds gateway route on host OS to expose containers IPs (172.\*) for host.
* Mac OS: [Configures NFS sharing](https://github.com/adlogix/docker-machine-nfs) (works faster than default vboxsf)

## How to use?

You need to add the `DevEnvConf` file next in the same folder as your the `Dockerfile`. The `DevEnvFile` is regular shell script which should define two variables:
* `NAME` - The name is used as an image name, an container name, and a hostname. A hostname is suffixed with ".loc".
* `ARGS` - Arguments for the Docker's run command. You can provide special argument `--build-only` to prevent an image from run.

The simple `DevEnvFile` file could look like this:
```bash
#!/bin/bash

NAME="example-php5"
ARGS="-tdi -v $MOUNT_DIR/www:/var/www/html"
```

To start your machines you need to run the `./bin/docker-dev-env` script and provide paths to directories containing the `Dockerfile` and the `DevEnvFile` as arguments. For example:

`./bin/docker-dev-env images/example-php5 images/example-mysql`

Now, an `example-php5` and an `example-mysql` containers will be accessible through an `example-php5.loc` and an `example-mysql.loc` domains. You can use these domains also inside your containers.

## Requirements

* [Docker](https://www.docker.com/)
* [Dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) (on a Mac OS currently supports only version installed from a Macports)

For Mac OS only:
* [Docker Machine](https://docs.docker.com/machine/) 0.5.0+
* [docker-machine-nfs](https://github.com/adlogix/docker-machine-nfs)
