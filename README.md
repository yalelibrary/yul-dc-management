# README

[![CircleCI](https://circleci.com/gh/yalelibrary/yul-dc-management/tree/master.svg?style=svg)](https://circleci.com/gh/yalelibrary/yul-dc-management/tree/master) ![Docker Image CI](https://github.com/yalelibrary/yul-dc-management/workflows/Docker%20Image%20CI/badge.svg)

# Prerequisites

- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in

# Docker Development Setup

## Clone application

```bash
git clone git@github.com:yalelibrary/yul-dc-management.git
```

## Change to the application directory

```bash
cd ./yul-dc-management
```

## Create needed files on your command line

```bash
touch .secrets
```

## If this is your first time working in this repo or the Dockerfile has been updated you will need to pull your services

```bash
  docker-compose pull management
```

## Starting the app

- Start the management service and its dependencies

  ```bash
  docker-compose up management
  ```

- Access the Management app at http://localhost:3001/management

- Access the solr instance at http://localhost:8983

- If you would like to see how items indexed by the Management application appear in the Discovery application,
  you can bring down the Management application (ctrl-c or `docker-compose down`), and bring up the Management and
  Discovery applications together:
  ```bash
  docker-compose up blacklight  
  ```
  - _NOTE_: In order to keep the docker-compose file focused on development for the Management application, it does not
    contain all the services required for the Discovery application to display images (the manifest and image services). If
    you need to test images in the Discovery application, you can add these services to docker-compose file.

  - Access the Discovery application at http://localhost:3000

### Accessing the management container

- Navigate to the app root directory in another tab and run:

  ```bash
  docker-compose exec management bundle exec bash
  ```

- You will need to be inside the container to:

  - Run migrations
  - Seed the database with a pre-defined list of oids from Ladybird

    ```bash
    RAILS_ENV=development rails db:seed
    RAILS_ENV=test rails db:seed
    ```

  - Access the rails console for debugging

    ```bash
    rails c
    ```

  - Run the tests, excluding those that require the Yale VPN (the tilda(~) means the tag is excluded)

    ```bash
    rspec --tag ~vpn_only:true
    ```

  - Run only the tests that require the Yale VPN

    ```bash
    rspec --tag vpn_only:true
    ```

  - Run Rubocop to fix any style errors

    ```bash
    rubocop -a
    ```

    - If Rubocop is still flagging something that you've checked and want to keep as-is, add it to the `.rubocop_todo.yml` manually.

  - If you are doing development that requires access to the Yale Metadata Cloud, get on the Yale VPN, and add your credentials to your `.secrets` file. These should never be added to version control.

    ```
    # Metadata Cloud
    MC_USER=YOUR_INFO_HERE
    MC_PW=YOUR_INFO_HERE
    ```

## Running the rake tasks

- Update fixture data from the MetadataCloud

  - _NOTE:_ you must be on the Yale VPN
  - If you have trouble connecting to the MetadataCloud, see the DCE doc on [connecting to VPN from within a container](https://curationexperts.github.io/playbook/tools/docker/containers.html)
  - Add your credentials to your `.secrets` file.

    ```
    # Metadata Cloud
    MC_USER=YOUR_INFO_HERE
    MC_PW=YOUR_INFO_HERE
    ```

    Valid metadata sources: ils [aka Voyager], aspace, or ladybird.

    ```bash
    METADATA_SOURCE=YOUR_SOURCE_HERE rake yale:refresh_fixture_data
    ```

- Index sample data (if you go to solr and hit "execute query" and don't have data, run this command)

  ```bash
      METADATA_SOURCE=YOUR_SOURCE_HERE rake yale:index_fixture_data
  ```

- Clean out Solr index

  ```bash
      rake yale:clean_solr
  ```

## Pulling or Building Docker Images
  Any time you pull a branch with a Gemfile change you need to pull or build a new Docker image. If you change the Dockerfile, you
  need to build a new Docker image. If you change a file in ./ops you need to build a new Docker image. These are the primary
  times in which you need to pull or build.

## When Installing a New Gem
  For the most part images are created and maintained by the CI process. However, if you change the Gemfile you need
  to take a few extra steps.  Make sure the application is running before you make your Gemfile change. Once you've
  updated the Gemfile, inside the container, run `bundle && nginx -s reload`. The next time you stop your running containers
  you need to rebuild.

## Releasing a new version

  1. Decide on a new version number. We use [semantic versioning](https://semver.org/).
  2. Update the version number in `.github_changelog_generator`
  3. github_changelog_generator --user yalelibrary --project yul-dc-management --token $YOUR_GITHUB_TOKEN
  4. Commit and merge the changes you just made.
  5. Once those changes are merged to the `master` branch, in the github web UI go to `Releases` and tag a new release with the right version number. Paste in the release notes for this version from the changelog you generated. In the release notes, split out `Features`, `Bug Fixes`, and `Other`
  7. Update `yul-dc-camerata` with the new version of management and submit a PR.
