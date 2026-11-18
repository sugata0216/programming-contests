# 環境構築手順

## 手順0

PostgreSQLのパスワードを覚えておく

## 手順1

次のコマンドでリポジトリをcloneする

```bash
git clone git@github.com:sugata0216/programming-contests.git
```

## 手順2

cloneしたリポジトリをIntelliJ IDEAで開く

## 手順3

プロジェクト直下に`.env`ファイルを配置し以下のように記述する

```dotenv
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=programming_contests
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your-password-here
```

## 手順4

IntelliJ内のMavenメニューから「すべてのMavenプロジェクトを再ロード」する
