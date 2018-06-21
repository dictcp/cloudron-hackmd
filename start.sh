#!/bin/bash

set -eu

# prepare data directory
mkdir -p /app/data/uploads /tmp/hackmd /run/hackmd
chown -R cloudron:cloudron /app/data /tmp/hackmd /run/hackmd

if [ ! -e /app/data/config.json ]; then
	cp /app/code/config.json-cloudron /app/data/config.json
fi

if [ -f .sequelizerc ]; then
	node_modules/.bin/sequelize db:migrate
fi

# generate and store an unique sessionSecret for this installation
CONFIG_JSON=/app/data/config.json
if [ $(jq .sessionSecret $CONFIG_JSON) == "null" ]; then
        echo "generating sessionSecret"
        sessionsecret=$(pwgen -1sc 32)
        jq ".sessionSecret = \"$sessionsecret\"" $CONFIG_JSON | sponge $CONFIG_JSON
fi

export NODE_ENV='production'
export HMD_ALLOW_ANONYMOUS="false"
export HMD_DB_URL="$POSTGRESQL_URL"
export HMD_LDAP_URL="$LDAP_URL"
export HMD_LDAP_BINDDN="$LDAP_BIND_DN"
export HMD_LDAP_BINDCREDENTIALS="$LDAP_BIND_PASSWORD"
export HMD_LDAP_SEARCHBASE="$LDAP_USERS_BASE_DN"
export HMD_LDAP_SEARCHFILTER="(username={{username}})"
export HMD_LDAP_USERNAMEFIELD="username"
export HMD_IMAGE_UPLOAD_TYPE=filesystem
# the following two changes could be transferred to config.json to enable users to change this
export HMD_EMAIL=false
export HMD_ALLOW_EMAIL_REGISTER=false
# disable pdf export until https://github.com/hackmdio/hackmd/issues/820 is fixed
export HMD_ALLOW_PDF_EXPORT=false
# respect users privacy and make notes private by default
export HMD_DEFAULT_PERMISSION=private
# let users choose to allow guest editing
export HMD_ALLOW_ANONYMOUS_EDITS=true
# create new page, if url does not yet exist
export HMD_ALLOW_FREEURL=true

# run
exec /usr/local/bin/gosu cloudron:cloudron node app.js
