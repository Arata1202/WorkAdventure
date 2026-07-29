# Set Up Google OIDC

The default Synapse configuration in this repository targets Microsoft Entra ID.
Use the following steps when configuring Google as the OpenID Connect provider.

1. Access Google Cloud Platform
2. Create a new project
3. Go to APIs & Services -> OAuth consent screen
   - App name: WorkAdventure
   - User support email: `<EMAIL_ADDRESS>`
   - User Type: External
   - Contact Information: `<EMAIL_ADDRESS>`
4. Go to APIs & Services -> Credentials
5. Create an OAuth client ID
   - Application type: Web application
   - Name: WorkAdventure
   - Authorized redirect URIs:
     - `https://<YOUR_FQDN>/openid-callback`
     - `https://matrix.<YOUR_FQDN>/_synapse/client/oidc/callback`
6. Save the Client ID and Client Secret

Configure the following values in `.env`:

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
OPENID_PROMPT=
DISABLE_ANONYMOUS=true
MAP_EDITOR_ALLOWED_USERS=<EMAIL_ADDRESS>
MAP_EDITOR_ALLOW_ALL_USERS=false
```

Google uses the `email` claim for the Matrix localpart. Before deploying with
Google, add `email` to the Synapse scopes in
`synapse/homeserver.template.yaml`:

```yaml
scopes: ["openid", "profile", "email"]
```

Apply the configuration:

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

After restarting, verify the login, Matrix chat, and Map Editor access with a
Google account.

For other providers and advanced settings, see the
[upstream WorkAdventure OpenID Connect documentation](https://github.com/workadventure/workadventure/blob/master/docs/others/self-hosting/openid.md).
