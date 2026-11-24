# CLAUDE.md

## プロジェクト概要

Spring Boot 4.1.2、Java 17、Maven のプロジェクトです。アプリのコードはまだメインクラスだけで、パッケージとディレクトリの枠だけを `.gitkeep` で用意しています。

- 主な依存: Spring Web MVC、Thymeleaf、Spring JDBC、MyBatis（4.0.1）、PostgreSQL ドライバ、Spring Mail、Bean Validation、springboot4-dotenv、Lombok、DevTools
- Spring Security、`thymeleaf-extras-springsecurity6`、JWT（jjwt）は pom.xml にコメントアウトで残っていて、まだ有効ではありません。
- パッケージの枠: `controller`、`service`、`repository`、`mapper`、`entity`、`form`、`dto`、`security`、`exception`（`exception/handler`）。
- 採点（提出コードの実行）には Judge0 を使います。開発時は各自の PC の Docker で動かし、アプリからは `http://localhost:2358` の API を呼ぶ想定です。Judge0 を呼ぶコードと接続先の設定は、まだありません。
- データアクセスは MyBatis を使います。`mybatis.configuration.map-underscore-to-camel-case=true` なので、`snake_case` のカラムは `camelCase` のフィールドに自動で対応します。
- `spring.sql.init.mode=never` なので、起動時にスキーマは作られません。テーブルは [docs/db.md](docs/db.md) に沿って別途用意します。
- テスト: JUnit 5 + `@SpringBootTest`（現状はコンテキスト起動の確認だけ）

## 実装の決まり

### 層と DI

- 呼び出しは controller → service → repository → mapper の一方向で、層を飛ばしません。
- 各層は、ひとつ下の層だけを `private final` のフィールドに持ち、コンストラクタで受け取ります。どの部品を使っているかがコードを見て一目でわかるように、コンストラクタは手で書きます。`@RequiredArgsConstructor` やフィールドへの `@Autowired` は使いません。

### mapper・repository・service

- `mapper` には `@Mapper` を付けたインターフェースを置きます。SQL は XML ファイルではなく、メソッドに `@Select`、`@Insert`、`@Update`、`@Delete` で書きます。
- `repository` には `@Repository` を付けたクラスを置き、mapper を呼び出します。
- `@Transactional` は service のメソッドに付けますが、そのメソッドで SQL を2件以上発行する場合だけにします（ループで同じ SQL を何度も発行する場合も含みます）。SQL が1件だけのメソッドには付けません。

### controller

- ページは `@Controller` と Thymeleaf で描く MPA です。`@RestController` は、ページの JavaScript から一部の処理だけを呼ぶために使い、外部からの利用は想定しません。
- `@RestController` のクラスには、必ず `/api` で始まるパスの `@RequestMapping` を付けます（例: `@RequestMapping("/api/submissions")`）。
- `@RestController` のメソッドは `ResponseEntity` を返し、ステータスコードを明示します（例: `ResponseEntity.ok(...)`、`ResponseEntity.status(HttpStatus.CREATED).body(...)`）。「見つからない」などのエラーは controller で返さず、service が例外を投げ、API 用のハンドラが返します。
- `@RestController` は REST の原則に沿って、取得は `@GetMapping`、作成は `@PostMapping`、更新は `@PutMapping`、削除は `@DeleteMapping` を使います。論理削除（`is_deleted` を `true` にする）も、SQL は `@Update` で書きますが、エンドポイントは `@DeleteMapping` にします。

### form・dto

- 入力は entity で直接受けません。画面の入力は `form` のクラス、API の入力は `dto` のクラスで受け、service で entity に詰め替えます。
- API のレスポンスは entity ではなく、`dto` のクラスを `ResponseEntity` に入れて返します。

### 入力チェック

- 形式のチェック（必須、文字数、使える文字など）も業務のチェック（重複、パスワードの一致など）も、service に `if` 文で書きます。最初に引っかかったところで例外を投げます。`@Valid` と Bean Validation のアノテーションは、今は使いません。
- 画面のフォームでの入力エラーは、controller で例外を try-catch し、エラーの文言を `Model` に入れて同じフォームを表示し直します（入力値は form に残ります）。

### 例外処理

