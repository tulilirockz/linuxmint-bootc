FROM docker.io/linuxmintd/mint22.1-amd64:latest

COPY files/37composefs/ /usr/lib/dracut/modules.d/37composefs/
COPY files/ostree/prepare-root.conf /usr/lib/ostree/prepare-root.conf

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y && \
    apt upgrade -y && \
    apt install -y libzstd-dev libssl-dev pkg-config curl git build-essential meson libfuse3-dev && \
    apt build-dep ostree -y

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/ostreedev/ostree.git ostree && \
    cd ostree && \
    git submodule update --init --recursive && \
    env NOCONFIGURE=1 ./autogen.sh && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --libdir=/usr/lib \
        --mandir=/usr/share/man \
        --infodir=/usr/share/info \
        --localstatedir=/var \
        --disable-silent-rules \
        --enable-gtk-doc \
        --with-curl \
        --with-openssl \
        --without-soup \
        --with-dracut=yesbutnoconf && \
    make && \
    make install && \
    cp -vf /usr/lib/libostree* /lib/$(arch)-linux-gnu

RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/bootc-dev/bootc.git bootc && \
    cd bootc && \
    git fetch --all && \
    git switch origin/composefs-backend -d && \
    /root/.cargo/bin/cargo build --release --bins && \
    install -Dpm0755 -t /usr/bin ./target/release/bootc && \
    install -Dpm0755 -t /usr/bin ./target/release/system-reinstall-bootc && \
    install -Dpm0755 -t /usr/bin ./target/release/bootc-initramfs-setup

RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/p5/coreos-bootupd.git bootupd && \
    cd bootupd && \
    git fetch --all && \
    git switch origin/sdboot-support -d && \
    /root/.cargo/bin/cargo build --release --bins --features systemd-boot && \
    install -Dpm0755 -t /usr/bin ./target/release/bootupd && \
    ln -s ./bootupd /usr/bin/bootupctl

RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/containers/composefs.git composefs && \
    cd composefs && \
    git fetch --all && \
    meson setup build --prefix=/usr --default-library=shared -Dfuse=enabled && \
    ninja -C build && \
    ninja -C build install

RUN apt install -y \
  dracut \
  podman \
  linux-image-generic \
  linux-firmware \
  systemd \
  btrfs-progs \
  e2fsprogs \
  xfsprogs \
  udev \
  cpio \
  zstd \
  binutils \
  dosfstools \
  conmon \
  crun \
  netavark \
  skopeo \
  dbus \
  fdisk \
  systemd-boot*

RUN cp /usr/bin/bootc-initramfs-setup /usr/lib/dracut/modules.d/37composefs

RUN echo "$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" > kernel_version.txt && \
    dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$(cat kernel_version.txt)"  "/usr/lib/modules/$(cat kernel_version.txt)/initramfs.img" && \
    cp /boot/vmlinuz-$(cat kernel_version.txt) "/usr/lib/modules/$(cat kernel_version.txt)/vmlinuz" && \
    rm kernel_version.txt

# If you want a desktop :)
RUN apt install -y mint-meta-cinnamon

RUN cp -vf /usr/lib/libostree* /lib/$(arch)-linux-gnu

RUN tee /etc/containers/policy.json <<EOF
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ]
}
EOF

RUN apt install -y xinit lightdm mate-terminal gnome-terminal flatpak vim mintsystem

# Alter root file structure a bit for ostree
RUN mkdir -p /boot /sysroot /var/home && \
    rm -rf /var/log /home /root /usr/local /srv && \
    ln -s /var/home /home && \
    ln -s /var/roothome /root && \
    ln -s /var/usrlocal /usr/local && \
    ln -s /var/srv /srv

# Setup a temporary root passwd (changeme) for dev purposes
# TODO: Replace this for a more robust option when in prod
RUN usermod -p '$6$AJv9RHlhEXO6Gpul$5fvVTZXeM0vC03xckTIjY8rdCofnkKSzvF5vEzXDKAby5p3qaOGTHDypVVxKsCE3CbZz7C3NXnbpITrEUvN/Y/' root

# Necessary labels
LABEL containers.bootc 1
