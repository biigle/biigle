# Module installation

The most important BIIGLE modules are already included in the distribution configuration of [`biigle/biigle`](https://github.com/biigle/biigle). In some cases you may want to install additional modules, though. Official BIIGLE modules come with installation instructions in their readme. However, these are always written for a "standard" installation of a PHP package and not for the Docker setup of `biigle/biigle`. The installation instructions of a module have to be adapted for an installation based on the `biigle/biigle` setup.

The installation of a BIIGLE module usually follows the same steps: Require the module using [Composer](https://getcomposer.org/), add the module service provider to the core configuration, run the command to publish module assets, update environment variables and/or the module configuration. For `biigle/biigle`, these steps can be performed as follows:

## 1. Require the module using Composer

In `biigle/biigle`, modules are installed in the [`build.dockerfile`](https://github.com/biigle/biigle/blob/master/build/build.dockerfile) file. To require a new module (or any other PHP package), add it to the [`composer require`](https://github.com/biigle/biigle/blob/08bae6f5a6f81b005bdf6bc0a38ad4c8a789e23d/build/build.dockerfile#L38) command arguments in this file. The default modules that are installed use Docker build arguments to specify their version constraints. These can be configured in the [`build.sh`](https://github.com/biigle/biigle/blob/08bae6f5a6f81b005bdf6bc0a38ad4c8a789e23d/build/build.sh#L11) file.

## 2. Add the module service provider

Module service provider classes are added to the core configuration with `sed` file modification commands. Add te service provider class to the [list of modification commands](https://github.com/biigle/biigle/blob/08bae6f5a6f81b005bdf6bc0a38ad4c8a789e23d/build/build.dockerfile#L48) to include the module that should be installed.

## 3. Publish module assets

The command to publish module assets is [already included](https://github.com/biigle/biigle/blob/08bae6f5a6f81b005bdf6bc0a38ad4c8a789e23d/build/build.dockerfile#L58) in the `build.dockerfile` file.

## 4. Update environment variables

New environment variables can be added to the `build/.env` file. This file is used when the Docker images of your BIIGLE instance are built.

## 5. Update the module configuration

Module configuration files can be added to the [`build/config`](https://github.com/biigle/biigle/tree/master/build/config) directory. You can also modify existing configuration files there (e.g. `filesystems.php`). When you add a new configuration file, also add a corresponding [`COPY` command](https://github.com/biigle/biigle/blob/08bae6f5a6f81b005bdf6bc0a38ad4c8a789e23d/build/build.dockerfile#L68) to `build.dockerfile`.
