# README

[![CircleCI](https://circleci.com/gh/yalelibrary/yul-dc-management/tree/master.svg?style=svg)](https://circleci.com/gh/yalelibrary/yul-dc-management/tree/master) ![Docker Image CI](https://github.com/yalelibrary/yul-dc-management/workflows/Docker%20Image%20CI/badge.svg) [![Coverage Status](https://coveralls.io/repos/github/yalelibrary/yul-dc-management/badge.svg?branch=master)](https://coveralls.io/github/yalelibrary/yul-dc-management?branch=master)

# Table of contents

- [README](#readme)
- [Table of contents](#table-of-contents)
- [Prerequisites](#prerequisites)
- [Docker Development Setup](#docker-development-setup)

  - [Clone application](#clone-application)
  - [Camerata](#camerata)

    - [Install Camerata](#install-camerata)
    - [Update Camerata](#update-camerata)
    - [General Use](#general-use)
    - [Troubleshooting](#troubleshooting)
    - [Running on the VPN](#running-on-the-vpn)
    - [Accessing the web container](#accessing-the-web-container)

  - [Running the rake tasks](#running-the-rake-tasks)

  - [Data Loading](#data-loading)

  - [Pulling or Building Docker Images](#pulling-or-building-docker-images)

  - [Releasing a new version](#releasing-a-new-version)

  - [Test coverage](#test-coverage)

# Prerequisites

- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in

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
git pull origin master
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

- Access the manifests instance at `http://localhost/manifests`

- Access the management app at `http://localhost:3001/management`

### Troubleshooting

#### If on VPN and cannot connect to network
Check your Docker Engine setting:

Reference link: https://curationexperts.github.io/playbook/tools/docker/containers.html
```bash
cam down
```
Go to your Docker Desktop -> Preference -> Docker Engine, replace the content of the box to:
```json
{
  "debug": true,
  "default-address-pools": [
    {
      "base": "10.160.0.0/16",
      "size": 24
    }
  ],
  "experimental": false
}
```

Restart your Docker Desktop
```bash
docker network prune
```
#### AWS Profile
If you receive an `please set your AWS_PROFILE and AWS_DEFAULT_REGION (RuntimeError)` error when you `cam up`, you will need to set your AWS credentials. Credentials can be set in the `~/.aws/credentials` file in the following format:

```bash
[your-profile-name]
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY
```

After the credentials have been set, you will need to export the following settings via the command line:

```bash
export AWS_PROFILE=your-profile-name AWS_DEFAULT_REGION=us-east-1
```

Note: AWS_PROFILE name needs to match the credentials profile name (`[your-profile-name]`). After you set the credentials, you will need to re-install camerata: `rake install`

If you use rbenv, you must run the following command after installing camerata: `rbenv rehash`

### Running on the VPN

If you'd like to hit the Metadata cloud endpoint and are running on the VPN, then start the application with `VPN=true cam up` or `VPN=true cam up management`. Setting this variable will enable VPN specs and make full requests to the Yale services.

### Accessing the web container

- Navigate to the app root directory in another tab and run:

  ```bash
  cam sh management
  ```

- You will need to be inside the container to:

  - Run new migrations or seeds (existing migrations and seeds will automatically be run when you bring up the container in development mode)

  ```bash
  RAILS_ENV=development rails db:seed
  RAILS_ENV=test rails db:seed
  ```

  - Access the rails console for debugging

    ```bash
    rails c
    ```

  - Run the tests. (in order to run the VPN-only tests, bring up camerata using `VPN=true cam up` or `VPN=true cam up management`)

    ```bash
    rspec
    ```

  - Run Rubocop to fix any style errors

    ```bash
    rubocop -a
    ```

    - If Rubocop is still flagging something that you've checked and want to keep as-is long term, add it to the `.rubocop.yml` manually. If it needs to remain short term, but will need to be fixed, you can automatically re-generate the `rubocop_todo.yml` file by running `rubocop --auto-gen-config`.

  - If you are doing development that requires access to the Yale Metadata Cloud, you will need to be connected to the Yale VPN and have active Yale AWS credentials.

  ### Dynatrace

  - We've integrated Dynatrace OneAgent for monitoring our Docker container environments.
    - Instructions on configuring OneAgent can be found [here](https://github.com/yalelibrary/yul-dc-camerata/tree/master/base)


## Running the rake tasks

- Index sample data (if you go to solr and hit "execute query" and don't have data, run this command). This should also occur automatically when you seed the database or otherwise create ParentObjects

```bash
rake solr:index
```

- Clean out Solr index

```bash
rake solr:delete_all
```

- Create a CSV of random public visibility parent oids, formatted for import into the application:

```bash
rake parent_oids:random[NUMBER_OF_PARENT_OIDS_YOU_WANT]
```

e.g., to get a list of 50 random public parent oids:
```bash
rake parent_oids:random[50]
```

The resulting file can be found at `data/random_parent_oids.csv`

## Data Loading

In development mode, the database and solr are seeded / loaded with information from 1 sample object. You can see the oids for this object in `db/parent_oids_short.csv` and `db/seeds.rb`.

In production and development mode, you can add objects either individually, either by creating a new parent_object at `https://[hostname]/parent_objects/new` or using the CSV import of a sheet of oids (this file should be structured the same as `db/parent_oids_short.csv`). If you have access to DCE or Yale AWS S3 buckets, you can add any of the oids in the `db/parent_oids.csv` file, and the parent and child objects should be created correctly. If you are on the VPN, you should be able to add any pre-existing valid oid from Ladybird, and it will bring in the correct data from the MetadataCloud.

## Pulling or Building Docker Images

Any time you pull a branch with a Gemfile change you need to pull or build a new Docker image. If you change the Dockerfile, you need to build a new Docker image. If you change a file in ./ops you need to build a new Docker image. These are the primary times in which you need to pull or build.

## Releasing a new version
1. Checkout to the `master` branch and run `git pull`

2. Ensure you have a github personal access token.

    Instructions here: <https://github.com/github-changelog-generator/github-changelog-generator#github-token> You will need to make your token available via an environment variable called `CHANGELOG_GITHUB_TOKEN`, e.g.:

    ```
    export CHANGELOG_GITHUB_TOKEN=YOUR_TOKEN_HERE
    ```

3. Use the camerata gem to increment the management version and deploy:
  Note: See [the camerata readme](https://github.com/yalelibrary/yul-dc-camerata) for details on installing camerata.

    ```
    cam release management
    ```

4. Proceed with the steps for the Yale infrastructure or the DCE infrastructure
##### Using the Yale infrastructure
  - Log on to VPN
  - Go to Jenkins website in your browser (request it from a member of the team if you don't have it)
  - Click on "YUL-DC-Test-Deploy" on the dashboard
  - Click on "Build with Parameters" in the left side navigation panel
  - In the "MANAGEMENT_VERSION" input box, type in the version you released with the command in step 3 (e.g.: v1.30.0)
  - Check the UPDATE_SSM box
  - Press "Build"
  - You will see your build in the "Build History" section in the left side navigation panel with a blinking blue circle, indicating it's in progress
    - If you press the number associated with the build, you can see the details
    - The build typically takes 10-15 minutes
    - A successful build will show a solid blue circle when finished
    - An unsuccessful build will show a solid red circle when finished


##### Using the DCE infrastructure
```
  cam push_version management NEW_MANAGEMENT_VERSION_NUMBER
  cam deploy-main CLUSTER_NAME (e.g., yul-test)
```

5. Move any tickets that were included in this release from `For Release` to `Ready for Acceptance`

## Test coverage

We use [coveralls](https://coveralls.io/github/yalelibrary/yul-dc-management) to measure test coverage. More details [here](https://github.com/yalelibrary/yul-dc-management/wiki/code-coverage).


## Authorization

We use Omniauth with cas to authenticate users.

The uids of authorized cas users are read from a CSV at `ENV['SAMPLE_BUCKET']/authorization/cas_users.csv`.
That list of uids is used to seed the database when the app starts.  Uids not found in that file will be deleted.

To override the CSV on S3, place a csv in `config/cas_users.csv`.

To upload a new CSV to S3, place the new csv in `config/cas_users.csv` and run the rake task from management shell with `rake authorized_users:upload`.