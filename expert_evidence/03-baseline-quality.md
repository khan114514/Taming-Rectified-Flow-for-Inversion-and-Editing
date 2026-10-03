# 03 · Baseline 合理性检查（autoresearch-baseline-quality）

> 记录时间 2026-10-03（设计阶段静态审查；动态 run 证据在 pilot 后回填，见 04 文档）。

## 角色

- **Starter** = 合理 naive 起点：官方 dev 默认 time_shift(mu) 偏移 schedule，可直接运行。
- **正式 Baseline（兼评分锚点 B）** = 同一官方默认 schedule 在冻结协议下的正式结果。
  选择理由：它是 RF-Solver-Edit 仓库对 flux-dev 的出厂默认行为
  （`get_schedule(..., shift=True)` + `time_shift(mu)`，mu 由序列长线性估计），
  代表"论文方法 + 官方默认步长"这一自然对照；不是为放大差距而设的弱化版。
  （v2 修订：backbone 由 schnell 改 dev 后，Baseline 从"均匀"相应改为官方 dev 默认，
  依据见 02 文档修订记录。）
- **Reference（锚点 R）** = 仅证明改进空间：从候选 schedule 族中 pilot 选出的最强者
  （候选：uniform / sine / square / mu15 强偏移）。同协议、同预算、同评测器。

## 八项检查（设计阶段）

| 项目 | 状态 | 证据与理由 |
|---|---|---|
| B01 代表性 | 通过 | Baseline 为官方实现对官方模型的默认配置；无"故意过时"问题（论文本身未提供步长分配的更强默认） |
| B02 实现与训练健全 | 不适用/通过 | 推理任务无训练；实现直接复用官方 `denoise()`，不截步、不改公式 |
| B03 公平预算 | 通过 | NFE 由合同冻结（每图 100），B/R/参赛者同一上限；无追加资源通道 |
| B04 配置与搜索公平 | 通过 | Baseline 参数=官方默认，非异常值；Reference 候选族与选择规则在 pilot 前固定（本节记录即冻结） |
| B05 随机性公平 | 不适用 | 确定性协议（无采样噪声）；复跑一致性由 pilot 复算验证 |
| B06 基本锚点 | 通过 | Starter=Baseline 兼任有理由（官方默认）；sanity：退化常数 schedule 被 validator 拒绝，NFE 无法缩水 |
| B07 改进归因 | 通过 | R 相对 B 唯一变量是 schedule；权重、prompt、guidance、步数、图像集全部冻结 |
| B08 选择披露 | 通过 | 本节即披露：来源、理由、角色映射、限制（仅 512×512、schnell、空 prompt 下的结论） |

关键红旗：未发现直接红旗。
边界：以上为静态审查 + 协议设计结论；"Baseline 实际可达分数"与"Reference 实际提升"以 pilot 动态证据为准（04 文档回填），静态一致不等于独立复现。
