---
title: handoff YYYY-MM-DD <topic>
form: trace
topic: [implementation]
date: YYYY-MM-DD
project: <项目名>
author: <作者名>
updated: YYYY-MM-DD
status: active
tags:
  - handoff
---

# Handoff YYYY-MM-DD · <topic>

## Summary

1-3 句事实性描述：本轮做了什么、达到什么状态。
**不要**写 chain-of-thought，不要写尝试过的废案，不要写流水账。

## Changed files

### 代码仓库侧
- `path/to/file` — <一句话说明>
- ...

### Docs 仓库侧
- `CURRENT.md` — <改了哪段>
- `_handoffs/...md` — 本文件
- ...

## Decisions made

- **<决策 1>**：<Why>
- **<决策 2>**：<Why>

> 如果包含架构 / 产品级决策，**同时**追加 ADR 到项目的 ADR 文件。

## Tests run

```
<实际跑的命令 1>
<结果，例如：45 passed, 8 skipped>

<实际跑的命令 2>
<结果>
```

没跑测试就写：

```
无
```

**不要编造测试结果。**

## Risks

**新发现**：
- <新风险简述>（同步更新 RISKS.md）

**本轮消除**：
- ~~<被解决的旧风险>~~

没有就省略整段。

## Suggested next steps

1. <有序动作 1，粒度让下一位接手能直接开工>
2. <动作 2>
3. ...

## 链接（可选）

- PR: #<番号>
- Issue: #<番号>
- 相关 ADR: `docs/decisions/NNNN-<slug>.md`
- 相关 devlog: `obsidian-docs/开发记录/<用户名>/<文件>.md`
