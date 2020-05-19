# README

# Prerequisites
- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in

# Docker Development Setup
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
- Access the web app at `http://localhost:3000`
- Access the solr instance at `http://localhost:8983`

##### Accessing the web container
- Navigate to the app root directory in another tab and run:
  ``` bash
  docker-compose exec web bash
  ```
- You will need to be inside the container to:
  - Run migrations
  - Access the seed file
  - Access the rails console for debugging
    ```
    bundle exec rails c
    ```
  - Index sample data (if you go to solr and hit "execute query" and don't have data, run this command)
    ```
    bundle exec rake yale:load_voyager_sample_data
    ```

### Proposed pattern for development
- Start the database
  ``` bash
  docker-compose up db
  ```
- Start solr
  ``` bash
  docker-compose up solr
  ```
- Run rspec on the command line _outside_ the container
  ``` bash
  bundle exec rspec spec
  ```
