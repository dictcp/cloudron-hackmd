#!/usr/bin/env node

/* jslint node:true */
/* global it:false */
/* global xit:false */
/* global describe:false */
/* global before:false */
/* global after:false */

'use strict';

require('chromedriver');

var execSync = require('child_process').execSync,
    expect = require('expect.js'),
    path = require('path'),
    webdriver = require('selenium-webdriver');

var by = webdriver.By,
    until = webdriver.until;

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

if (!process.env.USERNAME || !process.env.PASSWORD || !process.env.EMAIL) {
    console.log('USERNAME, PASSWORD and EMAIL env vars need to be set');
    process.exit(1);
}

describe('Application life cycle test', function () {
    this.timeout(0);

    var chrome = require('selenium-webdriver/chrome');
    var server, browser = new chrome.Driver();
    var username = process.env.USERNAME, password = process.env.PASSWORD;
    // var email = process.env.EMAIL;
    var noteUrl;

    function login(done) {
        browser.manage().deleteAllCookies().then(function () {
            return browser.get('https://' + app.fqdn);
        }).then(function () {
            return browser.wait(until.elementLocated(by.xpath('//button[text()="Sign In"]')), TEST_TIMEOUT);
        }).then(function () {
            return browser.findElement(by.xpath('//div[@class="ui-signin"]/button[text()="Sign In"]')).click();
        }).then(function () {
            return browser.sleep(2000); // wait for login popup
        }).then(function () {
            return browser.findElement(by.xpath('//input[@name="username"]')).sendKeys(username);
        }).then(function () {
            return browser.findElement(by.xpath('//input[@name="password"]')).sendKeys(password);
        }).then(function () {
            return browser.findElement(by.xpath('//button[text()="Sign in" and contains(@formaction, "ldap")]')).click();
        }).then(function () {
            return browser.wait(until.elementLocated(by.xpath('//a[contains(text(), "New note")]')), TEST_TIMEOUT);
        }).then(function () {
            done();
        });
    }

    function newNote(done) {
        browser.get('https://' + app.fqdn + '/new').then(function () {
            return browser.wait(until.elementLocated(by.xpath('//a[contains(text(), "Publish")]')), TEST_TIMEOUT);
        }).then(function () {
            return browser.sleep(5000); // code mirror takes a while to load
        }).then(function () {
            return browser.getCurrentUrl();
        }).then(function (url) {
            noteUrl = url;
            console.log('The note url is ' + noteUrl);
            return browser.findElement(by.css('.CodeMirror textarea')).sendKeys('hello cloudron');
        }).then(function () {
            return browser.sleep(2000); // give it a second to 'save'
        }).then(function () {
            done();
        });
    }

    function checkExistingNote(done) {
        browser.get(noteUrl).then(function () {
            return browser.wait(until.elementLocated(by.xpath('//p[contains(text(), "hello cloudron")]')), TEST_TIMEOUT);
        }).then(function () {
            done();
        });
    }

    function checkNoteIsPrivate(done) {
        browser.get(noteUrl).then(function () {
            return browser.wait(until.elementLocated(by.xpath('//h1[contains(text(), "403 Forbidden")]')), TEST_TIMEOUT);
        }).then(function () {
            done();
        });
    }

    function logout(done) {
        browser.get('https://' + app.fqdn).then(function () {
            return browser.findElement(by.xpath('//button[@id="profileLabel"]')).click();
        }).then(function () {
            return browser.sleep(2000); // wait for menu to open
        }).then(function () {
            return browser.findElement(by.xpath('//a[contains(text(), "Sign Out")]')).click();
        }).then(function () {
            return browser.sleep(2000);
        }).then(function () {
            done();
        });
    }

    before(function (done) {
        var seleniumJar= require('selenium-server-standalone-jar');
        var SeleniumServer = require('selenium-webdriver/remote').SeleniumServer;
        server = new SeleniumServer(seleniumJar.path, { port: 4444 });
        server.start();

        done();
    });

    after(function (done) {
        browser.quit();
        server.stop();
        done();
    });

    var LOCATION = 'test';
    var TEST_TIMEOUT = 30000;
    var app;

    xit('build app', function () {
        execSync('cloudron build', { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('install app', function () {
        execSync('cloudron install --new --wait --location ' + LOCATION, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('can get app information', function () {
        var inspect = JSON.parse(execSync('cloudron inspect'));

        app = inspect.apps.filter(function (a) { return a.location === LOCATION; })[0];

        expect(app).to.be.an('object');
    });

    it('can login', login);
    it('can create new note', newNote);
    it('can check existing note', checkExistingNote);
    it('can logout', logout);

    it('did create private note', checkNoteIsPrivate);

    it('backup app', function () {
        execSync('cloudron backup create --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('restore app', function () {
        execSync('cloudron restore --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('can login', login);
    it('can check existing note', checkExistingNote);
    it('can logout', logout);

    it('did create private note', checkNoteIsPrivate);

    it('can restart app', function (done) {
        execSync('cloudron restart --wait --app ' + app.id);
        done();
    });

    it('can login', login);
    it('can check existing note', checkExistingNote);
    it('can logout', logout);

    it('did create private note', checkNoteIsPrivate);

    it('move to different location', function (done) {
        execSync('cloudron configure --wait --location ' + LOCATION + '2 --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
        var inspect = JSON.parse(execSync('cloudron inspect'));
        app = inspect.apps.filter(function (a) { return a.location === LOCATION + '2'; })[0];
        expect(app).to.be.an('object');
        noteUrl = noteUrl.replace(LOCATION, LOCATION + '2');

        done();
    });

    it('can login', login);
    it('can check existing note', checkExistingNote);
    it('can logout', logout);

    it('did create private note', checkNoteIsPrivate);

    it('uninstall app', function () {
        execSync('cloudron uninstall --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    // test update
    it('can install from appstore', function () {
        execSync('cloudron install --new --wait --appstore-id io.hackmd.cloudronapp --location ' + LOCATION, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
        var inspect = JSON.parse(execSync('cloudron inspect'));
        app = inspect.apps.filter(function (a) { return a.location === LOCATION; })[0];
        expect(app).to.be.an('object');
    });

    it('can login', login);
    it('can create new note', newNote);
    it('can logout', logout);

    it('can update', function () {
        execSync('cloudron install --wait --app ' + LOCATION, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('can login', login);
    it('can check existing note', checkExistingNote);
    it('can logout', logout);

    it('did create private note', checkNoteIsPrivate);

    it('uninstall app', function () {
        execSync('cloudron uninstall --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });
});
