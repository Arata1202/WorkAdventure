<div align="right">

![GitHub License](https://img.shields.io/github/license/Arata1202/WorkAdventure)

</div>

## Getting Started

### Create Resources on AWS with Terraform（Local）

```bash
# Clone repository
git clone git@github.com:Arata1202/WorkAdventure.git
cd WorkAdventure/terraform

# Prepare and edit variables file
mv variables.example.tf variables.tf
vi variables.tf

# Create resources
terraform init
terraform plan
terraform apply
```

### Set Up WorkAdventure Server (EC2)

[Self-hosting WorkAdventure using Docker Compose](https://github.com/workadventure/workadventure/blob/develop/contrib/docker/README.md)

```bash
# Clone repository
git clone git@github.com:Arata1202/WorkAdventure.git
cd WorkAdventure

# Prepare and edit .env file
cp .env.example .env
vi .env

# Set up Ubuntu
./ubuntu/setup.sh

# Start server
make up
```
