<div align="right">

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Arata1202/WorkAdventure/upload-wa-maps.yml)
![GitHub License](https://img.shields.io/github/license/Arata1202/WorkAdventure)

</div>

## Getting Started

- This guide supports both AWS EC2 and Azure VM with Terraform.

### Notes

- Ensure that meeting room names and user display names are unique.

### Prepare Repository

```bash
# Local and VM

# Clone repository
git clone git@github.com:Arata1202/WorkAdventure.git
cd WorkAdventure

# Install dependencies
make wa-init
```

### Create Resources with Terraform

```bash
# Local

# Move to repository
cd WorkAdventure
cd terraform/aws # or terraform/azure

# Prepare and edit variables file
cp variables.tf.example variables.tf
vi variables.tf

# Create resources
terraform init
terraform plan
terraform apply
```

### Connect AWS EC2 with SSM

- Default for AWS is SSM.
- Default for Azure is SSH (Azure Bastion can be costly).

```bash
# Local

# Move to repository
cd WorkAdventure

# Prepare and edit .envrc file
cp .envrc.example .envrc
vi .envrc

# Allow direnv to load variables
direnv allow .

# Connect to AWS EC2 via SSM
make ssm

# Switch to ubuntu user and move to repository
sudo -iu ubuntu
cd ~/WorkAdventure
```

```env
# Required
export EC2_INSTANCE_ID=<EC2_INSTANCE_ID>
```

### Configure SSH Access

- Default for AWS is SSM.
- Default for Azure is SSH (Azure Bastion can be costly).

```bash
# Local

# Move to repository
cd WorkAdventure

# Prepare and edit .envrc file
cp .envrc.example .envrc
vi .envrc

# Allow direnv to load variables
direnv allow .

# Connect to VM via SSH
make ssh P=aws # or P=azure

# Sync Repository to VM
make rsync P=aws # or P=azure
```

```env
# Required
export EC2_SSH_KEY_PATH=<EC2_SSH_KEY_PATH>
export EC2_PUBLIC_IPV4_ADDRESS=<EC2_PUBLIC_IPV4_ADDRESS>

# or

export ARM_SUBSCRIPTION_ID=<AZURE_SUBSCRIPTION_ID>
export AZURE_SSH_KEY_PATH=<AZURE_SSH_KEY_PATH>
export AZURE_PUBLIC_IPV4_ADDRESS=<AZURE_PUBLIC_IPV4_ADDRESS>
```

### Set Up WorkAdventure Server

- https://github.com/workadventure/workadventure/blob/develop/contrib/docker/README.md
- https://github.com/workadventure/workadventure/releases

```bash
# VM

# Set up Ubuntu
./ubuntu/setup.sh

# Move to repository
cd WorkAdventure

# Remove existing .env file
rm -f .env

# Generate random strings for .env values
openssl rand -hex 16
openssl rand -hex 32

# Prepare and edit .env file
cp .env.example .env
vi .env

# Encrypt .env file
make encrypt

# Start server
make up
```

```env
# Required
SECRET_KEY=<UNIQUE_RANDOM_64_HEX>
DOMAIN=<YOUR_FQDN>
MAP_STORAGE_AUTHENTICATION_TOKEN=<UNIQUE_RANDOM_64_HEX>
MAP_STORAGE_AUTHENTICATION_USER=admin
MAP_STORAGE_AUTHENTICATION_PASSWORD=<UNIQUE_RANDOM_32_HEX>
```

1. Add an A record in your DNS provider to point your domain to the VM public IP

| Record Name | Type | Value                    | TTL |
| ----------- | ---- | ------------------------ | --- |
| <YOUR_FQDN> | A    | <VM_PUBLIC_IPV4_ADDRESS> | 300 |

### Edit .env file for basic settings

```bash
# VM

# Move to repository
cd WorkAdventure

# Edit .env file
make decrypt
vi .env
make encrypt

# Restart server
make restart
```

```env
# Required
TZ=Asia/Tokyo

# Optional
ACME_EMAIL=<EMAIL_ADDRESS>
ENABLE_TELEMETRY=true
SECURITY_EMAIL=<EMAIL_ADDRESS>
FEATURE_FLAG_BROADCAST_AREAS=true
```

### Upload a Map Edited with Tiled

- https://docs.workadventu.re/map-building/tiled-editor/publish/wa-hosted

```bash
# Local

# Move to repository
cd WorkAdventure/maps

# Prepare .env file
cp .env.example .env

# Preview the map locally
make wa-dev

# Edit the map file (office.tmj) using Tiled

# Upload the map
make wa-upload

Please enter your Map storage URL: https://<YOUR_FQDN>/map-storage/
Please enter your API Key: <MAP_STORAGE_AUTHENTICATION_TOKEN>
Upload directory: maps
```

```bash
# VM

# Move to repository
cd WorkAdventure

# Edit .env file
make decrypt
vi .env
make encrypt

# Restart server
make restart
```

```env
# Required
START_ROOM_URL=/~/maps/office.wam
MAP_STORAGE_ENABLE_BEARER_AUTHENTICATION=true
```

1. Access the uploaded map
   `https://<YOUR_FQDN>`

### Set Up GitHub Actions

1. Configure GitHub Actions secrets

```env
# Required
UPLOAD_MODE=MAP_STORAGE
MAP_STORAGE_URL=https://<YOUR_FQDN>/map-storage/
MAP_STORAGE_API_KEY=<MAP_STORAGE_AUTHENTICATION_TOKEN>
UPLOAD_DIRECTORY=maps
```

### Set Up Google OIDC

1. Access Google Cloud Platform
2. Create a new project
3. Go to APIs & Services -> OAuth consent screen
   - App name: WorkAdventure
   - User support email: <EMAIL_ADDRESS>
   - User Type: External
   - Contact Information: <EMAIL_ADDRESS>
4. Go to APIs & Services -> Credentials
5. Create OAuth client ID
   - Application type: Web application
   - Name: WorkAdventure
   - Authorized redirect URIs: `https://<YOUR_FQDN>/openid-callback`
6. Save the Client ID and Client Secret

```bash
# VM

# Move to repository
cd WorkAdventure

# Edit .env file
make decrypt
vi .env
make encrypt

# Restart server
make restart
```

```env
# Required
OPENID_CLIENT_ID=<GOOGLE_CLIENT_ID>
OPENID_CLIENT_SECRET=<GOOGLE_CLIENT_SECRET>
OPENID_CLIENT_ISSUER=https://accounts.google.com
OPENID_LOGOUT_REDIRECT_URL=https://<YOUR_FQDN>
OPENID_USERNAME_CLAIM=email
OPENID_SCOPE=openid email profile

# Optional
DISABLE_ANONYMOUS=true
MAP_EDITOR_ALLOWED_USERS=<EMAIL_ADDRESS>
MAP_EDITOR_ALLOW_ALL_USERS=false
```

### Set Up LiveKit

```bash
# VM

# Move to repository
cd WorkAdventure

# Generate random strings for .env values
openssl rand -hex 32

# Edit .env file
make decrypt
vi .env
make encrypt

# Restart server
make restart
```

```env
# Required
LIVEKIT_HOST=https://livekit.<YOUR_FQDN>
LIVEKIT_API_KEY=<UNIQUE_RANDOM_64_HEX>
LIVEKIT_API_SECRET=<UNIQUE_RANDOM_64_HEX>

# Optional
MAX_PER_GROUP=<NUMBER>
```

1. Add an A record in your DNS provider to point your domain to the VM public IP

| Record Name         | Type | Value                    | TTL |
| ------------------- | ---- | ------------------------ | --- |
| livekit.<YOUR_FQDN> | A    | <VM_PUBLIC_IPV4_ADDRESS> | 300 |

### Set Up Coturn

```bash
# VM

# Move to repository
cd WorkAdventure

# Generate random strings for .env values
openssl rand -hex 32

# Edit .env file
make decrypt
vi .env
make encrypt

# Restart server
make restart
```

```env
# Required
TURN_SERVER=turn:<YOUR_FQDN>:3478,turns:<YOUR_FQDN>:5349
TURN_STATIC_AUTH_SECRET=<UNIQUE_RANDOM_64_HEX>
STUN_SERVER=stun:stun.l.google.com:19302
```

### Set Up Matrix

1. Add the following redirect URI to the existing Google OAuth client used by WorkAdventure (LiveKit configuration).
   - `https://matrix.<YOUR_FQDN>/_synapse/client/oidc/callback`

```bash
# VM

# Move to repository
cd WorkAdventure

# Generate random strings for .env values
openssl rand -hex 16
openssl rand -hex 32

# Edit .env file
make decrypt
vi .env
make encrypt

# Generate Synapse configuration files
npx dotenvx run -- docker compose run --rm synapse generate

# Create a Matrix Admin User
npx dotenvx run -- docker compose exec synapse register_new_matrix_user -c /data/homeserver.yaml -u "$MATRIX_ADMIN_USER" -p "$MATRIX_ADMIN_PASSWORD" --admin http://localhost:8008

# Restart server
make restart
```

```env
# Required
MATRIX_API_URI=http://synapse:8008/
MATRIX_DOMAIN=matrix.<YOUR_FQDN>
MATRIX_PUBLIC_URI=https://matrix.<YOUR_FQDN>
MATRIX_ADMIN_USER=admin
MATRIX_ADMIN_PASSWORD=<UNIQUE_RANDOM_32_HEX>
MATRIX_REGISTRATION_SHARED_SECRET=<UNIQUE_RANDOM_64_HEX>
MATRIX_MACAROON_SECRET_KEY=<UNIQUE_RANDOM_64_HEX>
MATRIX_FORM_SECRET=<UNIQUE_RANDOM_64_HEX>
POSTGRES_DB=synapse
POSTGRES_USER=admin
POSTGRES_PASSWORD=<UNIQUE_RANDOM_32_HEX>
```

1. Add an A record in your DNS provider to point your domain to the VM public IP

| Record Name        | Type | Value                    | TTL |
| ------------------ | ---- | ------------------------ | --- |
| matrix.<YOUR_FQDN> | A    | <VM_PUBLIC_IPV4_ADDRESS> | 300 |

## Log in to Matrix using Element

1. Access Element Web: `https://element.io`
2. Click Sign in -> Open Element web
3. Click Sign in
4. Enter your Matrix homeserver URL: `https://matrix.<YOUR_FQDN>`
5. Click Continue
6. Enter your Matrix credentials:
   - Username: admin
   - Password: <MATRIX_ADMIN_PASSWORD>
7. Click Sign in
8. After successful authentication, you will be redirected back to Element and logged in

## Set up Egress with MinIO

```bash
# VM

# Move to repository
cd WorkAdventure

# Generate random strings for .env values
openssl rand -hex 32

# Edit .env file
make decrypt
vi .env
make encrypt

# Restart server
make restart
```

```env
# Required
RECORDING_MEETING_ROOMS=<RECORDING_MEETING_ROOMS>
MINIO_REGION=ap-northeast-1
MINIO_ACCESS_KEY=<UNIQUE_RANDOM_64_HEX>
MINIO_SECRET_KEY=<UNIQUE_RANDOM_64_HEX>
MINIO_BUCKET=livekit-recording
MAX_USERS_FOR_WEBRTC=0
```

1. Add A records in your DNS provider to point your domain to the VM public IP

| Record Name               | Type | Value                    | TTL |
| ------------------------- | ---- | ------------------------ | --- |
| cdn-livekit.<YOUR_FQDN>   | A    | <VM_PUBLIC_IPV4_ADDRESS> | 300 |
| minio-livekit.<YOUR_FQDN> | A    | <VM_PUBLIC_IPV4_ADDRESS> | 300 |

## Log in to MinIO

1. Access MinIO Web: `https://minio-livekit.<YOUR_FQDN>`
2. Enter your MinIO credentials:
   - Username: <MINIO_ACCESS_KEY>
   - Password: <MINIO_SECRET_KEY>
3. Click Sign in
4. After successful authentication, you will be logged in
