# 04 · 任务合同（autoresearch-task-authoring）

> 任务代号 **rfsteps**。依据 authoring-contract.md「必须先回答」逐条冻结。记录时间 2026-10-03。
> 里程碑门禁：selection（本文件+01/02/03）→ pilot（B/R 成对实跑+复算）→ long_run（双轨迹）→（后续）QA/release。
> **合同修订 v2（启动前）**：pilot v1 动态证据显示 flux-schnell 步数蒸馏模型反演机制失效
> （uniform/schnell 反演-重建 PSNR 仅 5-10dB，重建图为无关节新采样，证据 pilot/runs v1），
> 按 optimization-surface 第 7 条在轨迹启动前修订合同：backbone 改为 **flux-dev**
> （论文反演实验的实际骨干，ModelScope AI-ModelScope/FLUX.1-dev 单文件权重），
> 官方默认 schedule 相应从"均匀"变为 time_shift(mu)。旧合同下未产生任何轨迹，作废无血缘损失。

## 必须先回答（逐条）

1. **参赛者能改什么**：仅 `~/workspace/method.py` 的 `get_timesteps(num_steps, image_seq_len)`，返回 26 个 1.0→0.0 单调不增时间点；语义=双向共用的采样时刻表。
2. **冻结面**：flux-dev 全部权重（ModelScope 单文件，sha 入 anchors 证据）；RF-Solver 二阶 denoise 公式；num_steps=25（每图 100 NFE）；prompt="" 双向；guidance=1；inject=0；512×512；评测集（public 12 + hidden 4，PNG 中心裁剪）；评分器 run_eval.py；锚点 anchors.json。
3. **Baseline 合理性 / Reference 不泄题**：见 03；R 只给锚点分数与所属函数族名称，**不**把 R 的具体 26 个数值写进 instruction；参赛 workspace 不含 R 代码。
4. **主指标重算**：run_eval.py 从候选 method.py 重新加载模型实跑，PSNR 由重建 PNG 与原图独立计算；schedule 校验不过 / 缺文件 / 超时直接判该轮失败，不用旧结果。
5. **目标 vs 硬门**：PSNR 是优化目标；NFE=100/图、显存 <40G、单轮评测 <20min 是硬门；速度/显存不作为分数。
6. **证据**：每轮 `agent-output/rounds/roundNN/`（method.py 副本、schedule.json、metrics.json、run.log、重建 PNG、hashes.txt）；轨迹 `agent-output/trajectory.jsonl` 八字段（ts/run_id/round/action/summary/metrics/artifacts/hashes）。
7. **随机性**：确定性协议，无 training_seed；`run_id`=`<track>-roundNN-<epoch>`；round 编号单调；聚合=16 图（正式）/12 图（过程）算术平均。
8. **环境验收**：开发环境=目标环境=GPU 云按量裸实例（torch 2.12.1+cu130，A100-40G）；无 Docker/Harbor 层，记「未验证平台运行」；GPU 能力证据=pilot 真实运行记录。

## 评测集

- 16 张 512×512 PNG：RF-Solver-Edit 官方示例 6 张 + COCO val2017 10 张。
- public 12（agent 可见，过程迭代用）：repo_{art,boy,horse,nobel} + coco×8。
- hidden 4（仅组织者复核用）：repo_{cartoon,hiking} + coco_{000000000802,000000001296}。
- 协议：空 prompt 反演-重建（null-text 路径）；预处理中心裁剪+LANCZOS。

## NFE 口径（冻结）

| 项 | 值 |
|---|---|
| 每时间步模型前向 | 2（t_curr + midpoint，RF-Solver 二阶） |
| 单向步数 | 25 → 50 NFE |
| 每图总 NFE | 100（inversion 50 + reconstruction 50） |
| 单次 public 评测总 NFE | 1200 |

## 锚点与评分

- B = 官方 dev 默认 time_shift(mu≈0.63) schedule 的 full 集正式 PSNR；R = pilot 候选族（uniform / sine / square / mu15）中最强者的 full 集正式 PSNR。
- score = clip((PSNR−B)/(R−B), 0, 1)；过程分（public）与正式分（full/hidden）分别报告。
- anchors.json 由 pilot 实跑生成，含权重/代码/评测集 sha256 与时间戳；生成后冻结，改动即全部轨迹作废。

## 交付目录（双轨迹共用冻结树 + 各自可写区）

```
/root/rfsteps/                     # 组织者侧（对 agent 只读约定）
  repo/RF-Solver-Edit/             # 官方代码（冻结）
  task/eval/{public,hidden}/       # 评测集
  task/contract/{TASK_CONTRACT.md,anchors.json,deadline_epoch,frozen_hashes.txt}
  scorer/run_eval.py               # 可信评分器
  locks/gpu_eval.lock              # 单 GPU 串行
/root/autoresearch_rfsteps_{codex,seed}/
  workspace/                       # starter 副本（agent 可写）：instruction.md/method.py/evaluate.sh
  agent-output/                    # rounds/ trajectory.jsonl run_summary.md best_method.py
/root/prompts/rfsteps_{codex,seed}.txt, resume_{codex,seed}.txt
```

## pilot 记录（回填）

- [x] 权重下载完成（schnell 全套 + dev 单文件 + T5-bf16 + CLIP，ModelScope 通道）
- [x] pilot v1（schnell 合同）：uniform 反演-重建 PSNR 5-10dB，机制失效 → 合同修订 v2
- [ ] pilot v2（dev 合同）：B（官方 time_shift）full 集正式跑分 + 复跑一致性
- [ ] 4 候选 Reference 族成对跑分，选定 R（质量门 ≥+0.3dB）
- [ ] anchors.json 生成 + 冻结任务树哈希
- [ ] 每条轨迹一次真实 trial 的端到端 smoke
