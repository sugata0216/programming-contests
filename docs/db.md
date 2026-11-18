# DB 定義

元資料: DB定義.xlsx（外部設計書の「3. DB設計」は別アプリのものなので使いません）。PostgreSQL を想定しています。

## 共通の約束

- 主キーはすべて `id integer GENERATED ALWAYS AS IDENTITY`。
- 日時は `timestamptz`。`created_at` は `current_timestamp` が既定値。`updated_at` は NULL 可。
- 論理削除は `is_deleted boolean`（既定 false）。
- 「NN」は NOT NULL を表します。

## テーブルの関係

- **問題まわり**: `questions` に `sections`、`question_images`、`testcases`、`model_answers` がぶら下がる。難易度は `difficulty`、模範解答の言語は `languages` を参照する。
- **承認リクエスト**: `requests` と `questions` を `request_questions` が多対多でつなぎ、問題ごとの審査結果を持つ。
- **大会まわり**: `tournaments` と `questions` を `question_list` が多対多でつなぐ。`tournaments` と `users` を `entry_users` がつなぐ。
- **提出・採点**: `users_questions`（利用者×大会×問題）は `entry_users` と `question_list` を複合 FK で参照する。テストケースごとの結果は `submission_results`（`users_questions` × `testcases`）に入る。
- **順位**: `rankings`（大会×利用者）。
- **テンプレート**: `templates` と `template_sections`。問題とは FK でつながっていない。

## ユーザー

### users（利用者）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| mail | varchar(255) | NN, UNIQUE | ログイン ID |
| name | varchar(20) | NN | ユーザー名 |
| password | varchar(60) | NN | bcrypt のハッシュ（60文字） |
| is_admin | boolean | NN, 既定 false | 管理者フラグ |
| is_organizer | boolean | NN, 既定 false | 大会運営者フラグ |
| is_active | boolean | NN, 既定 true | 有効フラグ |
| authenticated_at | timestamptz | 既定 null | 最後にメール認証した日時 |
| created_at | timestamptz | NN | 登録日時 |

### reset_tokens（パスワードリセットトークン）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| token | varchar(255) | NN, UNIQUE | |
| expired_date | timestamptz | NN | 有効期限（発行から1時間） |
| user_id | integer | NN | → users.id |
| created_at | timestamptz | NN | |

## 問題

### questions（問題）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| name | varchar(255) | NN, UNIQUE | 問題名 |
| difficulty | integer | NN | → difficulty.id |
| notes | text | 既定 null | 備考 |
| is_draft | boolean | NN, 既定 false | 下書きか |
| is_approved | boolean | NN, 既定 false | 承認済みか |
| created_at | timestamptz | NN | |
| created_user_id | integer | NN | → users.id |
| updated_at | timestamptz | | |
| updated_user_id | integer | | → users.id |
| is_deleted | boolean | NN, 既定 false | |

### difficulty（難易度）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| name | varchar(255) | NN | |
| estimated_duration | integer | NN | 目安所要時間 |

### sections（問題文のセクション）

問題文は複数のセクションに分けて持ちます。

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| question_id | integer | NN | → questions.id |
| name | text | NN | セクション名 |
| content | text | NN | `char_length(content) < 50000` |
| display_order | integer | NN | UNIQUE(question_id, display_order) |
| created_at | timestamptz | NN | |
| updated_at | timestamptz | | |

### question_images（問題の画像）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| question_id | integer | NN | → questions.id |
| name | uuid | NN, UNIQUE | 画像名 |
| title | varchar(255) | NN | 画像タイトル |
| mimetype | varchar(50) | NN | `image/jpeg`、`image/png`、`image/gif`、`image/webp` のいずれか |
| created_at | timestamptz | NN | |
| created_user_id | integer | NN | → users.id |

### testcases（テストケース）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| question_id | integer | NN | → questions.id（ON DELETE CASCADE） |
| stdin | text | | 標準入力 |
| expected_output | text | NN | 期待出力 |
| is_sample | boolean | NN, 既定 false | 問題文にサンプルとして出すか |
| display_order | integer | NN | UNIQUE(question_id, display_order) |

### model_answers（模範解答）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| question_id | integer | NN | → questions.id（ON DELETE CASCADE） |
| language_id | integer | NN | → languages.id |
| answer | text | NN | 解答コード |
| created_user_id | integer | NN | → users.id |
| created_at | timestamptz | NN | |
| updated_user_id | integer | | → users.id |
| updated_at | timestamptz | | |

### languages（対応言語）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| language | varchar(255) | NN, UNIQUE | 言語名 |
| language_version | varchar(255) | | バージョン |
| judge0_language_id | integer | NN, UNIQUE | Judge0 側の言語 ID |

### templates / template_sections（問題文のテンプレート）

問題文のセクション構成をテンプレートとして持ちます。

