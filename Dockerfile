FROM cloudron/base:0.10.0

# setup nodejs version
ENV NODEJS_VERSION 6.9.5
RUN ln -s /usr/local/node-$NODEJS_VERSION/bin/node /usr/local/bin/node && \
    ln -s /usr/local/node-$NODEJS_VERSION/bin/npm /usr/local/bin/npm

WORKDIR /hackmd

ENV HACKMD_VERSION master
RUN curl -L https://github.com/hackmdio/hackmd/archive/$HACKMD_VERSION.tar.gz | tar -xz --strip-components 1 -f -

# npm, deps
RUN npm install

# build front-end bundle
RUN npm run build

# remove dev dependencies
RUN npm prune --production

# add utils
ADD CloudronManifest.json ./
ADD start.sh ./
RUN chmod +x ./start.sh

# use local storage
RUN ln -sfn /app/data/build/constant.js ./public/build/constant.js && \
    rm -rf ./public/uploads && ln -sf /app/data/uploads ./public/uploads

EXPOSE 3000

CMD ["/hackmd/start.sh"]
