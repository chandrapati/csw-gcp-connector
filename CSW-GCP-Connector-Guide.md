# Cisco Secure Workload — GCP Connector Guide

> **Disclaimer:** Community reference guide by Cisco Solutions Engineering. Always consult the [official Cisco Secure Workload documentation](https://www.cisco.com/c/en/us/products/security/secure-workload/index.html) — specifically [Configure and Manage Connectors → GCP Connector](https://www.cisco.com/c/en/us/td/docs/security/workload_security/secure_workload/user-guide/4_0/cisco-secure-workload-user-guide-on-prem-v40/configure-and-manage-connectors-for-secure-workload.html) — for authoritative guidance.

## Table of Contents
1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Capabilities](#3-capabilities)
4. [Prerequisites](#4-prerequisites)
5. [Step A — GCP Service Account & IAM Setup](#5-step-a--gcp-service-account--iam-setup)
6. [Step B — Configure the GCP Connector in CSW](#6-step-b--configure-the-gcp-connector-in-csw)
7. [Step C — VPC and Capability Configuration](#7-step-c--vpc-and-capability-configuration)
8. [GKE Integration](#8-gke-integration)
9. [Multi-Project Access](#9-multi-project-access)
10. [Verification](#10-verification)
11. [Limits](#11-limits)
12. [Troubleshooting](#12-troubleshooting)
13. [Related Resources](#13-related-resources)

---

## 1. Overview

The **GCP connector** in Cisco Secure Workload automatically ingests workload inventory and labels from **GCP VPCs**, streams **VPC flow logs**, and enforces segmentation using **GCP native VPC firewall rules** — all without deploying CSW agents on every GCE instance.

### What the GCP connector provides

| Capability | Description |
|------------|-------------|
| **Label ingestion** | GCE instance labels/metadata → CSW workload labels |
| **Flow log ingestion** | VPC flow logs from Cloud Storage → CSW for ADM |
| **Segmentation** | CSW policies → GCP VPC firewall rules (auto-programmed) |
| **GKE integration** | K8s node/pod/service metadata from GKE clusters |

> **No virtual appliance required.** Unlike the NetFlow / ERSPAN / ISE connectors, the GCP cloud connector does **not** run on a Secure Workload Ingest or Edge virtual appliance — Secure Workload connects to the GCP APIs directly.

---

## 2. Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                       GCP Project                                     │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  VPC Network                                                  │   │
│  │                                                               │   │
│  │  GCE instances with labels:                                   │   │
│  │    env=production, tier=app, team=finance                     │   │
│  │                                                               │   │
│  │  VPC Flow Logs ──► Log Router Sink ──► Cloud Storage Bucket   │   │
│  │                                                               │   │
│  │  VPC Firewall Rules ◄── CSW programs policies                  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                  ▲ Compute API (labels/inventory)                     │
│                  │ Storage API (flow logs)                            │
│                  │ Compute API (firewall rules)                       │
│  GCP Service Account with IAM roles (provisioned via CLI)             │
└──────────────────────────────────────────────────────────────────────┘
                   ▲
                   │ GCP REST API
                   │
┌──────────────────┴───────────────────────────────────────────────────┐
│  Cisco Secure Workload (SaaS or On-Prem)                              │
│  GCP Connector (no virtual appliance needed)                          │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3. Capabilities

### Label Ingestion
- GCE instance labels + metadata → CSW workload labels
- Synced continuously as GCP labels change

### VPC Flow Log Ingestion
- Requires **VPC-level** flow logs enabled on subnets and a **Log Router sink** to a **Cloud Storage bucket** (the bucket name is mandatory in the connector config)
- CSW reads the storage bucket — it **cannot** collect flow data from Google Cloud Operations Suite (Stackdriver)
- Flow logs must capture **both Allowed and Denied** traffic
- Required fields (any others ignored): Source Address, Destination Address, Source Port, Destination Port, Protocol, Packets, Bytes, Start Time, End Time, Action, TCP Flags, Interface-ID, **Log status**, Flow Direction

### Segmentation
- Requires Gather Labels to be enabled
- CSW policies → GCP VPC firewall rules. GCP firewall supports both Allow and Deny rules, but **GCP enforces strict rule-count limits — prefer an Allow-list with a Catch-All Deny**
- **Warning:** Enabling segmentation **overwrites existing VPC firewall rules**. CSW automatically backs them up first (see Step C); take your own backup as defense-in-depth

### GKE Integration
- Node, pod, and service metadata from GKE clusters

---

## 4. Prerequisites

### GCP requirements
- [ ] GCP **service account** created (dedicated to CSW connector)
- [ ] IAM policy list applied to grant required permissions (generated by CSW connector wizard)
- [ ] For flow logs: VPC flow logs enabled on subnets + Log Router sink → Cloud Storage bucket configured
- [ ] Inclusion filter for Log Router sink:
  ```
  resource.type="gce-subnetwork"
  log_name="projects/<PROJECT_ID>/logs/compute.googleapis.com%2Fvpc_flows"
  ```
- [ ] GCS bucket accessible by the service account
- [ ] For segmentation: Existing VPC firewall rules backed up

### CSW requirements
- [ ] CSW cluster administrator access
- [ ] Each VPC belongs to exactly **one** GCP connector

---

## 5. Step A — GCP Service Account & IAM Setup

### A1 — Create a dedicated service account

```bash
gcloud iam service-accounts create csw-connector-sa \
  --display-name="CSW Connector Service Account" \
  --project=YOUR_PROJECT_ID
```

Note the service account email: `csw-connector-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com`

### A2 — Generate and download the IAM policy list from CSW

1. Start the connector wizard in CSW (see Step B)
2. Select desired capabilities
3. Download the **IAM Policy List** from the wizard

### A3 — Apply IAM permissions via CLI (recommended)

```bash
# Apply each role from the generated IAM policy list:
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:csw-connector-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.viewer"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:csw-connector-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

# (Additional roles per the generated policy list, based on enabled capabilities)
```

### A4 — Create and download service account key

```bash
gcloud iam service-accounts keys create csw-connector-key.json \
  --iam-account=csw-connector-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

This JSON key file is used in the CSW connector configuration.

---

## 6. Step B — Configure the GCP Connector in CSW

### B1 — Navigate to connector configuration

CSW UI: **Manage > Workloads > Connectors**, then choose the **GCP** cloud connector and start the wizard. **For a POV, enable Gather Labels + Ingest Flow Logs first and leave Segmentation off** until you are ready to enforce.

### B2 — Enter GCP credentials

| Field | Value |
|-------|-------|
| **Service Account Key (JSON)** | Paste contents of `csw-connector-key.json` |
| **Project ID** | Your GCP project ID |

### B3 — VPC discovery

CSW discovers all VPCs in the project after credentials are entered.

---

## 7. Step C — VPC and Capability Configuration

### Labels / Inventory
Select GCE instance labels to ingest as CSW workload labels:
```
GCP label: env=production
CSW label: env = production
```

### Flow Log Ingestion

Set up the Log Router sink before enabling in CSW:

```bash
# Create a Cloud Storage bucket for flow logs
gcloud storage buckets create gs://csw-vpc-flow-logs-YOURPROJECT \
  --location=us-central1

# Create a Log Router sink
gcloud logging sinks create csw-flow-log-sink \
  storage.googleapis.com/csw-vpc-flow-logs-YOURPROJECT \
  --log-filter='resource.type="gce-subnetwork" log_name="projects/YOURPROJECT/logs/compute.googleapis.com%2Fvpc_flows"'

# Grant the sink's service account write access to the bucket
SINK_SA=$(gcloud logging sinks describe csw-flow-log-sink --format='value(writerIdentity)')
gcloud storage buckets add-iam-policy-binding gs://csw-vpc-flow-logs-YOURPROJECT \
  --member="$SINK_SA" \
  --role="roles/storage.objectCreator"

# Enable VPC flow logs on a subnet
gcloud compute networks subnets update YOUR_SUBNET \
  --region=us-central1 \
  --enable-flow-logs \
  --logging-filter-expr="ingressDirection OR egressDirection" \
  --logging-aggregation-interval=interval-5-sec \
  --logging-flow-sampling=0.5
```

In CSW connector, provide the **Cloud Storage bucket name**.

### Segmentation
> **Best practice (per Cisco): do _not_ enable Segmentation during initial configuration.** Gather labels and flows first, build/analyze policies in a workspace, enable enforcement on that workspace, then return to the connector to enable Segmentation for the VPC.

When you enable segmentation:
1. Confirm **Gather Labels** is enabled (required dependency)
2. **Enable enforcement in the workspace _before_ enabling Segmentation for the VPC.** Otherwise **all traffic on that VPC is allowed**
3. Set the workspace **Catch-All to Deny**; prefer an Allow-list because GCP enforces strict firewall rule-count limits

**Automatic backup/restore:** when you enable Segmentation for a VPC, CSW automatically backs up that VPC's firewall rules; when you disable Segmentation, CSW restores the rules **it modified** to the most-recent backup state (unrelated rules untouched). Toggle via **Manage > Workloads > Connectors > GCP Connector > Resources > Resources Tree**. Still take your own backup first:
```bash
gcloud compute firewall-rules list --format=json > gcp-firewall-backup.json
```

---

## 8. GKE Integration

Enable Kubernetes integration for GKE clusters:

1. Check **Enable Kubernetes / GKE** in the VPC configuration
2. CSW collects node, pod, and service metadata
3. Pod metadata appears in CSW inventory with K8s labels

IAM permissions for GKE (add to service account):
```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:csw-connector-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.viewer"
```

---

## 9. Multi-Project Access

To monitor VPCs across multiple GCP projects:

```bash
# For each additional project, grant the CSW service account access:
gcloud projects add-iam-policy-binding ADDITIONAL_PROJECT_ID \
  --member="serviceAccount:csw-connector-sa@PRIMARY_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.viewer"
```

In CSW, add the additional Project IDs to the connector configuration.

---

## 10. Verification

### Check connector status
**Manage > Workloads > Connectors**, then select the GCP connector. Confirm a recent sync on the per-VPC rows.

### Check inventory
On the GCP connector page, click a workload **IP address** to open its **Inventory Profile** → confirm GCP labels are present.

### Verify flow logs
**Investigate > Traffic** (Flow Search) → filter by VPC subnet CIDR → confirm flows are visible.

### Check enforcement (if segmentation enabled)
**Defend > Enforcement Status** (see *Enforcement Status for Cloud Connectors*), then confirm the programmed rules in the GCP Console → VPC network → Firewall.

---

## 11. Limits

| Metric | Limit |
|--------|-------|
| VPCs per GCP connector | Multiple |
| Projects per connector | Multiple (with cross-project IAM) |
| Connectors per VPC | Exactly one — a VPC can belong to only one GCP connector |
| Flow log scope | VPC-level flow logs only |
| Flow log destination | Cloud Storage only — not Cloud Operations Suite (Stackdriver) |
| Firewall rules | GCP enforces strict rule-count limits; prefer Allow-list + Catch-All Deny |

---

## 12. Troubleshooting

| Symptom | Check |
|---------|-------|
| Auth failure | Verify service account key JSON is valid and not expired; check IAM roles applied |
| No VPCs discovered | Confirm `roles/compute.viewer` applied to service account; verify project ID correct |
| Flow logs missing | Confirm VPC flow logs enabled on subnets; Log Router sink → GCS configured with correct filter; GCS accessible by service account; flow logs capture both Allowed and Denied |
| Segmentation not enforcing | Confirm Gather Labels enabled and the workspace is enforcing; verify `roles/compute.securityAdmin` or equivalent in IAM |
| VPC unexpectedly allows all traffic | Segmentation was enabled on a VPC whose workspace is not enforcing, or the Catch-All policy is not set to **Deny** |
| Concrete policy shows **SKIPPED** | Generated rule count exceeds GCP firewall limits — consolidate policies (e.g., larger subnets) |
| GKE metadata missing | Add `roles/container.viewer` to service account |

---

## 13. Related Resources

| Repository | Description | Best for |
|------------|-------------|---------|
| [csw-aws-connector](https://github.com/chandrapati/csw-aws-connector) | AWS VPC label ingestion, Security Group enforcement | AWS workloads |
| [csw-azure-connector](https://github.com/chandrapati/csw-azure-connector) | Azure VNet label ingestion, NSG enforcement | Azure workloads |
| [CSW-Agent-Installation-Guide](https://github.com/chandrapati/CSW-Agent-Installation-Guide) | Deploy CSW agents inside GCE VMs | Agent-based visibility |
| [CSW-Policy-Lifecycle](https://github.com/chandrapati/CSW-Policy-Lifecycle) | Policy discovery → enforcement workflow | Policy management |
| [CSW-Operations-Toolkit](https://github.com/chandrapati/CSW-Operations-Toolkit) | Day-2 ops scripts | Ongoing operations |

---
*Community reference — Cisco Solutions Engineering. Not an official Cisco product document.*
