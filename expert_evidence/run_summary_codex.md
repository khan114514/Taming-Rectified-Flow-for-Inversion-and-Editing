# RFSteps codex: final research summary

Status: completed at 2026-10-03T11:43:30+08:00 Asia/Shanghai. Deadline epoch 1791002160. The final public confirmation is round84. There are 84 completed evaluation attempts: 81 successes and 3 failures/terminated runs.

Supervisor restart recovery was verified at 2026-10-03T11:58:13+08:00 and reverified at 2026-10-03T12:29:44+08:00, with 376 seconds remaining at the latest verification. The remaining time is below one hour, so the existing final confirmation was retained. Both recoveries rechecked every round's metrics, source hash, fixed budget and eight-field trajectory schema, plus the selected source and all 12 confirmation PNGs. No own-track evaluator is active, no new evaluation was launched, and the next unused round remains85. Each recovery appended a wrap_up record; final deliverables and the selected method are unchanged. No further research is planned.

Latest supervisor recovery was verified at 2026-10-03T12:34:45+08:00, with 75 seconds remaining. All 84 completion records, all 81 successful metric files and schedules, source hashes, and the existing round84 confirmation were independently rechecked. No own evaluator is running. The authoritative TASK_CONTRACT.md v2 explicitly specifies flux-dev; the workspace schnell instruction is stale. The frozen scorer hash matches the supplied manifest. This recovery updates the audit and appends a fourth wrap_up, retaining the completed research and next unused round85.

The selected method is the exact round61 snapshot, saved as `agent-output/best_method.py` and restored to `workspace/method.py`. Public PSNR is **21.21974298189495 dB**, score **1.0**, SSIM **0.7116836771313846**, pixel MSE **625.4500001271566**, and latent MSE **0.07312254204104345**. Final confirmation exactly reproduces every aggregate and per-image metric; all 12 reconstruction PNGs and schedule.json are byte-identical to round61. SHA256: `8b34e25306187b02cf1e21681a8e86797d5fbadcbec8a9657cac309ff041e051`.

All successful evaluations used 12 public images, 25 intervals per direction, two model calls per interval, and **100 NFE/image**. The same schedule was used for inversion and reconstruction, with empty prompt, guidance=1, inject=0, and 512×512 images. Scores below were emitted by the scorer; historical missing scores remain N/A.

## Method evolution

Uniform and low-time square clustering were inferior. High-time sine clustering became the strongest smooth control at 20.224832 dB, matching the reference anchor. Projecting sine onto grid128 improved PSNR to 20.949118 dB; grids64/125/256 were weaker. Restricting all intervals to powers of two was too strong. A soft 0.5 penalty for non-power-of-two intervals reached 21.210273 dB in round18.

Subsequent controls tested curve powers and blends, both-endpoint cosine clustering, time shifts, boundary layers, exponential/rational/polynomial warps, floor/ceil rounding, interval-length objectives, explicit bf16 division/rescaling costs, and bf16-exact adaptive lattices. None exceeded round18. Analytical Gaussian finite-step round-trip costs and h4 error-density models also failed to improve the main metric; CPU bf16 Gaussian proxies reached 21.097024 dB but remained below the final best.

Adding scaled-time embedding quantization error to the same soft sine projection produced the selected round61 method at weight4. Weights0.5/2/8 gave 20.735592/20.906439/20.730458 dB. Angular signal/noise warps, endpoint position weights, and h3/h4 regularization remained below best. The final selection uses mean PSNR even when score saturates or auxiliary metrics disagree.

Round83 was terminated while waiting for the GPU lock, before image evaluation, to start final confirmation. It is preserved with null metrics. Further minimum/maximum-step, adjacent-step smoothness, argument-power, and intermediate-penalty candidates remained unmeasured; they have no claimed PSNR. Exact duplicate schedules were skipped without allocating a round. Round84 intentionally repeats the selected method for confirmation.

## Selected method and theory

