#!/bin/bash
# rfsteps Harbor 评分入口（tests/test.sh，工作目录=/workspace）
# 1) 组装评测集：public 来自镜像内 public_assets；hidden 由组织者在评分时注入 /tests/hidden_assets
# 2) 运行冻结评测器 tests/run_eval.py（NFE=100/图、flux-dev bf16、双向同一 schedule）
# 3) 把归一化 score 写入 /logs/verifier/reward.json（Harbor 优先读取）
set -u

LOGS=/logs/verifier
mkdir -p "$LOGS"

CANDIDATE="${1:-/workspace/method.py}"
if [ ! -f "$CANDIDATE" ]; then
    echo "[test.sh] 未找到 $CANDIDATE，回退到 starter（Baseline）" >&2
    CANDIDATE=/workspace/environment/starter/method.py
fi

EVAL_ROOT="$(mktemp -d /tmp/rfsteps_eval.XXXXXX)"
ln -s /workspace/environment/public_assets/eval_public "$EVAL_ROOT/public"
SPLIT=public
if ls /tests/hidden_assets/*.png >/dev/null 2>&1; then
    ln -s /tests/hidden_assets "$EVAL_ROOT/hidden"
    SPLIT=full
fi
echo "[test.sh] candidate=$CANDIDATE split=$SPLIT"

export RFSTEPS_EVAL="$EVAL_ROOT"
export RFSTEPS_REPO_SRC="${RFSTEPS_REPO_SRC:-/workspace/repo/RF-Solver-Edit/FLUX_Image_Edit/src}"
export RFSTEPS_WEIGHTS="${RFSTEPS_WEIGHTS:-/opt/rfsteps/weights}"
export RFSTEPS_ANCHORS="${RFSTEPS_ANCHORS:-/tests/anchors.json}"

OUT="$(mktemp -d /tmp/rfsteps_out.XXXXXX)"
python3 /tests/run_eval.py --method "$CANDIDATE" --out "$OUT" --split "$SPLIT"
RC=$?

python3 - "$OUT/metrics.json" "$RC" "$LOGS/reward.json" <<'EOF'
import json, os, sys
metrics_path, rc, reward_path = sys.argv[1], int(sys.argv[2]), sys.argv[3]
reward = {"reward": 0.0}
if rc == 0 and os.path.exists(metrics_path):
    with open(metrics_path) as f:
        m = json.load(f)
    reward = {
        "reward": m.get("score", 0.0),
        "psnr": m["overall"]["psnr"],
        "ssim": m["overall"]["ssim"],
        "score_clipped": m.get("score_clipped"),
        "nfe_per_image": m.get("nfe_per_image"),
    }
tmp = reward_path + ".tmp"
with open(tmp, "w") as f:
    json.dump(reward, f, indent=2)
os.replace(tmp, reward_path)
print("[test.sh] reward:", json.dumps(reward))
EOF

exit $RC
