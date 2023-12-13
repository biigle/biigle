# Maintenance of a BIIGLE instance

This guide describes how basic maintenance operations such as updates of a BIIGLE instance work.

## Updating

Perform these steps to update an existing BIIGLE instance.

1. Apply the latest changes from the [`biigle/biigle`](https://github.com/biigle/biigle) repository with `git pull upstream master` (or `git pull upstream gpu` if you use the GPU setup). If this throws an error that 'upstream' does not appear to be a git repository, configure the upstream repository first:

        $ git remote add upstream https://github.com/biigle/biigle.git

    Check the [releases](https://github.com/biigle/biigle/releases) page for specific updating instructions. In particular, you should check if the latest changes include modifications to the `build/.env.example` file. If yes, update your `build/.env` file with the new variables. The "full changelog" on the releases page can show which files have been changed between releases.

2. Get the newest versions of the Docker images:

         $ docker pull ghcr.io/biigle/app:latest
         $ docker pull ghcr.io/biigle/web:latest
         $ docker pull ghcr.io/biigle/worker:latest


3. Run `cd build && ./build.sh`. This will fetch and install the newest versions of the BIIGLE modules, according to the version constraints configured in `build.sh`. Again, you can do this on a separate machine, too (see above). In this case the images mentioned above are not required on the production machine.

4. If the update requires a database migration, do this:

    1. Put the application in maintenance mode: `./artisan down`.

    2. Do a database backup (see [below](#database-backup)).

5. Update the running Docker containers: `docker compose up -d`.

6. If the update requires a database migration, do this:

    1. Run the migrations `./artisan migrate`
    2. Turn off the maintenance mode: `./artisan up`

7. Run `docker image prune` to delete old Docker images that are no longer required after the update.

## Database Backup

In the default configuration, the BIIGLE database runs in a Docker container and is stored in a Docker volume. Even if the container is replaced, the volume and thus the database persists. Still, it is advisable to do separate database backups of a production instance. The easiest way to backup the database is through an SQL dump.

### Create a database dump

A database dump SQL file can be generated with the command:

    docker exec -i $(docker compose ps -q database) \
        pg_dump -U biigle -d biigle > biigle_db.sql

### Restore a database dump

An SQL dump can be restored to an empty database with the command:

    cat biigle_db.sql | docker exec -i $(docker compose ps -q database) \
        psql -U biigle biigle

### Separate feature vectors

The database also stores feature vectors of certain items (e.g. annotations), which can make the database very large. Since feature vectors could also be recomputed from the (other) information in the database and the original image/video files, they can be backed up separately (and less frequently).

Create a database backup excluding the feature vectors with the command:

    docker exec -i $(docker compose ps -q database) \
        pg_dump --exclude-table-data "*_feature_vectors" -U biigle -d biigle \
        > biigle_db.sql

Create a database backup that only includes feature vectors with the command:

    docker exec -i $(docker compose ps -q database) \
         pg_dump --insert --on-conflict-do-nothing --data-only \
         --table "*_feature_vectors" -U biigle -d biigle \
         > biigle_vector_db.sql

To restore the backups, run the command of the [previous section](#restore-a-database-dump) first with `biigle_db.sql` and then with `biigle_vector_db.sql`. The second command can take a while as it uses a slower method to insert data that skips feature vectors of items that no longer exist in the other tables.


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
docker compose logs [service]
```

This shows the log file of the `[service]` service. You can use `--tail=[n]` to show only the last `[n]` lines of the log file and `-f` to follow the log file in real time.

### Restart all services

```bash
docker compose restart
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
docker compose up -d --scale worker=[n]
```

Set the number of worker containers running in parallel to `[n]`. If you want this to persist, set `scale: [n]` for the worker service in `docker-compose.yaml`.
