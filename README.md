<div align="right">

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Arata1202/WorkAdventure/upload-wa-maps.yml)
![GitHub License](https://img.shields.io/github/license/Arata1202/WorkAdventure)

</div>

## Getting Started

This guide deploys the complete WorkAdventure stack to either AWS EC2 or an Azure VM using Terraform. Follow only the instructions for your selected cloud provider.

### Prerequisites

- Git, Make, Node.js 20, npm, and Terraform
- AWS: AWS CLI and the Session Manager plugin
- Azure: Azure CLI and OpenSSH
- A domain whose DNS records you can configure

### Set Up Local Repository

```bash
# Local

# Clone repository
git clone https://github.com/Arata1202/WorkAdventure.git
cd WorkAdventure

# Install dependencies
make wa-init
```

### Create Resources with Terraform

Choose one cloud provider and run its commands from the repository root.

#### AWS

```bash
# Local

# Configure AWS credentials and region
aws configure

# Move to the AWS Terraform directory
cd terraform/aws

# Prepare local values
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your preferred editor.

#### Azure

If you do not already have a dedicated SSH key for this VM, create one first:

```bash
# Local

# Generate an SSH key pair
ssh-keygen -t ed25519 -C "workadventure" -f ~/.ssh/workadventure -N ""
```

Then authenticate with Azure and prepare the Terraform values:

```bash
# Local

# Authenticate with Azure
az login

# Move to the Azure Terraform directory
cd terraform/azure

# Prepare local values
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your preferred editor and set `ssh_public_key` to the contents of `~/.ssh/workadventure.pub`.

#### Apply

After preparing either the AWS or Azure values:

```bash
# Local

# Create resources
terraform init
terraform plan
terraform apply
```

### Connect to AWS EC2 with SSM

Use this section for AWS. The Terraform configuration uses AWS Systems Manager Session Manager instead of SSH.

```bash
# Local

# Connect to AWS EC2 via SSM
aws ssm start-session --target <EC2_INSTANCE_ID>

# Switch to ubuntu user
sudo -iu ubuntu
```

### Connect to Azure VM with SSH

Use this section for Azure. Add the following host alias to `~/.ssh/config`:

```sshconfig
Host workadventure
  HostName <VM_PUBLIC_IPV4_ADDRESS>
  User ubuntu
  IdentityFile ~/.ssh/workadventure
```

```bash
# Local

# Connect to VM via SSH
ssh workadventure
```

### Set Up WorkAdventure Server

- [Self-hosting WorkAdventure using Docker Compose](https://github.com/workadventure/workadventure/blob/v1.33.0/contrib/docker/README.md)
- [WorkAdventure releases](https://github.com/workadventure/workadventure/releases)

```bash
# VM

# Clone repository
git clone https://github.com/Arata1202/WorkAdventure.git

# Move to repository
cd WorkAdventure

# Set up Ubuntu
./ubuntu/setup.sh

# Install repository tools and map dependencies
make wa-init

# Remove existing .env file
rm -f .env

# Prepare .env file
cp .env.example .env
```

### Configure Basic Settings

- Generate a separate value for every secret. Run the matching command again as needed and do not reuse values.

```bash
# VM

# Generate random strings for .env values
openssl rand -hex 16
openssl rand -hex 32
```

```env
# Required
SECRET_KEY=<UNIQUE_RANDOM_64_HEX>
DOMAIN=<YOUR_FQDN>
START_ROOM_URL=/~/maps/office.wam
TZ=Asia/Tokyo
ACME_EMAIL=<EMAIL_ADDRESS>
MAP_STORAGE_ENABLE_BEARER_AUTHENTICATION=true
MAP_STORAGE_ENABLE_BASIC_AUTHENTICATION=true
MAP_STORAGE_AUTHENTICATION_TOKEN=<UNIQUE_RANDOM_64_HEX>
MAP_STORAGE_AUTHENTICATION_USER=admin
MAP_STORAGE_AUTHENTICATION_PASSWORD=<UNIQUE_RANDOM_32_HEX>

# Optional
ENABLE_TELEMETRY=true
SECURITY_EMAIL=<EMAIL_ADDRESS>
FEATURE_FLAG_BROADCAST_AREAS=true
```

1. Add an A record in your DNS provider to point your domain to the VM public IP

| Record Name | Type | Value                    | TTL |
| ----------- | ---- | ------------------------ | --- |
| <YOUR_FQDN> | A    | <VM_PUBLIC_IPV4_ADDRESS> | 300 |

### Configure OIDC

Configure one OIDC provider. To use Google, see [Set Up Google OIDC](docs/google-oidc.md).

#### Microsoft Entra ID

1. Access the [Microsoft Entra admin center](https://entra.microsoft.com/)
2. Go to Entra ID -> App registrations -> New registration
3. Register the application
   - Name: WorkAdventure
   - Supported account types: Accounts in this organizational directory only (Single tenant)
   - Platform: Web
   - Redirect URI: `https://<YOUR_FQDN>/openid-callback`
4. Go to Manage -> Authentication, add another URI to the existing Web platform, and save it
   - Redirect URI: `https://matrix.<YOUR_FQDN>/_synapse/client/oidc/callback`
5. Go to Manage -> Certificates & secrets -> Client secrets -> New client secret
6. Copy the client secret Value immediately and store it securely
7. Go to Manage -> Token configuration -> Add optional claim and add the `email` claim
   - Token type: ID
   - Claim: `email`
   - Keep `Turn on the Microsoft Graph email permission` enabled
8. Save the following values from the application Overview page
   - Application (client) ID
   - Directory (tenant) ID

```env
# Required
OPENID_IDP_ID=microsoft
OPENID_IDP_NAME=Microsoft
OPENID_CLIENT_ID=<APPLICATION_CLIENT_ID>
OPENID_CLIENT_SECRET=<CLIENT_SECRET_VALUE>
OPENID_CLIENT_ISSUER=https://login.microsoftonline.com/<DIRECTORY_TENANT_ID>/v2.0
OPENID_LOGOUT_REDIRECT_URL=https://<YOUR_FQDN>
OPENID_USERNAME_CLAIM=preferred_username
OPENID_SCOPE=openid email profile
DISABLE_ANONYMOUS=true
```

### Configure LiveKit

```bash
# VM

# Generate random strings for .env values
openssl rand -hex 32
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

### Configure Coturn

```bash
# VM

# Generate random strings for .env values
openssl rand -hex 32
```

```env
# Required
TURN_SERVER=turn:<YOUR_FQDN>:3478,turns:<YOUR_FQDN>:5349
TURN_STATIC_AUTH_SECRET=<UNIQUE_RANDOM_64_HEX>
STUN_SERVER=stun:stun.l.google.com:19302
```

### Configure Matrix

```bash
# VM

# Generate random strings for .env values
openssl rand -hex 16
openssl rand -hex 32
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

### Configure Egress with RustFS

```bash
# VM

# Generate random strings for .env values
openssl rand -hex 32
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

### Start WorkAdventure Server

Edit `.env` with your preferred editor and configure all required values listed above.

Before starting, confirm that every DNS record listed above resolves to the VM public IP so Traefik can obtain the TLS certificates.

```bash
# VM

# Encrypt .env file
make encrypt

# Prepare Synapse data volume
npx dotenvx run -- docker compose run --rm --user root --entrypoint sh synapse -lc 'chown -R 991:991 /data'

# Start all services
make up
```

Back up `.env.keys` securely after the first encryption. It is required to decrypt `.env` and must never be committed.

### Upload a Map Edited with Tiled

- [Upload maps to WorkAdventure Map Storage](https://docs.workadventu.re/map-building/tiled-editor/publish/wa-hosted)

```bash
# Local

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

1. Access the uploaded map: `https://<YOUR_FQDN>`

### Create and Log In as the Matrix Admin User

```bash
# VM

# Move to repository
cd ~/WorkAdventure

# Create a Matrix Admin User
npx dotenvx run -- sh -lc 'docker compose exec synapse register_new_matrix_user -c /data/homeserver.yaml -u "$MATRIX_ADMIN_USER" -p "$MATRIX_ADMIN_PASSWORD" --admin http://localhost:8008'
```

1. Access Element Web: `https://app.element.io`
2. Click Sign in
3. Click Edit and enter your Matrix homeserver URL: `https://matrix.<YOUR_FQDN>`
4. Click Continue
5. Enter your Matrix credentials:
   - Username: admin
   - Password: <MATRIX_ADMIN_PASSWORD>
6. Click Sign in

### Log in to RustFS

1. Access RustFS Console: `https://rustfs-livekit.<YOUR_FQDN>`
2. Enter your RustFS credentials:
   - Username: <LIVEKIT_RECORDING_S3_ACCESS_KEY>
   - Password: <LIVEKIT_RECORDING_S3_SECRET_KEY>
3. Click Sign in
4. After successful authentication, you will be logged in

### Set Up GitHub Actions

Go to the repository's Settings -> Secrets and variables -> Actions -> Secrets, then add the following repository secrets.

#### Upload Maps

Configure these secrets for `upload-wa-maps.yml`:

```env
# Required
UPLOAD_MODE=MAP_STORAGE
MAP_STORAGE_URL=https://<YOUR_FQDN>/map-storage/
MAP_STORAGE_API_KEY=<MAP_STORAGE_AUTHENTICATION_TOKEN>
UPLOAD_DIRECTORY=maps
```

Run the `Upload WA maps` workflow manually whenever you want to publish map changes.

#### Deploy

Configure these secrets for `deploy.yml`:

> [!NOTE]
> The `deploy.yml` workflow requires direct SSH access and is not compatible with the default AWS SSM setup.

```env
# Required
SSH_HOST=<VM_PUBLIC_IPV4_ADDRESS>
SSH_USERNAME=ubuntu
SSH_PRIVATE_KEY=<SSH_PRIVATE_KEY>
```

Run the `deploy` workflow manually to pull repository changes and recreate the services on the VM.

### Update Configuration

```bash
# VM

# Move to repository
cd ~/WorkAdventure

# Decrypt .env file
make decrypt
```

Edit `.env` with your preferred editor.

```bash
# VM

# Encrypt .env file
make encrypt

# Restart services
make up-f
```
