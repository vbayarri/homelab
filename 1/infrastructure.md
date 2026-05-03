# Infrastructure

## Overview
This document provides a high-level overview of the homelab infrastructure, which is primarily managed using Proxmox VE.

## Components
The infrastructure consists of:
-   **Proxmox Hosts:** Physical servers running Proxmox VE for virtualization.
-   **Virtual Machines (VMs):** Used for various application and infrastructure services.
-   **LXC Containers:** Lightweight containers for specific services.
-   **Storage:** Local and network-attached storage solutions for VMs, LXCs, and backups.

## Management
Infrastructure is defined and managed using Terraform. Detailed setup instructions for Terraform access can be found in the associated `proxmox-terraform` module documentation.