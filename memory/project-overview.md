---
name: project-overview
description: プロジェクトの目的・構成・技術スタック
type: project
updated: 2026-09-03
---

# moewbgt — Overview

**Why:** 環境省 熱中症予防情報サイトが提供する暑さ指数（WBGT）と熱中症警戒アラートのデータを R で扱う。2026 年度から追加された WebAPI のクライアントを提供することが主目的。

## 技術スタック

- R パッケージ（`Depends: R (>= 4.1.0)`）。tidyverse 系（dplyr / readr / tidyr / purrr / stringr / rvest / lubridate / hms / glue / memoise / rlang / tidyselect）
- フォーマッタは air（`air.toml`、line-width 80）。renv・targets は未導入
- Claude Code / Codex 統合（`.claude/`, `.codex/`, `AGENTS.md`, `memory/`）

## 構成

- 関数定義: `R/`（`read_moe_wbgt.R` / `moe_alert.R` / `guides.R`）
- 導出スクリプト: `data-raw/`（`.Rbuildignore` 対象）
- 同梱参照テーブル: `inst/extdata/`（地点マスタ・都道府県ローマ字表）
- 出所と引き継いだ課題: `PROVENANCE.md`、未決着の判断: `TODO.md`
- 規約と設計上の注意: `CLAUDE.md`

## 現在地

[uribo/japan-heatstroke](https://github.com/uribo/japan-heatstroke) からのコピー直後。`man/` と `tests/` が無く `R CMD check` は通らない。WebAPI 未対応。

**How to apply:** 新しいタスクに着手する前にこのファイルで全体像を確認する。詳細な規約は `CLAUDE.md` を参照。
