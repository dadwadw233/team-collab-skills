---
title: <项目名> TODO
form: state
topic: [implementation]
updated: YYYY-MM-DD
status: current
tags:
  - todo
target_lines: 120
---

# <项目名> TODO

> [!summary]
> **事务级任务清单**（区别于 [NEXT](./NEXT.md) 的战略方向）。务必言简意赅，避免流水账；每条是一个可认领动作，背景和证据用标准 Markdown 链接指向 NEXT/设计文档/devlog/archive。每条 `进行中` / `阻塞` / `最近完成` 必须有 `@owner` 和时间戳。
> TODO 认领是公开意图声明 + 乐观冲突检测，不提供严格互斥；容易混淆的任务请保留稳定身份（如 `id: T-YYYYMMDD-NN` 或 `blocks: NEXT#N`）。

## 进行中

- [ ] <任务描述> @<owner> since YYYY-MM-DD (id: T-YYYYMMDD-NN; blocks: NEXT#N)
- [ ] <另一个任务> @<owner> since YYYY-MM-DD (id: T-YYYYMMDD-NN)

## 阻塞

- [ ] <任务> @<owner> since YYYY-MM-DD (blocked by: <阻塞原因，例如"等某个外部依赖"、"等某个决策拍板">)

## 待办（未认领，先到先得）

- [ ] <任务，不带 owner，谁想做谁领走>
- [ ] <任务> (id: T-YYYYMMDD-NN)

## 最近完成

- [x] <任务> @<owner> YYYY-MM-DD
- [x] <另一个> @<owner> YYYY-MM-DD

<!-- 当"最近完成"段超过 15-20 条时，定期归档到 archive/todo-YYYY-MM.md，或直接删除（历史在 _handoffs/ 和 开发记录/<用户名>/ 能找回） -->
