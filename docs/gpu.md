# Setup of BIIGLE with GPU computing

Some BIIGLE modules, such as [`biigle/maia`](https://github.com/biigle/maia), may require GPU computing resources. This guide describes how to set up a BIIGLE instance with access to GPU computing resources by setting up a working instance with the `biigle/maia` module.

## Prerequisites

You need the NVIDIA GPU drivers, Docker, nvidia-docker2 and Docker Compose installed on the GPU machine(s) that should perform GPU computing. You can find example installation instructions [here](/appendix/gpu-setup).

## Basic Concepts

BIIGLE can be flexibly configured to use GPU computing resources in various scenarios. The GPU can be located on the same machine on which the BIIGLE instance is running ([Same Host GPU](#same-host-gpu)) or the GPU(s) can be located on (an)other machine(s) ([Remote Host GPU](#remote-host-gpu)).

## Same Host GPU

This is the simplest setup. In this scenario, the GPU is available on the same host that runs the BIIGLE instance. BIIGLE makes use of special queues for GPU jobs and responses to distinguish between regular jobs and those that should be executed on a GPU. This requires a dedicated queue worker for GPU jobs.

The `gpu` branch of [`biigle/biigle`](https://github.com/biigle/biigle/tree/gpu) includes the configuration for `biigle/maia` and same host GPU computing. Use this branch to [install](/installation#installation) your new BIIGLE instance. If you already have a BIIGLE instance set up, merge this branch in your existing configuration and then perform the [updating steps](/maintenance#updating) (including database migrations).

## Remote Host GPU

In this scenario, the GPU(s) are available on different machines than the host that runs the BIIGLE instance. Start with the `gpu` branch of [`biigle/biigle`](https://github.com/biigle/biigle/tree/gpu) as described in the [same host GPU setup](#same-host-gpu).

!!! warning "Important"
    The remote GPU machines need to be able to access the image and video files in the same way than the main BIIGLE instance. This could be achieved with a shared filesystem, an (S)FTP server, a cloud object storage service or with the exclusive use of remote volumes in your BIIGLE instance. You must update the `build/config/filesystems.php` file for this.

### 1. Update the cache configuration

The job queue is managed by the `cache` service. In order for other machines to access the cache, it needs to be accessible outside of the private network that is established between the service Docker containers of BIIGLE. Update the `cache` service in the `docker-compose.yaml` file as follows:

```yml
cache:
  image: redis:3.0-alpine
  restart: always
  command: redis-server --requirepass $REDIS_PASSWORD
  environment:
    - "REDIS_PASSWORD=${REDIS_PASSWORD}"
  ports:
    - 6379:6379
```

Now the cache can be accessed from other machines.

### 2. Update the environment

Add `REDIS_PASSWORD=mypassword` to the `.env` file and update the respective line in the `build/.env` file. Replace `mypassword` with a strong password of your choosing (e.g. generated with `pwgen 30 1`). In addition, set the `REDIS_HOST` variable in `build/.env` to the IP address of the host that runs the BIIGLE instance.

### 3. Configure a GPU worker

Since in this scenario the `gpu-worker` services run on different machines than the BIIGLE main application, remove the service from the `docker-compose.yaml` file. Next, create a new `docker-compose.gpu.yaml` file with the following contents:

```yml
services:
  gpu-worker:
    image: biigle/gpu-worker-dist
    user: ${USER_ID}:${GROUP_ID}
    runtime: nvidia
    restart: always
    scale: 1
    volumes:
      - ./storage:/var/www/storage
    init: true
    command: "php -d memory_limit=1G artisan queue:work --queue=gpu --sleep=5 --tries=1 --timeout=0"
```

### 4. Deploy a GPU worker

To deploy a new GPU worker, first [install and build](/installation#installation) (or [update](/maintenance#updating)) your main BIIGLE instance (with the modifications described above). Then perform these steps on the new GPU machine:

1. Transfer the `biigle/gpu-worker-dist` Docker image the the new GPU machine (e.g. using `docker save` and `docker load`).

2. Copy the files of your `biigle/biigle` setup to the GPU machine (including the `.env` file). You can exclude the `build` and `certificate` directories if you like.

3. Update the `USER_ID` and `GROUP_ID` variables in `.env` if necessary.

4. Run `docker-compose -f docker-compose.gpu.yaml up -d` to start the GPU worker.

This can be done with multiple GPU machines to enable parallel processing of GPU jobs.
