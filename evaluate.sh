#!/bin/bash
# rfsteps 每轮评测入口（轨迹期辅助脚本；Harbor 正式评分入口为 tests/test.sh）
# 用法: bash <TRACK_ROOT>/workspace/evaluate.sh [method_path]
# 评测器位置由 RFSTEPS_SCORER 指定，默认取包内 tests/run_eval.py
set -u
WS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRACK_ROOT="$(dirname "$WS")"
METHOD="${1:-$WS/method.py}"
OUT="$TRACK_ROOT/agent-output"
ROUNDS="$OUT/rounds"
SCORER="${RFSTEPS_SCORER:-$WS/tests/run_eval.py}"
mkdir -p "$ROUNDS"

N=$(ls -d "$ROUNDS"/round* 2>/dev/null | wc -l | tr -d ' ')
NN=$(printf "%02d" $((10#$N + 1)))
R="$ROUNDS/round$NN"
mkdir -p "$R"

if [ ! -f "$METHOD" ]; then
    echo "method 不存在: $METHOD" >&2
    exit 2
fi
cp "$METHOD" "$R/method.py"
echo "[evaluate] round$NN method=$METHOD scorer=$SCORER -> $R"

python3 "$SCORER" --method "$R/method.py" --out "$R" --split public 2>&1 | tee "$R/run.log"
RC=${PIPESTATUS[0]}

if command -v sha256sum >/dev/null; then
    (cd "$R" && sha256sum method.py schedule.json metrics.json 2>/dev/null) > "$R/hashes.txt"
fi
echo "[evaluate] round$NN exit=$RC, 结果见 $R/metrics.json"
echo "[evaluate] 请记得在 $OUT/trajectory.jsonl 追加本轮记录（八字段）"
exit $RC
