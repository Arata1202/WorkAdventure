<div align="right">

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Arata1202/WorkAdventure/upload-wa-maps.yml)
![GitHub License](https://img.shields.io/github/license/Arata1202/WorkAdventure)

</div>

## Getting Started

- This guide supports both AWS EC2 and Azure VM with Terraform.

### Prepare Repository

```bash
# Local and VM

# Clone repository
git clone https://github.com/Arata1202/WorkAdventure.git
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

# Prepare and edit local values
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars

# Create resources
terraform init
terraform plan
terraform apply
```

### Connect AWS EC2 with SSM

- Default for AWS is SSM.

```bash
# Local

# Configure AWS CLI credentials and region before connecting
aws configure

# Connect to AWS EC2 via SSM
aws ssm start-session --target <EC2_INSTANCE_ID>

# Switch to ubuntu user
sudo -iu ubuntu
```

### Configure SSH Access

- Default for Azure is SSH (Azure Bastion can be costly).

```bash
# Local

# Save the VM private key
vi ~/.ssh/workadventure_key.pem
chmod 600 ~/.ssh/workadventure_key.pem

# Configure SSH host aliases
vi ~/.ssh/config
```

```sshconfig
Host workadventure
  HostName <VM_PUBLIC_IPV4_ADDRESS>
  User ubuntu
  IdentityFile ~/.ssh/workadventure_key.pem
```

```bash
# Local

# Connect to VM via SSH
ssh workadventure
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

# Start services with the basic configuration.
# For production, prefer the recommended initial production setup in this section.
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

#### Recommended Initial Production Setup

- Use this flow for a new production server before the first start.
- Start from a clean `.env`, add all values from the sections you plan to use, then start the stack once.
- Run the Synapse commands only when Matrix is configured.

```bash
# VM

# Move to repository
cd WorkAdventure

# Prepare a clean .env file for initial setup
rm -f .env
cp .env.example .env

# Edit .env once with all values from the sections you plan to use
vi .env

# Encrypt .env file
make encrypt

# Prepare Synapse data volume when Matrix is enabled
npx dotenvx run -- docker compose run --rm --user root --entrypoint sh synapse -lc 'chown -R 991:991 /data'

# Start services with the completed .env
make up-f

# Create a Matrix Admin User when Matrix is enabled
npx dotenvx run -- sh -lc 'docker compose exec synapse register_new_matrix_user -c /data/homeserver.yaml -u "$MATRIX_ADMIN_USER" -p "$MATRIX_ADMIN_PASSWORD" --admin http://localhost:8008'
```

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
make up-f
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
cd WorkAdventure

# Prepare .env file
cp maps/.env.example maps/.env

# Preview the map locally
make wa-dev

# Edit the map file (maps/office.tmj) using Tiled

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
make up-f
```

```env
# Required
START_ROOM_URL=/~/maps/office.wam
MAP_STORAGE_ENABLE_BEARER_AUTHENTICATION=true
```

1. Access the uploaded map
   `https://<YOUR_FQDN>`

### Set Up GitHub Actions

1. Configure GitHub Actions secrets for `upload-wa-maps.yml`

```env
# Required
UPLOAD_MODE=MAP_STORAGE
MAP_STORAGE_URL=https://<YOUR_FQDN>/map-storage/
MAP_STORAGE_API_KEY=<MAP_STORAGE_AUTHENTICATION_TOKEN>
UPLOAD_DIRECTORY=maps
```

2. Configure GitHub Actions secrets for `deploy.yml`

```env
# Required
SSH_HOST=<VM_PUBLIC_IPV4_ADDRESS>
SSH_USERNAME=ubuntu
SSH_PRIVATE_KEY=<SSH_PRIVATE_KEY>
```

3. Run the `deploy` workflow manually from GitHub Actions to apply repository changes to the VM

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
make up-f
```

```env
# Required
OPENID_IDP_ID=google
OPENID_IDP_NAME=Google
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
make up-f
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
make up-f
```

```env
# Required
TURN_SERVER=turn:<YOUR_FQDN>:3478,turns:<YOUR_FQDN>:5349
TURN_STATIC_AUTH_SECRET=<UNIQUE_RANDOM_64_HEX>
STUN_SERVER=stun:stun.l.google.com:19302
```

### Set Up Matrix

1. Add the following redirect URI to the existing Google OAuth client used by WorkAdventure.
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

# Prepare Synapse data volume
npx dotenvx run -- docker compose run --rm --user root --entrypoint sh synapse -lc 'chown -R 991:991 /data'

# Restart server
make up-f

# Create a Matrix Admin User
npx dotenvx run -- sh -lc 'docker compose exec synapse register_new_matrix_user -c /data/homeserver.yaml -u "$MATRIX_ADMIN_USER" -p "$MATRIX_ADMIN_PASSWORD" --admin http://localhost:8008'
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

### Log in to Matrix using Element

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

### Set Up Egress with RustFS

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
make up-f
```

```env
# Required
LIVEKIT_RECORDING_S3_ENDPOINT=http://rustfs-livekit:9000
LIVEKIT_RECORDING_S3_CDN_ENDPOINT=https://cdn-livekit.<YOUR_FQDN>
LIVEKIT_RECORDING_S3_ACCESS_KEY=<UNIQUE_RANDOM_64_HEX>
LIVEKIT_RECORDING_S3_SECRET_KEY=<UNIQUE_RANDOM_64_HEX>
LIVEKIT_RECORDING_S3_BUCKET=livekit-recordings
LIVEKIT_RECORDING_S3_REGION=ap-northeast-1
MAX_USERS_FOR_WEBRTC=0
```

1. Add A records in your DNS provider to point your domain to the VM public IP

| Record Name                | Type | Value                    | TTL |
| -------------------------- | ---- | ------------------------ | --- |
| cdn-livekit.<YOUR_FQDN>    | A    | <VM_PUBLIC_IPV4_ADDRESS> | 300 |
| rustfs-livekit.<YOUR_FQDN> | A    | <VM_PUBLIC_IPV4_ADDRESS> | 300 |

### Log in to RustFS

1. Access RustFS Console: `https://rustfs-livekit.<YOUR_FQDN>`
2. Enter your RustFS credentials:
   - Username: <LIVEKIT_RECORDING_S3_ACCESS_KEY>
   - Password: <LIVEKIT_RECORDING_S3_SECRET_KEY>
3. Click Sign in
4. After successful authentication, you will be logged in