The method is a pure function of the requested step count; it does not inspect image identity, pixels, prompts, model outputs, or dataset files. The implementation uses only Python's standard `math` module.

For N=25, use grid G=128 and choose 25 positive integer lengths in 1,...,12 whose sum is 128. If x_i is the cumulative interval length, the target is

`x_i* = 128 * (1 - sin(pi/2 * (1 - i/25)))`.

Dynamic programming minimizes the sum of three costs:

1. Squared cumulative-node displacement `(x_i - x_i*)²`.
2. Arithmetic preference `0.5 * [step is not a power of two]`.
3. Embedding cost `4 * E(position,step) / mean_edge_E`, averaged over all feasible grid edges for normalization.

For bf16 round-to-nearest-even q, let `e(t)=(q(1000*q(t))-1000*t)²`. For an interval with high/low endpoints and their midpoint,

`E=e(high)+e(low)+2*e(midpoint)`.

The endpoint multiplicity and doubled midpoint reflect both directions using the same schedule. CPU Torch independently validated all 257 grid endpoint/midpoint scaled-time values against the standard-library rounding implementation. All selected endpoints and midpoints are exactly bf16-representable before the multiplication by 1000. No dtype or frozen update changes are made.

The returned schedule is:

```text
1, 0.9921875, 0.984375, 0.9765625, 0.96875, 0.9609375, 0.9453125, 0.8984375, 0.8671875, 0.84375, 0.8125, 0.78125, 0.7265625, 0.6796875, 0.640625, 0.59375, 0.53125, 0.484375, 0.421875, 0.3671875, 0.3125, 0.25, 0.1875, 0.125, 0.0625, 0
```

