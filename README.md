# Apache-NiFi-setup 
The repo which include all setup script, image and docker-compose for nifi and nifi registry.

## Folder Structure
```
|-- docker-container/
|-- packer_ami/
|-- templates/
```

i. `docker-container/` folder: include docker-compose.yaml which build up nifi and nifi registry container. 
ii. `packer_ami/` folder: include nifi and nifi registry custom image. ex. openid, ssl and security settings. You can build up AWS AMI or Docker Image, juse change packer plugins.
ii. `templates/` folder: include my custom processor group module for reuse.

