-- DB定義（Google スプレッドシート「DB定義」）をもとにした PostgreSQL 用のスキーマ

-- 利用者
CREATE TABLE if not exists users (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mail varchar(255) NOT NULL UNIQUE, -- メールアドレス
    name varchar(20) NOT NULL, -- ユーザ名
    password varchar(60) NOT NULL, -- bcrypt のハッシュ（60文字）
    is_admin boolean NOT NULL DEFAULT false, -- 管理者フラグ
    is_organizer boolean NOT NULL DEFAULT false, -- 大会管理者フラグ
    is_active boolean NOT NULL DEFAULT true, -- 有効ユーザフラグ
    authenticated_at timestamptz, -- 最終認証日時
    created_at timestamptz NOT NULL -- 作成日時
);

-- パスワードリセットトークン
CREATE TABLE if not exists reset_tokens (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    token varchar(255) NOT NULL UNIQUE, -- トークン
    expired_date timestamptz NOT NULL, -- 有効期限
    user_id integer NOT NULL REFERENCES users (id), -- 作成者
    created_at timestamptz NOT NULL DEFAULT current_timestamp -- 作成日時
);

-- 難易度
CREATE TABLE if not exists difficulty (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(255) NOT NULL, -- 難易度名
    estimated_duration integer NOT NULL -- 難易度に合わせた推奨時間
);

-- 対応言語
CREATE TABLE if not exists  languages (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    language varchar(255) NOT NULL UNIQUE, -- 言語名
    language_version varchar(255), -- 言語のバージョン
    judge0_language_id integer NOT NULL UNIQUE -- judge0の言語ID
);

-- 問題
CREATE TABLE if not exists questions (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(255) NOT NULL UNIQUE, -- 問題名
    difficulty integer NOT NULL REFERENCES difficulty (id), -- 難易度
    notes text, -- 備考
    is_draft boolean NOT NULL DEFAULT true, -- 下書きフラグ
    is_approved boolean NOT NULL DEFAULT false, -- 承認フラグ
    created_at timestamptz NOT NULL DEFAULT current_timestamp, -- 作成日時
    created_user_id integer NOT NULL REFERENCES users (id), -- 作成者
    updated_at timestamptz, -- 更新日時
    updated_user_id integer REFERENCES users (id), -- 更新者
    is_deleted boolean NOT NULL DEFAULT false -- 削除フラグ
);

-- 問題文のセクション
CREATE TABLE if not exists sections (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    question_id integer NOT NULL REFERENCES questions (id), -- 問題
    name text NOT NULL, -- セクション名
    content text NOT NULL CHECK (char_length(content) < 50000), -- セクション内容
    display_order integer NOT NULL, -- 表示順
    created_at timestamptz NOT NULL DEFAULT current_timestamp, -- 作成日時
    updated_at timestamptz, -- 更新日時
    UNIQUE (question_id, display_order) -- 同じ問題において、同じ表示順は拒否する
);

-- 問題の画像
CREATE TABLE if not exists question_images (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    question_id integer NOT NULL REFERENCES questions (id), -- 問題
    name uuid NOT NULL UNIQUE, -- 画像名(uuid)
    title varchar(255) NOT NULL, --　画像名(元の名前)
    mimetype varchar(50) NOT NULL CHECK (mimetype IN ('image/jpeg', 'image/png', 'image/gif', 'image/webp')), -- 画像タイプ
    created_at timestamptz NOT NULL DEFAULT current_timestamp, -- 作成日時
    created_user_id integer NOT NULL REFERENCES users (id) --　作成者
);

-- テストケース
CREATE TABLE if not exists testcases (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    question_id integer NOT NULL REFERENCES questions (id) ON DELETE CASCADE, -- 問題
    stdin text, -- 標準入力
    expected_output text NOT NULL, -- 想定される標準出力
    display_order integer NOT NULL, -- 表示順
    UNIQUE (question_id, display_order) -- 同じ問題において同じ表示順を拒否する
);

-- 模範解答
CREATE TABLE if not exists model_answers (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    question_id integer NOT NULL REFERENCES questions (id) ON DELETE CASCADE, -- 問題
    language_id integer NOT NULL REFERENCES languages (id), -- 言語ID
    answer text NOT NULL, -- 解答
    created_user_id integer NOT NULL REFERENCES users (id), -- 作成者
    created_at timestamptz NOT NULL DEFAULT current_timestamp, -- 作成日時
    updated_user_id integer REFERENCES users (id), -- 更新者
    updated_at timestamptz -- 更新日時
);

-- 問題文のテンプレート（シート名は question_templates、表題と他シートの参照先は templates）
CREATE TABLE if not exists templates (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(255) NOT NULL, -- テンプレート名
    description text NOT NULL CHECK (char_length(description) < 50000), -- テンプレート内容
    difficulty integer NOT NULL REFERENCES difficulty (id), --　難易度
    display_order integer NOT NULL UNIQUE, -- 表示順
    is_deleted boolean NOT NULL DEFAULT false, --　削除フラグ
    created_user_id integer NOT NULL REFERENCES users (id), -- 作成者
    created_at timestamptz NOT NULL DEFAULT current_timestamp, -- 作成日時
    updated_user_id integer REFERENCES users (id), -- 更新者
    updated_at timestamptz -- 更新日時
);

