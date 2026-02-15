# Bacula File Daemon Installation Guide - RHEL 10 Hypervisors

**Document Version:** 1.0
**Date:** February 1, 2026
**Target Platform:** Red Hat Enterprise Linux 10
**Purpose:** Step-by-step installation and configuration of Bacula File Daemon on KVM hypervisors

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Installation Steps](#3-installation-steps)
4. [Configuration](#4-configuration)
5. [Service Management](#5-service-management)
6. [Firewall Configuration](#6-firewall-configuration)
7. [SSH Access Setup](#7-ssh-access-setup)
8. [Integration Testing](#8-integration-testing)
9. [Troubleshooting](#9-troubleshooting)
10. [Security Hardening](#10-security-hardening)
11. [Deployment Automation](#11-deployment-automation)
12. [Reference Commands](#12-reference-commands)

---

## 1. Overview

### 1.1 What is the Bacula File Daemon?

The Bacula File Daemon (bacula-fd) is a lightweight agent that runs on each hypervisor and enables
the Bacula Director to:

- Execute backup scripts remotely via RunScript directives
- Monitor job execution status
- Return exit codes for success/failure tracking

**Important:** In this architecture, the File Daemon does NOT transfer backup data. It only
executes scripts that write directly to NFS storage.

### 1.2 Role in Backup Architecture

```text
Bacula Director (Bacula VM)
    ↓ (TCP 9102)
File Daemon (Each Hypervisor)
    ↓ (executes)
Backup Scripts (/opt/vm-backup/)
    ↓ (writes)
NFS Storage (/mnt/backup)
```

The File Daemon is the bridge that allows the Bacula Director to orchestrate backup operations on
remote hypervisors.

### 1.3 Port and Protocol

- **Port:** TCP 9102
- **Direction:** Bacula Director → File Daemon (inbound to hypervisor)
- **Protocol:** Bacula proprietary protocol over TCP
- **Authentication:** Password-based + IP restriction

---

## 2. Prerequisites

### 2.1 System Requirements

- **Operating System:** Red Hat Enterprise Linux 10
- **Minimum Resources:**
  - CPU: Negligible (< 1% under normal load)
  - RAM: ~50-100MB
  - Disk: ~50MB for binaries and logs
- **Network:** Connectivity to Bacula Director VM
- **Privileges:** Root access for installation

### 2.2 Network Prerequisites

- [ ] Hypervisor can resolve Bacula VM hostname or IP
- [ ] Port 9102 not in use by another service
- [ ] Firewall rules allow TCP 9102 from Bacula Director
- [ ] SELinux configured to permit bacula-fd operations

### 2.3 Required Information

Before starting, gather:

- **Bacula Director IP/Hostname:** _________________
- **Bacula Director Name:** _________________ (from Director config)
- **File Daemon Password:** _________________ (generate secure password)
- **Hypervisor Hostname:** _________________ (e.g., hypervisor-01)

### 2.4 Pre-Installation Checklist

```bash
# Verify RHEL version
cat /etc/redhat-release
# Expected: Red Hat Enterprise Linux release 10.x

# Check network connectivity to Bacula VM
ping -c 3 <bacula-vm-ip>

# Verify port 9102 not in use
ss -tuln | grep 9102
# Should return nothing

# Check if bacula-fd already installed
rpm -qa | grep bacula-client
# Should return nothing (fresh install)
```

---

## 3. Installation Steps

### 3.1 Enable Bacula Repository

Bacula packages are not in the default RHEL repositories. You need to add the Bacula repository.

#### Option A: Bacula Community Repository

```bash
# Add Bacula repository for RHEL 10
# Note: Adjust URL for current Bacula version (13.x or later)
sudo dnf install -y https://www.bacula.org/downloads/Bacula-Community-SRPM/release/el10/bacula-repo-1.0-1.el10.noarch.rpm

# Or manually create repo file
sudo cat > /etc/yum.repos.d/bacula.repo <<EOF
[bacula]
name=Bacula Community Repository
baseurl=https://www.bacula.org/downloads/Bacula-Community/el10/\$basearch/
enabled=1
gpgcheck=1
gpgkey=https://www.bacula.org/downloads/Bacula-Community/RPM-GPG-KEY-Bacula
EOF
```

#### Option B: Bacula Enterprise Repository (if licensed)

```bash
# Contact Bacula Systems for enterprise repository credentials
# Repo URL and credentials provided by Bacula Systems
sudo cat > /etc/yum.repos.d/bacula-enterprise.repo <<EOF
[bacula-enterprise]
name=Bacula Enterprise Repository
baseurl=https://username:password@www.bacula.org/enterprise/el10/\$basearch/  # pragma: allowlist secret
enabled=1
gpgcheck=1
gpgkey=https://www.bacula.org/downloads/Bacula-Enterprise/RPM-GPG-KEY-Bacula
EOF
```

### 3.2 Install Bacula File Daemon

```bash
# Update repository metadata
sudo dnf clean all
sudo dnf makecache

# Install Bacula client package (includes File Daemon)
sudo dnf install -y bacula-client

# Alternative: Install only File Daemon (minimal)
# sudo dnf install -y bacula-fd
```

**Package Contents:**

- `bacula-fd` - File Daemon binary
- `/etc/bacula/bacula-fd.conf` - Configuration file
- `/usr/lib/systemd/system/bacula-fd.service` - Systemd service
- `/var/log/bacula/` - Log directory (created on first run)

### 3.3 Verify Installation

```bash
# Check installed version
bacula-fd -?
# Expected output: bacula-fd version 13.x.x (or later)

# Verify configuration file exists
ls -l /etc/bacula/bacula-fd.conf
# Expected: -rw-r----- 1 root bacula ... /etc/bacula/bacula-fd.conf

# Check service unit file
systemctl cat bacula-fd.service
# Should display service definition
```

### 3.4 Create Required Directories

```bash
# Log directory (usually created automatically)
sudo mkdir -p /var/log/bacula
sudo chown bacula:bacula /var/log/bacula
sudo chmod 755 /var/log/bacula

# Working directory
sudo mkdir -p /var/spool/bacula
sudo chown bacula:bacula /var/spool/bacula
sudo chmod 700 /var/spool/bacula
```

---

## 4. Configuration

### 4.1 Generate Secure Password

Generate a strong password for Director-FD communication:

```bash
# Generate 32-character password
FD_PASSWORD=$(openssl rand -base64 32)
echo "File Daemon Password: $FD_PASSWORD"

# Save this password - you'll need it for:
# 1. bacula-fd.conf (this file)
# 2. bacula-dir.conf on Bacula Director VM (Client definition)
```

**Important:** Store this password securely. It will be needed on both the hypervisor and the
Bacula Director.

### 4.2 Configure bacula-fd.conf

Edit the File Daemon configuration:

```bash
sudo vi /etc/bacula/bacula-fd.conf
```

**Recommended Configuration:**

```conf
#
# Bacula File Daemon Configuration
# Hypervisor: hypervisor-01
#

# File Daemon definition
FileDaemon {
  Name = hypervisor-01-fd
  FDport = 9102
  WorkingDirectory = /var/spool/bacula
  Pid Directory = /var/run
  Maximum Concurrent Jobs = 5
  Plugin Directory = /usr/lib64/bacula
  FDAddress = 0.0.0.0                    # Listen on all interfaces
}

# Director authorization
# Only the Bacula Director can connect
Director {
  Name = bacula-director                 # Must match Director's Name
  Password = "REPLACE_WITH_FD_PASSWORD"  # pragma: allowlist secret Use generated password
}

# Messages configuration
Messages {
  Name = Standard
  director = bacula-director = all, !skipped, !restored

  # Local logging
  append = "/var/log/bacula/bacula-fd.log" = all, !skipped, !restored

  # Timestamp format
  timestamp format = "%Y-%m-%d %H:%M:%S"
}
```

**Key Configuration Parameters:**

| Parameter | Value | Description |
|-----------|-------|-------------|
| `Name` | `hypervisor-01-fd` | Unique identifier for this FD (must match Director's Client definition) |
| `FDport` | `9102` | Port to listen on (default) |
| `Maximum Concurrent Jobs` | `5` | Max simultaneous jobs (usually 1 VM backup at a time in our setup) |
| `Director Name` | `bacula-director` | Must match Director's Name in Director config |
| `Director Password` | `<generated-password>` | Shared secret for authentication |
| `FDAddress` | `0.0.0.0` or specific IP | Interface to bind to |

### 4.3 Customize for Each Hypervisor

**Important:** Each hypervisor needs a unique File Daemon name:

- **hypervisor-01:** `Name = hypervisor-01-fd`
- **hypervisor-02:** `Name = hypervisor-02-fd`
- **hypervisor-03:** `Name = hypervisor-03-fd`
- **hypervisor-04:** `Name = hypervisor-04-fd`
- **hypervisor-05:** `Name = hypervisor-05-fd`
- **hypervisor-06:** `Name = hypervisor-06-fd`

The password can be the same across all hypervisors (simpler) or unique per hypervisor (more secure).

### 4.4 Set File Permissions

```bash
# Restrict access to configuration file (contains password)
sudo chmod 640 /etc/bacula/bacula-fd.conf
sudo chown root:bacula /etc/bacula/bacula-fd.conf

# Verify
ls -l /etc/bacula/bacula-fd.conf
# Expected: -rw-r----- 1 root bacula ... bacula-fd.conf
```

### 4.5 Validate Configuration

```bash
# Test configuration syntax
sudo bacula-fd -t -c /etc/bacula/bacula-fd.conf

# Expected output:
# bacula-fd: <timestamp> Fatal error: configuration file syntax error:
# (no errors should be shown)

# If successful, no errors are printed
echo $?
# Expected: 0 (success)
```

---

## 5. Service Management

### 5.1 Enable and Start Service

```bash
# Enable bacula-fd to start on boot
sudo systemctl enable bacula-fd

# Start the service
sudo systemctl start bacula-fd

# Verify service is running
sudo systemctl status bacula-fd
```

**Expected Output:**

```text
● bacula-fd.service - Bacula File Daemon service
     Loaded: loaded (/usr/lib/systemd/system/bacula-fd.service; enabled; vendor preset: disabled)
     Active: active (running) since Sat 2026-02-01 10:30:00 EST; 5s ago
    Process: 12345 ExecStart=/usr/sbin/bacula-fd -f -c /etc/bacula/bacula-fd.conf (code=exited, status=0/SUCCESS)
   Main PID: 12346 (bacula-fd)
      Tasks: 2 (limit: 38400)
     Memory: 12.5M
        CPU: 45ms
     CGroup: /system.slice/bacula-fd.service
             └─12346 /usr/sbin/bacula-fd -f -c /etc/bacula/bacula-fd.conf
```

### 5.2 Verify Port Listening

```bash
# Check if port 9102 is listening
sudo ss -tuln | grep 9102

# Expected output:
# tcp   LISTEN 0      128          0.0.0.0:9102       0.0.0.0:*
```

### 5.3 Service Management Commands

```bash
# Start service
sudo systemctl start bacula-fd

# Stop service
sudo systemctl stop bacula-fd

# Restart service (after config changes)
sudo systemctl restart bacula-fd

# Reload configuration (without stopping)
sudo systemctl reload bacula-fd

# Check service status
sudo systemctl status bacula-fd

# View service logs
sudo journalctl -u bacula-fd -f

# View last 100 log lines
sudo journalctl -u bacula-fd -n 100
```

### 5.4 Enable Auto-Start on Boot

```bash
# Enable service
sudo systemctl enable bacula-fd

# Verify enabled
sudo systemctl is-enabled bacula-fd
# Expected output: enabled

# List all bacula services
systemctl list-unit-files | grep bacula
```

---

## 6. Firewall Configuration

### 6.1 Open Port 9102 for Bacula Director

**Using firewalld (default on RHEL 10):**

```bash
# Check if firewalld is active
sudo systemctl status firewalld

# Add permanent rule for Bacula FD port
sudo firewall-cmd --permanent --add-port=9102/tcp

# Reload firewall to apply changes
sudo firewall-cmd --reload

# Verify rule is active
sudo firewall-cmd --list-ports
# Expected: 9102/tcp (among others)
```

### 6.2 Restrict Access to Director IP Only (Recommended)

For enhanced security, allow connections only from the Bacula Director VM:

```bash
# Remove generic rule (if added)
sudo firewall-cmd --permanent --remove-port=9102/tcp

# Add rich rule to allow only Director IP
# Replace <DIRECTOR_IP> with actual Bacula Director IP
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="<DIRECTOR_IP>/32"
  port protocol="tcp" port="9102" accept
'

# Reload firewall
sudo firewall-cmd --reload

# Verify rich rule
sudo firewall-cmd --list-rich-rules
```

**Example with actual IP:**

```bash
# Allow only Bacula Director at 192.168.1.100
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.100/32"
  port protocol="tcp" port="9102" accept
'
sudo firewall-cmd --reload
```

### 6.3 Verify Firewall Configuration

```bash
# List all active firewall rules
sudo firewall-cmd --list-all

# Test from Bacula Director VM
# (Run this on Bacula Director)
telnet <hypervisor-ip> 9102
# Expected: Connection established, then disconnected (no banner)
```

### 6.4 SELinux Considerations

RHEL 10 has SELinux enabled by default. Bacula FD should work out-of-the-box, but if you
encounter permission issues:

```bash
# Check SELinux status
getenforce
# Expected: Enforcing

# View SELinux denials related to bacula
sudo ausearch -m avc -ts recent | grep bacula

# If needed, generate and load custom policy
sudo grep bacula /var/log/audit/audit.log | audit2allow -M bacula_fd_custom
sudo semodule -i bacula_fd_custom.pp

# Verify SELinux contexts
ls -Z /usr/sbin/bacula-fd
ls -Z /etc/bacula/bacula-fd.conf
```

**Default SELinux contexts should be:**

- Binary: `system_u:object_r:bacula_exec_t:s0`
- Config: `system_u:object_r:bacula_etc_t:s0`

---

## 7. SSH Access Setup

The Bacula Director needs SSH access to execute backup scripts on each hypervisor.

### 7.1 Create Bacula Service Account

```bash
# Create dedicated user for Bacula operations
sudo useradd -r -s /bin/bash -d /var/lib/bacula -m bacula

# Set a strong password (or disable password login after SSH keys deployed)
sudo passwd bacula
```

### 7.2 Configure Sudo Access for Backup Scripts

The `bacula` user needs to run `virsh` and `qemu-img` commands as root:

```bash
# Create sudoers file for bacula user
sudo visudo -f /etc/sudoers.d/bacula
```

**Add the following content:**

```sudoers
# Bacula user sudo permissions for backup operations
# Allow passwordless execution of specific commands

bacula ALL=(root) NOPASSWD: /usr/bin/virsh
bacula ALL=(root) NOPASSWD: /usr/bin/qemu-img
bacula ALL=(root) NOPASSWD: /usr/bin/systemctl status libvirtd
bacula ALL=(root) NOPASSWD: /usr/bin/systemctl start libvirtd
```

**Verify syntax:**

```bash
sudo visudo -c -f /etc/sudoers.d/bacula
# Expected: /etc/sudoers.d/bacula: parsed OK
```

**Set proper permissions:**

```bash
sudo chmod 440 /etc/sudoers.d/bacula
sudo chown root:root /etc/sudoers.d/bacula
```

### 7.3 Test Sudo Access

```bash
# Switch to bacula user
sudo su - bacula

# Test virsh command
sudo virsh list --all
# Should list VMs without password prompt

# Test qemu-img command
sudo qemu-img --version
# Should display version

# Exit bacula user
exit
```

### 7.4 Deploy SSH Key from Bacula Director

**On Bacula Director VM:**

```bash
# Generate SSH key (if not already done)
sudo su - bacula
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Display public key
cat ~/.ssh/id_ed25519.pub
```

**On Each Hypervisor:**

```bash
# Create .ssh directory for bacula user
sudo mkdir -p /var/lib/bacula/.ssh
sudo chmod 700 /var/lib/bacula/.ssh
sudo chown bacula:bacula /var/lib/bacula/.ssh

# Add Director's public key to authorized_keys
# (Paste the public key from Director)
sudo vi /var/lib/bacula/.ssh/authorized_keys
# Paste: ssh-ed25519 AAAAC3...rest-of-key... bacula@bacula-vm

# Set permissions
sudo chmod 600 /var/lib/bacula/.ssh/authorized_keys
sudo chown bacula:bacula /var/lib/bacula/.ssh/authorized_keys
```

**Alternatively, use ssh-copy-id from Director:**

```bash
# On Bacula Director VM (as bacula user)
ssh-copy-id -i ~/.ssh/id_ed25519.pub bacula@hypervisor-01
ssh-copy-id -i ~/.ssh/id_ed25519.pub bacula@hypervisor-02
# ... repeat for all hypervisors
```

### 7.5 Test SSH Passwordless Access

**From Bacula Director VM:**

```bash
# Test SSH connection (should not prompt for password)
ssh bacula@hypervisor-01 "hostname"
# Expected: hypervisor-01

# Test virsh command over SSH
ssh bacula@hypervisor-01 "sudo virsh list --all"
# Expected: List of VMs

# Test script execution
ssh bacula@hypervisor-01 "bash -c 'echo Hello from $(hostname)'"
# Expected: Hello from hypervisor-01
```

---

## 8. Integration Testing

### 8.1 Test Connection from Bacula Director

**On Bacula Director VM:**

```bash
# Use bconsole to test FD connection
bconsole

# At bconsole prompt, check FD status
*status client=hypervisor-01-fd

# Expected output:
# Connecting to Client hypervisor-01-fd at hypervisor-01:9102
# hypervisor-01-fd Version: 13.x.x (date)
# Daemon started 01-Feb-26 10:30. Jobs: run=0, running=0.
```

**If connection fails:**

- Verify bacula-fd service is running on hypervisor
- Check firewall allows port 9102
- Verify password matches in both configs
- Check Director name matches in bacula-fd.conf

### 8.2 Test RunScript Execution

Create a simple test job to verify script execution:

**On Bacula Director, add test job to bacula-dir.conf:**

```conf
Job {
  Name = "test-fd-hypervisor-01"
  Type = Admin
  Client = hypervisor-01-fd
  FileSet = "VM-Backup-Dummy"
  Storage = File-Storage
  Pool = Default
  Messages = Standard

  RunScript {
    RunsWhen = Before
    RunsOnClient = Yes
    FailJobOnError = No
    Command = "echo 'Test from hypervisor-01' && hostname && date"
  }
}
```

**Restart Bacula Director:**

```bash
sudo systemctl restart bacula-dir
```

**Run test job:**

```bash
bconsole
*run job=test-fd-hypervisor-01
# Confirm: yes

# Check job status
*status dir

# View job log
*list joblog jobid=<jobid>
```

**Expected output in job log:**

```text
Test from hypervisor-01
hypervisor-01
Sat Feb  1 10:45:23 EST 2026
```

### 8.3 Test Backup Script Execution

If backup scripts are already deployed to `/opt/vm-backup/`:

**On Bacula Director:**

```bash
bconsole
*run job=backup-vm-test-vm
# This should execute the actual backup scripts

# Monitor in real-time
*messages
```

**On Hypervisor, watch logs:**

```bash
tail -f /var/log/bacula/bacula-fd.log
tail -f /opt/vm-backup/logs/backup-*.log
```

---

## 9. Troubleshooting

### 9.1 Common Issues and Solutions

#### Issue: bacula-fd service won't start

**Check logs:**

```bash
sudo journalctl -u bacula-fd -n 50
sudo tail -f /var/log/bacula/bacula-fd.log
```

**Common causes:**

- Configuration syntax error: Run `bacula-fd -t`
- Port 9102 already in use: Check with `ss -tuln | grep 9102`
- Permission issues: Verify file ownership and SELinux contexts

#### Issue: Director cannot connect to FD

**Symptoms:**

```text
*status client=hypervisor-01-fd
Failed to connect to Client hypervisor-01-fd
```

**Troubleshooting steps:**

```bash
# 1. Verify FD is running on hypervisor
ssh hypervisor-01 "sudo systemctl status bacula-fd"

# 2. Test network connectivity from Director
telnet hypervisor-01 9102
# Should connect briefly, then disconnect

# 3. Check firewall on hypervisor
ssh hypervisor-01 "sudo firewall-cmd --list-ports"

# 4. Verify password matches
# Compare Director's Client definition with FD config

# 5. Check Director name matches
grep "Name =" /etc/bacula/bacula-dir.conf  # On Director
ssh hypervisor-01 "grep 'Name =' /etc/bacula/bacula-fd.conf"
```

#### Issue: RunScript commands fail to execute

**Symptoms:**

```text
JobId 123: Error: RunScript command failed
```

**Check:**

```bash
# 1. Verify script exists on hypervisor
ssh hypervisor-01 "ls -l /opt/vm-backup/scripts/backup-vm.sh"

# 2. Verify script is executable
ssh hypervisor-01 "test -x /opt/vm-backup/scripts/backup-vm.sh && echo OK"

# 3. Test manual execution
ssh hypervisor-01 "/opt/vm-backup/scripts/backup-vm.sh test-vm quiesce"

# 4. Check script logs
ssh hypervisor-01 "tail -50 /opt/vm-backup/logs/*.log"
```

#### Issue: Permission denied when running virsh

**Symptoms:**

```text
sudo: a password is required
virsh: error: failed to connect to the hypervisor
```

**Solution:**

```bash
# Verify sudoers configuration
sudo visudo -c -f /etc/sudoers.d/bacula

# Check bacula user can run virsh
sudo su - bacula
sudo virsh list --all  # Should NOT prompt for password

# Verify libvirt socket permissions
ls -l /var/run/libvirt/libvirt-sock
```

### 9.2 Log File Locations

| Log File | Purpose |
|----------|---------|
| `/var/log/bacula/bacula-fd.log` | File Daemon main log |
| `/var/log/messages` or `journalctl -u bacula-fd` | System logs for FD service |
| `/var/log/audit/audit.log` | SELinux denials (if any) |
| `/opt/vm-backup/logs/` | Backup script execution logs |

### 9.3 Debug Mode

Enable debug logging for troubleshooting:

```bash
# Stop FD service
sudo systemctl stop bacula-fd

# Run FD in foreground with debug
sudo bacula-fd -f -d 100 -c /etc/bacula/bacula-fd.conf

# In another terminal, trigger connection from Director
# Observe detailed debug output

# Stop with Ctrl+C when done
```

### 9.4 Network Troubleshooting

```bash
# Test basic connectivity from Director to hypervisor
ping -c 3 hypervisor-01

# Test DNS resolution
nslookup hypervisor-01
host hypervisor-01

# Test port connectivity
nc -zv hypervisor-01 9102
# or
telnet hypervisor-01 9102

# Check if FD is listening
ssh hypervisor-01 "sudo ss -tlnp | grep 9102"

# Capture network traffic (if needed)
sudo tcpdump -i any port 9102 -w /tmp/bacula-fd.pcap
```

---

## 10. Security Hardening

### 10.1 Restrict FD Binding

Bind FD to specific interface instead of all interfaces:

```bash
# Edit bacula-fd.conf
sudo vi /etc/bacula/bacula-fd.conf

# Change FDAddress from 0.0.0.0 to specific IP
FileDaemon {
  ...
  FDAddress = 192.168.1.10  # Hypervisor's management IP
  ...
}

# Restart service
sudo systemctl restart bacula-fd
```

### 10.2 Use Strong Passwords

```bash
# Generate strong password (32 characters minimum)
openssl rand -base64 32

# Update both:
# 1. /etc/bacula/bacula-fd.conf (hypervisor)
# 2. bacula-dir.conf Client definition (Director)
```

### 10.3 Firewall: Allow Only Director IP

```bash
# Remove any open port rules
sudo firewall-cmd --permanent --remove-port=9102/tcp

# Add rich rule for Director IP only
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.100/32"
  port protocol="tcp" port="9102" accept
'

sudo firewall-cmd --reload
```

### 10.4 Disable Root SSH Login (if not already)

```bash
# Edit SSH config
sudo vi /etc/ssh/sshd_config

# Ensure these lines:
PermitRootLogin no
PasswordAuthentication no  # Use keys only

# Restart SSH
sudo systemctl restart sshd
```

### 10.5 Enable Audit Logging

```bash
# Add audit rule for bacula-fd binary
sudo auditctl -w /usr/sbin/bacula-fd -p x -k bacula_fd_exec

# Add audit rule for config file
sudo auditctl -w /etc/bacula/bacula-fd.conf -p wa -k bacula_fd_config

# Make rules persistent
echo "-w /usr/sbin/bacula-fd -p x -k bacula_fd_exec" | sudo tee -a /etc/audit/rules.d/bacula.rules
echo "-w /etc/bacula/bacula-fd.conf -p wa -k bacula_fd_config" | sudo tee -a /etc/audit/rules.d/bacula.rules

# Load rules
sudo augenrules --load

# View bacula-related audit events
sudo ausearch -k bacula_fd_exec
sudo ausearch -k bacula_fd_config
```

### 10.6 Regular Security Maintenance

**Quarterly tasks:**

- Rotate File Daemon password
- Review firewall rules
- Check for unauthorized SSH keys in `/var/lib/bacula/.ssh/`
- Update Bacula packages: `sudo dnf update bacula-client`
- Review audit logs for anomalies

---

## 11. Deployment Automation

### 11.1 Ansible Playbook Snippet

For automated deployment across all hypervisors:

```yaml
---
# file: deploy-bacula-fd.yml
- name: Deploy Bacula File Daemon to Hypervisors
  hosts: hypervisors
  become: yes
  vars:
    bacula_director_name: "bacula-director"
    bacula_director_ip: "192.168.1.100"
    bacula_fd_password: "{{ vault_bacula_fd_password }}"  # Store in Ansible Vault

  tasks:
    - name: Add Bacula repository
      dnf:
        name: https://www.bacula.org/downloads/Bacula-Community-SRPM/release/el10/bacula-repo-1.0-1.el10.noarch.rpm
        state: present

    - name: Install Bacula File Daemon
      dnf:
        name: bacula-client
        state: present

    - name: Deploy bacula-fd.conf
      template:
        src: templates/bacula-fd.conf.j2
        dest: /etc/bacula/bacula-fd.conf
        owner: root
        group: bacula
        mode: '0640'
      notify: restart bacula-fd

    - name: Create bacula service user
      user:
        name: bacula
        system: yes
        shell: /bin/bash
        home: /var/lib/bacula
        create_home: yes

    - name: Configure sudo for bacula user
      copy:
        dest: /etc/sudoers.d/bacula
        content: |
          bacula ALL=(root) NOPASSWD: /usr/bin/virsh
          bacula ALL=(root) NOPASSWD: /usr/bin/qemu-img
        mode: '0440'
        validate: 'visudo -cf %s'

    - name: Open firewall for Bacula Director
      firewalld:
        rich_rule: 'rule family="ipv4" source address="{{ bacula_director_ip }}/32" port protocol="tcp" port="9102" accept'
        permanent: yes
        state: enabled
        immediate: yes

    - name: Enable and start bacula-fd service
      systemd:
        name: bacula-fd
        enabled: yes
        state: started

  handlers:
    - name: restart bacula-fd
      systemd:
        name: bacula-fd
        state: restarted
```

**Template file: `templates/bacula-fd.conf.j2`**

```jinja2
FileDaemon {
  Name = {{ inventory_hostname }}-fd
  FDport = 9102
  WorkingDirectory = /var/spool/bacula
  Pid Directory = /var/run
  Maximum Concurrent Jobs = 5
  FDAddress = {{ ansible_default_ipv4.address }}
}

Director {
  Name = {{ bacula_director_name }}
  Password = "{{ bacula_fd_password }}"
}

Messages {
  Name = Standard
  director = {{ bacula_director_name }} = all, !skipped, !restored
  append = "/var/log/bacula/bacula-fd.log" = all, !skipped, !restored
  timestamp format = "%Y-%m-%d %H:%M:%S"
}
```

**Run playbook:**

```bash
ansible-playbook -i inventory.ini deploy-bacula-fd.yml --ask-vault-pass
```

### 11.2 Bash Script for Manual Bulk Deployment

```bash
#!/bin/bash
# deploy-fd-to-all-hypervisors.sh

HYPERVISORS=(hypervisor-01 hypervisor-02 hypervisor-03 hypervisor-04 hypervisor-05 hypervisor-06)
FD_PASSWORD="<your-generated-password>"
DIRECTOR_NAME="bacula-director"
DIRECTOR_IP="192.168.1.100"

for HV in "${HYPERVISORS[@]}"; do
  echo "Deploying to $HV..."

  # Install package
  ssh root@$HV "dnf install -y bacula-client"

  # Deploy configuration
  ssh root@$HV "cat > /etc/bacula/bacula-fd.conf <<EOF
FileDaemon {
  Name = ${HV}-fd
  FDport = 9102
  WorkingDirectory = /var/spool/bacula
  Pid Directory = /var/run
  Maximum Concurrent Jobs = 5
}

Director {
  Name = $DIRECTOR_NAME
  Password = \"$FD_PASSWORD\"
}

Messages {
  Name = Standard
  director = $DIRECTOR_NAME = all, !skipped, !restored
  append = \"/var/log/bacula/bacula-fd.log\" = all, !skipped, !restored
}
EOF"

  # Set permissions
  ssh root@$HV "chmod 640 /etc/bacula/bacula-fd.conf"

  # Configure firewall
  ssh root@$HV "firewall-cmd --permanent --add-rich-rule='rule family=\"ipv4\" source address=\"${DIRECTOR_IP}/32\" port protocol=\"tcp\" port=\"9102\" accept' && firewall-cmd --reload"

  # Enable and start service
  ssh root@$HV "systemctl enable --now bacula-fd"

  echo "✓ $HV deployment complete"
done

echo "All deployments finished!"
```

---

## 12. Reference Commands

### 12.1 Quick Command Reference

```bash
# Installation
sudo dnf install -y bacula-client

# Service Management
sudo systemctl start bacula-fd
sudo systemctl stop bacula-fd
sudo systemctl restart bacula-fd
sudo systemctl status bacula-fd
sudo systemctl enable bacula-fd

# Configuration
sudo vi /etc/bacula/bacula-fd.conf
sudo bacula-fd -t -c /etc/bacula/bacula-fd.conf  # Test config

# Logs
sudo tail -f /var/log/bacula/bacula-fd.log
sudo journalctl -u bacula-fd -f

# Firewall
sudo firewall-cmd --permanent --add-port=9102/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports

# SSH Key Deployment
ssh-copy-id bacula@hypervisor-01

# Testing
telnet hypervisor-01 9102
ssh bacula@hypervisor-01 "sudo virsh list --all"
```

### 12.2 Status Check Commands

```bash
# Service status
systemctl is-active bacula-fd
systemctl is-enabled bacula-fd

# Port listening
ss -tlnp | grep 9102

# Process info
ps aux | grep bacula-fd

# Recent logs
journalctl -u bacula-fd --since "1 hour ago"

# From Bacula Director
bconsole
*status client=hypervisor-01-fd
```

### 12.3 Maintenance Commands

```bash
# Restart after config change
sudo systemctl restart bacula-fd

# View full configuration
sudo cat /etc/bacula/bacula-fd.conf

# Check file permissions
ls -l /etc/bacula/bacula-fd.conf
ls -ld /var/log/bacula/
ls -ld /var/spool/bacula/

# Update packages
sudo dnf update bacula-client

# Uninstall (if needed)
sudo systemctl stop bacula-fd
sudo systemctl disable bacula-fd
sudo dnf remove bacula-client
```

---

## Appendix A: Complete bacula-fd.conf Example

```conf
#
# Bacula File Daemon Configuration File
# Hypervisor: hypervisor-01
# Updated: 2026-02-01
#

FileDaemon {
  Name = hypervisor-01-fd
  FDport = 9102
  WorkingDirectory = /var/spool/bacula
  Pid Directory = /var/run
  Maximum Concurrent Jobs = 5
  Plugin Directory = /usr/lib64/bacula

  # Bind to specific interface (recommended)
  FDAddress = 192.168.1.10

  # Optional: TLS encryption
  # TLS Enable = yes
  # TLS Require = yes
  # TLS Certificate = /etc/bacula/certs/hypervisor-01-cert.pem
  # TLS Key = /etc/bacula/certs/hypervisor-01-key.pem
  # TLS CA Certificate File = /etc/bacula/certs/ca-cert.pem
}

# Director that can connect to this File Daemon
Director {
  Name = bacula-director
  Password = "YourSecurePasswordHere123456789ABCDEF="  # pragma: allowlist secret

  # Optional: Restrict to specific IP
  # Address = 192.168.1.100
}

# Monitor Director (for status queries)
Director {
  Name = bacula-monitor
  Password = "MonitorPasswordHere123456789ABCDEF="  # pragma: allowlist secret
  Monitor = yes
}

# Messages configuration
Messages {
  Name = Standard
  director = bacula-director = all, !skipped, !restored

  # Log to file
  append = "/var/log/bacula/bacula-fd.log" = all, !skipped, !restored

  # Log timestamp format
  timestamp format = "%Y-%m-%d %H:%M:%S"
}
```

---

## Appendix B: Verification Checklist

After installation, verify the following:

- [ ] Bacula client package installed: `rpm -qa | grep bacula-client`
- [ ] Configuration file present and valid: `bacula-fd -t`
- [ ] Service enabled: `systemctl is-enabled bacula-fd`
- [ ] Service running: `systemctl is-active bacula-fd`
- [ ] Port 9102 listening: `ss -tlnp | grep 9102`
- [ ] Firewall rule configured: `firewall-cmd --list-ports`
- [ ] Bacula user created: `id bacula`
- [ ] SSH key deployed: `ssh bacula@localhost echo OK`
- [ ] Sudo configured: `sudo -l -U bacula`
- [ ] Director can connect: `bconsole` → `*status client=hypervisor-XX-fd`
- [ ] RunScript test successful: Run test job from Director
- [ ] Logs being written: `ls -lh /var/log/bacula/bacula-fd.log`

---

## Appendix C: Troubleshooting Decision Tree

```text
Connection Issue?
├─ Service not running?
│  ├─ Start service: systemctl start bacula-fd
│  └─ Check logs: journalctl -u bacula-fd
├─ Firewall blocking?
│  ├─ Check rules: firewall-cmd --list-all
│  └─ Test port: nc -zv hypervisor-01 9102
├─ Wrong password?
│  ├─ Compare FD config vs Director Client definition
│  └─ Update and restart both services
└─ SELinux denial?
   └─ Check audit log: ausearch -m avc -ts recent | grep bacula

Script Execution Failed?
├─ Script missing or not executable?
│  └─ ls -l /opt/vm-backup/scripts/
├─ Permission denied?
│  ├─ Check sudoers: visudo -c -f /etc/sudoers.d/bacula
│  └─ Test manually: sudo su - bacula; sudo virsh list
└─ Script error?
   └─ Review logs: /opt/vm-backup/logs/backup-*.log
```

---

## Document Maintenance

**Review Schedule:** Quarterly
**Last Reviewed:** 2026-02-01
**Next Review:** 2026-05-01
**Owner:** Backup Administration Team

**Change Log:**

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-01 | 1.0 | Initial document creation |

---