- service は、入力エラー、見つからない、権限がない、を独自の例外（`exception` パッケージ）で投げます。
- ハンドラは `exception/handler` に置き、例外ごと、かつ画面用と API 用で別のクラスにします（例: `NotFoundPageExceptionHandler` と `NotFoundApiExceptionHandler`）。1つのクラスは、1つの例外と1つの返し方だけを受け持ちます。
- 画面用: `@ControllerAdvice` で「見つからない」「権限がない」を受け、一覧ページなどへリダイレクトし、フラッシュ属性でエラーの文言を表示させます。
- API 用: `@RestControllerAdvice(annotations = RestController.class)` で受け、`new ResponseEntity<>(e.getMessage(), HttpStatus.NOT_FOUND)` のように、文言の文字列とステータスコードを返します。入力エラーは 400 です。
- 画面用のハンドラは対象を絞らないので、`@RestController` の例外も受け取れてしまいます。API 用のハンドラには `@Order(Ordered.HIGHEST_PRECEDENCE)` を付け、API の例外は必ず API 用が先に受け取るようにします。API 用の `annotations = RestController.class` は、API 用が画面の例外を受け取らないために必要なので、外さないでください。
- `Exception` をまとめて受け取る処理は書きません。予期しないエラーは Spring Boot の標準の動き（エラーページや標準のエラー JSON）に任せます。

## 仕様

学内向けのプログラミング大会プラットフォームを作ります。仕様は docs/ にあります。機能を実装・変更するときは、まず [docs/spec.md](docs/spec.md)（概要・決定事項・保留中の点・各ドキュメントへの案内）を読み、必要に応じて次を参照してください。

- [docs/requirements.md](docs/requirements.md): ロール、機能要件、業務ルール
- [docs/screens.md](docs/screens.md): 画面一覧
- [docs/db.md](docs/db.md): テーブル定義
- [docs/setup.md](docs/setup.md): 環境構築手順（開発者向け）
- [docs/judge0_setup_guide.md](docs/judge0_setup_guide.md): Judge0 のセットアップ手順（Windows + Docker Desktop）

仕様に書かれていないことや、spec.md の「保留・未決事項」に挙がっている点を決める必要が出たら、実装の前にユーザーに確認してください。

## コマンド

Maven Wrapper（Maven 3.10.1）を使います。cmd では `mvnw`、Git Bash では `./mvnw` を使ってください。

DB の接続先は環境変数で渡します（`DATABASE_HOST`、`DATABASE_PORT`、`DATABASE_NAME`、`DATABASE_USERNAME`、`DATABASE_PASSWORD`）。springboot4-dotenv が入っているので、プロジェクト直下の `.env` に書いても読み込まれます（`.env` は `.gitignore` で追跡対象外）。起動や `@SpringBootTest` のテストには、これらの環境変数と、接続できる PostgreSQL が必要です。手順の詳細は [docs/setup.md](docs/setup.md) にあります。採点を動かすには Judge0 も必要です。立ち上げ方は [docs/judge0_setup_guide.md](docs/judge0_setup_guide.md) にあります（現状のアプリの起動やテストには不要です）。

```bash
./mvnw spring-boot:run                 # アプリを起動
./mvnw test                            # 全テストを実行
./mvnw test -Dtest=ProgrammingContestsApplicationTests            # 1クラスだけ実行
./mvnw test -Dtest=ProgrammingContestsApplicationTests#contextLoads  # 1メソッドだけ実行
./mvnw package                         # 実行可能 JAR を target/ に生成
```

lint やフォーマッタの設定はありません。

## 注意点

- `.gitignore` は許可リスト方式です。先頭の `*` ですべて無視し、`!` で指定したファイル（`pom.xml`、`src/`、`mvnw` など）だけを追跡します。`src/` 配下は `!/src/**` でまとめて許可しているので、新しいファイルも自動で追跡されます。一方、トップレベルや `docs/`（ファイルを1つずつ指定）に作ったファイルやディレクトリは、`.gitignore` に `!/<パス>` を追加しない限り追跡されません。
- ユーザーが明示的に指示しない限り、`.gitignore` に新しいファイルやディレクトリを追加しないでください。
- `.gitattributes` で改行コードを固定しています（`mvnw` は LF、`*.cmd` は CRLF）。
