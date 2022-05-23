# README

[![CircleCI](https://circleci.com/gh/yalelibrary/yul-dc-management/tree/main.svg?style=svg)](https://circleci.com/gh/yalelibrary/yul-dc-management/tree/main) ![Docker Image CI](https://github.com/yalelibrary/yul-dc-management/workflows/Docker%20Image%20CI/badge.svg)

# Table of contents

- [README](#readme)
- [Quick Start Guide](#quick-start-guide)
- [Prerequisites](#prerequisites)
- [Docker Development Setup](#docker-development-setup)

  - [Clone application](#clone-application)
  - [Camerata](#camerata)

    - [Install Camerata](#install-camerata)
    - [Update Camerata](#update-camerata)
    - [General Use](#general-use)
    - [Troubleshooting](#troubleshooting)

  - [Running the rake tasks](#running-the-rake-tasks)

  - [Data Loading](#data-loading)

  - [Pulling or Building Docker Images](#pulling-or-building-docker-images)

  - [Releasing a new version of Management](#releasing-a-new-version-of-management)
    - [Deploy an individual branch](#deploy-an-individual-branch)

  - [Test coverage](#test-coverage)

# Prerequisites

- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in

# Quick Start Guide

- To start the application without VPN: 

```bash
git clone git@github.com:yalelibrary/yul-dc-camerata.git
cd yul-dc-camerata
bundle install
rake install
```
cd back into your main directory.

```
git clone git@github.com:yalelibrary/yul-dc-management.git
cd yul-dc-management
cam build
VPN=false cam up management
access at localhost:3001/management
```

- To bash into containers and run specs: 

With the application already started: 
```
cam sh management
bundle exec rspec spec/file/path
```
- See the [wiki](https://github.com/yalelibrary/yul-dc-documentation/wiki/Management-Development-Setup#bashing-into-containers) for further information on containers.


# Docker Development Setup

## Clone application

```bash
git clone git@github.com:yalelibrary/yul-dc-management.git
```

## Camerata

Camerata is a gem which is used to orchestrate and deploy the Yale DC suite of applications.

### Install Camerata

Clone the yul-dc-camerata repo and install the gem. If you are using an application for gem and ruby management, such as rvm or rbenv, be sure to use the same gemset when installing the Camerata gem as you use to bring up the management application (or the blacklight application, etc.).

Note: Clone Camerata in your project directory (not inside your management repo)

```bash
git clone git@github.com:yalelibrary/yul-dc-camerata.git
cd yul-dc-camerata
bundle install
rake install
```

### Update Camerata

You can get the latest camerata version at any point by updating the code and reinstalling

```bash
cd yul-dc-camerata
git pull origin main
bundle install
rake install
```

### General Use

Once camerata is installed on your system, interactions happen through the camerata command-line tool or through its alias `cam`. The camerata tool can be used to bring the development stack up and down locally, interact with the docker containers, deploy, run the smoke tests, and otherwise do development tasks common to the various applications in the yul-dc application stack.

All built in commands can be listed with `cam help` and individual usage information is available with `cam help COMMAND`. Please note that deployment commands (found in the `./bin` directory) are passed through and are therefore not listed by the help command. See the usage for those in the [camerata README](https://github.com/yalelibrary/yul-dc-camerata#yul-dc-camerata).

To start the application stack, run `cam up` in the management directory

```bash
cd ./yul-dc-management
cam up
```

This starts all of the applications, as they are all dependencies of yul-blacklight. Camerata is smart. If you start `cam up` from a management code check out it will mount that code for local development (changes to the outside code will affect the inside container). If you start the `cam up` from the blacklight application you will get the blacklight code mounted for local development and the management code will run as it is in the downloaded image. You can also start the two applications both mounted for development by starting the management application with `--without blacklight` and the blacklight application `--without solr --withouth db` each from their respective code checkouts.

- Access the blacklight app at `http://localhost:3000`

- Access the solr instance at `http://localhost:8983`

- Access the image instance at `http://localhost:8182`

- Access the management app at `http://localhost:3001/management`

### Troubleshooting
- See the [wiki](https://github.com/yalelibrary/yul-dc-documentation/wiki/Management-Development-Setup#troubleshooting) for further troubleshooting topics

### Dynatrace
- We've integrated Dynatrace OneAgent for monitoring our Docker container environments.
  - Instructions on configuring OneAgent can be found [here](https://github.com/yalelibrary/yul-dc-camerata/tree/main/base)

## Running the rake tasks
- See the [wiki](https://github.com/yalelibrary/yul-dc-documentation/wiki/Management-Development-Setup#running-the-rake-tasks) for further information on rake tasks.
  
## Data Loading

In development mode, the database and solr are seeded / loaded with information from 1 sample object. You can see the oids for this object in `db/parent_oids_short.csv` and `db/seeds.rb`.

In production and development mode, you can add objects either individually, either by creating a new parent_object at `https://[hostname]/parent_objects/new` or using the CSV import of a sheet of oids (this file should be structured the same as `db/parent_oids_short.csv`). If you have access to DCE or Yale AWS S3 buckets, you can add any of the oids in the `db/parent_oids.csv` file, and the parent and child objects should be created correctly. If you are on the VPN, you should be able to add any pre-existing valid oid from Ladybird, and it will bring in the correct data from the MetadataCloud.

## Pulling or Building Docker Images

Any time you pull a branch with a Gemfile change you need to pull or build a new Docker image. If you change the Dockerfile, you need to build a new Docker image. If you change a file in ./ops you need to build a new Docker image. These are the primary times in which you need to pull or build.

## Releasing a new version of Management
Refer to the steps in the [Camerata repo](https://github.com/yalelibrary/yul-dc-camerata#releasing-a-new-app-version)

## Deploy an individual branch
Refer to the steps in the [Camerata repo](https://github.com/yalelibrary/yul-dc-camerata#deploy-a-branch)

## Test coverage

We use [coveralls](https://coveralls.io/github/yalelibrary/yul-dc-management) to measure test coverage. More details [here](https://github.com/yalelibrary/yul-dc-management/wiki/code-coverage).


## Authorization

We use Omniauth with cas to authenticate users.

The uids of authorized cas users are read from a CSV at `ENV['SAMPLE_BUCKET']/authorization/cas_users.csv`.
That list of uids is used to seed the database when the app starts.  Uids not found in that file will be deleted.

Management needs to deployed for a new file to be loaded.

To override the CSV on S3, place a csv in `config/cas_users.csv`.  This will be used, if it exists, instead of the file
on S3.

To upload a new CSV to S3:
 - Download the existing cas_users.csv from S3 using the AWS management console.
 - Place the downloaded csv in `config/cas_users.csv` and update it.
 - Run the rake task from management shell with `rake authorized_users:upload`.

 To upload to different environments, run from management container:
 ```bash
SAMPLE_BUCKET=yul-dc-development-samples rake authorized_users:upload
SAMPLE_BUCKET=yul-dc-test-samples rake authorized_users:upload
SAMPLE_BUCKET=yul-dc-uat-samples rake authorized_users:upload
SAMPLE_BUCKET=yul-dc-infra-samples rake authorized_users:upload
SAMPLE_BUCKET=yul-dc-prod-samples rake authorized_users:upload
SAMPLE_BUCKET=yul-dc-samples rake authorized_users:upload
SAMPLE_BUCKET=yul-dc-staging-samples rake authorized_users:upload
```
