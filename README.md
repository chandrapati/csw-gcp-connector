# Cisco Secure Workload — GCP Connector Guide

> **Disclaimer:** Community reference guide by Cisco Solutions Engineering. Always consult [official Cisco Secure Workload documentation](https://www.cisco.com/c/en/us/products/security/tetration/index.html) for authoritative guidance.

GCP connector: GCE label ingestion, VPC flow logs, firewall enforcement, GKE visibility

---

## Contents

| File | Description |
|------|-------------|
| [`CSW-GCP-Connector-Guide.md`](./CSW-GCP-Connector-Guide.md) | Full integration guide (Markdown) |
| [`CSW-GCP-Connector-Guide.html`](./CSW-GCP-Connector-Guide.html) | Standalone HTML version |
| [`build.sh`](./build.sh) | Rebuild HTML from Markdown |

---

## Related Cisco Secure Workload Resources

| Repository | Description | Best for |
|------------|-------------|---------|
| [CSW-User-Education](https://github.com/chandrapati/CSW-User-Education) | Onboarding guides and concept explainers | New CSW users |
| [CSW-Agent-Installation-Guide](https://github.com/chandrapati/CSW-Agent-Installation-Guide) | Deploy CSW agents on Linux/Windows/cloud | Day-1 sensor deployment |
| [CSW-Policy-Lifecycle](https://github.com/chandrapati/CSW-Policy-Lifecycle) | Policy discovery → enforcement workflow | Policy management |
| [csw-ise-integration](https://github.com/chandrapati/csw-ise-integration) | ISE/pxGrid: user-identity–aware microsegmentation | Identity & Zero Trust |
| [csw-anyconnect-nvm](https://github.com/chandrapati/csw-anyconnect-nvm) | AnyConnect NVM: endpoint process flows + user identity | Endpoint telemetry |
| [csw-servicenow-integration](https://github.com/chandrapati/csw-servicenow-integration) | ServiceNow CMDB label enrichment for workload scopes | CMDB-driven policy |
| [csw-aws-connector](https://github.com/chandrapati/csw-aws-connector) | AWS VPC label ingestion + Security Group enforcement | AWS workloads |
| [csw-azure-connector](https://github.com/chandrapati/csw-azure-connector) | Azure VNet label ingestion + NSG enforcement | Azure workloads |
| [csw-gcp-connector](https://github.com/chandrapati/csw-gcp-connector) | GCP VPC label ingestion + firewall enforcement | GCP workloads |
| [csw-netflow-integration](https://github.com/chandrapati/csw-netflow-integration) | NetFlow v9/IPFIX agentless flow ingestion from switches | Network fabric visibility |
| [csw-erspan-integration](https://github.com/chandrapati/csw-erspan-integration) | ERSPAN agentless packet mirroring for legacy/OT/IoT | Agentless deep visibility |
| [CSW-Secure-Firewall-Integration-Guide](https://github.com/chandrapati/CSW-Secure-Firewall-Integration-Guide) | NSEL from Cisco Secure Firewall (FTD/ASA) | Firewall flow visibility |
| [csw-splunk-integration](https://github.com/chandrapati/csw-splunk-integration) | CSW syslog alerts → Splunk SIEM | SecOps / SIEM teams |
| [CSW-Compliance-Mapping](https://github.com/chandrapati/CSW-Compliance-Mapping) | Map CSW to NIST, PCI-DSS, HIPAA, CIS | Compliance & audit |
| [CSW-Tenant-Insights](https://github.com/chandrapati/CSW-Tenant-Insights) | Tenant-level reporting and analytics | Visibility metrics |
| [CSW-Operations-Toolkit](https://github.com/chandrapati/CSW-Operations-Toolkit) | Day-2 ops scripts: health checks, reporting, policy analysis | Ongoing operations |

> **Suggested customer journey:**  
> CSW-User-Education → CSW-Agent-Installation-Guide → CSW-Policy-Lifecycle → csw-ise-integration → csw-servicenow-integration → csw-splunk-integration → CSW-Compliance-Mapping → CSW-Operations-Toolkit
