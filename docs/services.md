# Services

## Overview
This document lists the core services running within the homelab environment.

## Core Services
The homelab hosts a variety of services to support its operations and provide functionality:
-   **Proxmox VE:** The virtualization platform hosting all VMs and LXC containers.
-   **Proxmox Backup Server (PBS):** Manages backups for all virtualized environments.
-   **Minio:** Provides S3-compatible object storage, primarily used for Terraform state management.
-   **Uptime Kuma:** A monitoring service for tracking the status and availability of other services.

## Management
Detailed configuration, access, monitoring, and backup procedures for these services are defined and managed as part of the infrastructure-as-code in the main repository.