# Docker compose

## Basic command

```bash
# イメージを作成
docker compose build

# Dockerを起動（イメージなければbuild）
docker compose up -d

-d      バックグラウンドで起動する（デタッチモードで起動する）
--build 強制的に再ビルドする
-f      ymlのファイル名を指定
--abort-on-container-exit  コンテナが１つでも停止したら全てのコンテナを停止。-dと同時に使えない

# Dockerを停止して削除
docker compose down -v

-v 関連するボリュームも削除

# Dockerの停止/開始
docker compose stop
docker compose strt

# Dockerのステータスを確認
docker compose ps

# ログを表示する
docker compose logs <service>

# Dockerにコマンドを実行
docker compose exec <service> <command>
docker compose exec web rails db:create
```

## docker-compose.yml

```yaml
version: "3"
services:
  web:
    build: .
    dockerfile: ./Dockerfile
    command: rails s -p 3000 -b '0.0.0.0'
    ports:
      - 3000:3000
    volumes:
      - .:/sampleapp
    environment:
      MYSQL_ROOT_PASSWORD: password
    depends_on:
      - db
    links:
      - db

  db:
    image: mysql:5.7
    ports:
      - 3306:3306
    environment:
      MYSQL_ROOT_PASSWORD: password
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```
