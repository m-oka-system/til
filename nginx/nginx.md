# nginx

## Config file

`/etc/nginx`

これは nginx の主要な設定ディレクトリで、nginx.conf という主要な設定ファイルと、他の設定ファイル（サイトやモジュールの設定）がここに格納されます。

`/etc/nginx/nginx.conf`

これは nginx の主要な設定ファイルで、http、server、location ブロックのデフォルトの設定を含みます。

`/etc/nginx/conf.d`

これは追加の設定ファイルを保管するディレクトリで、ここに格納された設定ファイルは自動的に読み込まれます。

`/var/log/nginx`

nginx のログファイルが格納されるディレクトリ。

`/var/cache/nginx`

nginx のキャッシュデータが格納されるディレクトリ。

`/usr/share/nginx/html`

nginx のデフォルトの web コンテンツが格納されているディレクトリ。

```bash
# 初期設定の nginx.conf
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
```

```bash
# 初期設定の /etc/nginx/conf.d/default.conf
server {
    listen       80;
    server_name  localhost;

    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}
```

## Basic

```bash
# 開始
systemctl start nginx

# 停止
systemctl stop nginx

# 再起動
systemctl restart nginx

# 状態を表示.......................................
systemctl status nginx

# 設定の再読み込み
systemctl reload nginx

# バイナリ入れ替え
/sbin/service nginx upgrade
```

## nginx command

```bash
# バージョンを表示
nginx -v

# 設定ファイルのテスト
nginx -t

-T 設定ファイルの内容も表示

# 実行中のnginxデーモンを停止（強制終了）
nginx -s stop

# 実行中のnginxデーモンを停止（リクエストが終わるのを待ってから）
nginx -s quit

# 実行中のnginxデーモンにログファイルを開き直させる
nginx -s reopen

# 実行中のnginxデーモンに設定ファイルを再読み込みさせる
nginx -s reload
```

## Logs

```bash
/var/log/nginx/access.log
/var/log/nginx/error.log
```
