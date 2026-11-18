# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Spring Boot 4.1.2、Java 17、Maven のプロジェクトです。アプリのコードはまだメインクラスだけで、パッケージとディレクトリの枠だけを `.gitkeep` で用意しています。

- 主な依存: Spring Web MVC、Thymeleaf、Spring JDBC、MyBatis（4.0.1）、PostgreSQL ドライバ、Spring Mail、Bean Validation、springboot4-dotenv、Lombok、DevTools
- Spring Security、`thymeleaf-extras-springsecurity6`、JWT（jjwt）は pom.xml にコメントアウトで残っていて、まだ有効ではありません。
- パッケージの枠: `controller`、`service`、`repository`、`mapper`、`entity`、`security`、`exception`（`exception/handler`）。画面側は `templates/` と `static/`（`css/`、`js/`、`images/`）です。
- データアクセスは MyBatis を使います。`mybatis.configuration.map-underscore-to-camel-case=true` なので、`snake_case` のカラムは `camelCase` のフィールドに自動で対応します。
- `spring.sql.init.mode=never` なので、起動時にスキーマは作られません。テーブルは [docs/db.md](docs/db.md) に沿って別途用意します。
- ルートパッケージ: `com.example.programmingcontests`
- エントリポイント: `ProgrammingContestsApplication`（`@SpringBootApplication`）
- 設定: `src/main/resources/application.properties`
- テスト: JUnit 5 + `@SpringBootTest`（現状はコンテキスト起動の確認だけ）

## 仕様

学内向けのプログラミング大会プラットフォームを作ります。仕様は docs/ にあります。機能を実装・変更するときは、まず [docs/spec.md](docs/spec.md)（概要・決定事項・保留中の点・各ドキュメントへの案内）を読み、必要に応じて次を参照してください。

- [docs/requirements.md](docs/requirements.md): ロール、機能要件、業務ルール
- [docs/screens.md](docs/screens.md): 画面一覧
- [docs/db.md](docs/db.md): テーブル定義

仕様に書かれていないことや、spec.md の「保留・未決事項」に挙がっている点を決める必要が出たら、実装の前にユーザーに確認してください。

## コマンド

Maven Wrapper（Maven 3.10.1）を使います。Windows の PowerShell では `.\mvnw.cmd`、Git Bash では `./mvnw` を使ってください。

DB の接続先は環境変数で渡します（`DATABASE_HOST`、`DATABASE_PORT`、`DATABASE_NAME`、`DATABASE_USERNAME`、`DATABASE_PASSWORD`）。springboot4-dotenv が入っているので、プロジェクト直下の `.env` に書いても読み込まれます（`.env` は `.gitignore` で追跡対象外）。起動や `@SpringBootTest` のテストには、これらの環境変数と、接続できる PostgreSQL が必要です。

```bash
./mvnw spring-boot:run                 # アプリを起動
./mvnw test                            # 全テストを実行
./mvnw test -Dtest=ProgrammingContestsApplicationTests            # 1クラスだけ実行
./mvnw test -Dtest=ProgrammingContestsApplicationTests#contextLoads  # 1メソッドだけ実行
./mvnw package                         # 実行可能 JAR を target/ に生成
```

lint やフォーマッタの設定はありません。

## 注意点

- `.gitignore` は許可リスト方式です。先頭の `*` ですべて無視し、`!` で指定したファイル（`pom.xml`、`src/`、`mvnw` など）だけを追跡します。新しく追跡したいトップレベルのファイルやディレクトリを作ったら、`.gitignore` に `!/<パス>` を追加してください。`docs/` はファイルを1つずつ指定しているので、docs/ に md を増やしたときも追加が必要です。
- `.gitattributes` で改行コードを固定しています（`mvnw` は LF、`*.cmd` は CRLF）。
