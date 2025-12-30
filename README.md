<div align="right">

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Arata1202/WorkAdventure/build-and-deploy.yml)
![GitHub License](https://img.shields.io/github/license/Arata1202/WorkAdventure)

</div>

## Getting Started

### Create Resources on AWS with Terraform

```bash
# Local

# Clone repository
git clone git@github.com:Arata1202/WorkAdventure.git
cd WorkAdventure/terraform

# Prepare and edit variables file
cp variables.tf.example variables.tf
vi variables.tf

# Create resources
terraform init
terraform plan
terraform apply
```

### Set Up WorkAdventure Server

[Self-hosting WorkAdventure using Docker Compose](https://github.com/workadventure/workadventure/blob/develop/contrib/docker/README.md)

```bash
# EC2

# Clone repository
git clone git@github.com:Arata1202/WorkAdventure.git
cd WorkAdventure

# Set up Ubuntu
./ubuntu/setup.sh

# Install dependencies
npm install

# Remove existing .env file
rm -f .env

# Generate random strings for .env values
openssl rand -base64 16
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
SECRET_KEY=<RANDOM_32_STRING>
DOMAIN=<YOUR_FQDN>
VERSION=v1.27.10
MAP_STORAGE_AUTHENTICATION_TOKEN=<RANDOM_32_STRING>
MAP_STORAGE_AUTHENTICATION_USER=admin
MAP_STORAGE_AUTHENTICATION_PASSWORD=<RANDOM_16_STRING>
```

1. Add an A record in Route 53 to point your domain to the EC2 public IP

| Record Name | Type | Value                     | TTL |
| ----------- | ---- | ------------------------- | --- |
| <YOUR_FQDN> | A    | <EC2_PUBLIC_IPV4_ADDRESS> | 300 |

### Edit .env file for basic settings

```bash
# EC2

# Move repository
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
YOUTUBE_ENABLED=false
GOOGLE_DRIVE_ENABLED=false
GOOGLE_DOCS_ENABLED=false
GOOGLE_SHEETS_ENABLED=false
GOOGLE_SLIDES_ENABLED=false
ERASER_ENABLED=false
EXCALIDRAW_ENABLED=false
CARDS_ENABLED=false
TLDRAW_ENABLED=false
```

### Upload a Map Edited with Tiled

[Upload your Map to WorkAdventure](https://docs.workadventu.re/map-building/tiled-editor/publish/wa-hosted/)

```bash
# EC2

# Move repository
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
MAP_STORAGE_ENABLE_BEARER_AUTHENTICATION=true
```

[map-starter-kit](https://github.com/workadventure/map-starter-kit)

```bash
# Local

# Move repository
cd WorkAdventure/map-starter-kit-master

# Prepare .env file
cp .env.example .env

# Install dependencies
npm install

# Preview the map locally
npm run dev

# Edit the map file (office.tmj) using Tiled

# Upload the map
npm run upload

Please enter your Map storage URL: https://<YOUR_FQDN>/map-storage/
Please enter your API Key: <MAP_STORAGE_AUTHENTICATION_TOKEN>
Upload directory: maps
```

```bash
# EC2

# Move repository
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
   - Authorized redirect URIs: `https://<YOUR_FQDN>//openid-callback`
6. Save the Client ID and Client Secret

```bash
# EC2

# Move repository
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
# EC2

# Move repository
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
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=<RANDOM_32_STRING>

# Optional
MAX_PER_GROUP=<NUMBER>
MAX_USERS_FOR_WEBRTC=<NUMBER>
```

1. Add an A record in Route 53 to point your domain to the EC2 public IP

| Record Name         | Type | Value                     | TTL |
| ------------------- | ---- | ------------------------- | --- |
| livekit.<YOUR_FQDN> | A    | <EC2_PUBLIC_IPV4_ADDRESS> | 300 |

### Set Up Coturn

```bash
# EC2

# Move repository
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
TURN_STATIC_AUTH_SECRET=<RANDOM_32_STRING>
STUN_SERVER=stun:stun.l.google.com:19302
```

### Set Up Matrix

1. Add the following redirect URI to the existing Google OAuth client used by WorkAdventure (LiveKit configuration).
   - `https://matrix.<YOUR_FQDN>/_synapse/client/oidc/callback`

```bash
# EC2

# Move repository
cd WorkAdventure

# Generate random strings for .env values
openssl rand -base64 16
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
MATRIX_API_URI=http://synapse:8008/
MATRIX_PUBLIC_URI=https://matrix.<YOUR_FQDN>
MATRIX_ADMIN_USER=admin
MATRIX_ADMIN_PASSWORD=<RANDOM_16_STRING>
MATRIX_REGISTRATION_SHARED_SECRET=<RANDOM_32_STRING>
MATRIX_MACAROON_SECRET_KEY=<RANDOM_32_STRING>
MATRIX_FORM_SECRET=<RANDOM_32_STRING>
```

1. Add an A record in Route 53 to point your domain to the EC2 public IP

| Record Name        | Type | Value                     | TTL |
| ------------------ | ---- | ------------------------- | --- |
| matrix.<YOUR_FQDN> | A    | <EC2_PUBLIC_IPV4_ADDRESS> | 300 |
