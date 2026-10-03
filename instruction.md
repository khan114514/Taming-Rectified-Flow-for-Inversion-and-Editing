# rfsteps：RF-Solver 高阶近似的步长分配优化

## 任务

论文 *Taming Rectified Flow for Inversion and Editing*（ICML 2025, PMLR v267 wang25ce）
提出 RF-Solver：对 Rectified Flow ODE 的精确解做高阶 Taylor 展开，用二阶近似降低
反演（inversion）误差。本任务冻结 RF-Solver 的二阶更新公式与 NFE 预算，**只开放
一个优化面：时间步分配（timestep schedule / 步长分配）**。

目标：**在固定函数评估次数（NFE）下，降低图像反演-重建误差**。

## 你可以改什么

只能修改你工作区里的 `method.py`（起始内容为官方默认 schedule），实现：

```python
def get_timesteps(num_steps: int, image_seq_len: int) -> list[float]:
    ...
    return [1.0, ..., 0.0]   # 长度 num_steps+1，单调不增，取值 [0,1]
```

- 允许：任意生成 schedule 的算法——参数化函数族、分段设计、基于理论误差模型
  的推导、离线搜索出的查表值（直接硬编码 26 个数也合法）、混合策略等。
  这是方法级接口：你怎么"设计出这组步长"就是研究方法本身。
- 允许参考论文与公开文献设计新 schedule，但实现必须写在你自己的 method.py 里。

## 冻结项（违反 = 该轮无效）

- `num_steps = 25`（返回 26 个时间点）；每步 2 次前向（RF-Solver 二阶），
  双向各 25 步 → 每图 100 NFE。不得通过任何方式增减函数评估次数。
- 模型 flux-dev（bf16）与全部权重；RF-Solver 更新公式（scorer 内的 denoise）。
- prompt 为 `""`（双向），guidance=1，inject=0，图像 512×512。
- 评测代码 `tests/run_eval.py`、评测集、锚点文件：只读，不得修改。
- 同一 schedule 同时用于 inversion 与 reconstruction，不允许按方向返回不同值。

## 评测

- 正式评分由组织者运行 `tests/test.sh` 完成：先在 public 集（12 张）上评测，
  正式复核时注入同分布 hidden 集（4 张）做 full 评测。reward 写入
  `/logs/verifier/reward.json`。
- 主指标：**平均 PSNR（越高越好）**；辅助 SSIM / 像素 MSE / latent MSE。
- score = (PSNR − B) / (U − B)，**未裁剪**：B = 官方 Baseline 锚点（time_shift μ 偏移），
  U = 独立上限锚点（出题方预先校准，见 anchors.json `upper_bound`）；
  展示用裁剪分见 metrics.json 的 `score_clipped`。
- 不要用 public 集过拟合（例如只针对 12 张图逐图硬编码——schedule 只能是
  (num_steps, image_seq_len) 的函数，接口天然限制了这一点，但请勿尝试旁路）。
- 单 GPU：评测会自动排队（flock），请一次只跑一个评测，不要并行抢卡。

## 记录（每轮必须）

1. 每完成一轮评测，在 `agent-output/trajectory.jsonl` 追加一行 JSON，八个字段：
   `ts`（ISO8601, Asia/Shanghai）、`run_id`、`round`、`action`、`summary`、
   `metrics`（含 psnr/score）、`artifacts`（路径列表）、`hashes`（method.py 的 sha256）。
2. 失败的轮次同样记录（metrics 记 null，summary 写明失败原因）。
3. 任务结束时（或收到收尾指令时）写 `agent-output/run_summary.md`：
   方法演进、逐轮 PSNR/score 表、最佳方法说明与理论依据、复算命令；
   并把最佳 method.py 复制为 `agent-output/best_method.py`。

## 禁止事项

- 修改/替换冻结代码、权重、评测器、锚点、评测集。
- 读取 hidden 评测集（正式复核集，评分时由组织者注入）。
- 外发数据、自报分数代替真实评测、跨轮拼接证据。
- 长时间空转：没有想法时先跑理论分析或社区文献回顾，再上下一轮评测。

## 工具与网络策略

- 工具使用按平台默认工具策略。
- 禁止联网外发任何任务数据（评测集、权重、结果）；查阅公开文献是允许的，
  但实现必须写在你自己的 method.py 里。

## 环境

- 仓库代码（只读）：RF-Solver-Edit（FLUX_Image_Edit/src 为核心）。
- 关键实现：`flux/sampling.py` 的 `denoise()`（二阶更新）与 `get_schedule()`（官方默认）。
- 论文 arXiv:2411.04746；官方参考：dev 模型用 `time_shift(mu)` 偏移 schedule，schnell 默认均匀。
