# Dockerfile

## Instruction

```docker
FROM       ベースのイメージを指定する
RUN        コマンドを実行する
ENV        環境変数を定義する
WORKDIR    ディレクトリを変更する（ディレクトリがなければ作成もする）
CMD        コンテナのデフォルトのコマンドを指定する(Dockerfileの最後に記述する)
ENTRYPOINT コンテナのデフォルトのコマンドを指定する。docker run実行時に上書き不可
COPY       ファイルをイメージにコピーする
ADD        ファイルをイメージにコピーする(自動で解凍する)
EXPOSE     オープンするポートを指定する


# COPYとADDの違い
COPY 単純にファイルやフォルダをコピーする場合に使う
ADD  tarの圧縮ファイルをコピーして解凍したい場合に使う

# Layerを作るインストラクション
RUN
COPY
ADD

# ベストプラクティス
Dockerfileのレイヤーは極力少なくする（容量を軽くする）
パッケージのインストールなどは && で繋げてワンライナーで書く
Dockerfile作成の過程では用途ごとにRUNを分けてキャッシュを利用しながら作成する(最後に1行にまとめる)
```

## Build

```docker
# Dockerfileからイメージを作成する
docker build -t <repo_name:tag> <directory>
docker build -t new-ubuntu:latest .
docker build -t image_name -f Dockerfile_dev

-t イメージタグの名前を指定
-f Dockerfileの名前(パス)を指定

# イメージのレイヤーを確認
docker history <image_name>

# イメージの詳細を確認
docker inspect <image_name>
```
