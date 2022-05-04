# Packer usage for build AMI

## Install Pakcer on your localhose
* Homebrew on OS X
```
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```
Ref: [Related installation on other system](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli?in=packer/docker-get-started)

## How to build AMI?
1. Need to create folder by service.
2. The Folder structure follow as :
```
|-- {service_name}/
    |-- {service_name}.pkr.hcl
    |-- {service_name}_secret.pkrvars.hcl       ## for secret or credential variables file, which can be replaced vault with in the future
    |-- {service_name}.pkrvars.hcl              ## for variables file
    |-- {service_name}.service                  ## for systemd deamon
    |-- init.sh                                 ## It is used to init and install packages.
```
ps. You need replace aws acceess key id, secret key and ssh key pem by yourself.

3. Init packer hashicorp.
```
cd {service_name} && packer init .
```

4. Replace `{service_name}.pkrvars.hcl` and  `{service_name}_secret.pkrvars.hcl` value.<br/>
In order to manage config and related key, we need to replace related setting value in `{service_name}_secret.pkrvars.hcl`.<br/>
ps. About credentials, secret key or sensitive value, we can use vault service to solve in the future.

5. Validate packer hashicorp. (Remember to use `--var-file`)
```
cd {service_name} && packer validate -var-file="{service_name}.pkrvars.hcl" -var-file="{service_name}_secret.pkrvars.hcl" {service_name}.pkr.hcl
```

6. If validated status is success. you can build related AMI. (Remember to use `--var-file`)
```
cd {service_name} && packer build -var-file="{service_name}.pkrvars.hcl" -var-file="{service_name}_secret.pkrvars.hcl" {service_name}.pkr.hcl
```
