# Setup App
 - This runs on Ruby 2.1.2, so make sure to install 2.1.2 version.
 - cd $APP and bundle install

# Run App
 - cd $APP
 - rackup config.ru
 
# Details
 1. Check config.yml.erb, you will need to set the keys in your bashrc or /etc/profile
  - QFLIGHTS_GOOGLE_CLIENT_ID
  - QFLIGHTS_GOOGLE_CLIENT_SECRET
  - QFLIGHTS_SESSION_SECRET
  - QFLIGHTS_API_KEY
 2. Go to https://console.developers.google.com and create your project
  - Enable QPX Express Airfare API, Google+ API atleast for your project 
  - Create an OAuth 2.0 Credentials (will provide you QFLIGHTS_GOOGLE_CLIENT_ID and QFLIGHTS_GOOGLE_CLIENT_SECRET Keys)
  - Create an Browser Key Credentials will provide you QFLIGHTS_API_KEY
  - QFLIGHTS_SESSION_SECRET can be any random string for security
 3. Under https://console.developers.google.com when you create OAuth 2.0 Credentials (for development purpose you can use these as below)
  - Mention http://localhost:3001 as Authorized JavaScript origins
  - Mention http://localhost:3001/auth/google_oauth2/callback as Authorized redirect URIs
 4. This Sinatra Rack App runs on port 3001, check config.ru. If you need to make change to port make sure the above points reflect that too

#Note
  Although QPX Express Airfare API supports OAuth 2.0 access token they haven't mentioned the scope that needs to be written for it, so currently I have tried with access token of OAuth 2.0 but it does not work for Flights Search so I used the other way of using their API by creating a Public API Key i.e Browser Key (QFLIGHTS_API_KEY). Once their documentation is clear about the scope to be provided for OAuth 2.0 access token way of doing it would suggest you to implement that instead of API Key
