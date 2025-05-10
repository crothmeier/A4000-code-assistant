#!/usr/bin/env bash
set -euo pipefail

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export VLLM_ALLOW_LONG_MAX_MODEL_LEN=1

MODEL_ID="facebook/opt-2.7b"
MODEL_DIR="$HOME/code_llm_models/opt-2.7b"
VENV_DIR="$HOME/code_llm_env"

echo ">>> Setting up Python venv"
rm -rf "$VENV_DIR"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

echo ">>> Installing Python packages"
pip install --upgrade pip
pip install   torch==2.5.1+cu121   torchvision==0.20.1+cu121   torchaudio==2.5.1+cu121   --index-url https://download.pytorch.org/whl/cu121
pip install vllm==0.7.3 xformers==0.0.28.post3
pip install huggingface_hub

echo ">>> Downloading model"
python - <<'EOF'
from huggingface_hub import snapshot_download
import os
snapshot_download(
    repo_id=os.environ.get("MODEL_ID", "facebook/opt-2.7b"),
    local_dir=os.path.expanduser("~/code_llm_models/opt-2.7b"),
    local_dir_use_symlinks=False,
    resume_download=True)
EOF

echo ">>> Creating launch script"
cat <<EOS > ~/start_code_llm.sh
#!/usr/bin/env bash
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export VLLM_ALLOW_LONG_MAX_MODEL_LEN=1
source "$HOME/code_llm_env/bin/activate"
exec python -m vllm.entrypoints.openai.api_server \
  --model "$HOME/code_llm_models/opt-2.7b" \
  --host 0.0.0.0 --port 8002 \
  --gpu-memory-utilization 0.55 \
  --max-model-len 1024 \
  --swap-space 8 \
  --dtype half
EOS
chmod +x ~/start_code_llm.sh

echo ">>> Creating systemd unit"
cat <<EOS | sudo tee /etc/systemd/system/code_llm.service >/dev/null
[Unit]
Description=vLLM Code Assistant
After=network.target

[Service]
Type=simple
User=${USER}
ExecStart=${HOME}/start_code_llm.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOS

sudo systemctl daemon-reload
sudo systemctl enable code_llm

echo ">>> Done. Run: sudo systemctl start code_llm"
