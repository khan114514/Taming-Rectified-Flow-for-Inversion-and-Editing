#!/bin/bash
# Oracle 入口（可选）：把参考 schedule（sine）放到 Agent 工作面
set -euo pipefail
cp /solution/method.py /workspace/method.py
echo "[solve.sh] reference schedule (sine) installed to /workspace/method.py"
