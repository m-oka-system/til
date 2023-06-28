## Ubuntu のバージョンとコードネーム

- Ubuntu のリリースにはそれぞれコードネームが付けられており、これらは通常、形容詞と動物の名前を組み合わせたもので、アルファベット順に進行する。バージョン番号は `西暦下 2 桁.月 2 桁`

| バージョン | コードネーム   |
| ---------- | -------------- |
| 20.04 LTS  | Focal Fossa    |
| 20.10      | Groovy Gorilla |
| 21.04      | Hirsute Hippo  |
| 21.10      | Impish Indri   |
| 22.04 LTS  | Jammy Jelyfish |
| 22.10      | Kinetic Kudu   |

## OS のアップグレード

```bash
# 現在のバージョンを確認 (lsb_release)
lsb_release -a

No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.2 LTS
Release:        22.04
Codename:       jammy

# 現在のバージョンを確認 (cat)
cat /etc/os-release
PRETTY_NAME="Ubuntu 22.04.2 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.2 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy

# OSアップグレード
sudo do-release-upgrade
```

## Ubuntu のリポジトリとコンポーネント

- リポジトリ

| リポジトリ      | 内容                                                     |
| --------------- | -------------------------------------------------------- |
| jammy           | リリース時のパッケージ                                   |
| jammy-update    | リリース後に更新されたパッケージ                         |
| jammy-security  | リリース後にセキュリティアップデートが行われたパッケージ |
| jammy-backports | 新しいリリースからバックポートされたパッケージ           |
| jammy-proposed  | テスト中で未リリースのパッケージ                         |

- コンポーネント

|          | Canonical  | コミュニティ |
| :------: | :--------: | :----------: |
|  フリー  |    main    |   universe   |
| 非フリー | restricted |  multiverse  |
|          |            |              |

```bash
# コンポーネントの有効化
sudo apt-add-repository universe

# コンポーネントの無効化
sudo apt-add-repository -r universe

# リポジトリの確認
cat /etc/apt/sources.list

deb http://azure.archive.ubuntu.com/ubuntu/ jammy main restricted
deb http://azure.archive.ubuntu.com/ubuntu/ jammy-updates main restricted
deb http://azure.archive.ubuntu.com/ubuntu/ jammy-backports main restricted
deb http://azure.archive.ubuntu.com/ubuntu/ jammy-security main restricted
```

## apt

| sub command  | 説明                                                                                   |
| ------------ | -------------------------------------------------------------------------------------- |
| update       | パッケージの情報を更新する                                                             |
| upgrade      | 全てのパッケージを最新のものに更新する（削除は保留）                                   |
| full-upgrade | 全てのパッケージを最新のものに更新する                                                 |
| install      | パッケージをインストールする                                                           |
| remove       | パッケージをアンインストールする                                                       |
| purge        | パッケージをアンインストールし、設定ファイルも削除する                                 |
| autoremove   | 依存関係によって自動インストールされ、後に不要になったパッケージをアンインストールする |
| search       | パッケージを検索する                                                                   |
| list         | パッケージの一覧を表示する                                                             |
| show         | パッケージの詳細を表示する                                                             |

## インストール済みのパッケージ一覧をバックアップ

```bash
# 手動でインストールしたパッケージを表示
apt-mark showmanual > manuaru.txt

# 自動でインストールされたパッケージを表示
apt-mark showauto > auto.txt

# txtを元にインストール
sudo apt install -y $(cat manual.txt auto.txt)
```

## snap

| sub command | 説明                                             |
| ----------- | ------------------------------------------------ |
| install     | パッケージをインストールする                     |
| remove      | パッケージをアンインストールする                 |
| list        | インストール済みのパッケージ一覧を表示する       |
| find        | パッケージを検索する                             |
| info        | パッケージの詳細を表示する                       |
| reflesh     | パッケージをアップデートする                     |
| switch      | パッケージのチャンネルを切り替える               |
| disable     | インストール済みのパッケージを無効にする         |
| enable      | 無効になっているパッケージを有効にする           |
| change      | システムに対して行われた変更の一覧を表示する     |
| task        | システムに対して行われた変更の詳細を表示する     |
| services    | サービスの関する情報を表示する                   |
| start       | 指定されたサービスを開始する                     |
| stop        | 指定されたサービスを停止する                     |
| restart     | 指定されたサービスを再起動する                   |
| logs        | 指定されたサービスのログを表示する               |
| set         | 指定されたパッケージに対してオプションを設定する |
| get         | 指定されたオプションを表示する                   |
| unset       | 指定されたオプションを削除する                   |
| alias       | Snap コマンドにエイリアスを設定する              |
| aliases     | 設定されているエイリアスの一覧を表示する         |
| unalias     | 設定されているエイリアスを無効にする             |
