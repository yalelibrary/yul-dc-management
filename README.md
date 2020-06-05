# README
[![CircleCI](https://circleci.com/gh/yalelibrary/yul-dc-management/tree/master.svg?style=svg)](https://circleci.com/gh/yalelibrary/yul-dc-management/tree/master)
![Docker Image CI](https://github.com/yalelibrary/yul-dc-management/workflows/Docker%20Image%20CI/badge.svg)

# Prerequisites
- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in

# Docker Development Setup
### Clone application
```bash
git clone git@github.com:yalelibrary/yul-dc-management.git
```
### Change to the application directory
```bash
cd ./yul-dc-management
```
### Create needed files on your command line
```bash
touch .secrets
```

### If this is your first time working in this repo, build the base service (dependencies, etc. that don't change)
  ``` bash
  docker-compose build base
  ```

### If this is your first time working in this repo or the Dockerfile has been updated you will need to (re)build your services
  ``` bash
  docker-compose build web
  ```

### Starting the app
- Start the web service
  ``` bash
  docker-compose up web
  ```
- Access the web app at `http://localhost:3001`
- Access the solr instance at `http://localhost:8983`

##### Accessing the web container
- Navigate to the app root directory in another tab and run:
  ``` bash
  docker-compose exec web bundle exec bash
  ```
- You will need to be inside the container to:
  - Run migrations
  - Access the seed file
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

### Running the rake tasks
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
        rake yale:index_fixture_data
   ```
  - Clean out Solr index
   ```bash
        rake yale:clean_solr
   ```
