Intro
=====

Demo to create a simple VM with nodejs installed
on openstack with minimal footprint:
- small flavor
- boot from volume (small size)
- ipv6 only

using [terraform](https://www.terraform.io/)

In this example I use Infomaniak Public Cloud because it's performamt and cost effective
(moreover the company is a must in terms of compliance, ecology, etc)

A VM like this one costs CHF 3.37 / month !
[link to the calculator](https://infomaniak.cloud/calculator?uuid=7826f3ad-7bc1-4ca9-8412-ed965b867ad5)

Setup
=====

Prepare
-------

If not yet done, install terraform using this doc: https://developer.hashicorp.com/terraform/install

Clone this repo

```shell
git clone https://github.com/reneluria/vm-node-tf-openstack.git
cd vm-node-tf-openstack
```

Create a public cloud project here: https://www.infomaniak.com/fr/hebergement/public-cloud
and source your credentials

Then:

```shell
terraform init
```

It will install terraform openstack provider

Create
------

```shell
terraform apply
```

after confirmation, it will create everything and provide you the necessary information to connect to the VM

```shell
Outputs:

curl-command = <<EOT
curl "http://[2001:1600:10:101::aaa]:8080"

EOT
instance_ip = "2001:1600:10:101::aaa"
ssh-command = <<EOT
ssh-keyscan 2001:1600:10:101::aaa >> ~/.ssh/known_hosts
SSH_AUTH_SOCK= ssh -i ./sshkey debian@2001:1600:10:101::aaa

EOT
```

Use the localy created `sshkey` private key to connect to the instance

```shell
❯ SSH_AUTH_SOCK= ssh -i ./sshkey debian@2001:1600:10:101::aaa
Linux demo-vm-node 6.1.0-17-cloud-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.69-1 (2023-12-30) x86_64
(...)
debian@demo-vm-node:~$ node -e "console.log('hello world')"
hello world
```

And of course, a simple node server installed:

```
> curl "http://[2001:1600:10:101::aaa]:8080"
Hello World
```

Cool, new VM, super cheap, with nodejs :aw_yeah:

Customization
-------------

You can create a variable file to override defaults:

```
# vm.tfvars
stack_name = my-vm
ports = [333, 555]
```

and apply

```shell
terraform apply -var-file vm.tfvars
```
