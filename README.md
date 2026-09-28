# Secure Three-Tier Azure Infrastructure

A hands-on Azure cloud infrastructure project built with Terraform that demonstrates Infrastructure as Code (IaC), network segmentation, least-privilege access, Linux administration, and secure communication between application tiers.

## Project Overview

This project deploys a segmented three-tier architecture in Microsoft Azure using Terraform.

The environment separates the web, application, and database layers into dedicated subnets and uses Network Security Groups (NSGs) to restrict communication between tiers.

### Architecture

```text
                    Internet
                       |
                    HTTP :80
                       |
                 +-------------+
                 |   Web Tier  |
                 |   Nginx     |
                 |   vm-web    |
                 | 10.20.1.0/24|
                 +-------------+
                       |
                 TCP 5000 only
                       |
                 +-------------+
                 |  App Tier   |
                 | Flask API   |
                 |   vm-app    |
                 | 10.20.2.0/24|
                 +-------------+
                       |
                 TCP 5432 only
                       |
                 +-------------+
                 | Database    |
                 | PostgreSQL  |
                 |    vm-db    |
                 | 10.20.3.0/24|
                 +-------------+
```

## Technologies Used

- Microsoft Azure
- Terraform
- Azure Virtual Network
- Azure Virtual Machines
- Network Security Groups
- Linux / Ubuntu
- Nginx
- Python / Flask
- PostgreSQL
- Azure CLI
- Git / GitHub

## Network Design

The Azure virtual network is segmented into three subnets:

| Tier | Subnet | Purpose |
|---|---|---|
| Web | `10.20.1.0/24` | Public-facing Nginx web tier |
| Application | `10.20.2.0/24` | Private Flask application tier |
| Database | `10.20.3.0/24` | Private PostgreSQL database tier |

Only the web tier is directly exposed to inbound Internet traffic.

The application and database tiers communicate over private Azure networking.

## Security Controls

Network Security Groups enforce communication boundaries between tiers.

- Internet traffic is permitted to the web tier on TCP port 80.
- SSH administrative access to the web tier is restricted to a specific source IP.
- Web-to-application traffic is restricted to TCP port 5000.
- Application-to-database traffic is restricted to PostgreSQL TCP port 5432.
- The application and database VMs do not require public-facing application endpoints.
- Terraform state files and local Terraform directories are excluded from source control.

This design reduces unnecessary exposure and demonstrates network segmentation and least-privilege access.

## Application Flow

A request travels through the environment as follows:

```text
Client
  |
  v
Nginx Web Server
  |
  | TCP 5000
  v
Flask Application
  |
  | TCP 5432
  v
PostgreSQL Database
```

Nginx acts as the public-facing reverse proxy and forwards API requests to the Flask application running on the private application tier.

The Flask application then communicates with PostgreSQL on the private database tier.

## Validation

End-to-end connectivity was tested after deployment.

The application API successfully communicated with PostgreSQL through the segmented network:

```json
{
  "database": "connected",
  "project": "Secure Azure Infrastructure",
  "status": "Operational"
}
```

This validates the complete traffic path:

```text
Internet -> Web Tier -> Application Tier -> Database Tier
```

while maintaining network separation between the three layers.

## Infrastructure as Code

Terraform is used to define and deploy the Azure infrastructure, including:

- Resource group
- Virtual network
- Three application subnets
- Network Security Groups
- NSG security rules
- NSG-to-subnet associations
- Network interfaces
- Linux virtual machines
- Public IP resources
- Infrastructure outputs
- Resource tagging

Terraform provides a repeatable deployment process and keeps the infrastructure configuration version-controlled.

## Repository Structure

```text
azure-secure-infrastructure/
|
|-- main.tf
|-- variables.tf
|-- outputs.tf
|-- providers.tf
|-- .gitignore
|-- README.md
```

## Key Skills Demonstrated

- Azure infrastructure deployment
- Infrastructure as Code with Terraform
- Azure virtual networking
- Subnet segmentation
- Network Security Groups
- Linux server administration
- Nginx reverse proxy configuration
- REST API deployment
- PostgreSQL configuration
- Private tier-to-tier connectivity
- Azure CLI administration
- Git version control
- Cloud troubleshooting

## Future Improvements

Potential enhancements include:

- Azure Key Vault for centralized secret management
- Azure Bastion for administrative access
- HTTPS/TLS termination
- Azure Monitor and Log Analytics
- Remote Terraform state using Azure Storage
- CI/CD deployment through GitHub Actions
- Terraform modules for reusable infrastructure components
- Application Gateway and Web Application Firewall

## Purpose

This project was built as a hands-on cloud engineering and security portfolio project to demonstrate the ability to deploy, secure, troubleshoot, and validate a multi-tier Azure environment using Infrastructure as Code.




## Architecture Diagram

```text
                         INTERNET
                            |
                         HTTP :80
                            |
                            v
                  +-------------------+
                  |     WEB TIER      |
                  |      vm-web       |
                  |       Nginx       |
                  |   10.20.1.0/24    |
                  +---------+---------+
                            |
                         TCP 5000
                    NSG: Web -> App
                            |
                            v
                  +-------------------+
                  |     APP TIER      |
                  |      vm-app       |
                  |     Flask API     |
                  |   10.20.2.0/24    |
                  +---------+---------+
                            |
                         TCP 5432
                    NSG: App -> DB
                            |
                            v
                  +-------------------+
                  |   DATABASE TIER   |
                  |       vm-db       |
                  |    PostgreSQL     |
                  |   10.20.3.0/24    |
                  +-------------------+
```

Terraform manages the Azure infrastructure, including the virtual network, subnets, NSGs, network interfaces, and virtual machines.