# Installation of a new BIIGLE instance

This guide describes how to install BIIGLE on a new machine.

## Setup


This is an example setup of a machine that should run BIIGLE. It is based on a clean install of Ubuntu 20.04 with the user `ubuntu`.

1. Run `sudo apt update && sudo apt upgrade`.

2. [Install Docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/#set-up-the-repository). If you are in a cloud environment, add the repository like this so it is not deleted when a new machine is booted:

        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
    

3. Run `sudo usermod -aG docker ubuntu` to add the ubuntu user to the docker group.

4. [Install Docker Compose](https://docs.docker.com/compose/install/#install-as-a-container) as a Docker container.

5. Log out of the machine and back in.

Now you can follow the installation instructions below to install BIIGLE on the machine.

## Installation

Perform these steps on the machine that should run BIIGLE.

1. Clone the [`biigle/biigle`](https://github.com/biigle/biigle) repository to the directory where BIIGLE should be installed (e.g. `/mnt/biigle` or `/var/biigle`).

1. Create a user for BIIGLE and find out the user and group ID:

        $ sudo useradd biigle -U
        $ id -u biigle
        <user_id>
        $ id -g biigle
        <group_id>

2. Change the owner of the `storage` directory:
   
        sudo chown -R biigle:biigle storage/

2. Move `.env.example` to `.env`.

3. Now set the configuration variables in `.env`:

    - `USER_ID` should be `<user_id>`.
    - `GROUP_ID` should be `<group_id>`.

2. Move `build/.env.example` to `build/.env`.

3. Now set the build configuration variables in `build/.env`:

    - `GITHUB_OAUTH_TOKEN` is an [OAuth token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) of your GitHub account.
    - `APP_KEY` is the secret encryption key. Generate one with: `head -c 32 /dev/urandom | base64`. Then set `APP_KEY=base64:<your_key>`.
    - `APP_URL` is `https://<your_domain>`. For a local setup without SSL (see below), use `http://localhost`.
    - `ADMIN_EMAIL` is the email address of the administrator(s) of the application.

5. Put the SSL keychain (`fullchain.pem`) and private key (`privkey.pem`) to `certificate/`. See [here](http://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate) for a description of the required contents of the keychain file. For a local setup no SSL certificate may be required. Update the `web` service in [`docker-compose.yaml`](https://github.com/biigle/biigle/blob/master/docker-compose.yaml) as described by the comments in this case.

6. Now build the Docker images for production: `cd build && ./build.sh`. You can build the images on a separate machine, too, and transfer them to the production machine using [`docker save`](https://docs.docker.com/engine/reference/commandline/save/) and [`docker load`](https://docs.docker.com/engine/reference/commandline/load/). `build.sh` also supports an optional argument to specify the version tag of the Docker images to build (e.g. `v2.8.0`). Default is `latest`.

7. Go back and run the containers: `cd .. && docker compose up -d`.

8. Apply the database migrations: `./artisan migrate`.

9. Create the first user: `./artisan user:new`.

## Configuration

The default configuration of the production setup includes a `local` storage disk that can be used to store images and videos for new volumes (in `build/config/filesystems.php`). You can configure more storage disks as well. These storage disks are then offered as an alternative to remote volumes in BIIGLE.

Storage disks must be explicitly allowed for different user roles in BIIGLE. By default, only instance admins are allowed to use the `local` storage disk for new volumes. This can be changed with the `VOLUME_ADMIN_STORAGE_DISKS` and `VOLUME_EDITOR_STORAGE_DISKS` variables in the `build/.env` file. Each variable contains a comma-separated list of storage disk names that should be allowed for the respective user role. If the variable is empty, no storage disk is allowed.
