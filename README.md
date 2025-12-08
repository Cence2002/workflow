# Workflow Project

This project provides scripts to manage Google Cloud VMs for development and a Development Container to ensure a consistent environment.

On any machine (local or VM), the recommended layout is:

```text
~/projects/
  workflow/         # this repo
  <your-projects>/  # created via scripts/create-project.sh
```

## Getting Started

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (running)
- [VS Code](https://code.visualstudio.com/) or [Cursor](https://cursor.sh/) with the **Dev Containers** extension installed ([ms-vscode-remote.remote-containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers))

### Cloning

On a new machine or VM:

```bash
mkdir -p ~/projects
cd ~/projects
git clone git@github.com:Cence2002/workflow.git workflow
cd workflow
```

### Using the Dev Container

1. Open `~/projects/workflow` in VS Code or Cursor.
2. Click **Reopen in Container** when prompted.

Inside the devcontainer:
* `$HOME` is `/home/bence`.
* `$HOME/projects` is a bind-mount of the host `~/projects`.

### Setup

Run the setup script **inside the container** to configure your environment (GCloud auth, SSH config, etc.):

```bash
./scripts/setup-host.sh
```

This script will:
* Authenticate with Google Cloud.
* Configure `~/.ssh/config` to include VM configurations.
* Generate an SSH key if needed.
* Configure Git user and email.

### Managing VMs

Create a new VM:
```bash
./scripts/create-vm.sh [vm-name]
```

Delete a VM:
```bash
./scripts/delete-vm.sh [vm-name]
```

Sync projects on the VM:
```bash
./scripts/sync-projects.sh
```

VMs follow the same layout: the workflow repo is cloned into `~/projects/workflow`.

## Creating New Projects

Projects always live under `$HOME/projects`.

To create a new minimal Python project:

```bash
./scripts/create-project.sh my-project
```

This creates `~/projects/my-project` with:
* An empty `README.md`.
* A minimal `.devcontainer/devcontainer.json` (Python 3).
* A fresh Git repository.

## SSH Configuration & Mounts

The Dev Container bind-mounts your local SSH directory (`~/.ssh`) to `/home/bence/.ssh`.

* SSH keys generated inside the container are saved to your host.
* `create-vm.sh` creates VM configs in `~/.ssh/vms/`.
* `setup-host.sh` adds `Include vms/*` to `~/.ssh/config`.

This allows VS Code Remote SSH to connect to any VM created by these scripts without additional configuration.