`templates`:

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| name | varchar(255) | NN | テンプレート名 |
| description | text | NN | `char_length(description) < 50000` |
| difficulty | integer | NN | → difficulty.id |
| display_order | integer | NN, UNIQUE | |
| is_deleted | boolean | NN, 既定 false | |
| created_user_id | integer | NN | → users.id |
| created_at | timestamptz | NN | |
| updated_user_id | integer | | → users.id |
| updated_at | timestamptz | | |

`template_sections`:

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| template_id | integer | NN | → templates.id |
| name | varchar(255) | NN | セクション名 |
| content | text | NN | |
| display_order | integer | NN | UNIQUE(template_id, display_order) |

## 問題の承認リクエスト

### requests（承認リクエスト）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| description | text | NN | 説明 |
| created_at | timestamptz | NN | |
| reviewed_user_id | integer | | → users.id。レビューした管理者 |
| reviewed_at | timestamptz | | |

### request_questions（リクエストに含まれる問題）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| question_id | integer | NN | → questions.id |
| request_id | integer | NN | → requests.id。UNIQUE(question_id, request_id) |
| question_status | varchar(15) | NN, 既定 `not_reviewed` | 承認審査の状態。`not_reviewed`（未審査）/ `approved`（承認）/ `not_approved`（拒否）/ `pending`（保留） |
| review_reason | text | | 拒否理由・修正依頼 |

## 大会

### tournaments（大会）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| name | varchar(255) | NN | 大会名 |
| date | timestamptz | NN | 開始日時 |
| description | text | NN | 概要 |
| time_limit | integer | NN | 制限時間（分）。`time_limit > 0` |
| stop_remaining_time | integer | | 大会終了の何分前に順位表の更新を止めるか。NULL なら終了まで更新する |
| status | varchar(8) | NN, 既定 `before` | `before` / `ongoing` / `after` |
| url | varchar(36) | NN, UNIQUE | 大会ページの URL。大会関連ページのルーティングと重ならないこと |
| created_at | timestamptz | NN | |
| updated_at | timestamptz | | |
| is_published | boolean | NN, 既定 false | 公開済みか |
| is_deleted | boolean | NN, 既定 false | |

画面上の大会の状態との対応: 下書き＝`is_published = false` かつ `before`、公開済み＝`is_published = true` かつ `before`、開催中＝`ongoing`、終了＝`after`。

### question_list（大会の出題問題）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| tournament_id | integer | NN | → tournaments.id |
| question_id | integer | NN | → questions.id。UNIQUE(tournament_id, question_id) |
| question_order | integer | NN | UNIQUE(tournament_id, question_order) |

### entry_users（エントリーした利用者）

xlsx 上の表題は `entered_users`、シート名は `entry_users` です。他テーブルの FK は `entry_users` を参照しています。

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| user_id | integer | NN | → users.id |
| tournament_id | integer | NN | → tournaments.id。UNIQUE(user_id, tournament_id) |
| created_at | timestamptz | NN | 出場決定日時 |

### users_questions（利用者ごとの問題の閲覧・提出）

1行が「ある大会で、ある利用者が、ある問題を開いてから提出するまで」を表します。提出は1問につき1回です。

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| user_id | integer | NN | → users.id。FK(user_id, tournament_id) → entry_users |
| question_id | integer | NN | → questions.id。FK(tournament_id, question_id) → question_list |
| tournament_id | integer | NN | → tournaments.id。UNIQUE(user_id, question_id, tournament_id) |
| answer | text | | 提出したコード |
| language_id | integer | | → languages.id |
| score | integer | NN, 既定 0 | |
| opened_at | timestamptz | NN | 問題を開いた日時 |
| submitted_at | timestamptz | | 提出日時 |

### submission_results（テストケースごとの採点結果）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| users_question_id | integer | NN | → users_questions.id（ON DELETE CASCADE） |
| testcase_id | integer | NN | → testcases.id。UNIQUE(users_question_id, testcase_id) |
| judge0_token | varchar(36) | UNIQUE | Judge0 の実行識別子 |
| status_id | integer | | Judge0 のステータス。`status_id between 1 and 14` |
| stdout | text | | |
| stderr | text | | |
| compile_output | text | | |
| created_at | timestamptz | NN | |
| judged_at | timestamptz | | 判定完了日時 |

### rankings（大会ごとの順位）

| カラム | 型 | 制約・既定値 | 備考 |
| --- | --- | --- | --- |
| id | integer | PK | |
| tournament_id | integer | NN | → tournaments.id |
| user_id | integer | NN | → users.id。UNIQUE(tournament_id, user_id) |
| score | integer | NN | 得点 |
| number_of_questions | integer | NN | 全テストケースを通した問題の数 |
| created_at | timestamptz | NN | |
| updated_at | timestamptz | | |
