# Setup of BIIGLE with GPU computing

Some BIIGLE modules, such as [`biigle/maia`](https://github.com/biigle/maia), may require GPU computing resources. This guide describes how to set up a BIIGLE instance with access to GPU computing resources by setting up a working instance with the `biigle/maia` module.

## Prerequisites

You need the NVIDIA GPU drivers, Docker, nvidia-docker2 and Docker Compose installed on the GPU machine(s) that should perform GPU computing. You can find example installation instructions [here](/appendix/gpu-setup).

This guide assumes that you already have a working BIIGLE instance. Head over to the [installation instructions](/installation) to get started if you don't have a running instance. However, use the [setup instructions for a GPU machine](/appendix/gpu-setup) instead of the regular setup instructions of the installation guide.


## Basic Concepts

BIIGLE can be flexibly configured to use GPU computing resources in various scenarios. The GPU can be located on the same machine on which the BIIGLE instance is running ([Same Host GPU](#same-host-gpu)), the GPU can be located on another machine ([Single Remote Host GPU](#single-remote-host-gpu)) or many GPUs can be located on many remote machines ([Many Remote Host GPUs](#many-remote-host-gpus)).

To enable the flexible configuration, BIIGLE makes extensive use of [job queues](https://laravel.com/docs/6.x/queues). Jobs that should be executed on a GPU are submitted to a special "GPU" queue. Once a job is finished, the results are submitted back to a special "GPU Response" queue. Read on for a detailed description of the setup for the different scenarios:

- [Same Host GPU](#same-host-gpu)

- [Single Remote Host GPU](#single-remote-host-gpu)

- [Many Remote Host GPUs](#many-remote-host-gpus)

## Same Host GPU

This is the simplest setup. In this scenario, the GPU is available on the same host that runs the BIIGLE instance. However, BIIGLE still makes use of special queues for GPU jobs and responses to distinguish between regular jobs and those that should be executed on a GPU. This requires a dedicated queue worker for GPU jobs. Follow these steps for the setup:

### 1. Install `biigle/maia`

To install the `biigle/maia` in your BIIGLE instance, take a look at the [installation instructions](https://github.com/biigle/maia#installation). Since we are working with a BIIGLE production configuration based on [`biigle\distribution`](https://github.com/biigle/distribution) the installation works as follows:

1. Add `biigle/maia` to the [list of Composer requirements](https://github.com/biigle/distribution/blob/5a7f58e1d9e1778b3ad753d19bc7f9f86a53c4b0/build/build.dockerfile#L42) in `build.dockerfile`.

2. Append the following line to the [modification command](https://github.com/biigle/distribution/blob/5a7f58e1d9e1778b3ad753d19bc7f9f86a53c4b0/build/build.dockerfile#L56) for the service providers array:


        && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Maia\\MaiaServiceProvider::class,' config/app.php


3. Configure the [storage disks (step 4)](https://github.com/biigle/maia#in-your-biigle-application-instance) required by `biigle/maia` in [`filesystems.php`](https://github.com/biigle/distribution/blob/master/build/config/filesystems.php).

### 2. Configure `biigle/maia`

In this scenario `biigle/maia` should submit jobs that should be executed on a GPU to the `gpu` queue of the `gpu` connection. We will configure the `gpu` connection in the next step. To implement the configuration, add this to the `build/.env` file:

```
MAIA_REQUEST_QUEUE=gpu
MAIA_REQUEST_CONNECTION=gpu
```

Similarly, `biigle/maia` should submit GPU results to the `default` queue of the `redis` connection. Again, append this to `build/.env`:

```
MAIA_RESPONSE_QUEUE=default
MAIA_RESPONSE_CONNECTION=redis
```

Finally, `biigle/maia` has some configuration options that can be adjusted to the computing capabilities of the machine and GPU. `MAIA_AVAILABLE_BYTES` can be set to the available memory of the GPU. As a rule of thumb, you should set this option to 1 GB less than the actual size of the GPU memory, as it can't be used in its entirety. `MAIA_MAX_WORKERS` can be set to the number of CPU cores that MAIA is allowed to use during processing. As BIIGLE runs on the same machine, you should spare some cores for this. An example configuration for a machine with 16 GB GPU memory and 14 CPU cores looks like this:

```
MAIA_AVAILABLE_BYTES=15E+9
MAIA_MAX_WORKERS=10
```

### 3. Configure the queue connections

By default, queued jobs in Laravel expire after a certain time and are assumed to have failed. As queued jobs usually run only a few seconds, the expiration time is set rather low. However, MAIA jobs can run for many hours, so we have to increase the expiration time for these jobs. Since we want to do this independently of the regular queued jobs, we configure a new `gpu` queue connection. To do this, add the file [`build/config/queue.php`](/appendix/queue.php) to your setup. Then add the following line to the [custom configs](https://github.com/biigle/distribution/blob/5d6c08fcc8aad92211b56b3cb1b2e665e980ae94/build/build.dockerfile#L82-L83) in `build.dockerfile`:

```dockerfile
COPY config/queue.php /var/www/config/queue.php
```


### 4. Add a GPU Queue Worker

Now we have to add a new queue worker to your production setup, which is actually able to process jobs on the GPU. Create the file `build/gpu-worker.dockerfile` with the following content:

```dockerfile
FROM biigle/build-dist AS intermediate

FROM docker.pkg.github.com/biigle/gpus/gpus-worker

COPY --from=intermediate /etc/localtime /etc/localtime
COPY --from=intermediate /etc/timezone /etc/timezone
COPY --from=intermediate /var/www /var/www
```

Then add the following line to [`build/build.sh`](https://github.com/biigle/distribution/blob/5a7f58e1d9e1778b3ad753d19bc7f9f86a53c4b0/build/build.sh#L36):

```sh
docker build -f gpu-worker.dockerfile -t biigle/gpu-worker-dist:$VERSION .
```

Finally, add the new queue worker service to the file [`docker-compose.yml`](https://github.com/biigle/distribution/blob/master/docker-compose.yaml):

```yaml
gpu-worker:
   image: biigle/gpu-worker-dist
   user: ${USER_ID}:${GROUP_ID}
   runtime: nvidia
   restart: always
   depends_on:
      - cache
   volumes_from:
      - app
   init: true
   command: "php -d memory_limit=1G artisan queue:work --queue=gpu --sleep=5 --tries=1 --timeout=0"
```

This service will start a Docker container with access to the GPU which processes all jobs that are submitted to the new `gpu` queue.

### 5. Finish the Installation

To finish the setup, perform the [updating steps](/maintenance#updating) (including database migrations) for your BIIGLE instance. This will build and start the new GPU worker service, as well as apply the database migrations of `biigle/maia`.

## Single Remote Host GPU

This is probably the most common scenario, where the GPU is available on a different machine than the one that runs the BIIGLE instance. Here, too, communication between the machines happens through job queues. To enable queued jobs being sent from one host to another, we developed the [`biigle/laravel-remote-queue`](https://github.com/biigle/laravel-remote-queue) package. Follow these steps for the setup:

### 1. Install `biigle/maia`

Install `biigle/maia` in your BIIGLE instance as described  [above](#1-install-biiglemaia). You don't have to configure the module here in this scenario.

### 2. Install `biigle/laravel-remote-queue`

`biigle/laravel-remote-queue` is a special queue driver which enables the submission of queued jobs to another machine. In this scenario, the driver is used for the communication between the BIIGLE instance and the GPU machine. The installation in your BIIGLE instance works as follows:

1. Add `biigle/laravel-remote-queue` to the [list of Composer requirements](https://github.com/biigle/distribution/blob/5a7f58e1d9e1778b3ad753d19bc7f9f86a53c4b0/build/build.dockerfile#L42) in `build.dockerfile`.

2. Add the following configuration options to the `build/.env` file:


        REMOTE_QUEUE_LISTEN=true
        REMOTE_QUEUE_ACCEPT_TOKENS=<token1>

      You can generate the random string for `<token1>` with the command `head -c 32 /dev/urandom | base64`.

3. Create the file [`build/config/queue.php`](/appendix/queue2.php). Append the following line to [`build.dockerfile`](https://github.com/biigle/distribution/blob/5a7f58e1d9e1778b3ad753d19bc7f9f86a53c4b0/build/build.dockerfile#L80):


        COPY config/queue.php /var/www/config/queue.php

      Then add this to the `build/.env` file:

        QUEUE_GPU_TOKEN=<token2>
        QUEUE_GPU_URL=http://<gpu-ip>/api/v1/remote-queue/

      You can generate the random string for `<token2>` in the same way than `<token1>` of the previous step. `<gpu-ip>` should be the IP address of the GPU machine.

### 3. Update the BIIGLE instance

To finish the installation of `biigle/maia` and `biigle/laravel-remote-queue`, perform the [updating steps](/maintenance#updating) (including database migrations) for your BIIGLE instance.

### 4. Set up `biigle/gpus-distribution`

[`biigle/gpus-distribution`](https://github.com/biigle/gpus-distribution) is the production setup for the BIIGLE "GPU server" which is meant to run on the machine with the GPU. The job of the GPU server is to accept queued jobs that should run on a GPU and to return the results as response jobs. This production setup already comes with `biigle/maia` included.

Follow the [installation instructions](https://github.com/biigle/gpus-distribution#installation) to set up the GPU server on the machine with GPU. In step 6 of the instructions, set the following configuration options:

```
REMOTE_QUEUE_ACCEPT_TOKENS=<token2>
QUEUE_GPU_RESPONSE_URL=http://<biigle-ip>/api/v1/remote-queue/
QUEUE_GPU_RESPONSE_TOKEN=<token1>
```

`<token1>` and `<token2>` are the random strings from the previous steps. `<biigle-ip>` is the IP address of your machine running the BIIGLE instance. In addition, configure the options `MAIA_MAX_WORKERS` and `MAIA_AVAILABLE_BYTES` as described [above](#2-configure-biiglemaia).

!!! warning "Important"
      The GPU server needs to be able to access the image files in the same way than the BIIGLE instance. This could be achieved with a shared filesystem, an (S)FTP server, a cloud object storage service or with the exclusive use of remote volumes in your BIIGLE instance. To enable the GPU server to access the same storage location for images than the BIIGLE instance, copy the storage disk configuration of [`filesystems.php`](https://github.com/biigle/distribution/blob/master/build/config/filesystems.php) to your production setup of the GPU server and append the following line to [`build.dockerfile`](https://github.com/biigle/gpus-distribution/blob/32dbf32617fe245834413f41fa357dec61219520/build/build.dockerfile#L35) of the GPU server:

        COPY config/filesystems.php /var/www/config/filesystems.php

## Many Remote Host GPUs

If you plan to make extensive use of GPU computing resources in BIIGLE, it's advisable to use more than a single GPU. In this scenario, the [`biigle/laravel-round-robin-queue`](https://github.com/biigle/laravel-round-robin-queue) package is used in addition to
[`biigle/laravel-remote-queue`](https://github.com/biigle/laravel-remote-queue) to distribute new queued GPU jobs evenly to many machines with GPU. Follow these steps for the setup:

### 1. Set up the machines

Configure your BIIGLE instance and each of the GPU machines as described in the [Single Remote Host GPU scenario](#single-remote-host-gpu). `biigle/gpus-distribution` needs to be installed on every GPU machine.

### 2. Install `biigle/laravel-round-robin-queue`

`biigle/laravel-round-robin-queue` is a special queue driver which handles the even distribution of queued jobs to a set of sub-queues. In this scenario, the driver is used to distribute GPU jobs evenly to the remote queues which are connected to the GPU machines. The installation in your BIIGLE instance works as follows:

1. Add `biigle/laravel-round-robin-queue` to the [list of Composer requirements](https://github.com/biigle/distribution/blob/5a7f58e1d9e1778b3ad753d19bc7f9f86a53c4b0/build/build.dockerfile#L42) in `build.dockerfile`.

2. Modify the file [`build/config/queue.php`](/appendix/queue2.php) and replace the existing `gpu` connection with the following new connections:

        'gpu-1' => [
           'driver' => 'remote',
           'queue' => 'default',
           'url' => env('QUEUE_GPU1_URL'),
           'token' => env('QUEUE_GPU_TOKEN'),
        ],

        'gpu-2' => [
           'driver' => 'remote',
           'queue' => 'default',
           'url' => env('QUEUE_GPU2_URL'),
           'token' => env('QUEUE_GPU_TOKEN'),
        ],

        'gpu' => [
           'driver' => 'roundrobin',
           'queue' => 'default',
           'connections' => ['gpu-1', 'gpu-2'],
        ],

      This assumes two remote hosts (`gpu-1` and `gpu-2`) with GPUs. Add more connections for more hosts.

3. Update the configuration options in the `build/.env` file:

        QUEUE_GPU1_URL=http://<gpu-1-ip>/api/v1/remote-queue/
        QUEUE_GPU2_URL=http://<gpu-2-ip>/api/v1/remote-queue/

      `<gpu-1-ip>` and `<gpu-2-ip>` are the IP addresses of the GPU machines, respectively. Add more variables if you use more machines.

### 3. Update the BIIGLE instance

To finish the installation of `biigle/laravel-round-robin-queue`, perform the [updating steps](/maintenance#updating) (without database migrations) for your BIIGLE instance.

That's it! New GPU jobs will now be processed on all configured GPU machines.
