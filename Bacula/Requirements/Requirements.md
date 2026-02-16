# First you should read the README.

- We will deploy as a POC first before deploying in prod, all functionality should be working in the POC before we can move to Prod
- We will need a script to add new hypervisors as backup clients, in POC we will have one hypervisor, in Prod we will have 6 hypervisors
- In POC we will use standard NFS storage, in prod, storage will be NFS from Netapp
- We have some reference scripts that we can adapt to fit our use cases, they should be reviewed and modified to fit our environment
- All hypervisors are RHEL 10
- Our hypervisor setup script should connect as root *with password* and then create a bacula user.
- We will need to push keys for the bacula user and allow passwordless sudo
- The bacula user should only be allowed to ssh to the hypervisors from the bacula VM (limit in known_hosts)
- On the bacula host we will need an install script, an uninstall script, a db backup script, a health-check script, and a script to test heath/connectivity to hypervisors
as well as a script to setup a new hypervisor
- All VMs will have guest agent, We will do a full backup each saturday of each VM (with exceptions) and a nightly incremental every night
- VMS that will not be backed up will be the bacula vm (all other vms will need to be backed up)
- Special Backup process will be needed for the Cisco ASAv (in both POC and in Production), as there is not a qemu agent (use snapshots)
- Our main backup script will come from this repo - https://github.com/abbbi/virtnbdbackup
- VMs that are backed up normally, with have qemu guest agent installed and will use freeze, quiesce
- We should expect to create helper/wrapper scripts to run backups on the CLI and also to perform restors
- All vars should exist in a .env file (for installer), a env-template should exist for reference to anyone who wants to use this repo
- .env file should be included in gitignore
- no IPs, passwords, secrets, hostnames, may be checked into github (this is one of the purposes of the reference doc env-templates
- We will configure bacula to send alerts to one slack channel and info notices to another slack channel - all via webhooks
- HTTPS only with self-signed cert (10 years)
- Install script should be idempotent
- Uninstall script should ensure all deployment artifacts are removed
- This repo used an AI Guardrails template, all bacula files should exist in the bacula directory
- Adhere to all best practices as detailed by Guardrails AI

```bash
# Directory Tree
├── Docs # all usage docs
├── Planning # all planning docs that are created along the way
├── Requirements # contains all requirements
│   ├── Bacula_Docs
│   │   ├── About Community and Enterprise Editions.pdf
│   │   ├── bsys-baculaenterpriseplanningandpreparation.pdf
│   │   ├── bsys-baculauserinterfaces.pdf
│   │   ├── bsys-installation.pdf
│   │   ├── KVM_Backup_With_Bacula.pdf
│   │   └── Requirement Specs for Bacula - Google Docs.pdf
│   ├── BACULA_FD_INSTALLATION_GUIDE.md
│   ├── IMPLEMENTATION_SUMMARY.md
│   ├── Libvirt_Docs
│   │   ├── libvirt_ Internals of incremental backup handling in qemu.pdf
│   │   └── libvirt_ The virtualization API.pdf
│   ├── README.md
│   └── Requirements.md
└── Scripts # install, uninstall, health-check, add-hypervisor, check-hypervisor-health should live here
```




## Produce a complete, copy/pasteable installation and configuration procedure (commands + config files + validation) to deploy Bacula Community Edition + Bacularis on RHEL 9 using RPMs (no containers).

GOALS
- Install Bacula Community Edition via official Bacula RPM repositories for RHEL 9.
- Install Bacularis (Web + API) via official Bacularis RPM repository for RHEL 9 (or EL9-compatible).
- Use PostgreSQL as the Bacula catalog DB on the same host.
- Run Director, Storage Daemon, and File Daemon on the same host initially (single-node backup server).
- Use systemd services and ensure they are enabled at boot.
- Provide a “works end-to-end” initial configuration: one FileSet, one Schedule, one Pool, one Storage resource, one Job for backing up a local path like /etc and /var/www (or a configurable test path).
- Ensure the Bacularis UI can connect to Bacula Director and display/manage jobs.

### CONSTRAINTS / PREFERENCES
- OS: RHEL 9 (assume latest minor release).
- Use RPMs only (dnf), no containers.
- SELinux should remain Enforcing (do not disable SELinux). If policies/booleans/labels are needed, specify them precisely.
- Firewalld should remain enabled. Open only required ports; list them explicitly.
- Minimize custom hacks. Prefer vendor-supported configs and defaults.
- All secrets (DB password, Bacula passwords) must be generated securely and stored appropriately (e.g., root-only config files). Provide a reproducible approach.
- Use /var/lib/bacula and /var/spool/bacula for state/spool unless vendor defaults differ; explain any required paths.
- Provide rollback/cleanup steps (optional but useful).

#### DELIVERABLE FORMAT
1) Pre-flight checklist
   - Host prerequisites (packages, repos, DNS, time sync)
   - Storage requirements (where volumes should live)
2) Repository setup
   - Exact steps to add Bacula official repository for EL9
   - Exact steps to add Bacularis official repository for EL9
   - GPG key import steps
   - Show how to verify repos are enabled
3) Install steps
   - dnf install commands for PostgreSQL, Bacula components (director, storage, client, db tools), Bacularis components
   - Any service enable/start commands
4) PostgreSQL catalog setup
   - Initialize Postgres if needed
   - Create bacula DB + user with strong password
   - Configure pg_hba.conf securely for local connections
   - Run Bacula catalog creation scripts (or documented method) and verify schema exists
5) Bacula configuration (minimal working)
   - Provide exact bacula-dir.conf, bacula-sd.conf, bacula-fd.conf snippets or full files as needed
   - Use TLS only if required; otherwise keep local-only for first bring-up
   - Ensure Director<->SD<->FD passwords match and are secure
   - Configure a FileSet and Job that backs up a test directory
   - Configure a storage volume path and labeling steps
6) Bacularis configuration
   - Configure Bacularis to talk to Bacula Director (and any required console config)
   - Ensure web UI/API services start and are accessible
   - Provide URL, default login steps, and how to create an admin user
7) Networking / firewall
   - Required ports for Bacula components and Bacularis UI/API
   - firewalld commands to open ports and reload
8) SELinux considerations
   - Any required contexts for backup storage directories
   - Any booleans or policies if needed
9) Validation & smoke tests
   - Confirm services active
   - Confirm Bacularis UI loads
   - Run a manual backup job from CLI and from Bacularis
   - Show how to verify a backup exists and run a test restore to /tmp/restore-test
10) Troubleshooting section
   - Common failures: DB auth, console auth, director-to-sd auth, permissions, SELinux AVCs
   - Commands to inspect logs and status
   - How to enable debug logging temporarily

## IMPORTANT
- Do not invent repository URLs or package names. If uncertain, include a step to discover the correct repo/package via vendor docs and show the command output patterns to look for (e.g., dnf search, repoquery). Prefer authoritative sources.
- Provide commands and file content blocks that can be executed as root.
- Keep the plan linear and reproducible.

