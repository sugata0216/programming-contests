# Judge0 セットアップガイド（Windows）

採点に使う Judge0 を、自分の PC の Docker で動かす手順です。アプリからは `http://localhost:2358` の API を呼びます。

## 前提

- Windows 11 と Docker Desktop
- コマンドは cmd（コマンドプロンプト）で実行する。PowerShell では curl の JSON が正しく送られない

## セットアップ

### 1. ダウンロードして展開する

リポジトリの外のフォルダで実行します。

```bash
curl -L -O https://github.com/judge0/judge0/releases/download/v1.13.1/judge0-v1.13.1.zip
```

```bash
tar -xf judge0-v1.13.1.zip && cd judge0-v1.13.1
```

### 2. judge0.conf を書き換える

```bash
notepad judge0.conf
```

次の7項目の `=` の後ろに値を書いて保存します。

| 項目 | 値 |
| --- | --- |
| `REDIS_PASSWORD` | ランダムな英数字 |
| `POSTGRES_PASSWORD` | ランダムな英数字（`REDIS_PASSWORD` とは別のもの） |
| `ENABLE_PER_PROCESS_AND_THREAD_TIME_LIMIT` | `true` |
| `ENABLE_PER_PROCESS_AND_THREAD_MEMORY_LIMIT` | `true` |
| `MAX_MEMORY_LIMIT` | `4096000` |
| `COUNT` | `2` |
| `RAILS_MAX_THREADS` | `2` |

- 書き換えるのは `ALLOW_` が付いていない行
- `ENABLE_PER_PROCESS_...` の2つを `true` にしないと、Windows では採点が `Internal Error` になる
- `judge0.conf` はコミットしない

### 3. 起動する

Docker Desktop を起動してから実行します。

```bash
docker compose up -d db redis && timeout /t 10 && docker compose up -d
```

### 4. 動作を確かめる

```bash
curl -s -X POST "http://localhost:2358/submissions?wait=true" -H "Content-Type: application/json" -d "{\"source_code\":\"print(1+1)\",\"language_id\":71}"
```

結果に `"description":"Accepted"` が含まれていれば完了です。

## 毎日の使い方

| やりたいこと | コマンド |
| --- | --- |
| 止める | `docker compose stop` |
| 再開する | `docker compose start` |
| `judge0.conf` を変えた | `docker compose up -d --force-recreate` |

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
| `service "db" has no container to start` | `docker compose up -d` で作り直す |
| `Internal Error` と `/box/script.py` のエラー | `ENABLE_PER_PROCESS_...` の2つを `true` にして、`docker compose up -d --force-recreate` |
| `judge0.conf` の変更が反映されない | `docker compose up -d --force-recreate` |
