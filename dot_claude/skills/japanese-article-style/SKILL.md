---
name: japanese-article-style
description: 'Rules specific to this user for Japanese first-person articles: experience reports, blog posts, tech notes about what the author actually tried, and Obsidian resource notes. Covers who the narrator is (the user, not Claude), replacing the user''s in-house tool names with reader-facing words, stating the scope of each observation, keeping verified / inferred / unverified facts apart, and paragraph formatting. Use when writing, drafting, or rewriting a Japanese article, blog post, or note that reports the author''s own experience. For documents that build an argument (book chapters, specifications, design docs), use japanese-doc-style instead.'
---

# 日本語記事の文章規範（体験記・ブログ）

体験記、ブログ記事、Obsidian の記事ノート（`30_resource/`）が対象。書籍の章、仕様書、設計ドキュメントには当てない（`japanese-doc-style` を使う）。自分の検証結果を根拠に一般論を述べる技術記事は、読者に「筆者が何をどう試したか」を渡すのが主なら本規範、一般に成り立つ主張を証明するのが主なら `japanese-doc-style`。

この規範は、Claude が自力では知り得ないこの環境固有の事項だけを書く。文章の上手さに関する一般論は置かない（2026-10-01 の A/B 検証で、一般論を足した稿のほうが AI 臭いと評価された。削った節は `~/.claude/docs/japanese-article-style-retired.md`）。

## 書き手はユーザーであって Claude ではない

一人称の「私」はユーザーを指す。Claude 自身の作業手順・判断基準・内部方針を本文に出さない。
AI と協業した記録を書くのはよい。そのときも主体をぼかさない。「返ってきた」「調べてもらった」で済ませず、誰が何をやったかが見える形にする（「Claude に叩かせた」「こちらがクリックした」）。
Claude が助かった／うまくやった話を書かない。読者が知りたいのは、その作業をやる人が何に詰まって何で解けたかである。

## 内輪の語を読者の語へ言い換える

ユーザーの運用環境でしか通じない名前を、そのまま本文へ持ち込まない。スキル名やスラッシュコマンド（`/context-load` 等）、タスクストアのセクション名（Inbox / Next / Waiting）、自作の呼称（捕捉箱・作業キュー）は、読者にとって未定義の固有名詞になる。
言い換えるか、初出で 1 行説明する。運用の仕組みそのものが記事の主題でない限り、名前は要らない。

## 観測範囲を明示する

一件の経験から一般論へ飛ぶとき、何が今回の環境・案件だけの条件だったかを書く。「私の環境では」「今回の案件では」のような限定を、根拠が出てきたその場に添える。末尾へまとめない。

## 事実の等級を混ぜない

実行して確認した / コードや文書を読んで推論した / 未確認 の 3 段階を区別して書く（`~/.claude/CLAUDE.md` の基本方針と同じ）。実行していないことを、実行したかのように滑らかに書かない。

## 整形

一文ごとの改行はしない。段落として書き、空行で段落を区切る（`japanese-doc-style` との最大の違い）。

## 書き上げたら点検する

書き手がユーザーで一貫しているか。読者の知らない内輪の名前が残っていないか。この 2 点は構造や文体が整っていても素通りするので、独立して確認する（実際に書き手が Claude になった稿と、スキル名をそのまま使った稿の 2 回、全面書き直しになった）。
