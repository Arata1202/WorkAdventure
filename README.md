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

# Generate random strings for .env values
openssl rand -base64 16

# Prepare and edit .env file
cp .env.example .env
vi .env

# Set up Ubuntu
./ubuntu/setup.sh

# Start server
make up
```

```env
SECRET_KEY=<RANDOM_STRING>
DOMAIN=<YOUR_FQDN>
VERSION=v1.27.10
MAP_STORAGE_AUTHENTICATION_TOKEN=<RANDOM_STRING>
MAP_STORAGE_AUTHENTICATION_USER=admin
MAP_STORAGE_AUTHENTICATION_PASSWORD=<RANDOM_STRING>
```

1. Add an A record in Route 53 to point your domain to the EC2 public IP

| Record Name | Type | Value                    | TTL |
| ----------- | ---- | ------------------------ | --- |
| <YOUR_FQDN> | A    | <YOUR_PUBLIC_IP_ADDRESS> | 60  |

### Upload a Map Edited with Tiled (Local)

[Upload your Map to WorkAdventure](https://docs.workadventu.re/map-building/tiled-editor/publish/wa-hosted/)

```bash
# Move repository
cd WorkAdventure

# Edit .env file
vi .env
```

```env
MAP_STORAGE_ENABLE_BEARER_AUTHENTICATION=true
```

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

# Upload the map
npm run build
npm run upload

Please enter your Map storage URL: https://<YOUR_FQDN>/map-storage/
Please enter your API Key: <MAP_STORAGE_AUTHENTICATION_TOKEN>
Upload directory: maps
```

```bash
# Move repository
cd WorkAdventure

# Edit .env file
vi .env
```

```env
START_ROOM_URL=/~/maps/map/office.wam
```

1. Access the uploaded map
   `https://<YOUR_FQDN>`

### Set Up LiveKit (EC2)

```bash
# Move repository
cd WorkAdventure

# Generate random strings for LiveKit API secret
openssl rand -hex 32

# Edit LiveKit configuration
vi livekit-config.yaml

# Edit .env file
vi .env

# Start server
make up
```

```
# livekit-config.yaml
# --------------------------------------------------
# LiveKit API key and secret
# Replace these values with your own.
# DO NOT use these example values in production.
# --------------------------------------------------

keys:
  devkey: 12345678901234567890123456789012
```

```env
LIVEKIT_HOST=https://livekit.<YOUR_FQDN>
LIVEKIT_API_KEY=<LIVEKIT_API_KEY>
LIVEKIT_API_SECRET=<LIVEKIT_API_SECRET>
```

1. Add an A record in Route 53 to point your domain to the EC2 public IP

| Record Name         | Type | Value                    | TTL |
| ------------------- | ---- | ------------------------ | --- |
| livekit.<YOUR_FQDN> | A    | <YOUR_PUBLIC_IP_ADDRESS> | 60  |
