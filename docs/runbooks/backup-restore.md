# Backup & Restore Runbook

## Overview

This runbook documents backup procedures, verification steps, and restoration procedures for all infrastructure components.

## Backup Strategy

### Backup Tiers

```
┌─────────────┐
│   Tier 1    │  Local backups (Proxmox Backup Server - Home)
│   Daily     │  7 day retention
└──────┬──────┘
       │
┌──────▼──────┐
│   Tier 2    │  Remote backups (PBS - Offsite)
│   Weekly    │  4 week retention + monthly archives
└─────────────┘
```

### What Gets Backed Up

| Component | Backup Method | Frequency | Retention | Tier |
|-----------|--------------|-----------|-----------|------|
| Proxmox Host Config | PBS | Daily | 7d/4w | Both |
| All VMs | PBS | Daily | 7d/4w | Both |
| All LXC Containers | PBS | Daily | 7d/4w | Both |
| Minio VM | PBS | Daily | 7d/4w | Both |
| Minio Data | PBS + Versioning | Continuous | 30d | Both |
| Terraform State | Minio Versioning | On change | 30d | Minio |
| Terraform Code | Git (GitHub) | On commit | Infinite | Git |
| Encrypted Secrets | Git (GitHub) | On commit | Infinite | Git |

### What's NOT Backed Up

- Local terraform.tfstate (intentionally, stored in Minio)
- Plaintext terraform.tfvars (intentionally, encrypted version in git)
- Temporary VM disks
- ISO images (can be re-downloaded)

## Backup Procedures

### Manual VM Backup

```bash
# On Proxmox host
# Backup specific VM
vzdump <VMID> --storage <PBS-storage> --mode snapshot

# Backup specific container
vzdump <CTID> --storage <PBS-storage> --mode snapshot

# Backup all VMs and containers
vzdump --all --storage <PBS-storage> --mode snapshot
```

### Manual Minio Bucket Backup

```bash
# Export bucket contents
mc mirror myminio/terraform-state ./backup/terraform-state-$(date +%Y%m%d)

# Encrypt backup
tar czf backup.tar.gz backup/
gpg --encrypt --recipient your-key backup.tar.gz

# Copy to safe location
```

### Terraform State Backup

Terraform state is automatically versioned in Minio:

```bash
# List state versions
mc ls --versions myminio/terraform-state/proxmox/terraform.tfstate

# Download specific version
mc cp --version-id <VERSION_ID> \
  myminio/terraform-state/proxmox/terraform.tfstate \
  terraform.tfstate.backup
```

## Backup Verification

### Weekly Verification Checklist

- [ ] Check PBS backup job completion status
- [ ] Verify backup sizes are reasonable (not 0 bytes)
- [ ] Check PBS storage capacity
- [ ] Verify remote replication completed
- [ ] Review backup logs for errors
- [ ] Test restore of one random VM (monthly)

### PBS Verification Commands

```bash
# Check backup jobs status
proxmox-backup-manager task list

# List backups for a VM
proxmox-backup-manager backup list --id <VMID>

# Verify backup integrity
proxmox-backup-manager backup verify <backup-id>
```

## Restoration Procedures

### Scenario 1: Restore Single VM

**Situation:** VM corrupted or accidentally deleted

**Steps:**
1. Access Proxmox web UI
2. Navigate to PBS storage
3. Select backup to restore
4. Click "Restore"
5. Choose restore options:
   - New VMID (if original still exists)
   - Original VMID (if deleted)
6. Start VM after restoration
7. Verify functionality

**Command-line:**
```bash
# List available backups
pbs-restore list --repository <pbs-repo>

# Restore VM
qmrestore <pbs-storage>:backup/<vm-backup> <VMID>

# Start VM
qm start <VMID>
```

### Scenario 2: Restore LXC Container

**Situation:** Container corrupted or accidentally deleted

**Steps:**
1. Access Proxmox web UI
2. Navigate to PBS storage
3. Select container backup
4. Click "Restore"
5. Choose new CTID if needed
6. Start container
7. Verify functionality

**Command-line:**
```bash
# Restore container
pct restore <CTID> <pbs-storage>:backup/<ct-backup>

# Start container
pct start <CTID>
```

### Scenario 3: Restore Minio VM

**Situation:** Minio VM corrupted

**Impact:** Terraform state unavailable

**Steps:**
1. Restore Minio VM from PBS (see Scenario 1)
2. Start Minio VM
3. Verify Minio service running:
   ```bash
   systemctl status minio
   ```
4. Verify buckets accessible:
   ```bash
   mc ls myminio/
   ```
5. Test Terraform access:
   ```bash
   terraform init
   terraform plan
   ```

**Recovery Time Objective (RTO):** 30 minutes
**Recovery Point Objective (RPO):** Last PBS backup (max 24 hours)

### Scenario 4: Restore Terraform State from Version

