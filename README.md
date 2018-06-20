# BIIGLE Distribution

This is the production setup of BIIGLE.

## Installation

Perform these steps on the machine that should run BIIGLE.

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

4. If you use an external database system (as is recommended), remove the `database` block from `docker-compose.yaml` and configure the `DB_*` variables in `build/.env`.

5. Put the SSL keychain (`fullchain.pem`) and private key (`privkey.pem`) to `certificate/`.

6. Now build the Docker images for production: `cd build && ./build.sh`. You can build the images on a separate machine, too, and transfer them to the production machine using [`docker save`](https://docs.docker.com/engine/reference/commandline/save/) and [`docker load`](https://docs.docker.com/engine/reference/commandline/load/).

7. Go back and run the containers: `cd .. && docker-compose up -d`.

8. Apply the database migrations: `docker-compose exec app php artisan migrate`.

9. Create the first user: `docker-compose exec app php artisan user:new`.

## Updating

1. Get the newest versions of the `biigle/app`, `biigle/web` and `biigle/worker` images.

2. Run `cd build && ./build.sh`. This will fetch and install the newest versions of the BIIGLE modules, according to the version constraints configured in `build.sh`. Again, you can do this on a separate machine, too (see above). In this case the images mentioned above are not required on the production machine.

3. If the update requires a database migration, do this:
   1. Put the application in maintenance mode: `docker-compose exec app php artisan down`.
   2. Do a database backup. This might look along the lines of: `pg_dump -h localhost -U biigle_user -d biigle_db > biigle_db.dump`

4. Update the running Docker containers: `docker-compose up -d`.

5. If the update requires a database migration, do this:
   1. Run the migrations `docker-compose exec app php artisan migrate`
   2. Turn off the maintenance mode: `docker-compose exec app php artisan up`
