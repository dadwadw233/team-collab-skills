<!--
此模板是**单条 ADR** 的结构。实际使用时两种方式之一：
(1) 单文件一条 ADR：文件名 `ADR-NNN-<slug>.md`，加 frontmatter:
    ---
    title: ADR-NNN <决策标题>
    form: decision
    topic: [<具体决策领域，如 architecture / product / ops>]
    updated: YYYY-MM-DD
    status: proposed | accepted | deprecated | superseded-by-ADR-XXX
    tags: [adr]
    ---
(2) 集中到一个 `决策日志.md`：每条 ADR 用下面 `# ADR-NNN` 一级标题分节，
    决策日志.md 整体 frontmatter 用 form=decision。
-->

# ADR-NNN：<决策标题>

- **日期**：YYYY-MM-DD
- **状态**：proposed / accepted / deprecated / superseded by ADR-XXX
- **作者**：<名字>

## 背景

<为什么需要这个决策？约束是什么？之前的状态是什么样的？>

## 决策

<具体选择了什么方案。一段话说清楚。>

## 理由

<为什么选这个方案而不是别的？列 2-5 条关键理由。>

- 理由 1
- 理由 2
- ...

## 考虑过的替代方案

- **方案 A**：<简述> — 为什么不选：<原因>
- **方案 B**：<简述> — 为什么不选：<原因>

## 影响 / 后果

**好的方面**：
- <具体好处>

**Trade-off（诚实面对代价）**：
- <这个决策带来了什么不便 / 成本 / 未来麻烦>

## 回滚条件（可选但推荐）

当以下情况出现时，重新评估本决策：

- <条件 1，例如"用户规模超过 N"、"某依赖被弃用"、"延迟要求变严"等>
- <条件 2>

## 相关

- 链接到相关的代码文件、issue、PR、其他 ADR
