# rfsteps — Harbor Task

**优化 RF-Solver 高阶近似的步长分配（timestep schedule），在固定函数评估次数（NFE）下降低图像反演-重建误差。**

论文：*Taming Rectified Flow for Inversion and Editing*（ICML 2025, PMLR v267 wang25ce, arXiv:2411.04746）

## 任务概要

- 优化面：推理期时间步分配设计——`get_timesteps(num_steps, image_seq_len)` 返回 26 个单调不增节点，生成算法不限（参数族/分段/理论推导/查表/DP）
- 冻结：num_steps=25、NFE=100/图（双向各 25 步 × 每步 2 次前向）、flux-dev (bf16)、RF-Solver 二阶更新公式、prompt=""、guidance=1、512×512
- 主指标：平均 PSNR（越高越好）；score=(PSNR−B)/(U−B) 未裁剪
  - B=19.5289（官方 time_shift(μ) 默认 schedule）
  - U=21.5356（独立上限锚点，双轨 Agent 实测最强 schedule）
- Reference：sine schedule（20.4573，归一化 0.4627）

## 目录结构（Harbor 教学 profile，task.toml 在仓根）

```
instruction.md          # 题面
task.toml               # Harbor 配置（schema 1.3，GPU×1 A100/H100）
environment/
  Dockerfile            # 构建上下文=仓根；WORKDIR /workspace
  requirements.txt
  starter/method.py     # Starter = 官方 Baseline schedule
  public_assets/eval_public/   # 12 张公开评测图
tests/
  test.sh               # Harbor 评分入口 → /logs/verifier/reward.json
  run_eval.py           # 冻结评测器（sha256 见 anchors.json）
  anchors.json          # B/R/U 锚点与哈希清单
  hidden_assets/        # 交付时为空，评分时外部注入 hidden 集（4 张）
solution/               # Oracle（solve.sh + 参考 method.py）
repo/RF-Solver-Edit/    # 第三方只读参考实现（上游开源仓库）
evaluate.sh             # 轨迹期逐轮评测辅助脚本
```

## 运行要求

- GPU：A100/H100 ×1（bf16，峰值显存约 22.5GB）
- 权重（约 24GB，不打入镜像）：运行时挂载到 `/opt/rfsteps/weights`，结构：
  `flux-dev/flux1-dev.safetensors`、`flux-schnell/ae.safetensors`、`t5-encoder-bf16/`、`clip-vit-l14/`
  （sha256 见 `tests/anchors.json` 的 `weights_sha256`；可从 ModelScope/HuggingFace 获取 FLUX.1-dev 官方权重）

## 构建与评分

```bash
docker build -f environment/Dockerfile .
# Harbor 评分：tests/test.sh 由 Harness 调用，reward 写 /logs/verifier/reward.json
# 本地手动评测（需挂载权重）：
python3 tests/run_eval.py --method environment/starter/method.py --out /tmp/out --split public
```

## 提交证据（非 Harbor 任务组成部分，仅作提交材料镜像）

- `optimization_evidence/`：Baseline/Reference 正式运行证据（result.json、run.log、metrics、comparison_summary.json、训练证据说明.md、 pilot 候选）
- `expert_evidence/`：设计文档（01-05）、双轨轨迹 JSONL、run_summary、best_method、hidden 复核 metrics/log、anchors.json、冻结哈希清单
- `reference/method.py`：参考解（sine schedule）

## 许可与第三方内容

- `repo/RF-Solver-Edit/` 为上游开源仓库（github.com/wangjiangshan0725/RF-Solver-Edit）只读副本，保留其原始许可证与作者信息
- FLUX.1-dev 权重受其自身许可证约束（见 `repo/.../model_licenses/LICENSE-FLUX1-dev`），本仓不含权重
