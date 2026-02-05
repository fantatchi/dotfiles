---
name: naming
description: 日本語から土木業界向けの識別子名（変数・クラス・関数・型など）を生成する。命名規則や名前の相談、「この日本語を変数名にしたい」「クラス名どうする？」といった質問に使う。
argument-hint: [日本語の用語や概念]
allowed-tools: Read, Grep, Glob, Bash(rg *), Bash(grep *), WebFetch, WebSearch
---

日本語から土木業界向けの識別子名を生成してください。

## 入力

$ARGUMENTS

## 命名規則

1. まず、このプロジェクト内の既存コードを検索し、同じ概念や類似の概念がどう命名されているか確認する
2. 既存の命名パターンがあればそれに合わせる
3. なければ下記の用語集と参考資料を基に提案する

## 社内用語集（優先度：最高）

`./glossary.md` を参照すること。用語集に載っている単語は必ずその表記に従う（例：工事は Construction であって Work ではない）。複合語を作るときも用語集の単語を組み合わせる。

## 用語集にない場合の参照先（優先順）

1. プロジェクト内の既存コード（grep/ripgrepで類似の命名を探す）
2. TS出来形データ交換仕様書 http://www.nilim.go.jp/lab/pfg/ts/download/140314tsdataexchangev4_1.pdf
3. 土木工事共通仕様書 共通タグ http://www.cals-ed.go.jp/mg/wp-content/uploads/form_schema_rev10.pdf
4. JIS規格の英語 https://kikakurui.com/a0/A0203-2014-01.html
5. 法令翻訳 https://www.japaneselawtranslation.go.jp/ja
6. codic https://codic.jp/engine

## 出力形式

1. **既存コードの調査結果**: 類似の名前があれば提示
2. **推奨する名前**: 用途に応じて以下のケースで提案
   - PascalCase: クラス名・型名・インターフェース名
   - camelCase: 変数名・関数名・メソッド名
   - snake_case: 必要な場合（DB カラム名など）
   - UPPER_SNAKE_CASE: 定数名
3. **根拠**: どの資料/既存コードを参考にしたか
4. **注意点**: 類似語との使い分けがあれば補足

## 重要

- 用語集にない場合は、まず既存コードを検索してプロジェクトの慣習を確認する
