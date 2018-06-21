#!/bin/bash

set -eu

# prepare data directory
mkdir -p /app/data/uploads /tmp/hackmd /run/hackmd

if [ ! -e /app/data/config.json ]; then
    echo "Creating initial template on first run"
	cp /app/code/config.json-cloudron /app/data/config.json
fi

# generate and store an unique sessionSecret for this installation
CONFIG_JSON=/app/data/config.json
if [ $(jq .production.sessionSecret $CONFIG_JSON) == "null" ]; then
    echo "generating sessionSecret"
    sessionsecret=$(pwgen -1sc 32)
    jq ".production.sessionSecret = \"$sessionsecret\"" $CONFIG_JSON | sponge $CONFIG_JSON
fi

# these cannot be changed by user (https://github.com/hackmdio/hackmd/wiki/Environment-Variables)
export HMD_DOMAIN="$APP_DOMAIN"
export HMD_DB_URL="$POSTGRESQL_URL"
export HMD_LDAP_URL="$LDAP_URL"
export HMD_LDAP_BINDDN="$LDAP_BIND_DN"
export HMD_LDAP_BINDCREDENTIALS="$LDAP_BIND_PASSWORD"
export HMD_LDAP_SEARCHBASE="$LDAP_USERS_BASE_DN"
export HMD_LDAP_SEARCHFILTER="(username={{username}})"
export HMD_LDAP_USERNAMEFIELD="username"
export HMD_PORT=3000
export HMD_IMAGE_UPLOAD_TYPE=filesystem
export HMD_TMP_PATH=/tmp/hackmd

if [ -f .sequelizerc ]; then
	node_modules/.bin/sequelize db:migrate
fi

chown -R cloudron:cloudron /app/data /tmp/hackmd /run/hackmd

# run
export NODE_ENV=production
exec /usr/local/bin/gosu cloudron:cloudron node app.js

