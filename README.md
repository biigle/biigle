# BIIGLE Distribution

This is the production setup of BIIGLE. You can fork this repository to customize your own production instance.

## Installation

Perform these steps on the machine that should run BIIGLE. Check out the wiki for an [example](https://github.com/biigle/distribution/wiki) of how to prepare a new machine for the installation of BIIGLE. You also need to [configure Docker](https://help.github.com/en/github/managing-packages-with-github-packages/configuring-docker-for-use-with-github-packages#authenticating-to-github-packages) to authenticate to the GitHub package registry.

1. Create a user for BIIGLE and find out the user and group ID:
   ```bash
   $ sudo useradd biigle -U
   $ id -u biigle
   <user_id>
   $ id -g biigle
   <group_id>
   ```

2. Change the owner of the `storage` directory:
   ```bash
   $ sudo chown -R biigle:biigle storage/
   ```

2. Move `.env.example` to `.env`.

3. Now set the configuration variables in `.env`:

   - `USER_ID` should be `<user_id>`.
   - `GROUP_ID` should be `<group_id>`.

2. Move `build/.env.example` to `build/.env`.

3. Now set the build configuration variables in `build/.env`:

   - `GITHUB_OAUTH_TOKEN` is an [OAuth token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) of your GitHub account.
   - `APP_KEY` is the secret encryption key. Generate one with: `head -c 32 /dev/urandom | base64`. Then set `APP_KEY=base64:<your_key>`.
   - `APP_URL` is `https://<your_domain>`.
   - `ADMIN_EMAIL` is the email address of the administrator(s) of the application.

4. If you use an external database system (outside Docker), remove the `database` block from `docker-compose.yaml` and configure the `DB_*` variables in `build/.env`.

5. Put the SSL keychain (`fullchain.pem`) and private key (`privkey.pem`) to `certificate/`. See [here](http://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate) for a description of the required contents of the keychain file. For a local setup no SSL certificate may be required. Update the `web` service in [`docker-compose.yaml`](docker-compose.yaml) as described by the comments in this case.

6. Now build the Docker images for production: `cd build && ./build.sh`. You can build the images on a separate machine, too, and transfer them to the production machine using [`docker save`](https://docs.docker.com/engine/reference/commandline/save/) and [`docker load`](https://docs.docker.com/engine/reference/commandline/load/). `build.sh` also supports an optional argument to specify the version tag of the Docker containers to build (e.g. `v2.8.0`). Default is `latest`.

7. Go back and run the containers: `cd .. && docker-compose up -d`.

8. Apply the database migrations: `./artisan migrate`.

9. Create the first user: `./artisan user:new`.

## Updating

1. Get the newest versions of the Docker images:
   ```
   docker pull docker.pkg.github.com/biigle/core/app:latest
   docker pull docker.pkg.github.com/biigle/core/web:latest
   docker pull docker.pkg.github.com/biigle/core/worker:latest
   ```

2. Run `cd build && ./build.sh`. This will fetch and install the newest versions of the BIIGLE modules, according to the version constraints configured in `build.sh`. Again, you can do this on a separate machine, too (see above). In this case the images mentioned above are not required on the production machine.

3. If the update requires a database migration, do this:
   1. Put the application in maintenance mode: `./artisan down`.
   2. Do a database backup. This might look along the lines of:
      ```bash
      docker exec -i $(docker-compose ps -q database) pg_dump -U biigle -d biigle > biigle_db.dump
      ```

4. Update the running Docker containers: `docker-compose up -d`.

5. If the update requires a database migration, do this:
   1. Run the migrations `./artisan migrate`
   2. Turn off the maintenance mode: `./artisan up`

6. Run `docker image prune` to delete old Docker images that are no longer required after the update.

## Common tasks

BIIGLE runs as an ensemble of multiple Docker containers (called "services" by Docker Compose).

- `app` runs the BIIGLE PHP application that handles user interactions.
- `web` accepts HTTP requests, forwards them to the PHP application or serves static files.
- `worker` executes jobs from the asynchronous queue which are submitted by `app`. This is the only service that runs multiple Docker containers in parallel.
- `scheduler` runs recurring tasks (similar to cron jobs).
- `cache` provides the Redis cache that BIIGLE uses.
- `database` provides the PostgreSQL database that BIIGLE uses.

To interact with these services rather than individual Docker containers, you have to use Docker Compose. Here are some common tasks a maintainer of a BIIGLE instance might perform using Docker Compose.

### Inspect the logs of running containers

```bash
docker-compose logs [service]
```

This shows the log file of the `[service]` service. You can use `--tail=[n]` to show only the last `[n]` lines of the log file and `-f` to follow the log file in real time.

### Restart all services

```bash
docker-compose restart
```

This may be required if a service crashed or if file system mounts changed.

### Run an artisan command

```bash
./artisan [command]
```

This runs the artisan command `[command]` in the worker service.

### Access the interactive shell

```bash
./artisan tinker
```

This opens the interactive PHP shell that you can use to manipulate BIIGLE. The shell only runs in the `worker` service as a debugging mechanism.

### Change the number of worker containers

```bash
docker-compose up -d --scale worker=[n]
```

Set the number of worker containers running in parallel to `[n]`. If you want this to persist, set `scale: [n]` for the worker service in `docker-compose.yaml`.
