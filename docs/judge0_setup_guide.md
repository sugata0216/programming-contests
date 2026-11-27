# Judge0 セットアップガイド（Windows）

採点に使う Judge0 を、自分の PC の Docker で動かす手順です。アプリからは `http://localhost:2358` の API を呼びます。

Judge0 の起動に必要なファイルは、リポジトリに入っています。

| ファイル | 内容 |
| --- | --- |
| `compose.yaml`（プロジェクト直下） | Judge0 のコンテナ（server、workers、db、redis）の定義 |
| `docker/judge0/judge0.conf` | Judge0 の設定。Windows 向けに設定済みなので、書き換えなくてよい。パスワードはここに書かない（書くと `.env` の値が空で上書きされる） |
| `.env`（プロジェクト直下、追跡しない） | Judge0 のパスワード。各自で書く |

## 前提

- Windows 11 と Docker Desktop
- コマンドは cmd（コマンドプロンプト）で、プロジェクト直下で実行する。PowerShell では curl の JSON が正しく送られない

## セットアップ

### 1. `.env` にパスワードを書く

プロジェクト直下の `.env`（アプリの DB の設定と同じファイル）に、次の2行を足します。値はランダムな英数字にし、2つは別のものにします。

```dotenv
JUDGE0_REDIS_PASSWORD=your-redis-password
JUDGE0_POSTGRES_PASSWORD=your-postgres-password
```

Judge0 の中だけで使うパスワードなので、覚えておく必要はありません。ただし、一度起動したあとで `JUDGE0_POSTGRES_PASSWORD` を変えると、Judge0 が自分の DB に接続できなくなります（「困ったとき」を参照）。

### 2. 起動する

Docker Desktop を起動してから実行します。

```bash
docker compose up -d
```

初回はイメージのダウンロードに数分かかります。db と redis の準備ができてから、server と workers が起動します。

### 3. 動作を確かめる

起動してから API が応答するまで、数十秒かかります。

```bash
curl -s -X POST "http://localhost:2358/submissions?wait=true" -H "Content-Type: application/json" -d "{\"source_code\":\"print(1+1)\",\"language_id\":71}"
```

結果に `"description":"Accepted"` が含まれていれば完了です。

## 毎日の使い方

| やりたいこと | コマンド |
| --- | --- |
| 止める | `docker compose stop` |
| 再開する | `docker compose start` |
| `judge0.conf` か `.env` を変えた | `docker compose up -d --force-recreate` |

Docker Desktop を起動すると Judge0 も立ち上がります。`docker compose down` はコンテナを削除するので、止めるときは `stop` を使ってください。

## 言語ごとの値

| 言語 | `language_id` | `memory_limit`（KB） |
| --- | --- | --- |
| Python | 71 | 128000 |
| PHP | 68 | 128000 |
| C | 50 | 128000 |
| C++ | 54 | 128000 |
| C# | 51 | 128000 |
| JavaScript | 63 | 1024000 以上 |
| Java | 62 | 4096000 |

Java と JavaScript は、この値より小さいと起動できません。本番の環境では値が変わる見込みなので、コードには直接書かず、設定で変えられるようにしてください。

## 困ったとき

| 症状 | 直し方 |
| --- | --- |
| `failed to connect to the docker API` | Docker Desktop を起動する |
| `.env に JUDGE0_REDIS_PASSWORD を書いてください` | プロジェクト直下の `.env` に2行を足す（セットアップの1） |
| `port is already allocated`（2358） | 以前の手順で作った Judge0 が動いている。そのフォルダで `docker compose stop` を実行してから起動し直す |
| `service "db" has no container to start` | `docker compose up -d` で作り直す |
| `Internal Error` と `/box/script.py` のエラー | `judge0.conf` の `ENABLE_PER_PROCESS_...` の2つが `true` か確かめて、`docker compose up -d --force-recreate` |
| `judge0.conf` や `.env` の変更が反映されない | `docker compose up -d --force-recreate` |
| `JUDGE0_POSTGRES_PASSWORD` を変えたら起動しなくなった | DB は最初のパスワードのまま。`.env` を元の値に戻すか、`docker compose down -v` で DB ごと消して作り直す（過去の提出結果も消える） |
