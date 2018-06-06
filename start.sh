#!/bin/bash

# prepare data directory
mkdir -p /app/data/build && \
mkdir -p /app/data/uploads
chown -R cloudron:cloudron /app/data

if [ -f .sequelizerc ];
then
    node_modules/.bin/sequelize db:migrate
fi

# wait for db up
sleep 3

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

# run
/usr/local/bin/gosu cloudron:cloudron node app.js
