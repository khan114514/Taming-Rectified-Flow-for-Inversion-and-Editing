# rfsteps 任务环境（teaching-task-root-v1：构建上下文 = 任务根 workspace/harbor_task）
# 等价构建命令（静态描述，非本次 QA 执行）：
#   docker build -f workspace/harbor_task/environment/Dockerfile workspace/harbor_task
#
# 说明：FLUX 权重（约 24GB）不打入镜像，运行时挂载到 /opt/rfsteps/weights
# （结构：flux-dev/flux1-dev.safetensors、flux-schnell/ae.safetensors、
#  t5-encoder-bf16/、clip-vit-l14/，sha256 见 expert_evidence/anchors.json）。
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV EVFI_TASK_ROOT=/workspace
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY environment/requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

COPY instruction.md task.toml ./
COPY environment/starter ./environment/starter
COPY environment/public_assets ./environment/public_assets
COPY solution ./solution
COPY tests ./tests

# Agent 工作面：起始 method.py 即官方 Baseline schedule
COPY environment/starter/method.py ./method.py

# 评测输入路径（tests/test.sh 与 tests/run_eval.py 通过环境变量覆盖）
ENV RFSTEPS_REPO_SRC=/workspace/repo/RF-Solver-Edit/FLUX_Image_Edit/src
ENV RFSTEPS_WEIGHTS=/opt/rfsteps/weights
ENV RFSTEPS_ANCHORS=/workspace/tests/anchors.json
ENV HF_HUB_OFFLINE=1
ENV TRANSFORMERS_OFFLINE=1

# RF-Solver-Edit 仓库（只读参考实现）需在构建时另行提供：
#   构建前将仓库放入构建上下文 workspace/harbor_task/repo/RF-Solver-Edit
#   （github.com/wangjiangshan0725/RF-Solver-Edit，冻结哈希见 expert_evidence/frozen_hashes.txt）
COPY repo ./repo

CMD ["/bin/bash"]
