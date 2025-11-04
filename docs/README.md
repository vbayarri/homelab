# Proxmox Homelab Documentation

## Overview

This repository contains Terraform infrastructure-as-code for managing Proxmox VE homelab infrastructure, along with comprehensive documentation.

## Documentation Structure

### Core Documentation
- [Infrastructure Inventory](infrastructure.md) - Current servers, VMs, LXC containers
- [Network Architecture](network.md) - IP addressing, VLANs, topology
- [Services](services.md) - Services and applications running

### Runbooks
- [Backup & Restore](runbooks/backup-restore.md) - Backup procedures and recovery steps
- [Disaster Recovery](runbooks/disaster-recovery.md) - DR scenarios and procedures

### Security
- [Security Setup](../proxmox-terraform/SECURITY_SETUP.md) - Secrets encryption and state management

## Quick Links

### Infrastructure Overview

**Current Setup:**
- Proxmox VE Cluster
- Terraform-managed resources
- Self-hosted services

**Key Services:**
- Minio (Terraform state storage)
- Proxmox Backup Server (PBS)

### Network Summary

| Network | VLAN | Subnet | Purpose |
|---------|------|--------|---------|
| Management | - | TBD | Proxmox management |
| Services | - | TBD | Internal services |
| DMZ | - | TBD | External-facing services |

### External Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Minio Documentation](https://min.io/docs/minio/linux/index.html)

## Getting Started

### Prerequisites

1. Terraform installed
2. Access to Proxmox API
3. Yubikey configured (for secrets)

### Initial Setup

```bash
# Clone repository
git clone <your-repo-url>
cd proxmox-terraform

# Copy example vars
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply
```

## Maintenance

### Regular Tasks
- Weekly: Review running services
- Monthly: Test backup restoration
- Quarterly: Review security configuration
- Yearly: Audit access credentials

### Monitoring
- Proxmox host health
- VM/LXC resource usage
- Backup job status
- Minio storage capacity

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-11-03 | Initial repository setup | - |
| 2025-11-03 | Added security documentation | - |

## Future Plans

- [ ] Deploy NetBox for infrastructure documentation
- [ ] Implement monitoring stack (Prometheus/Grafana)
- [ ] Add CI/CD pipeline for Terraform validation
- [ ] Document all VMs and services
