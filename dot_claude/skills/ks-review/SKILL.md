---
name: ks-review
description: コーディング規約に基づいてコードレビューを行う。PRレビュー、コード品質チェック、規約違反の指摘に使用する。「レビューして」「コードチェックして」「規約違反ない？」といった依頼で使う。
argument-hint: "[ファイルパス、PRのURL、または空（= 現在のブランチのdiff）]"
disable-model-invocation: true
context: fork
agent: general-purpose
allowed-tools: Read, Glob, Grep, Bash(git diff*), Bash(gh pr *)
---

# コードレビュー

## 引数の解釈

- **ファイルパス** → そのファイルをレビュー
- **PR URL / PR番号** → `gh pr diff` でdiffを取得してレビュー
- **空** → `git diff` でステージ済み + 未ステージの変更をレビュー

## レビュー手順

1. 対象の特定（引数に応じて）
   - ファイルパスの場合: `git diff HEAD -- <ファイルパス>` で変更差分を取得。差分がなければファイル全体を対象とする
   - PR URL / PR番号の場合: `gh pr diff <番号>` でdiffを取得
   - 空の場合: `git diff HEAD` でステージ済み + 未ステージの変更を取得
2. [rules.md](rules.md)（汎用規約）をロード
3. プロジェクトルートの `.claude/review-rules.md` が存在すればロード（プロジェクト固有規約）
4. 対象コードを読み込み、規約と照合
5. [template.md](template.md) の形式で結果を出力

## プロジェクト固有規約について

- プロジェクト固有の規約は **各プロジェクトの `.claude/review-rules.md`** に配置する
- このファイルが存在しない場合はエラーにせず、汎用規約のみでレビューする
- プロジェクトルートは `git rev-parse --show-toplevel` で取得する

## 注意事項

- 変更されたコードのみをレビュー対象とする（既存コードの全体レビューはしない）
- 周辺コンテキスト（importされているモジュール等）は必要に応じて読む
- レビュー結果は日本語で出力する
