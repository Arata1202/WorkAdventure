# Set Up Google OIDC

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
   - Authorized redirect URIs
     - Redirect URI: `https://<YOUR_FQDN>/openid-callback`
     - Redirect URI: `https://matrix.<YOUR_FQDN>/_synapse/client/oidc/callback`
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
```
