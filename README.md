# Docker + Terraform + Ansible: Automated Deployment

## Project Overview

This project automates the provisioning of AWS infrastructure and deployment of a containerized Node.js application using Terraform, Ansible, and Docker.

The goal is to demonstrate Infrastructure as Code (IaC), configuration management, containerization, and repeatable application deployment.

## Architecture

**Deployment flow:**

Developer → Terraform → AWS VPC and EC2 → Ansible → Docker → Node.js application

- **Terraform:** Provisions AWS networking and EC2 infrastructure.
- **Ansible:** Configures the EC2 host, installs Docker, and deploys the application.
- **Docker:** Packages the Node.js application into a container.
- **Handlers:** Rebuild the image and redeploy the application when notified by changed source files.
- **Variables:** Configure application version, container name, ports, and environment.

## Technology Stack

- AWS EC2, VPC, subnet, Internet Gateway, route table, and security groups
- Terraform
- Ansible playbooks, roles, handlers, tags, and variables
- Docker
- Node.js
- Ubuntu / WSL
- Git and GitHub

## Project Structure

```text
docker-terraform-ansible/
├── app/
│   └── server.js
├── Dockerfile
├── terraform/
└── ansible/
    ├── deploy.yml
    ├── roles/
    │   └── webapp/
    │       ├── defaults/
    │       ├── handlers/
    │       ├── tasks/
    │       └── vars/
    │           ├── dev.yml
    │           └── prod.yml
```

## Deployment Workflow

1. Provision AWS infrastructure using Terraform.
2. Configure Ansible inventory and SSH connectivity to EC2.
3. Install and start Docker using Ansible.
4. Copy application files and Dockerfile to the EC2 instance.
5. Build the Docker image and run the application container.
6. Use Ansible handlers to rebuild and redeploy after relevant file changes.
7. Use tags and variable files to control deployment tasks and configuration.

## Verification

Application health endpoint:

```text
http://<EC2-PUBLIC-IP>:3000/health
```

Expected response:

```json
{"status":"healthy"}
```

Check the running container:

```bash
docker ps
```

Check the application environment variable:

```bash
docker exec devops-web-container printenv APP_ENV
```

## Key Learning Outcomes

- Provisioning AWS infrastructure with Terraform.
- Automating server configuration with Ansible.
- Using reusable Ansible roles and handlers.
- Understanding idempotency and task tags.
- Building and running Docker containers.
- Passing environment-specific configuration through variables.
- Troubleshooting SSH connectivity, Docker builds, and application health checks.

## Security and Cost Notes

- Never commit private SSH keys, passwords, access keys, or other secrets to GitHub.
- Restrict SSH access to a trusted IP address.
- Review AWS resources and charges after testing.
- Destroy Terraform-managed infrastructure when it is no longer required, after confirming the correct workspace and resources.

## Future Improvements

- Add a CI/CD pipeline with GitHub Actions or Jenkins.
- Add automated tests and image vulnerability scanning.
- Configure separate development and production infrastructure.
- Add HTTPS, monitoring, and centralized logging.


## Ansible Commands Cheat Sheet

### 1. Inventory and Connectivity

| Command | Purpose |
|---|---|
| `ansible-inventory -i ansible/inventory.ini --list` | Displays hosts and groups from the inventory. |
| `ansible -i ansible/inventory.ini webservers -m ping` | Tests Ansible connectivity to EC2. |
| `ansible -i ansible/inventory.ini webservers -m command -a "hostname"` | Executes a command on remote hosts. |
| `ansible -i ansible/inventory.ini webservers -b -m command -a "docker ps"` | Runs a command with privilege escalation (`sudo`). |

### 2. Playbook Validation and Execution

| Command | Purpose |
|---|---|
| `ansible-playbook -i ansible/inventory.ini ansible/deploy.yml --syntax-check` | Checks playbook syntax without deploying. |
| `ansible-playbook -i ansible/inventory.ini ansible/deploy.yml --list-tasks` | Lists tasks without executing them. |
| `ansible-playbook -i ansible/inventory.ini ansible/deploy.yml` | Runs the deployment playbook. |
| `ansible-playbook -i ansible/inventory.ini ansible/deploy.yml --check` | Performs a dry-run where supported; not every change can be predicted accurately. |
| `ansible-playbook -i ansible/inventory.ini ansible/deploy.yml --diff` | Shows supported file changes during execution. |

