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

### Upload a Map Edited with Tiled (Local)

[map-starter-kit](https://github.com/workadventure/map-starter-kit)

```bash
# Clone repository
git clone git@github.com:workadventure/map-starter-kit.git
cd map-starter-kit.git

# Edit the map file (office.tmj) using Tiled

# Install dependencies
npm install

# Preview the map locally
npm run dev

# Prepare files for upload
npm run build
mv dist map
zip -r map.zip map
```

1. Open the Map Storage
   `https://<YOUR_FQDN>/map-storage`
2. Upload the map
   - Select a file to upload: `map.zip`
   - Directory: /
3. Access the uploaded map
   `https://<YOUR_FQDN>/_/global/<YOUR_FQDN>/map-storage/map/office.tmj`
