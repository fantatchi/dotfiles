# 社内用語集

## 命名上の注記

### 「確認」の使い分け（cloud-dsc 文脈）

- **段階確認**（業務行為としての確認）→ `StepConfirmation`
- **確認ステータス**（列挙値の遷移単位）→ `ConfirmationStatus`
- **確認動作**（汎用的に「確認する」/メール確認等）→ `Confirm` / `Acknowledge`

### 「計測」の使い分け

- **計測値**（個別の数値）→ `MeasuredValue`
- **計測結果**（業務的な結果セット）→ `MeasurementResult`
- **計測レコード**（不変履歴の 1 単位、cloud-dsc では `StepConfirmationRevision` クラスに相当）→ `StepConfirmationRevision`
- **段階確認エンティティ**（`degKshId` で一意、可変ステータスを持つ長命集約ルート）→ `StepConfirmation`

### enum メンバ命名

- **状態形を選ぶ**（動詞形は曖昧 → 過去分詞・形容詞）: `Pass / Fail` ではなく `Passed / Failed`、`Approve` ではなく `Approved`
- **否定接頭辞は `Un-` で統一**: `Unmeasured` / `Unconfirmed`（`NotMeasured` ではない）
- **保留状態は `Pending` を優先**: `Undetermined` より短く意図明瞭

### 標準型との衝突回避

- glossary 上の `Standard` / `Reference` / `Construction` は業務概念の英訳として保持
- 実装型では `StandardValue` / `ReferenceValue` / `ConstructionProject` 等にエスケープ（CA1716 予防）

### `Standard` の同名衝突（既知の課題）

- 「規格値」と「規格」（重機）が同じ `Standard`。実装時は **規格値 → `SpecValue`**、**規格（重機）→ `Spec`** で分離推奨（glossary 本体の整理は将来 PR）

## 基本用語

| 日本語 | 英語 |
|--------|------|
| 発注者 | Orderer |
| 工事 | Construction |
| 出来形管理 | AsBuiltManagement |
| 品質管理 | QualityManagement |
| 工程管理 | ProcessManagement |
| 工種 | ConstructionType |
| 略図 | Drawing |
| 測定項目 | MeasurementItem |
| 測点 | MeasurementPoint |
| 写真 | Photo |
| 許容範囲 | Tolerance |
| 規格値 | Standard |
| 基準値 | Reference |
| 社内規格値 | Company |

## 計測・データ・判定

| 日本語 | 英語 |
|--------|------|
| 計測値 | MeasuredValue |
| 判定（結果） | ComplianceResult |
| 合格 | Passed |
| 不合格 | Failed |
| 確認ステータス | ConfirmationStatus |
| 未確認 | Unconfirmed |
| 未測定 | Unmeasured |
| 未判定 | Pending |
| 差分値 | Deviation |

## ドキュメント・帳票

| 日本語 | 英語 |
|--------|------|
| 測定結果一覧 | MeasurementResultListView |
| 再提出 | Resubmission |
| 提出 | Submission |
| 自動提出 | AutomaticSubmission |

## 業務フロー・接続

| 日本語 | 英語 |
|--------|------|
| 招待 | Invitation |
| 内部 API | InternalApi |
| push（計測データ送信） | DataPush |

## 権限・ロール

| 日本語 | 英語 |
|--------|------|
| 監理技術者（受注者側で施工統括、建設業法 26 条） | ChiefEngineer |
| 工事監督員（発注者側の現場監督） | ConstructionSupervisor |

## データモデル

| 日本語 | 英語 |
|--------|------|
| マージビュー | MergedView |
| 不変履歴モデル | ImmutableHistory |

## 施工体制

| 日本語 | 英語 |
|--------|------|
| 建設業許可 | ConstructionBusinessLicense |
| 業種 | BusinessType |
| 建設業許可区分（大臣知事） | ConstructionPrefecturesType |
| 建設業許可区分（特定一般） | ConstructionSubcontractAmountType |
| 建設業許可業種 | ConstructionBusinessTypes |
| 建設業許可番号 | ConstructionLicenseNumber |
| 建設業許可年月日 | ConstructionLicensedDate |
| 警備業認定証種類 | SecurityCertificateType |
| 警備業認定元 | SecurityCertificateBy |
| 警備業認定書番号 | SecurityCertificateNumber |
| 建設業退職金共済制度 | ConstructionRetirementBenefit |
| 中小企業退職金共済制度 | SMERetirementBenefit |
| 一号特定技能外国人 | SpecifiedSkilledWorker |
| 外国人建設就労者 | ForeignConstructionWorker |
| 外国人技能実習生 | TechnicalInternTrainee |

## 重機・車両

| 日本語 | 英語 |
|--------|------|
| 重機 | Machine |
| 車両 | Vehicle |
| レンタル会社名 | RentalCompany |
| メーカー | Manufacturer |
| 管理番号 | ManagementNumber |
| 規格 | Standard |
| 製造年 | ManufactureYear |
| 車検有効開始日 | InspectionStartDate |
| 車検有効終了日 | InspectionEndDate |
| 年次自主検査有効期限 | AnnualSelfInspectionExpirationDate |
| 月次自主検査有効期限 | MonthlySelfInspectionExpirationDate |
| 特定自主検査有効期限 | SpecificSelfInspectionExpirationDate |
| 性能検査有効期限 | PerformanceInspectionExpirationDate |
| 自賠責保険 | AutoLiabilityInsurance |
| 車両型式 | VehicleModel |
| 車両番号 | VehicleNumber |
