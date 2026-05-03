# Network

## Overview
This document provides a high-level overview of the homelab network architecture.

## Architecture
The network is designed with segmentation to separate different types of traffic and services:
-   **Management Network:** For Proxmox host management and infrastructure-level access.
-   **Services Network:** For internal homelab services and applications.
-   **DMZ Network:** For external-facing services (if applicable).

Network segmentation is achieved using VLANs, managed by a central router/firewall and core switch.

## Configuration
Network configuration details, including IP addressing schemes, VLAN IDs, and firewall rules, are maintained in the associated infrastructure-as-code (Terraform) repository.