-- テンプレートのセクション
CREATE TABLE if not exists template_sections (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    template_id integer NOT NULL REFERENCES templates (id), -- テンプレート
    name varchar(255) NOT NULL, -- セクション名
    content text NOT NULL, -- 内容
    display_order integer NOT NULL, -- 表示順
    UNIQUE (template_id, display_order) -- 同じテンプレートにおいて同じ表示順を拒否する
);

-- 問題の承認リクエスト
CREATE TABLE if not exists requests (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    description text NOT NULL, -- 備考
    created_at timestamptz NOT NULL DEFAULT current_timestamp, -- リクエスト送信日時
    reviewed_user_id integer REFERENCES users (id), -- レビュアー
    reviewed_at timestamptz -- レビュー日時
);

-- リクエストに含まれる問題
CREATE TABLE if not exists request_questions (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    question_id integer NOT NULL REFERENCES questions (id), -- 問題
    request_id integer NOT NULL REFERENCES requests (id), -- リクエスト
    question_status varchar(15) NOT NULL DEFAULT 'not_reviewed'
        CHECK (question_status IN ('not_reviewed', 'approved', 'not_approved', 'pending')), -- リクエストにおける問題のステータス
    review_reason text, --　理由
    UNIQUE (question_id, request_id) --　同じリクエストにおいて同じ問題のレビューを拒否する
);

-- 大会
CREATE TABLE if not exists tournaments (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(255) NOT NULL,
    date timestamptz NOT NULL,
    description text NOT NULL,
    time_limit integer NOT NULL CHECK (time_limit > 0),
    stop_remaining_time integer,
    status varchar(8) NOT NULL DEFAULT 'before' CHECK (status IN ('before', 'ongoing', 'after')),
    -- シートには「url not in (大会関連のページのルーティング)」とあるが、具体的な値が未定のため CHECK は付けていない
    url varchar(36) NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT current_timestamp,
    updated_at timestamptz,
    is_published boolean NOT NULL DEFAULT false,
    is_deleted boolean NOT NULL DEFAULT false
);

-- 大会の出題問題
CREATE TABLE if not exists question_list (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tournament_id integer NOT NULL REFERENCES tournaments (id),
    question_id integer NOT NULL REFERENCES questions (id),
    question_order integer NOT NULL,
    UNIQUE (tournament_id, question_id),
    UNIQUE (tournament_id, question_order)
);

-- 大会にエントリーした利用者（シート上の表題は entered_users）
CREATE TABLE if not exists entry_users (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id integer NOT NULL REFERENCES users (id),
    tournament_id integer NOT NULL REFERENCES tournaments (id),
    created_at timestamptz NOT NULL DEFAULT current_timestamp,
    UNIQUE (user_id, tournament_id)
);

-- 利用者ごとの問題の閲覧・提出
CREATE TABLE if not exists users_questions (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id integer NOT NULL REFERENCES users (id),
    question_id integer NOT NULL REFERENCES questions (id),
    tournament_id integer NOT NULL REFERENCES tournaments (id),
    answer text,
    language_id integer REFERENCES languages (id),
    score integer NOT NULL DEFAULT 0,
    opened_at timestamptz NOT NULL DEFAULT current_timestamp,
    submitted_at timestamptz,
    UNIQUE (user_id, question_id, tournament_id),
    FOREIGN KEY (user_id, tournament_id) REFERENCES entry_users (user_id, tournament_id),
    FOREIGN KEY (tournament_id, question_id) REFERENCES question_list (tournament_id, question_id)
);

-- テストケースごとの採点結果
CREATE TABLE if not exists submission_results (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    users_question_id integer NOT NULL REFERENCES users_questions (id) ON DELETE CASCADE,
    testcase_id integer NOT NULL REFERENCES testcases (id),
    judge0_token varchar(36) UNIQUE,
    status_id integer CHECK (status_id BETWEEN 1 AND 14),
    stdout text,
    stderr text,
    compile_output text,
    created_at timestamptz NOT NULL DEFAULT current_timestamp,
    judged_at timestamptz,
    UNIQUE (users_question_id, testcase_id)
);

-- 大会ごとの順位
CREATE TABLE if not exists rankings (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tournament_id integer NOT NULL REFERENCES tournaments (id),
    user_id integer NOT NULL REFERENCES users (id),
    score integer NOT NULL,
    number_of_questions integer NOT NULL, -- 全テストケースを通した問題の数
    created_at timestamptz NOT NULL DEFAULT current_timestamp,
    updated_at timestamptz,
    UNIQUE (tournament_id, user_id)
);
