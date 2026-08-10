# Set Up Google OIDC

1. Access the [Google Cloud console](https://console.cloud.google.com/) and create or select a project
2. Go to Google Auth Platform -> Overview and select Get started if prompted
3. Go to Google Auth Platform -> Branding and configure the application
   - App name: WorkAdventure
   - User support email: <EMAIL_ADDRESS>
   - Contact Information: <EMAIL_ADDRESS>
4. Go to Google Auth Platform -> Audience
   - User type: Internal when the project belongs to a Google Cloud Organization; otherwise External
   - Add test users when using External in testing mode
5. Go to Google Auth Platform -> Clients -> Create client
   - Application type: Web application
   - Name: WorkAdventure
   - Authorized redirect URIs
     - Redirect URI: `https://<YOUR_FQDN>/openid-callback`
     - Redirect URI: `https://matrix.<YOUR_FQDN>/_synapse/client/oidc/callback`
6. Create the client, then copy the Client ID and Client Secret immediately and store them securely

Add the following values to `.env` during initial setup. For an existing server, follow the **Update Configuration** section in the main README.

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
DISABLE_ANONYMOUS=true
```
