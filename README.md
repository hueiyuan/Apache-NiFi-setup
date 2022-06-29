# Apache-NiFi-setup 
The repo which include all setup script, image and docker-compose for nifi and nifi registry.

## Folder Structure
```
|-- docker-container/
|-- packer_ami/
|-- templates/
```

1. `docker-container/` folder: include docker-compose.yaml which build up nifi and nifi registry container. 
2. `packer_ami/` folder: include nifi and nifi registry custom image. ex. openid, ssl and security settings. You can build up AWS AMI or Docker Image, juse change packer plugins.
3. `templates/` folder: include my custom processor group module for reuse.

