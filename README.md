# Free Debian-based web kiosk

This is a project that creates a Debian-based locked-down browser kiosk
system. The primary content is the ansible playbook and roles that configure
the system for kiosk behavior. These can be executed on an installed Debian 12
system to kioskify it. Alternately, an installer iso can be built that installs
Debian and configures it before first boot.

## Running on an existing system

Install ansible, clone this repo, and execute the playbook:
```
$ sudo apt install -y ansible git
$ git clone https://github.com/kk7ds/freekiosk
$ cd freekiosk
$ ./runlocal.sh 
```

In reality, you will want to configure the kiosk behavior, so generate a
settings override file and edit it before executing the playbook:
```
$ cat roles/*/defaults/*.yaml > settings.yaml
```

## Building the installer

For this you will need the Debian 12 netinst iso locally. Generate the new
iso from the existing one:
```
$ ./installer/mkiso.sh /path/do/debian-netinst.iso
```

The resulting `kiosk-debian-netinst.iso` will be built. Boot this like you
would any other ISO (i.e. probably write it to a USB drive). The install
is super opinionated, designed for UEFI systems only, and *will destroy the
existing system without asking*.

To configure the installation, create and edit a `settings.yaml` file per
above, and put it in the root of the FAT partition of the ISO file (visible
after you write it to the USB drive). The installer will run the playbook at
the end of the process before the first boot.

## Details

This kiosk is based on Wayland/Weston, with Chromium as the browser. The
browser is configured to be very locked down (the user cannot change settings,
download things, or install extensions). They should not be able to do anything
other than run the browser. If they quit the browser it will respawn. The
chromium policy is set to, by default, deny everything except for the home
URL, and you should punch additional holes to allow the user to get to specific
things you want.

For example, in `settings.yaml`:
```
kiosk_home_url: https://example.com/landing.html
kiosk_allow_url:
  - .example.com
  - .other.com
kiosk_block_url:
  - https://example.com/private/*
  - "*"```
```
