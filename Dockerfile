FROM cloudron/base:0.10.0

# setup nodejs version
ENV NODEJS_VERSION 6.9.5
RUN ln -s /usr/local/node-$NODEJS_VERSION/bin/node /usr/local/bin/node && \
    ln -s /usr/local/node-$NODEJS_VERSION/bin/npm /usr/local/bin/npm

WORKDIR /app/code

ENV HACKMD_VERSION 1.1.1-ce
RUN curl -L https://github.com/hackmdio/hackmd/archive/$HACKMD_VERSION.tar.gz | tar -xz --strip-components 1 -f -

# npm, deps
RUN npm install

# build front-end bundle
RUN npm run build

# remove dev dependencies
RUN npm prune --production

# add utils
ADD start.sh /app/code
RUN chmod +x /app/code/start.sh

# use local storage
RUN ln -sfn /app/data/build/constant.js /app/code/public/build/constant.js && \
    rm -rf /app/code/public/uploads && ln -sf /app/data/uploads /app/code/public/uploads

# add user definable config
ADD config.json /app/code/config.json-cloudron
RUN ln -sfn /app/data/config.json /app/code/config.json

EXPOSE 3000

CMD ["/app/code/start.sh"]