The [RF-Solver paper](https://arxiv.org/html/2411.04746v3) motivates a second-order Taylor update. In the supplied frozen code, the extra prediction occurs at half the interval, so the real-arithmetic update is explicit midpoint RK2. Finite precision prevents unrestricted algebraic simplification; the schedule objective preserves the actual update and accounts for a small part of its arithmetic.

Numerical diagnostics support the proposed tradeoff rather than establish a causal quality guarantee. Across all 100 time inputs, embedding RMS error falls from 0.901301143 in round18 to 0.833971110 in round61, while sine-node RMSE rises from0.003460088 to0.005720268. There are 16 power-of-two intervals in round61 versus 17 in round18.

An independent Gaussian RF surrogate uses `V(t)=t²+sigma²*(1-t)²` and `a(t)=((1+sigma²)*t-sigma²)/V(t)`. Its centered midpoint round-trip relative defect has leading `C(t)*h^4`, where

`C(t)=-sigma²*((1+sigma²)*t-sigma²)²/(4*V(t)^4)`.

The error-density prior `rho proportional to mean(abs(C))^(1/4)` follows by minimizing the continuum absolute-error bound at fixed total step count. Exact rational checks at 16 preset scale/location pairs agree with the derived coefficient; the maximum relative finite-h discrepancy at h=1/400 is 5.1511275207717504e-05. These image-independent surrogates were evaluated and their weaker PSNR is retained in the table.

## Evidence and limits

Independent recomputation from the 12 round61 reconstruction PNGs exactly reproduces the mean PSNR, with maximum per-image disagreement 7.105427357601002e-15. The audit is saved in [round61_psnr_audit.json](round61_psnr_audit.json). The final audit verifies every completed round's eight-field record, actual source hash and successful metric file; the frozen scorer hash also matches. Workspace method.py, best_method.py, and the selected evaluated snapshot are identical. No own-track evaluator remains running.

Relative to the measured baseline and raw sine/reference, round61 gains 1.858165844 dB and 0.994911416 dB in mean PSNR. It improves 7/12 images against each; gains are uneven. Its advantage over the earlier round18 is only 0.009469836 dB, with some images improving and others worsening. Selection on this small public set over many global schedules does not establish hidden-set generalization. Hidden performance remains for organizer verification.

## Environment provenance

The initial workspace instruction and scorer described schnell, but its main checkpoint was absent. Rounds01–02 failed before image evaluation. The organizer externally supplied a dev scorer at about 02:46, matching the available dev checkpoint and the organizer's revised TASK_CONTRACT.md; every successful result uses that supplied scorer. Candidate work did not substitute a model or edit frozen files.

The historical scorer SHA256 was `7ba27122b3e331bc4359ccf8d8637ce17fa04083be3f00f2c4367792240e78db`; the supplied successful-run/final scorer SHA256 is `17e1779437e61328f40c7574826a216a007d04f663798371c38dae9590382dc9`. The workspace instruction still describes schnell; this discrepancy is explicitly preserved rather than relabeling dev measurements. Anchors became available during round08; earlier missing scores remain null. Public anchors are baseline 19.361577137501065 and reference 20.22483156573475.

No hidden dataset files were accessed, and no other trajectory directory was entered. Evaluations were serial through the supplied entry point. All evaluated source snapshots, schedules, metrics, logs and hashes remain under their own round directories.

## Per-round results

| Round | Schedule | Public PSNR | Score | Outcome |
| --- | --- | ---: | ---: | --- |
| 01 | Official time_shift mu=0.63 | N/A | N/A | Missing schnell flow checkpoint; no image evaluation |
| 02 | Uniform | N/A | N/A | Missing schnell flow checkpoint; no image evaluation |
| 03 | Cosine, both endpoints | 20.212329 | N/A | Improved best at that time |
| 04 | Square, low-t clustering | 15.419368 | N/A | Successful; below selected best |
| 05 | Sine, high-t clustering | 20.224832 | N/A | Improved best at that time |
| 06 | Uniform | 17.959307 | N/A | Successful; below selected best |
| 07 | Original time_shift baseline | 19.361577 | N/A | Successful; below selected best |
| 08 | time_shift mu=1.5 | 19.641245 | 0.323969 | Successful; below selected best |
| 09 | Sine / grid125 | 19.751011 | 0.451123 | Successful; below selected best |
| 10 | Sine / grid128 | 20.949118 | 1.000000 | Improved best at that time |
| 11 | Smooth sine-power p=1.5 | 19.935899 | 0.665298 | Successful; below selected best |
| 12 | Sine DP, power-of-two intervals | 20.635418 | 1.000000 | Successful; below selected best |
| 13 | Sine-power p=1.5 / grid128 | 20.453204 | 1.000000 | Successful; below selected best |
| 14 | Sine-power p=1.25 / grid128 | 20.905768 | 1.000000 | Successful; below selected best |
| 15 | Sine-power p=0.75 / grid128 | 19.553352 | 0.222153 | Successful; below selected best |
| 16 | Sine / grid64 | 20.418674 | 1.000000 | Successful; below selected best |
| 17 | Sine / grid256 | 19.605151 | 0.282158 | Successful; below selected best |
| 18 | Soft sine DP, penalty0.5 | 21.210273 | 1.000000 | Improved best at that time |
| 19 | Soft sine DP, penalty1.0 | 20.785906 | 1.000000 | Successful; below selected best |
| 20 | Soft sine DP, penalty2.0 | 20.548943 | 1.000000 | Successful; below selected best |
| 21 | Cosine / grid128 | 19.972006 | 0.707125 | Successful; below selected best |
| 22 | time_shift mu0.63 / grid128 | 19.425692 | 0.074271 | Successful; below selected best |
| 23 | time_shift mu1.5 / grid128 | 19.698690 | 0.390514 | Successful; below selected best |
| 24 | Soft sine-power p1.25, penalty0.5 | 19.948752 | 0.680188 | Successful; below selected best |
| 25 | Soft sine-power p1.5, penalty0.5 | 20.253778 | 1.000000 | Successful; below selected best |
| 26 | Soft cosine DP, penalty0.5 | 20.294800 | 1.000000 | Successful; below selected best |
| 27 | Exp density a2 / grid128 | 20.522008 | 1.000000 | Successful; below selected best |
| 28 | Reverse-square / grid128 | 19.611622 | 0.289654 | Successful; below selected best |
| 29 | High-time boundary2 + uniform / grid128 | 19.804869 | 0.513513 | Successful; below selected best |
| 30 | High-time boundary4 + uniform / grid128 | 20.498185 | 1.000000 | Successful; below selected best |
| 31 | High-time boundary8 + uniform / grid128 | 20.827205 | 1.000000 | Successful; below selected best |
| 32 | Rational high-time warp / grid128 | 19.219764 | 0.000000 | Successful; below selected best |
| 33 | Exp density a1 / grid128 | 20.458407 | 1.000000 | Successful; below selected best |
| 34 | Soft boundary8 DP, penalty0.5 | 20.574755 | 1.000000 | Successful; below selected best |
| 35 | Sine / grid128 floor | 20.276320 | 1.000000 | Successful; below selected best |
| 36 | Sine / grid128 ceil | 20.414599 | 1.000000 | Successful; below selected best |
| 37 | bf16 arithmetic sine DP, penalty0.5, h^0 | 20.259531 | 1.000000 | Successful; below selected best |
| 38 | bf16 arithmetic sine DP, penalty1, h^0 | 20.578213 | 1.000000 | Successful; below selected best |
| 39 | bf16 arithmetic sine DP, penalty0.5, h^2 | 20.637363 | 1.000000 | Successful; below selected best |
| 40 | Embedding-aware soft sine DP, weight0.5 | 20.735592 | 1.000000 | Successful; below selected best |
| 41 | Embedding-aware soft sine DP, weight2 | 20.906439 | 1.000000 | Successful; below selected best |
| 42 | Sine increment DP, node0, step1, penalty0 | 20.217340 | 0.991321 | Successful; below selected best |
| 43 | Sine increment DP, node0, step1, penalty0.5 | 19.761769 | 0.463585 | Successful; below selected best |
| 44 | Sine increment DP, node1, step1, penalty0.5 | 19.476456 | 0.133076 | Successful; below selected best |
| 45 | Sine increment DP, node1, step4, penalty0.5 | 20.393648 | 1.000000 | Successful; below selected best |
| 46 | Soft sine/uniform blend12.5% | 20.961584 | 1.000000 | Successful; below selected best |
| 47 | Soft sine/uniform blend25% | 20.525204 | 1.000000 | Successful; below selected best |
| 48 | Soft sine/cosine blend12.5% | 20.831647 | 1.000000 | Successful; below selected best |
| 49 | Soft sine/cosine blend25% | 20.932914 | 1.000000 | Successful; below selected best |
| 50 | Soft cosine argument-power0.75 | 20.788324 | 1.000000 | Successful; below selected best |
| 51 | Soft cosine argument-power1.25 | 19.814127 | 0.524237 | Successful; below selected best |
| 52 | Soft cubic Hermite a1.5 | 20.863658 | 1.000000 | Successful; below selected best |
| 53 | Soft cubic Hermite a2.0 | 19.723127 | 0.418822 | Successful; below selected best |
| 54 | Gaussian round-trip DP sigma0.5/1/2, geometry0, penalty0 | 18.532414 | 0.000000 | Successful; below selected best |
| 55 | Gaussian round-trip DP sigma0.5/1/2, geometry0, penalty0.5 | 19.431271 | 0.080734 | Successful; below selected best |
| 56 | Gaussian round-trip DP sigma1/2/4, geometry0, penalty0.5 | 19.315474 | 0.000000 | Successful; below selected best |
| 57 | Gaussian round-trip DP sigma2/4/8, geometry0, penalty0.5 | 19.596130 | 0.271708 | Successful; below selected best |
| 58 | Gaussian round-trip DP sigma1/2/4, geometry0.25, penalty0.5 | 20.429735 | 1.000000 | Successful; below selected best |
| 59 | Gaussian round-trip DP sigma1/2/4, geometry1, penalty0.5 | 20.523233 | 1.000000 | Successful; below selected best |
| 60 | Adaptive bf16 lattice grid256, penalty0 | 20.273859 | 1.000000 | Successful; below selected best |
| 61 | Embedding-aware soft sine DP, weight4 | 21.219743 | 1.000000 | Selected final best |
| 62 | Embedding-aware soft sine DP, weight8 | 20.730458 | 1.000000 | Successful; below selected best |
| 63 | Gaussian h4 density sigma0.5/1/2, soft DP0.5 | 18.470497 | 0.000000 | Successful; below selected best |
| 64 | Gaussian h4 density sigma0.5/1/2, grid128 | 18.208517 | 0.000000 | Successful; below selected best |
| 65 | Gaussian h4 density sigma1/2/4, soft DP0.5 | 18.910384 | 0.000000 | Successful; below selected best |
| 66 | Gaussian h4 density sigma1/2/4, grid128 | 18.936060 | 0.000000 | Successful; below selected best |
| 67 | Gaussian h4 density sigma2/4/8, soft DP0.5 | 19.291106 | 0.000000 | Successful; below selected best |
| 68 | Gaussian h4 density sigma2/4/8, grid128 | 19.227379 | 0.000000 | Successful; below selected best |
| 69 | Gaussian h4 density sigma4/8/16, soft DP0.5 | 20.726184 | 1.000000 | Successful; below selected best |
| 70 | Gaussian h4 density sigma4/8/16, grid128 | 20.128735 | 0.888681 | Successful; below selected best |
| 71 | CPU bf16 Gaussian proxy sigma1/2/4, weight2, embeddingtrue | 21.097024 | 1.000000 | Successful; below selected best |
| 72 | CPU bf16 Gaussian proxy sigma2/4/8, weight2, embeddingtrue | 20.617135 | 1.000000 | Successful; below selected best |
| 73 | CPU bf16 Gaussian proxy sigma1/2/4, weight2, embeddingfalse | 21.014042 | 1.000000 | Successful; below selected best |
| 74 | Soft angular RF warp sigma1, power1 | 16.519170 | 0.000000 | Successful; below selected best |
| 75 | Soft angular RF warp sigma2, power1 | 19.303937 | 0.000000 | Successful; below selected best |
| 76 | Soft angular RF warp sigma4, power1 | 20.737485 | 1.000000 | Successful; below selected best |
| 77 | Soft angular RF warp sigma8, power1 | 20.640064 | 1.000000 | Successful; below selected best |
| 78 | Soft angular RF warp sigma2, power2 | 20.528822 | 1.000000 | Successful; below selected best |
| 79 | Soft angular RF warp sigma4, power2 | 19.954181 | 0.686476 | Successful; below selected best |
| 80 | Soft sine position-weight high, beta16 | 20.382341 | 1.000000 | Successful; below selected best |
| 81 | Soft sine h3 regularization weight2 | 20.204664 | 0.976637 | Successful; below selected best |
| 82 | Soft sine h4 regularization weight2 | 20.677808 | 1.000000 | Successful; below selected best |
| 83 | Constrained sine DP minimum2 | N/A | N/A | Terminated before GPU lock/image evaluation for finalization |
| 84 | Final confirmation of best round61 | 21.219743 | 1.000000 | Final confirmation; metrics and PNGs identical to round61 |

## Reproduction

```bash
bash /root/autoresearch_rfsteps_codex/workspace/evaluate.sh /root/autoresearch_rfsteps_codex/agent-output/best_method.py
```

This creates a fresh round and reproduces the fixed-budget public evaluation. Inspect the selected original evidence in `agent-output/rounds/round61/` and the independent final confirmation in `agent-output/rounds/round84/`. Full eight-field records, including failed runs and final wrap_up, are in [trajectory.jsonl](trajectory.jsonl). Final audit details are in [final_checks.json](final_checks.json).