**Situation:** Terraform state corrupted after bad apply

**Steps:**
1. List state versions:
   ```bash
   mc ls --versions myminio/terraform-state/proxmox/terraform.tfstate
   ```

2. Download previous version:
   ```bash
   mc cp --version-id <VERSION_ID> \
     myminio/terraform-state/proxmox/terraform.tfstate \
     ./terraform.tfstate.recovered
   ```

3. Upload as current state:
   ```bash
   mc cp ./terraform.tfstate.recovered \
     myminio/terraform-state/proxmox/terraform.tfstate
   ```

4. Verify:
   ```bash
   terraform plan
   # Should show expected infrastructure
   ```

### Scenario 5: Proxmox Host Failure

**Situation:** Proxmox host hardware failure

**Steps:**
1. Install Proxmox VE on new hardware
2. Configure network to match old host
3. Add PBS storage
4. Restore VMs from PBS:
   ```bash
   # Restore each VM
   qmrestore <pbs-storage>:backup/<vm-backup> <VMID>
   ```
5. Restore containers:
   ```bash
   pct restore <CTID> <pbs-storage>:backup/<ct-backup>
   ```
6. Verify all services operational
7. Update DNS if IP changed

**RTO:** 4 hours
**RPO:** Last PBS backup (max 24 hours)

### Scenario 6: Complete Site Loss (Home Disaster)

**Situation:** Fire, flood, theft - entire home lab lost

**Steps:**

1. **Acquire new hardware:**
   - Proxmox-capable server
   - Network equipment

2. **Restore from remote PBS:**
   - Install Proxmox VE
   - Configure network access to remote PBS
   - Add remote PBS as backup storage
   - Restore all VMs/containers from remote PBS

3. **Restore Minio VM:**
   - Restore from remote PBS
   - Verify Terraform state intact

4. **Restore secrets from Git:**
   - Clone repository from GitHub
   - Decrypt terraform.tfvars.enc with Yubikey
   - Verify Terraform can access Proxmox

5. **Verify infrastructure:**
   ```bash
   terraform init
   terraform plan
   # Should show existing infrastructure
   ```

6. **Resume operations**

**RTO:** 1-2 days (including hardware acquisition)
**RPO:** Last remote backup (max 7 days)

## Recovery Testing

### Monthly Test Schedule

**Week 1:** Restore random VM to test VMID
**Week 2:** Restore LXC container to test CTID
**Week 3:** Restore Minio VM to isolated network
**Week 4:** Restore Terraform state from old version

### Test Documentation

| Date | Test Type | Result | Issues Found | Resolution Time |
|------|-----------|--------|--------------|-----------------|
| TBD | VM Restore | - | - | - |

## Backup Monitoring

### Daily Checks

- [ ] All scheduled backups completed
- [ ] No backup errors in logs
- [ ] PBS storage has adequate space

### Weekly Checks

- [ ] Remote replication completed
- [ ] Perform test restore
- [ ] Review retention policy effectiveness

### Monthly Checks

- [ ] Full disaster recovery test
- [ ] Review and update runbook
- [ ] Verify off-site backup accessibility
- [ ] Update emergency contact information

## Backup Storage Management

### PBS Storage Capacity

**Alert Thresholds:**
- Warning: 70% full
- Critical: 85% full
- Emergency: 95% full

**Actions when nearing capacity:**
1. Review retention policies
2. Remove old backups manually if needed
3. Add additional storage
4. Adjust backup schedule

### Pruning Old Backups

```bash
# PBS automatically prunes based on retention policy
# Manual prune if needed:
proxmox-backup-manager prune <backup-group> \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6
```

## Emergency Contacts

| Role | Contact | Phone | Email |
|------|---------|-------|-------|
| Primary Admin | TBD | TBD | TBD |
| Secondary Contact | TBD | TBD | TBD |

## Important Locations

**Remote PBS Location:** TBD
**Physical Access:** TBD
**Network Access:** TBD (VPN, firewall rules)

## Tools Required for Recovery

### Software
- Proxmox VE ISO
- Proxmox Backup Server access credentials
- Terraform binary
- Git client
- Yubikey (for decrypting secrets)

### Hardware
- Bootable USB with Proxmox installer
- Spare Yubikey (backup)
- Network cables
- Console access equipment

## Appendix

### PBS Configuration Backup

PBS configuration itself should be backed up:

```bash
# On PBS server
tar czf /tmp/pbs-config-$(date +%Y%m%d).tar.gz \
  /etc/proxmox-backup \
  /etc/network/interfaces

# Copy to safe location
scp /tmp/pbs-config-*.tar.gz user@remote:/backup/
```

### Automation Scripts

Location of backup automation scripts: TBD

### Related Documentation

- [Disaster Recovery Runbook](disaster-recovery.md)
- [Infrastructure Inventory](../infrastructure.md)
- [Services Documentation](../services.md)
