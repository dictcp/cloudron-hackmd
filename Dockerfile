FROM cloudron/base:0.10.0
# install jq and moreutils (for sponge).
# can be removed once https://git.cloudron.io/cloudron/docker-base-image/merge_requests/3 is merged and released
RUN apt update && \
        apt -y install moreutils jq && \
        rm -rf /var/cache/apt /var/lib/apt/lists

# setup nodejs version
RUN mkdir -p /usr/local/node-8.11.3
RUN curl -L https://nodejs.org/download/release/v8.11.3/node-v8.11.3-linux-x64.tar.gz  | tar zxf - --strip-components 1 -C /usr/local/node-8.11.3
ENV PATH /usr/local/node-8.11.3/bin:$PATH

WORKDIR /app/code

ENV HACKMD_VERSION 1.2.0
RUN curl -L https://github.com/hackmdio/codimd/archive/$HACKMD_VERSION.tar.gz | tar -xz --strip-components 1 -f -

# npm, deps
RUN npm install && npm run build

# generate sequelizerrc
RUN sed -e "s/'change this'/process.env.POSTGRESQL_URL/" /app/code/.sequelizerc.example > /app/code/.sequelizerc

# add utils
ADD start.sh /app/code

# constant.js is generated on startup and "require"d by the code
RUN ln -sfn /run/hackmd/constant.js /app/code/public/build/constant.js && \
    rm -rf /app/code/public/uploads && ln -sf /app/data/uploads /app/code/public/uploads

# add user definable config
ADD config.json /app/code/config.json-cloudron
RUN ln -sfn /app/data/config.json /app/code/config.json

EXPOSE 3000

CMD ["/app/code/start.sh"]
