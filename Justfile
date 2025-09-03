build-containerfile:
    sudo podman build \
        -t linuxmint-bootc:latest .

bootc *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -it \
        -e RUST_LOG=debug \
        -v /sys/fs/selinux:/sys/fs/selinux \
        -v /var/lib/containers:/var/lib/containers \
        -v /dev:/dev \
        -v /tmp:/data \
        --security-opt label=type:unconfined_t \
        linuxmint-bootc:latest bootc {{ARGS}}

generate-bootable-image:
    #!/usr/bin/env bash
    if [ ! -e /tmp/bootable.img ] ; then
        fallocate -l 20G /tmp/bootable.img
    fi
    just bootc install to-disk --composefs-native --via-loopback /data/bootable.img --filesystem ext4 --wipe

