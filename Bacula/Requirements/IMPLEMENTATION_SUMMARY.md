# VM Backup Implementation Summary

**Date:** February 1, 2026
**Project:** Bacula-Orchestrated VM Backup Solution
**Environment:** 6x RHEL 10 Hypervisors with KVM

---

## Table of Contents

- [Quick Reference](#quick-reference)
- [Deployment Workflows](#deployment-workflows)
- [Repositories](#repositories)
- [Repository Structure](#repository-structure)
- [Backup Methods](#backup-methods)
- [How Bacula Orchestrates Backups](#how-bacula-orchestrates-backups)
- [Sequential Backup Processing](#sequential-backup-processing)
- [Health Checks](#health-checks)
- [Slack Integration](#slack-integration)
- [Restore Procedure](#restore-procedure)
- [Deployment Procedure](#deployment-procedure)
- [Redeployment (If Bacula VM Lost)](#redeployment-if-bacula-vm-lost)
- [Backup Schedule Example](#backup-schedule-example)
- [Storage Layout](#storage-layout)
- [Key Documentation Locations](#key-documentation-locations)
- [Next Steps](#next-steps)
- [Critical Success Factors](#critical-success-factors)
- [Common Issues and Solutions](#common-issues-and-solutions)

---

## Quick Reference

### Architecture at a Glance

```text
Custom Backup Scripts (on each hypervisor)
           ↓
    Bacula Orchestration VM
           ↓
     NetApp NFS Storage
           ↓
  Slack Notifications (success/failure)
```

**Key Decision:** Bacula acts as **orchestrator only** - it calls custom scripts but does NOT
transfer backup data through itself.

## Deployment Workflows

There will be two main workflows that we will need to cover.

1. Scheduled backups

2. ad-hoc one off backups

## Repositories

This project will include 2 seperate repositories.

1. Backup Scripts - these are the scripts that will be deployed from a git repo onto each
   hypervisor

   1. Need to have an installer script that will install all backup scripts in the proper
      location (/opt preferably)

   2. Install scripts should be idempotent and not overwrite any scripts already deployed on a
      hypervisor, without prompting the user that there are changes that need to be applied

2. Bacula + Bacularis - this repo should deploy Bacula and Bacularius on a Virtual Machine,
   ideally as podman containers (+quadlets), with persistent bind mounts

   1. All configuration files should be checked into git (and github)

   2. Bacula + Bacularis should be considered "infrascrtucture as code", so there will be no need
      to backup the bacula VM, as all configuration data will be in the repo and commited to git

## Repository Structure

### Repository 1: vm-backup-scripts

**Purpose:** Backup scripts and tools deployed to hypervisors

**Key Scripts:**

- `backup-vm-quiesce.sh` - Backup with QEMU guest agent freeze/thaw
- `backup-vm-snapshot.sh` - Backup using external snapshots (for ASAv)
- `pre-backup-checks.sh` - Validates VM and hypervisor health
- `post-backup-checks.sh` - Verifies backup integrity
- `restore-vm.sh` - Manual VM restoration
- `test-restore.sh` - Automated restore testing
- `lib/slack-notify.sh` - Slack webhook integration

**Configuration:**

- `config/vm-backup.conf` - Hypervisor-specific settings
- `config/vm-list.yaml` - VM inventory with backup schedules and priorities

### Repository 2: bacula-iac

**Purpose:** Infrastructure as Code for Bacula/Bacularis deployment

**Key Components:**

- `scripts/deploy-bacula.sh` - Main deployment script (idempotent)
- `templates/bacula-dir.conf.j2` - Bacula Director configuration template
- `templates/bacula-sd.conf.j2` - Storage Daemon template
- `deployment/` - Deployment automation

---

## Backup Methods

### Method 1: Quiesce (RHEL VMs with QEMU Guest Agent)

1. Pre-backup health checks
2. Freeze guest filesystem: `virsh qemu-agent-command ... fsfreeze-freeze`
3. Copy disk images: `qemu-img convert -O qcow2 source.qcow2 backup.qcow2`
4. Thaw guest filesystem: `fsfreeze-thaw`
5. Backup VM XML configuration
6. Post-backup validation
7. Slack notification

**Advantages:**

- Application-consistent snapshots
- Minimal VM disruption (<60 seconds freeze)
- Clean point-in-time backup

### Method 2: Snapshot (ASAv and VMs without Guest Agent)

1. Pre-backup health checks
2. SSH to ASAv: `write memory` (if ASAv)
3. Create external snapshot: `virsh snapshot-create-as --disk-only`
4. Backup original disk files (VM runs on snapshot)
5. Block-commit snapshot back: `virsh blockcommit --active --pivot`
6. Delete temporary snapshot files
7. Backup VM XML configuration
8. Post-backup validation
9. Slack notification

**Advantages:**

- Works for VMs without guest agent
- Zero downtime
- Safe for appliances like ASAv

---

## How Bacula Orchestrates Backups

**Bacula Job Definition Pattern:**

```conf
Job {
  Name = "backup-vm-<vm-name>"
  Type = Admin  # No file transfer through Bacula
  Client = <hypervisor-fd>

  RunScript {
    RunsWhen = Before
    RunsOnClient = Yes
    Command = "/opt/vm-backup/scripts/pre-backup-checks.sh <vm-name>"
  }

  RunScript {
    RunsWhen = Before
    RunsOnClient = Yes
    Command = "/opt/vm-backup/scripts/backup-vm.sh <vm-name> <method>"
  }

  RunScript {
    RunsWhen = After
    RunsOnSuccess = Yes
    Command = "/opt/vm-backup/scripts/post-backup-checks.sh <vm-name>"
  }

  RunScript {
    RunsWhen = After
    Command = "/opt/vm-backup/scripts/lib/slack-notify.sh <status> <vm> %i"
  }
}
```

**Execution Flow:**

1. Bacula Director reaches scheduled time
2. Connects to File Daemon on target hypervisor
3. Executes RunScript commands in sequence
4. Scripts write backup data directly to NFS share
5. Scripts return exit codes to Bacula
6. Bacula logs job status in catalog
7. Next VM backup initiated (sequential processing)

---

## Sequential Backup Processing

**Critical Requirement:** Only ONE VM backs up at a time

**Implementation Options:**

### Option A: Bacula Pool Limits

```conf
Pool {
  Name = Default
  Maximum Concurrent Jobs = 1
}
```

### Option B: Time-Staggered Schedules

```conf
Job { Name = "vm-01" ; Schedule = "Sat-22:00" }
Job { Name = "vm-02" ; Schedule = "Sat-22:30" }
Job { Name = "vm-03" ; Schedule = "Sat-23:00" }
```

**Option C: Priority-Based** (Recommended)

```conf
Job { Name = "critical-vm" ; Priority = 1 }
Job { Name = "high-vm" ; Priority = 5 }
Job { Name = "standard-vm" ; Priority = 10 }
```

With `Maximum Concurrent Jobs = 1`, Bacula processes by priority.

---

## Health Checks

### Pre-Backup Checks (Abort if ANY fail)

- ✓ VM is running
- ✓ NFS Mount (backup destination) is properly mounted
- ✓ QEMU guest agent responding or not installed (if quiesce method)
- ✓ No existing snapshots present
- ✓ Hypervisor has >50GB free disk space
- ✓ NFS mount accessible and writable
- ✓ NFS has sufficient space for backup
- ✓ Backup destination directory created successfully (directories should be time stamped with
  backup dates for each VM)

### Post-Backup Validation

- ✓ VM still running and responsive
- ✓ No orphaned snapshot files remain
- ✓ Backup files exist and are non-zero size
- ✓ Checksums verified (SHA-256)
- ✓ VM XML successfully backed up
- ✓ Backup metadata JSON created

---

## Slack Integration

### Failure Alerts (Immediate)

- Channel: `#TBD`
- Triggered: Any backup failure
- Contains: VM name, hypervisor, error message, timestamp
- Webhook: `SLACK_FAILURE_WEBHOOK`

### Success Summary (Weekly)

- Channel: `#TDB`
- Triggered: After weekend backup cycle completes
- Contains: Total VMs, success count, failed count, total size, duration
- Webhook: `SLACK_SUCCESS_WEBHOOK`

**Webhook Configuration:**

```bash
# In /opt/vm-backup/config/vm-backup.conf
SLACK_FAILURE_WEBHOOK="https://hooks.slack.com/services/XXX/YYY/ZZZ"
SLACK_SUCCESS_WEBHOOK="https://hooks.slack.com/services/AAA/BBB/CCC"
```

---

## Restore Procedure

**Manual Restore (Production):

Note: We will need an option to test a backup without attaching network interfaces, or attaching
test interfaces on a private network as to not affect any running VMs

```bash
# On any hypervisor with access to NFS backups
/opt/vm-backup/scripts/restore-vm.sh <vm-name> <backup-date>

# Script will:
# 1. Find backup on NFS
# 2. Verify checksums
# 3. Copy disk images to /var/lib/libvirt/images
# 4. Restore VM XML (update paths)
# 5. Define VM in libvirt
# 6. Optionally start VM
```

**Test Restore (Quarterly Validation):

Note: We will need an option to test a backup without attaching network interfaces, or attaching
test interfaces on a private network as to not affect any running VMs

```bash
# Creates test VM from backup for validation
/opt/vm-backup/scripts/test-restore.sh <vm-name> [<backup-date>]

# Script will:
# 1. Restore to test VM name (avoid conflict)
# 2. Update MAC addresses
# 3. Start VM
# 4. Validate boot and health
# 5. Optionally clean up after testing
```

---

## Deployment Procedure

### Initial Deployment

#### Step 1: Provision Bacula VM

- RHEL 9 or compatible
- 2 vCPU, 4GB RAM minimum
- 100GB disk (for OS and catalog)
- Network access to all 6 hypervisors
- Network access to NetApp NFS

### Step 2: Deploy Bacula Infrastructure

All WebUIs should be https with self-signed certs that are valid for 10 years, we will need to
create the self-signed cert as part of the deploy/install process, if existing certs exists, the
deploy process will prompt user to either keep or re-generate.

```bash
# Clone IaC repository
git clone <repo-url>/bacula-iac.git
cd bacula-iac

# Configure secrets (not in Git)
cat > config/secrets.conf <<EOF
DIRECTOR_PASSWORD="$(openssl rand -base64 32)"
FD_PASSWORD="$(openssl rand -base64 32)"
SD_PASSWORD="$(openssl rand -base64 32)"
DB_PASSWORD="$(openssl rand -base64 32)"
SLACK_FAILURE_WEBHOOK="https://hooks.slack.com/..."
SLACK_SUCCESS_WEBHOOK="https://hooks.slack.com/..."
EOF

# Run deployment (idempotent)
./scripts/deploy-bacula.sh
```

#### Step 3: Deploy Backup Scripts to Hypervisors

```bash
# Clone scripts repository
git clone <repo-url>/vm-backup-scripts.git
cd vm-backup-scripts

# Customize VM inventory
vi config/vm-list.yaml

# Deploy to all hypervisors
./deployment/deploy-backup-scripts.sh
```

#### Step 4: Test Single VM Backup

```bash
# On Bacula VM, run manual backup
bconsole
run job=backup-vm-test-vm

# Monitor in real-time
tail -f /var/log/bacula/bacula-dir.log

# Check on hypervisor
ssh hypervisor-01
tail -f /opt/vm-backup/logs/backup-test-vm-*.log
```

#### Step 5: Test Restore

```bash
# On any hypervisor
/opt/vm-backup/scripts/test-restore.sh test-vm
```

#### Step 6: Enable Production Schedules

- Update Bacula schedules for all VMs
- Monitor first weekend backup cycle
- Validate Slack notifications
- Review logs and metrics

---

## Redeployment (If Bacula VM Lost)

Total deployment time: 20-30 minutes

```bash
# 1. Provision new VM (same IP if possible)
# 2. Clone bacula-iac repository
git clone <repo-url>/bacula-iac.git
cd bacula-iac

# 3. Restore secrets (from secure vault)
cp /secure/location/secrets.conf config/

# 4. Run deployment
./scripts/deploy-bacula.sh --redeploy

# 5. Validate
systemctl status bacula-dir
systemctl status bacula-sd
curl http://localhost/bacularis

# Backup data intact on NFS - no data loss
```

---

## Backup Schedule Example

**vm-list.yaml:**

```yaml
vms:
  # Critical - Priority 1-5
  - name: prod-db-01
    hypervisor: hypervisor-01
    method: quiesce
    priority: 1
    schedule: weekly
    retention_weeks: 8

  - name: asav-firewall-01
    hypervisor: hypervisor-02
    method: snapshot
    priority: 2
    schedule: weekly
    retention_weeks: 8
    pre_backup_commands:
      - ssh admin@192.168.1.1 "write memory"

  # High - Priority 6-10
  - name: web-server-01
    hypervisor: hypervisor-03
    method: quiesce
    priority: 6
    schedule: weekly
    retention_weeks: 6

  # Standard - Priority 11-20
  - name: file-server-01
    hypervisor: hypervisor-04
    method: snapshot
    priority: 15
    schedule: biweekly
    retention_weeks: 4

  # Development - Priority 21+
  - name: dev-test-vm
    hypervisor: hypervisor-05
    method: snapshot
    priority: 25
    schedule: biweekly
    retention_weeks: 2
```

**Execution:**

- Saturday 12:00 (Noon) Backup cycle starts
- VMs backed up in priority order (1 → 25)
- One at a time, no parallelism (at least untill we are confident in the process)
- Expected completion: Sunday afternoon
- Slack summary: Sunday evening

---

## Storage Layout

**NFS Structure:**

```text
/mnt/backup/
├── hypervisor-01/
│   ├── prod-db-01/
│   │   ├── 2026-02-01-220015/
│   │   │   ├── prod-db-01-vda.qcow2
│   │   │   ├── prod-db-01.xml
│   │   │   ├── checksums.sha256
│   │   │   ├── backup-metadata.json
│   │   │   └── backup.log
│   │   └── 2026-02-08-220112/
│   │       └── ...
│   └── web-server-01/
│       └── ...
├── hypervisor-02/
│   └── asav-firewall-01/
│       └── 2026-02-01-220530/
│           ├── asav-firewall-01-vda.qcow2
│           ├── asav-firewall-01.xml
│           ├── configs/
│           │   ├── running-config.txt
│           │   ├── startup-config.txt
│           │   └── version.txt
│           ├── checksums.sha256
│           └── backup-metadata.json
└── metadata/
    ├── backup-catalog.db
    └── last-run-summary.json
```

---

## Key Documentation Locations

1. **Full Requirements:** `/home/cpaquin/Documents/Bacula/VM_Backup_Requirements.md`
2. **This Summary:** `/home/cpaquin/Documents/Bacula/IMPLEMENTATION_SUMMARY.md`
3. **Git Repo 1:** vm-backup-scripts (backup scripts and tools)
4. **Git Repo 2:** bacula-iac (Bacula deployment automation)

**In Production:**

- Bacula configs: `/etc/bacula/`
- Backup scripts: `/opt/vm-backup/` (on each hypervisor)
- Logs: `/opt/vm-backup/logs/` and `/var/log/bacula/`
- NFS mount: `/mnt/backup/`

---

## Next Steps

### Immediate (Week 1)

1. [ ] Create two Git repositories
2. [ ] Set up Slack workspace and webhooks
3. [ ] Provision Bacula VM
4. [ ] Write initial deployment scripts
5. [ ] Test deployment on Bacula VM
6. [ ] Deploy to one hypervisor for testing

### Short-Term (Week 2-3)

1. [ ] Backup one test VM successfully
2. [ ] Restore test VM successfully
3. [ ] Deploy scripts to all 6 hypervisors
4. [ ] Create VM inventory (vm-list.yaml)
5. [ ] Configure Bacula jobs for all VMs
6. [ ] Test Slack notifications

### Medium-Term (Week 4)

1. [ ] First full weekend backup cycle
2. [ ] Monitor and troubleshoot
3. [ ] Adjust schedules/priorities as needed
4. [ ] Document any issues and resolutions
5. [ ] Train team on restore procedures

### Ongoing

1. [ ] Monthly restore test (1 random VM)
2. [ ] Quarterly full restore validation
3. [ ] Review storage capacity monthly
4. [ ] Update documentation as needed
5. [ ] Rotate secrets quarterly

---

## Critical Success Factors

1. **Sequential Processing:** ONE VM at a time prevents resource contention
2. **Extensive Health Checks:** Catch issues before they cause problems
3. **Idempotent Deployment:** Bacula VM is disposable, easily rebuilt
4. **Slack Integration:** Immediate awareness of failures
5. **Test Restores:** Quarterly validation ensures recoverability
6. **Git-Based:** All configuration versioned and auditable
7. **NFS Direct Write:** Backup data doesn't flow through Bacula, improves performance
8. **Method Selection:** Quiesce for RHEL VMs, snapshot for ASAv

---

## Common Issues and Solutions

### Issue: QEMU Guest Agent Not Responding

**Solution:** Fall back to snapshot method automatically or manually

### Issue: Snapshot Left Behind

**Solution:** Run cleanup script: `virsh snapshot-list <vm>` and
`virsh blockcommit <vm> <disk> --active --pivot`

### Issue: NFS Mount Unavailable

**Solution:** All backups abort, fix NFS connectivity, re-run manually

### Issue: Backup Takes Too Long

**Solution:**

- Check NFS performance
- Review VM disk size (large VMs take longer)
- Consider compression for backup files
- Stagger backup schedules more

### Issue: Bacula VM Fails

**Solution:** Redeploy from Git (20-30 min), all backup data safe on NFS

---
