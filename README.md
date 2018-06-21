# HackMD Cloudron App

This repository contains the Cloudron app package source for [HackMD](https://hackmd.io/).

## Installation

[![Install](https://cloudron.io/img/button.svg)](https://cloudron.io/button.html?app=io.hackmd.cloudronapp)

or using the [Cloudron command line tooling](https://cloudron.io/references/cli.html)

```
cloudron install --appstore-id io.hackmd.cloudronapp
```

## Building

The app package can be built using the [Cloudron command line tooling](https://cloudron.io/references/cli.html).

```
cd hackmd-app

cloudron build
cloudron install
```

## Testing

The e2e tests are located in the `test/` folder and require [nodejs](http://nodejs.org/). They are creating a fresh build, install the app on your Cloudron, backup and restore. 

```
cd hackmd-app/test

npm install
USERNAME=<cloudron username> PASSWORD=<cloudron password> mocha --bail test.js
```

