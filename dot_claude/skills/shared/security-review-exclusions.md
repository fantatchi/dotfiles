# セキュリティレビュー 除外リスト（ペルソナ prompt 貼り付け用）

公式 `/security-review`（Claude Code CLI 2.1.243 埋め込みプロンプト）の除外規定を**逐語**で保持したもの。
セキュリティ観点のペルソナを立てる回に、この 2 リストを**要約せずそのまま** prompt へ貼る。

なぜ逐語か: 要約するとペルソナが「レビュー対象側の主張」と誤認して偽陽性を生む
（`[[feedback_pr_review_persona_prompt_verbatim]]`、PR #19 実例）。英語原文のまま貼ってよい。

貼り方の例:

```
以下は当方の環境で標準採用しているセキュリティ指摘の除外規定です（公式 /security-review 原文）。
これに該当する指摘は報告しないでください。
<ここに下記 2 ブロックを貼る>
```

## 前提（原文と併せて渡す）

- 対象は **この PR が新しく持ち込んだ**セキュリティ影響のみ。既存のセキュリティ懸念には触れない
- 実際に悪用可能だと **80% 以上の確信**が持てるものだけを挙げる
- 脆弱性を再現するためにコマンドを実行する必要はない。コードを読んで実在するか判断する
- 深刻度: **HIGH** = RCE / データ漏洩 / 認証バイパスに直結、**MEDIUM** = 特定条件が必要だが影響大、**LOW** = 多層防御レベル。HIGH と MEDIUM に絞る
- ローカルネットワークからしか悪用できなくても HIGH になりうる

## ブロック 1: HARD EXCLUSIONS（逐語）

> HARD EXCLUSIONS - Automatically exclude findings matching these patterns:
> 1. Denial of Service (DOS) vulnerabilities or resource exhaustion attacks.
> 2. Secrets or credentials stored on disk if they are otherwise secured.
> 3. Rate limiting concerns or service overload scenarios.
> 4. Memory consumption or CPU exhaustion issues.
> 5. Lack of input validation on non-security-critical fields without proven security impact.
> 6. Input sanitization concerns for GitHub Action workflows unless they are clearly triggerable via untrusted input.
> 7. A lack of hardening measures. Code is not expected to implement all security best practices, only flag concrete vulnerabilities.
> 8. Race conditions or timing attacks that are theoretical rather than practical issues. Only report a race condition if it is concretely problematic.
> 9. Vulnerabilities related to outdated third-party libraries. These are managed separately and should not be reported here.
> 10. Memory safety issues such as buffer overflows or use-after-free-vulnerabilities are impossible in rust. Do not report memory safety issues in rust or any other memory safe languages.
> 11. Files that are only unit tests or only used as part of running tests.
> 12. Log spoofing concerns. Outputting un-sanitized user input to logs is not a vulnerability.
> 13. SSRF vulnerabilities that only control the path. SSRF is only a concern if it can control the host or protocol.
> 14. Including user-controlled content in AI system prompts is not a vulnerability.
> 15. Regex injection. Injecting untrusted content into a regex is not a vulnerability.
> 16. Insecure documentation. Do not report any findings in documentation files such as markdown files.
> 17. A lack of audit logs is not a vulnerability.

## ブロック 2: 判断ガイド（逐語）

> 1. Logging high value secrets in plaintext is a vulnerability. Logging URLs is assumed to be safe.
> 2. UUIDs can be assumed to be unguessable and do not need to be validated.
> 3. Environment variables and CLI flags are trusted values. Attackers are generally not able to modify them in a secure environment. Any attack that relies on controlling an environment variable is invalid.
> 4. Resource management issues such as memory or file descriptor leaks are not valid.
> 5. Subtle or low impact web vulnerabilities such as tabnabbing, XS-Leaks, prototype pollution, and open redirects should not be reported unless they are extremely high confidence.
> 6. React and Angular are generally secure against XSS. These frameworks do not need to sanitize or escape user input unless it is using dangerouslySetInnerHTML, bypassSecurityTrustHtml, or similar methods. Do not report XSS vulnerabilities in React or Angular components or tsx files unless they are using unsafe methods.
> 7. Most vulnerabilities in github action workflows are not exploitable in practice. Before validating a github action workflow vulnerability ensure it is concrete and has a very specific attack path.
> 8. A lack of permission checking or authentication in client-side JS/TS code is not a vulnerability. Client-side code is not trusted and does not need to implement these checks, they are handled on the server-side. The same applies to all flows that send untrusted data to the backend, the backend is responsible for validating and sanitizing all inputs.
> 9. Only include MEDIUM findings if they are obvious and concrete issues.
> 10. Most vulnerabilities in ipython notebooks (*.ipynb files) are not exploitable in practice. Before validating a notebook vulnerability ensure it is concrete and has a very specific attack path where untrusted input can trigger the vulnerability.
> 11. Logging non-PII data is not a vulnerability even if the data may be sensitive. Only report logging vulnerabilities if they expose sensitive information such as secrets, passwords, or personally identifiable information (PII).
> 12. Command injection vulnerabilities in shell scripts are generally not exploitable in practice since shell scripts generally do not run with untrusted user input. Only report command injection vulnerabilities in shell scripts if they are concrete and have a very specific attack path for untrusted input.

## 出力形式（ペルソナに要求する）

ファイル / 行番号 / 深刻度 / カテゴリ（`sql_injection`、`xss` 等のスラッグ）/ 説明 / **悪用シナリオ** / 修正案。
悪用シナリオは「攻撃者が具体的に何を送ると何が起きるか」を書かせる。これが書けない指摘は落とす。

## 参照元

- 公式 `/security-review`: Claude Code CLI バイナリ埋め込み（`~/.local/share/claude/versions/<version>`、2.1.243 で確認）
- 利用側: [`pr-review`](../pr-review/SKILL.md) Phase 2（security ペルソナを立てる回）
