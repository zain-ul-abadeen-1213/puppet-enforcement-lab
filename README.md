# Puppet — Configuration Enforcement Lab

A serverless **Puppet** lab: one manifest (`manifests/web.pp`) declares the desired state of an nginx web server — package, site config, index page, `/etc/motd`, a `deploy` user, and the service — and `puppet apply` enforces it. The centrepiece is a **drift test**: the page and motd were deliberately vandalised by hand and the service was stopped; a single `puppet apply` restored everything on its own.

Publisher: **Zain Tech Automation Solutions** — Automate. Accelerate. Achieve.

## Status

**Complete — verified by an actual run, including the drift test** (see "Verified run" below).

## How it works

`manifests/web.pp` declares 6 resources:

- `package { 'nginx': }` — nginx installed
- `file { '/etc/nginx/sites-available/default': }` — the site config, with `require => Package['nginx']` and `notify => Service['nginx']` (a config change refreshes the service)
- `file { '/var/www/html/index.html': }` — the branded index page
- `file { '/etc/motd': }` — a warning that the machine is Puppet-managed
- `user { 'deploy': }` — a deploy user with bash shell and a home directory
- `service { 'nginx': }` — running and enabled

## Run it yourself

```bash
puppet parser validate manifests/web.pp          # syntax check
sudo puppet apply --noop manifests/web.pp        # dry run: report only, changes nothing
sudo puppet apply manifests/web.pp               # enforce the state
curl http://localhost
```

## Tech stack

Puppet Open Source 9.0.0-rc1 (`puppet apply`, serverless) · nginx · Kali Linux 2026.3

## Free / honesty note

Puppet Open Source was used — completely free. Puppet Enterprise is the paid product and was **not** used. The serverless `puppet apply` route was chosen deliberately: a full `puppetserver` is too heavy for this 4.6 GB RAM VM and is not needed to learn manifests, resources and enforcement.

## What I learned

- A **manifest** declares resources with their desired state; Puppet compares reality with the declaration and fixes only the differences.
- **Drift** is when a machine's real state quietly moves away from the declared state (hand edits, stopped services). **Enforcement** is Puppet pulling it back on the next apply.
- `--noop` is a safe dry run: it compiles the catalog and reports what *would* change, changing nothing — always run it before a real apply.
- `require` orders resources (package before files), and `notify` restarts a service when a file it depends on changes.

## Challenges faced (and fixed)

- Puppet 9 on Kali warns `Found multiple default providers for service: init, systemd; using init` — the service still started/stopped correctly under systemd, verified with `systemctl status` and `systemctl is-active`; the warning is cosmetic for this lab.
- During the drift test, `systemctl stop nginx` printed `Failed to allocate directory watch: Too many open files` on this small VM — the stop still took effect (curl confirmed the site was down), so the test proceeded.

## Verified run

Environment: Kali Linux 2026.3 VM · Puppet 9.0.0-rc1 at `/usr/bin/puppet`

**Syntax + dry run:**

```
puppet parser validate manifests/web.pp     # passed, no errors
sudo puppet apply --noop manifests/web.pp
Notice: Compiled catalog for kali in environment production in 5.27 seconds
Notice: /Stage[main]/Main/File[/etc/nginx/sites-available/default]/content: content changed '{sha256}...' to '{sha256}...' (noop)
Notice: /Stage[main]/Main/File[/var/www/html/index.html]/content: content changed '{sha256}...' to '{sha256}...' (noop)
Notice: /Stage[main]/Main/File[/etc/motd]/content: content changed '{sha256}...' to '{sha256}...' (noop)
Notice: /Stage[main]/Main/User[deploy]/ensure: created (noop)
Notice: Applied catalog in 4.33 seconds
```

**First real apply** — `sudo puppet apply manifests/web.pp`: all resources applied; `systemctl status nginx` showed the service started by the run, and:

```
$ curl http://localhost
<!DOCTYPE html><html><head><title>Zain Tech Automation Solutions</title></head><body><h1>Zain Tech Automation Solutions</h1><p>Ye page Puppet manifest se lagi hai aur Puppet hi ise hamesha aisi hi rakhega.</p><p>Automate. Accelerate. Achieve.</p></body></html>

$ id deploy
uid=1004(deploy) gid=1004(deploy) groups=1004(deploy)

$ sudo puppet apply --noop manifests/web.pp   # clean: zero changes reported
```

**Drift test** — damage done by hand:

```
echo 'HAATH SE BADLI HUI PAGE - ye ghalat hai' | sudo tee /var/www/html/index.html
echo 'badli hui motd' | sudo tee /etc/motd
sudo systemctl stop nginx
curl http://localhost
curl: (7) Failed to connect to localhost:80 ... Could not connect to server
```

**Enforcement** — one command, `sudo puppet apply manifests/web.pp`, and afterwards:

```
$ cat /var/www/html/index.html   # original Puppet page restored verbatim
$ cat /etc/motd                  # original Puppet-managed motd restored verbatim
$ sudo systemctl is-active nginx
active
$ curl http://localhost          # Puppet page served again
```

**Final apply** (no drift): `Notice: Applied catalog in 2.03 seconds` — no change Notices at all; the machine already matched the manifest.