### 3. Tags

| Command | Purpose |
|---|---|
| `ansible-playbook -i ansible/inventory.ini ansible/deploy.yml --list-tags` | Lists available playbook tags. |
| `ansible-playbook -i ansible/inventory.ini ansible/deploy.yml --tags setup` | Runs tasks tagged `setup`. |
| `ansible-playbook -i ansible/inventory.ini ansible/deploy.yml --tags deploy` | Runs tasks tagged `deploy`. |
| `ansible-playbook -i ansible/inventory.ini ansible/deploy.yml --tags build` | Runs tasks tagged `build`. |

**Note:** A tag runs only matching tasks, but handlers and dependencies may affect the complete workflow. Verify the tags before using selective deployment.

### 4. Environment-Specific Variables

**Development deployment:**

```bash
ansible-playbook -i ~/docker-terraform-ansible/ansible/inventory.ini ansible/deploy.yml -e @ansible/roles/webapp/vars/dev.yml
```

**Production deployment:**

```bash
ansible-playbook -i ~/docker-terraform-ansible/ansible/inventory.ini ansible/deploy.yml -e @ansible/roles/webapp/vars/prod.yml
```

`-e` passes extra variables, and `@` tells Ansible to load them from a YAML file. These values override role defaults.

### 5. File and Package Management

**Create a directory on EC2:**

```bash
ansible -i ansible/inventory.ini webservers -b -m file -a "path=/opt/devops-app state=directory mode=0755"
```

**Install Docker on EC2:**

```bash
ansible -i ansible/inventory.ini webservers -b -m apt -a "name=docker.io state=present update_cache=true"
```

**Copy application source to EC2:**

```bash
ansible -i ansible/inventory.ini webservers -b -m copy -a "src=app/server.js dest=/opt/devops-app/server.js mode=0644"
```

### 6. Docker Verification Through Ansible

**Check running containers:**

```bash
ansible -i ansible/inventory.ini webservers -b -m command -a "docker ps"
```

**Check all containers, including stopped ones:**

```bash
ansible -i ansible/inventory.ini webservers -b -m command -a "docker ps -a"
```

**List application images:**

```bash
ansible -i ansible/inventory.ini webservers -b -m command -a "docker images devops-web-app"
```

**Check the application environment variable:**

```bash
ansible -i ansible/inventory.ini webservers -b -m command -a "docker exec devops-web-container printenv APP_ENV"
```

**Check application health from the local WSL terminal:**

```bash
curl http://<EC2-PUBLIC-IP>:3000/health
```

Expected response:

```json
{"status":"healthy"}
```

### 7. Important Ansible Concepts

- **Inventory:** Identifies target hosts and connection settings.
- **`-i`:** Specifies the inventory file.
- **`-m`:** Selects an Ansible module for an ad-hoc command.
- **`-a`:** Supplies arguments to that module.
- **`-b`:** Enables privilege escalation, usually through `sudo`.
- **`--syntax-check`:** Checks playbook syntax.
- **`--list-tasks`:** Lists tasks without running them.
- **`--tags`:** Selects tasks by tag.
- **`-e`:** Supplies extra variables.
- **`register`:** Saves a task's result in a variable.
- **`notify`:** Notifies a handler when a task reports a change.
- **Handler:** Runs when notified, usually for actions such as rebuilding and redeploying.
- **Idempotency:** Repeated runs should not make unnecessary changes when the desired state is already achieved.

### Important Notes

1. Run project-relative paths from the project root, unless you provide absolute paths.
2. Use the correct inventory path. In this project, the inventory is stored under `~/docker-terraform-ansible/ansible/inventory.ini`, while the project files are under `/mnt/c/Users/user/Documents/23Oct2026/docker-terraform-ansible/`.
3. Update the inventory if the EC2 public IP changes.
4. Never commit private keys or secrets to GitHub.
