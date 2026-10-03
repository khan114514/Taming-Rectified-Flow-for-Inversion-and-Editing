# 01 · 候选账本（autoresearch-paper-discovery）

> 模式：专家指定论文后的选题预检（非候选池快选）。搜索合同：图像生成 / 反演与编辑 / 推理时方法（training-free）/ 单卡 A100-40G 可承载 / 预算 ≤10h×2 轨迹。记录时间 2026-10-03（Asia/Shanghai）。

## 候选条目

| 字段 | 值 | 证据 |
|---|---|---|
| 规范标题 | Taming Rectified Flow for Inversion and Editing | PMLR v267 wang25ce |
| canonical IDs | PMLR v267 wang25ce；arXiv:2411.04746；OpenReview uDreZphNky | proceedings.mlr.press/v267/wang25ce.html |
| 论文链接 | https://proceedings.mlr.press/v267/wang25ce.html（PDF 可直下） | 已打开核对摘要与作者 |
| 官方源码 | https://github.com/wangjiangshan0725/RF-Solver-Edit | 已克隆（depth1），含 FLUX_Image_Edit 与 Hunyuanvideo_Video_Edit |
| 源码许可证 | 仓库根未见顶层 LICENSE；FLUX_Image_Edit/ 内含 LICENSE（Apache-2.0，继承自 FLUX 上游）与 model_licenses/ | 本地克隆核验 |
| 模型权重 | black-forest-labs/FLUX.1-schnell（Apache-2.0，非门控，hf-mirror 可达）；FLUX.1-dev 门控需 token，不采用 | hf-mirror API 200 |
| 文本编码器 | city96/t5-v1_1-xxl-encoder-bf16（encoder-only bf16，替代 google/t5-v1_1-xxl 全量 fp32）；openai/clip-vit-large-patch14 | hf-mirror API 200 |

## 逐门槛结论（candidate-gates）

| 门槛 | 结论 | 依据 |
|---|---|---|
| 可修改算法接口 | PASS | `flux/sampling.py::get_schedule` 是明确的步长分配接口；denoise 的 RF-Solver 二阶更新与 schedule 解耦 |
| 可信 Baseline | PASS | 官方 schnell 默认均匀 schedule，即仓库默认行为，可复现 |
| 独立 evaluator | PASS | 反演-重建 PSNR/SSIM 可由 scorer 从候选运行产物独立重算，不采信自报 |
| 指标方向 | PASS | PSNR 越高越好（论文 inversion 主指标之一） |
| 随机性协议 | PASS | 反演/重建全程无采样噪声注入（seed=None 路径不消耗 rng），结果确定；协议记为确定性任务 |
| 效应与噪声 | NEEDS_PILOT | 需 pilot 确认 Reference（偏移 schedule 族）对均匀 Baseline 有稳定正向改善 → 见 03/04 文档 pilot 记录 |
| 资源上界 | PASS | schnell bf16 ≈34.5GB 显存（A100-40G 可行）；单图 100 NFE ≈25-40s；12 图 public 评测 <10min |
| 容器化/Harness | PARTIAL | 本次运行于裸实例（GPU 云按量实例），非平台 Docker/Harbor；记为"未验证平台运行"，证据限本机 |
| 权威题库查重 | UNKNOWN | 未接入 authoritative duplicate registry；按规则记 UNKNOWN，不写"未重复" |

## 决策

- **RECOMMEND（附条件）**：所有硬门槛中仅"效应与噪声"待 pilot 动态证据。若 pilot 显示 Reference 族对 Baseline 无稳定改善（可信改善低于质量门），按 optimization-surface 第 7 条换方向（备选见 02 文档）。
- 备选候选（未展开）：HunyuanVideo 视频反演（成本超预算，REJECT-成本）；RF-Edit 编辑质量（主观指标不可独立复算，REJECT-评测）。
