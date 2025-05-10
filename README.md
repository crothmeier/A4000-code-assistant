# Code Assistant Deployment (vLLM, RTX A4000)

This repository automates the setup of a local code assistant using vLLM on a single-GPU node.

## Environment

- Ubuntu 24.04 LTS
- NVIDIA RTX A4000 (16GB VRAM)
- Python 3.12
- CUDA 12.1 stack

## Components

- `deploy_code_assistant.sh`: One-shot setup for environment, Python packages, model pull, and systemd service.
- `start_code_llm.sh`: Launch script for vLLM OpenAI-compatible API.
- `code_llm.service`: Systemd unit file.
- `vs-code/continue-config.json`: Config for Continue.dev in VS Code.

## Quick Start

```bash
chmod +x deploy_code_assistant.sh
sudo ./deploy_code_assistant.sh
```

Then open a tunnel:

```bash
ssh -L 8000:localhost:8002 crathmene@your-server-ip
```

Browse to: [http://localhost:8000/docs](http://localhost:8000/docs)
