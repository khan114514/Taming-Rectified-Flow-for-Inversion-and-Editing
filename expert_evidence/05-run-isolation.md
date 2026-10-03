# 05 · 运行协议与隔离（autoresearch-run-isolation）

> 依据 protocol-and-isolation.md 不变量逐条落实。记录时间 2026-10-03。

## 双轨迹

| 轨迹 | agent 命令 | 模型 | 通道 | 推理档 |
|---|---|---|---|---|
| codex | `codex` | gpt-6.1-sol | ModCon 中转（按量，经 17892 反向隧道） | xhigh |
| seed | `codex turbo` | doubao-seed-2-1-turbo-260628 | 方舟 Coding Plan（国内直连） | high |

- 工作区：`/root/autoresearch_rfsteps_codex` 与 `/root/autoresearch_rfsteps_seed`，独立 workspace/agent-output/prompt/supervisor/tmux 会话（rfsteps_codex、rfsteps_seed）。
- 同一冻结任务树 `/root/rfsteps/`（启动前逐文件 sha256 入档；改动即旧轨迹作废）。
- 两条轨迹使用同一公共任务摘要（instruction.md 内容一致），不共享可写目录。
- 凭据：supervisor 显式注入各自通道 key；候选进程环境最小化（HF_HUB_OFFLINE=1）。

## 隔离不变量落实

- **GPU**：单卡 A100-40G。两条轨迹的评测经 `/root/rfsteps/locks/gpu_eval.lock` flock 强制串行；显存峰值 ~35GB，不并行。
- **hidden 集**：只放组织者目录，不进 agent workspace；instruction 明令禁止读取，监控 grep 轨迹中的 hidden 路径访问。
- **隔离风险（如实记录）**：双 agent 同机 root 运行，文件系统层面无法强制互相不可读；隔离靠协议+轨迹审计（与 dd1 口径一致）。评级：残余风险中，靠监控与事后 QA 审计兜底。
- **评测器**：不读候选自报分数；每轮从 method.py 实跑重算；输出先写 rounds/roundNN 完整后再算完成。
- **外部数据流**：prompt、工具输出、评测摘要会发送给 ModCon/方舟；不含 hidden 图像内容；key 只以 env 注入，不落盘到轨迹。
- **血缘**：每轮 run_id 绑定 method.py sha256 + schedule.json + metrics.json + run.log；失败轮同样保留，不覆盖不拼接。

## 时长与停止

- 预算：每轨迹 10h 有效时长（闭合 turn 口径），deadline 写入 `/root/rfsteps/task/contract/deadline_epoch`（Asia/Shanghai）。
- supervisor：session 退出 60s 后续跑（有 trajectory.jsonl 则用 resume prompt）；到 deadline 或出现 `$OUT/.stop` 即退出不再重启。
- 安装/下载/排队/故障时间不计入有效时长——但本任务环境在启动前已就绪，模型加载在每轮内部属正常评测成本。

## 快照与恢复

- 权重与冻结任务树在实例数据盘（rivermind-data，释放不保存）；关机前同步回 Mac：轨迹、agent-output、anchors、设计文档、supervisor 日志。
- 恢复：新实例按 gpu-codex-relay-setup skill 重建双通道 → rsync /root/rfsteps 与轨迹目录 → supervisor 以 resume prompt 续跑；恢复前比对任务树哈希与已完成轮次。
- 租赁口径：按量实例，10h 窗口内不重租；Mac 侧隧道中断只影响 codex 轨迹（seed 国内直连），监控自动化每 30min 检查。

## 成本台账（启动时）

- GPU：GPU 云 A100-40G 按量实例；预计 10-12h。
- ModCon：gpt-6.1-sol 按量 token（xhigh）。
- 方舟 Coding Plan：包月订阅内，不计增量。
