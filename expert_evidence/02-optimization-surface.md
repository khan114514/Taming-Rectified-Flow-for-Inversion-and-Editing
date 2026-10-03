# 02 · 优化面合同（autoresearch-optimization-surface）

> 依据 references/selection-gates.md 逐项核对。记录时间 2026-10-03。

## 候选优化面

**推荐：RF-Solver 高阶近似的时间步分配（timestep schedule / 步长分配）**

- 代码入口：`RF-Solver-Edit/FLUX_Image_Edit/src/flux/sampling.py::get_schedule`（官方默认：dev 用 `time_shift(mu)` 偏移、schnell 均匀）。
- 方法接口（开放给参赛者）：`get_timesteps(num_steps, image_seq_len) -> list[float]`，返回 26 个从 1.0 单调不增至 0.0 的时间点；同一 schedule 双向共用。
- 固定项：RF-Solver 二阶更新公式（每步 2 次前向，含 midpoint 评估）、num_steps=25（每图 100 NFE）、**flux-dev 权重**（v2 修订，见下）、prompt=""、guidance=1、inject=0、512×512、评测集与评分器。
- 可变项（方法空间）：schedule 的生成算法本身——参数化函数族（偏移/余弦/多项式/分段）、基于局部截断误差模型的理论推导、离线搜索查表、自适应准则。接口允许产生新方法，不是"调一个常数"：步长向量是 25 维自由度的设计对象，且设计依据（误差模型）是开放研究内容。
- 主指标：反演-重建平均 PSNR（越高越好）；辅助 SSIM / 像素 MSE / latent MSE。
- 质量门：Reference 在 full 集上 PSNR 提升 ≥ +0.3dB（确定性协议，复跑差 <0.05dB 视为复算一致）。
- 成本：单次 public 评测 ≈8-12min（含模型加载）；pilot（B+4 候选 R）≈50min；双轨迹 10h 内每条可跑 25+ 轮。

## backbone 修订记录（v1 → v2）

- v1 选定 flux-schnell（非门控假设）。动态证据 1：schnell 在 HF 已转受限（hf-mirror 403 / xet 401），权重改走 ModelScope 单文件。
- 动态证据 2（决定性）：pilot v1 中 schnell 均匀 schedule 反演-重建 PSNR 仅 5-10dB，重建图为与原图无关的新采样——步数蒸馏模型的概率流 ODE 不覆盖反演路径，题目机制不成立。
- 处置（轨迹启动前）：backbone 改 flux-dev（论文反演实验的实际骨干，ModelScope 有单文件权重）；Baseline 相应改为官方 dev 默认 time_shift(mu) schedule。dev 同样 23.8GB bf16，显存/成本口径不变。

## 为什么它不是伪优化面（对第 1/7 条的回应）

- 不是"学习率/epoch/阈值"式常量搜索：接口承载的是函数/算法设计（schedule 生成规则），文献中 offset-noise、shift、logsnr 均匀、EDM 风格 rho-schedule 等均为已知方法族，存在真实方法空间。
- 高阶求解器的步长分配与精度是 ODE 数值分析的经典问题；RF-Solver 论文本身只给固定步长，步长分配是其未覆盖的自由度。
- 可辨改善由 pilot 验证（见 04 文档）；若可信改善长期低于质量门 → 换备选方向，不用长轨迹掩盖。

## 备选方向（不推荐，保留退路）

1. **RF-Solver 二阶项系数的加权校正**（在 Taylor 二阶项前加松弛系数/校正算子）：仍属采样器内部，但修改面侵入冻结公式，合同更难写清；仅当 schedule 面 pilot 失败时启用。
2. **inversion 与 reconstruction 的非对称 schedule**：违反"同一 schedule 双向共用"的现行冻结项，需先改合同；作为 v2 候选记录。

## 退出条件

- pilot 中候选 Reference 族（uniform / sine / square / mu15）对官方 time_shift Baseline 均无 ≥+0.3dB 改善 → 放弃本题，改走备选 1。
- 单轮评测成本 >20min 或显存无法稳定运行 → 降到 384×384 重订合同（需重跑锚点，轨迹作废重计）。
