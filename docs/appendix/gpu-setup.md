**These instructions are from 2020 and slightly outdated now. They will be [updated](https://github.com/biigle/biigle/issues/26).**

This is an example setup of a machine that should run GPU computing for BIIGLE. It is based on a clean install of Ubuntu 18.04 with the user `ubuntu` and an NVIDIA GPU.

1. Run `sudo apt update && sudo apt upgrade`.

2. Install the GPU drivers (adapted from the [TensorFlow instructions](https://www.tensorflow.org/install/gpu#ubuntu_1804_cuda_10)):

        $ wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
        $ sudo dpkg -i cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
        $ rm cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
        $ sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
        $ sudo apt-get update
        $ sudo apt-get install -y --no-install-recommends cuda-drivers

3. Reboot the machine to activate the driver.

2. [Install Docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/#set-up-the-repository). If you are in a cloud environment, add the respository like this so it is not deleted when a new machine is booted:

        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

6. Install [nvidia-docker2](https://github.com/NVIDIA/nvidia-docker#ubuntu-140416041804-debian-jessiestretch) (Docker Compose does no support the newest version of `nvidia-container-toolkit` [yet](https://github.com/docker/compose/issues/6691) so we install the older version):

        $ distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        $ curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
        $ curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

        # install package maintainers version of /etc/docker/daemon.json
        $ sudo apt-get update && sudo apt-get install -y --no-install-recommends nvidia-docker2

7. Run `sudo systemctl restart docker`.

7. Run `sudo usermod -aG docker ubuntu` to add the ubuntu user to the docker group.

8. [Install Docker Compose](https://docs.docker.com/compose/install/#install-as-a-container) as a Docker container.

5. Log out of the machine and back in.

Now you can follow the [installation instructions](/installation#installation) to install BIIGLE on the machine.
