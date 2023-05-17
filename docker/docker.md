# Docker

## Image

```bash
# イメージをダウンロード(プル)する
docker pull hello-world

# イメージを表示する
docker images

-f フィルタして表示

# コンテナを元にイメージを作成する
docker commit <container> <repo_name:tag>
docker commit cd66403a67fa ubuntu:updated

# イメージ名を変更する（push先のリポジトリ名と合わせる）
docker tag <source> <target>
docker tag ubuntu:updated mokasystem/my-first-repo:latest

# Docker Hubにログイン
docker login

# イメージをpushする
docker push <image>
docker push epaasrepo.azurecr.io/scaffold:v1
docker push mokasystem/<image>:<tag>

# イメージをtarにする
docker save <image> <file_name>.tar
docker save 241f995adf9d > alpine.tar

# tarを読み込んでイメージを作成する
docker load < <file_name>.tar
```

## Container

```bash
# コンテナを作成する（イメージからコンテナを作成して開始する。create + start）
docker run --name <name> <image_name> <command>
docker run -it sv01 ubuntu bash
docker run -it sv01 -u $(id -u):$(id -g) -v /local_dir:/docker_dir ubuntu bash
docker run -it --rm --cpus 4 --memory 2g --dns 8.8.8.8 ubuntu bash

-i 標準入力を有効にする（インプットが可能になる）
-t 標準入出力となっている端末デバイス(tty)を割り当てる
-p ポートフォワーディングを指定する # -p <host_port>:<container_port>
-d バックグラウンドで起動する（デタッチモードで起動する）
-v ローカルディスクをマウントする
-u ユーザーID、グループIDを指定する # -u <userid>:<groupid>
--rm     プロセス終了時にコンテナを削除する
--name   コンテナの名前を指定する
--cpus   コンテナに割り当てるCPUの上限を指定する
--memory コンテナに割り当てるメモリの上限を指定する
--dns    DNSサーバを指定する

# コンテナの一覧を表示する
docker container ls
docker ps
-a 停止しているコンテナも含めてすべて表示する
-q コンテナIDのみ表示する

# コンテナの情報を表示する
docker inspect <container>
docker inspect <container> | grep -i cpu

# ログを表示する
docker logs <container>

# コンテナを再起動する
docker restart <container>

# コンテナを削除する
docker rm <container>

# 停止されているコンテナ(イメージ、ネットワーク、キャッシュなども)を全て削除する
docker system prune

# コンテナに対してコマンドを実行する（プロセスが終了したコンテナに再度接続する）
docker exec -it <container> bash
docker commit cd66403a67fa bash

# コンテナをすべて削除するコマンドのエイリアス
alias docker-rm ='docker container ls -aq | xargs docker rm -f'
```

## Volume

```bash
# ボリュームを作成する
docker volume create

# ボリュームの一覧を表示する
docker volume ls

# ボリュームの詳細を表示する
docker volume inspect

# ボリュームを削除する
docker volume prune

# ボリュームを削除する
docker volume rm
```
