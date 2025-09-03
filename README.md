# Linux Mint Bootc

Experiment to see if Bootc could work on Linux Mint. It requires a lot of workarounds, though!


## Building

In order to get a running ubuntu-bootc system you can run the following steps:
```shell
just build-containerfile # This will build the containerfile and all the dependencies you need
just generate-bootable-image # Generates a bootable image for you using bootc!
```

Then you can run the `bootable.img` as your boot disk in your preferred hypervisor.

# Fixes & Notes

A complete X11 session is a bit tricky to figure out, but if you want to get to the state the screenshot is in, follow these steps:

- `/tmp` is read only for some reason, do `mount -t tmpfs tmpfs /tmp` once your are on the image so that X11 can start up via the `.X11-UNIX` socket
- Once you've created your user, with `useradd (name) && usermod -a -G sudo (name) && passwd (name)`, create your user's directories and add permissions to it (`chown (user):(user) /var/home/(user)`)
- Start a TTY under that user, then write the following to `.xinitrc`: `dbus-run-session cinnamon-session`, running `startx` will work and you'll be dropped into a Cinnamon session like the desktop.
- `mount /dev/vda2 /sysroot/boot` - You can mount the ESP under `/sysroot/boot` so that `bootc status` works.
