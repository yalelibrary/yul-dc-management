# README

[![CircleCI](https://circleci.com/gh/yalelibrary/yul-dc-management/tree/master.svg?style=svg)](https://circleci.com/gh/yalelibrary/yul-dc-management/tree/master) ![Docker Image CI](https://github.com/yalelibrary/yul-dc-management/workflows/Docker%20Image%20CI/badge.svg) [![Coverage Status](https://coveralls.io/repos/github/yalelibrary/yul-dc-management/badge.svg?branch=master)](https://coveralls.io/github/yalelibrary/yul-dc-management?branch=master)

# Prerequisites

- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in

# Docker Development Setup

## Clone application

```bash
git clone git@github.com:yalelibrary/yul-dc-management.git
```

## Install Camerata

Clone the yul-dc-camerata repo and install the gem.
Note: Clone Camerata in your project directory (not inside your management repo)

```bash
git clone git@github.com:yalelibrary/yul-dc-camerata.git
cd yul-dc-camerata
bundle install
rake install
```

## Update Camerata

You can get the latest camerata version at any point by updating the code and reinstalling

```bash
cd yul-dc-camerata
git pull origin master
bundle install
rake install
```

## General Use

Once camerata is installed on your system, interactions happen through the
camerata command-line tool or through its alias `cam`.  The camerata tool can be
used to bring the development stack up and down locally, interact with the
docker containers, deploy, run the smoke tests, and otherwise do development
tasks common to the various applications in the yul-dc application stack.

All built in commands can be listed with `cam help` and individual usage
information is available with `cam help COMMAND`.  Please note that deployment
commands (found in the `./bin` directory) are passed through and are therefore not
listed by the help command.  See the usage for those in the [camerata README](https://github.com/yalelibrary/yul-dc-camerata#yul-dc-camerata).

To start the application stack, run `cam up` in the management directory
```bash
cd ./yul-dc-management
cam up
```
This starts all of the applications, as they are
all dependencies of yul-blacklight. Camerata is smart. If you start `cam up` from
a management code check out it will mount that code for local development
(changes to the outside code will affect the inside container). If you start the
`cam up` from the blacklight application you will get the blacklight code mounted
for local development and the management code will run as it is in the downloaded
image. You can also start the two applications both mounted for development by
starting the management application with `--without blacklight` and the
blacklight application `--without solr --withouth db` each from their respective
code checkouts.


- Access the blacklight app at `http://localhost:3000`

- Access the solr instance at `http://localhost:8983`

- Access the image instance at `http://localhost:8182`

- Access the manifests instance at `http://localhost`

- Access the management app at `http://localhost:3001/management`

## Troubleshooting

If you receive an `please set your AWS_PROFILE and AWS_DEFAULT_REGION (RuntimeError)`
error when you `cam up`, you will need to set your AWS credentials. Credentials
can be set in the `~/.aws/credentials` file in the following format:

```bash
[dce-hosting]
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY
```
After the credentials have been set, you will need to export the following settings via the command line:
```bash
export AWS_PROFILE=dce-hosting && export AWS_DEFAULT_REGION=us-east-1
```
Note: AWS_PROFILE name needs to match the credentials profile name (`[dce-hosting]`). After you set the credentials, you will need to re-install camerata: `rake install`

If you use rbenv, you must run the following command after installing camerata:
`rbenv rehash`


## Running on the VPN

If you'd like to hit the Metadata cloud endpoint and are running on the VPN,
then start the application with `VPN=true cam up` or `VPN=true cam up
management`. Setting this variable will enable VPN specs and make full requests
to the Yale services.

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

  - Run the tests. (in order to run the VPN-only tests, bring up camerata using `VPN=true cam up` or `VPN=true cam up
  management`)

    ```bash
    rspec
    ```

  - Run Rubocop to fix any style errors

    ```bash
    rubocop -a
    ```

    - If Rubocop is still flagging something that you've checked and want to keep as-is long term, add it to the `.rubocop.yml` manually. If it needs to remain short term, but will need to be fixed, you can automatically re-generate the `rubocop_todo.yml` file by running `rubocop --auto-gen-config`.

  - If you are doing development that requires access to the Yale Metadata Cloud, get on the Yale VPN, and add your credentials to your `.secrets` file. These should never be added to version control.<!-- This needs to be updated based on the camerata gem updates, but not sure what the current practice should be - they're not in the AWS parameter store -->

    ```
    # Metadata Cloud
    MC_USER=YOUR_INFO_HERE
    MC_PW=YOUR_INFO_HERE
    ```

## Running the rake tasks

- Update fixture data from the MetadataCloud

  - _NOTE:_ you must be on the Yale VPN
  - If you have trouble connecting to the MetadataCloud, see the DCE doc on [connecting to VPN from within a container](https://curationexperts.github.io/playbook/tools/docker/containers.html)
  - Add your credentials to your `.secrets` file.<!-- This needs to be updated based on the camerata gem updates, but not sure what the current practice should be - they're not in the AWS parameter store -->

    ```
    # Metadata Cloud
    MC_USER=YOUR_INFO_HERE
    MC_PW=YOUR_INFO_HERE
    ```

    Valid metadata sources: ils [aka Voyager], aspace, or ladybird.

    ```bash
    METADATA_SOURCE=YOUR_SOURCE_HERE rake yale:refresh_fixture_data
    ```

- Index sample data (if you go to solr and hit "execute query" and don't have data, run this command). This should also occur automatically when you seed the database or otherwise create ParentObjects

  ```bash
      rake solr:index
  ```

- Clean out Solr index

  ```bash
      rake solr:delete_all
  ```

## Pulling or Building Docker Images

Any time you pull a branch with a Gemfile change you need to pull or build a new
Docker image. If you change the Dockerfile, you need to build a new Docker image.
If you change a file in ./ops you need to build a new Docker image. These are
the primary times in which you need to pull or build.

## When Installing a New Gem

For the most part images are created and maintained by the CI process. However,
if you change the Gemfile you need to take a few extra steps. Make sure the
application is running before you make your Gemfile change. Once you've updated
the Gemfile, inside the container, run `bundle && nginx -s reload`. The next time
you stop your running containers you need to rebuild.

## Releasing a new version

1. Decide on a new version number. We use [semantic versioning](https://semver.org/).
2. Update the version number in `.github_changelog_generator` && `.env`
3. Go through all PRs since the last release and ensure that any **features** and **bug fixes** have been tagged with the appropriate label. No need to label it unless it is a feature or a bug fix.
4. Run this command: `github_changelog_generator --token $YOUR_GITHUB_TOKEN`. This will re-generate `CHANGELOG.md`.
5. Commit and merge the changes you just made with a message like "Prep for vX.Y.Z release"
6. Once those changes are merged to the `master` branch, in the github web UI go to `Releases` and tag a new release with the right version number. Paste in the release notes for this release from the top of `CHANGELOG.md`
7. Update `yul-dc-camerata` with the new version of management and submit a PR. (alternatively, see the [camerata README on Releasing a New Dependency Version](https://github.com/yalelibrary/yul-dc-camerata#releasing-a-new-dependency-version))
8. Move any tickets that were included in this release from `For Release` to `Ready for Acceptance`

## Test coverage

We use [coveralls](https://coveralls.io/github/yalelibrary/yul-dc-management) to measure test coverage. More details [here](https://github.com/yalelibrary/yul-dc-management/wiki/code-coverage).
