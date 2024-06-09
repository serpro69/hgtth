# Hitchhiker's Guide To The Homelab

This is an attempt to organize *my* homelab setup under a single Infrastructure-as-Code repo. It provides a single entry-point to get up-and-running from a "base" OS installation, to a fully-working homelab cluster. My cluster is currently based on [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment/overview), but since it's just a "layer" on top of Debian, a lot of the configs here can be "applied" to Debian-like servers as well.

> [!WANING]
> This is my own setup and it may *NOT* be suitable for you.
> Do not trust and run the code blindly, but rather use it as an inspiration for your own homelabbing endeavours.
> I take no responsibility for your own actions, broken systems, and hours spent on debugging.
> Proceed with caution.

---

## Requirements

- <s>Terraform</s>
- Ansible

## Usage

### Post-Install

After installing Proxmox VE or provisioning a new VM, we need to create a user that will execute tha playbooks. 
The user needs ssh access and sudo rights.
To do this, there is an [`init.sh`](init.sh) script which can be used to create a new user with sudo and ssh access on the target host:

```bash
./init.sh <host>
```

### Ansible

Ansible is used to configure both the Hosts (PVE nodes) as well as Guests (VMs that reside on those nodes).

The entry-point to the configuration is in the [`main.yml`](ansible/main.yml) file.

To run the playbook:

- Add a `hosts.yml` file (See [`ansible/hosts_example.yml`](ansible/hosts_example.yml) for details.) to the root of [`ansible`](ansible) directory
- Run `cd ansible && ansible-playbook run main.yml` or `make main`

## TODO

- `base.yml`
  - ssh 
    - [ ] ensure sshd_config is OK from security perspective
      - comment out `PermitRootLogin yes`
      - comment out `PasswordAuthentication yes`
  - users
    - [ ] create `fortytwo` firefighter user on all hosts (pve and vm)
      - add authorized key to the user's ~/.ssh dir
      - password-less sudo access
