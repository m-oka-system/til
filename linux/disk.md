## ファイルシステムが利用できるまでの流れ

```
1.ディスク接続
2.パーティション作成（fdisk）
3.ファイルシステム作成（mkfs）※フォーマット
```

## デバイスファイル

```bash
ハードディスク、CD-ROMなどすべてのデバイスを「デバイスファイル」を経由して制御する
/dev/hda　IDEプライマリマスタ接続のハードディスク
/dev/hdb　IDEプライマリスレーブ接続のハードディスク
/dev/hdc　IDEセカンダリマスタ接続のハードディスク
/dev/hdd　IDEセカンダリスレーブ接続のハードディスク

/dev/sda　SCSI/SATA/USB接続1つ目のハードディスク
/dev/sdb　SCSI/SATA/USB接続2つ目のハードディスク
/dev/sdc
:
/dev/cdrom　CD/DVDドライブ
/dev/st0　　テープドライブ
```

## パーティション

```bash
ディスクを使用するには必ずパーティションを作成する
基本パーティション3つ
拡張パーティション1つ
　|_論理パーティション2つ


パーティションごとにデバイスファイル名が割り当てられる
/dev/sda1
/dev/sda2
/dev/sda3
/dev/sda4
/dev/sda5　5以降が拡張パーティションの論理パーティション用
/dev/sda6

#パーティションを表示
fdisk -l

#パーティションを作成（対話形式）
fdisk /dev/sdb

# fdiskコマンド (help)
 DOS (MBR)
   a   起動可能フラグを切り替えます
   b   入れ子の BSD ディスクラベルを編集します
   c   DOS 互換フラグを切り替えます

  一般
   d   パーティションを削除します
   F   パーティションのない領域を一覧表示します
   l   既知のパーティションタイプを一覧表示します
   n   新しいパーティションを追加します
   p   パーティション情報を表示します
   t   パーティションタイプを変更します
   v   パーティション情報を検証します
   i   パーティションの情報を表示します

  その他
   m   このメニューを表示します
   u   表示項目の単位を変更します
   x   特殊機能に移動します (熟練者向け機能)

  スクリプト
   I   ディスクのレイアウトを sfdisk 互換のスクリプトから読み込みます
   O   ディスクのレイアウトを sfdisk 互換のスクリプトに書き出します

  保存と終了
   w   パーティション情報をディスクに書き込んで終了します
   q   変更点を保存せずに終了します

  新しいラベルを作成します
   g   新しい (何もない) GPT パーティションテーブルを作成します
   G   新しい (何もない) SGI (IRIX) パーティションテーブルを作成します
   o   新しい (何もない) DOS パーティションテーブルを作成します
   s   新しい (何もない) Sun パーティションテーブルを作成します
```

## ファイルシステム作成

```bash
# mkfs
mkfs -t ext4 <デバイスファイル名>
mkfs -t ext4 /dev/sdb1

-t ファイルシステムの種類を指定
-c 実行前に不良ブロックを検査する

# mke2fs
mke2fs -t ext4 /dev/sdb2
-t ファイルシステムの種類を指定
-c 実行前に不良ブロックを検査する
-j ext3ファイルシステムを作成する

# ファイルシステムの種類
ext2　　　Linuxの標準ファイルシステム
ext3　　　ext2にジャーナリング機能を追加したファイルシステム
ext4　　　ext3を機能追加したファイルシステム
reiserfs　高速なジャーナリングファイルシステム
xfs　 　　SGI社が開発したジャーナリングファイルシステム
jfs　 　　IBM社が開発したジャーナリングファイルシステム
iso9660　 CD-ROMのファイルシステム
msdos　　 MS-DOSのファイルシステム
vfat　　  Windowsのファイルシステム
nfs　　 　ネットワーク上の別のコンピュータのディレクトリを参照する
```

## ファイルシステム作成の例

```bash
# パーティションの表示
fdisk -l

ディスク /dev/xvda: 10 GiB, 10737418240 バイト, 20971520 セクタ
単位: セクタ (1 * 512 = 512 バイト)
セクタサイズ (論理 / 物理): 512 バイト / 512 バイト
I/O サイズ (最小 / 推奨): 512 バイト / 512 バイト
ディスクラベルのタイプ: gpt
ディスク識別子: 83181C97-6D5E-43C9-9EDE-E2F50EAD5338

デバイス     開始位置 最後から   セクタ サイズ タイプ
/dev/xvda1       4096 20971486 20967391    10G Linux ファイルシステム
/dev/xvda128     2048     4095     2048     1M BIOS 起動

# パーティションの分割
sudo fdisk /dev/sdc

fdisk (util-linux 2.30.2) へようこそ。
ここで設定した内容は、書き込みコマンドを実行するまでメモリのみに保持されます。
書き込みコマンドを使用する際は、注意して実行してください。

デバイスには認識可能なパーティション情報が含まれていません。
新しい DOS ディスクラベルを作成しました。識別子は 0xa8d6149d です。

コマンド (m でヘルプ): p
ディスク /dev/xvdf: 20 GiB, 21474836480 バイト, 41943040 セクタ
単位: セクタ (1 * 512 = 512 バイト)
セクタサイズ (論理 / 物理): 512 バイト / 512 バイト
I/O サイズ (最小 / 推奨): 512 バイト / 512 バイト
ディスクラベルのタイプ: dos
ディスク識別子: 0xa8d6149d

コマンド (m でヘルプ): m

ヘルプ:

  DOS (MBR)
   a   起動可能フラグを切り替えます
   b   入れ子の BSD ディスクラベルを編集します
   c   DOS 互換フラグを切り替えます

  一般
   d   パーティションを削除します
   F   パーティションのない領域を一覧表示します
   l   既知のパーティションタイプを一覧表示します
   n   新しいパーティションを追加します
   p   パーティション情報を表示します
   t   パーティションタイプを変更します
   v   パーティション情報を検証します
   i   パーティションの情報を表示します

  その他
   m   このメニューを表示します
   u   表示項目の単位を変更します
   x   特殊機能に移動します (熟練者向け機能)

  スクリプト
   I   ディスクのレイアウトを sfdisk 互換のスクリプトから読み込みます
   O   ディスクのレイアウトを sfdisk 互換のスクリプトに書き出します

  保存と終了
   w   パーティション情報をディスクに書き込んで終了します
   q   変更点を保存せずに終了します

  新しいラベルを作成します
   g   新しい (何もない) GPT パーティションテーブルを作成します
   G   新しい (何もない) SGI (IRIX) パーティションテーブルを作成します
   o   新しい (何もない) DOS パーティションテーブルを作成します
   s   新しい (何もない) Sun パーティションテーブルを作成します


コマンド (m でヘルプ): n
パーティションタイプ
   p   基本パーティション (0 プライマリ, 0 拡張, 4 空き)
   e   拡張領域 (論理パーティションが入ります)
選択 (既定値 p): p
パーティション番号 (1-4, 既定値 1): 1
最初のセクタ (2048-41943039, 既定値 2048): 1
範囲外の値です。
最初のセクタ (2048-41943039, 既定値 2048):
最終セクタ, +セクタ番号 または +サイズ{K,M,G,T,P} (2048-41943039, 既定値 41943039): +1024M

新しいパーティション 1 をタイプ Linux、サイズ 1 GiB で作成しました。

コマンド (m でヘルプ): n
パーティションタイプ
   p   基本パーティション (1 プライマリ, 0 拡張, 3 空き)
   e   拡張領域 (論理パーティションが入ります)
選択 (既定値 p): p
パーティション番号 (2-4, 既定値 2): 2
最初のセクタ (2099200-41943039, 既定値 2099200):
最終セクタ, +セクタ番号 または +サイズ{K,M,G,T,P} (2099200-41943039, 既定値 41943039): +1024M

新しいパーティション 2 をタイプ Linux、サイズ 1 GiB で作成しました。

コマンド (m でヘルプ): p
ディスク /dev/xvdf: 20 GiB, 21474836480 バイト, 41943040 セクタ
単位: セクタ (1 * 512 = 512 バイト)
セクタサイズ (論理 / 物理): 512 バイト / 512 バイト
I/O サイズ (最小 / 推奨): 512 バイト / 512 バイト
ディスクラベルのタイプ: dos
ディスク識別子: 0xa8d6149d

デバイス   起動 開始位置 最後から  セクタ サイズ Id タイプ
/dev/xvdf1          2048  2099199 2097152     1G 83 Linux
/dev/xvdf2       2099200  4196351 2097152     1G 83 Linux

コマンド (m でヘルプ): t
パーティション番号 (1,2, 既定値 2): 2
16 進数コード (L で利用可能なコードを一覧表示します): L

 0  空              24  NEC DOS         81  Minix / 古い Li bf  Solaris
 1  FAT12           27  隠し NTFS WinRE 82  Linux スワップ  c1  DRDOS/sec (FAT-
 2  XENIX root      39  Plan 9          83  Linux           c4  DRDOS/sec (FAT-
 3  XENIX usr       3c  PartitionMagic  84  隠し OS/2 また  c6  DRDOS/sec (FAT-
 4  FAT16 <32M      40  Venix 80286     85  Linux 拡張領域  c7  Syrinx
 5  拡張領域        41  PPC PReP Boot   86  NTFS ボリューム da  非 FS データ
 6  FAT16           42  SFS             87  NTFS ボリューム db  CP/M / CTOS / .
 7  HPFS/NTFS/exFAT 4d  QNX4.x          88  Linux プレーン  de  Dell ユーティリ
 8  AIX             4e  QNX4.x 第2パー  8e  Linux LVM       df  BootIt
 9  AIX 起動可能    4f  QNX4.x 第3パー  93  Amoeba          e1  DOS access
 a  OS/2 ブートマネ 50  OnTrack DM      94  Amoeba BBT      e3  DOS R/O
 b  W95 FAT32       51  OnTrack DM6 Aux 9f  BSD/OS          e4  SpeedStor
 c  W95 FAT32 (LBA) 52  CP/M            a0  IBM Thinkpad ハ ea  Rufus alignment
 e  W95 FAT16 (LBA) 53  OnTrack DM6 Aux a5  FreeBSD         eb  BeOS fs
 f  W95 拡張領域 (L 54  OnTrackDM6      a6  OpenBSD         ee  GPT
10  OPUS            55  EZ-Drive        a7  NeXTSTEP        ef  EFI (FAT-12/16/
11  隠し FAT12      56  Golden Bow      a8  Darwin UFS      f0  Linux/PA-RISC
12  Compaq 診断     5c  Priam Edisk     a9  NetBSD          f1  SpeedStor
14  隠し FAT16 <32M 61  SpeedStor       ab  Darwin ブート   f4  SpeedStor
16  隠し FAT16      63  GNU HURD または af  HFS / HFS+      f2  DOS セカンダリ
17  隠し HPFS/NTFS  64  Novell Netware  b7  BSDI fs         fb  VMware VMFS
18  AST SmartSleep  65  Novell Netware  b8  BSDI スワップ   fc  VMware VMKCORE
1b  隠し W95 FAT32  70  DiskSecure Mult bb  隠し Boot Wizar fd  Linux raid 自動
1c  隠し W95 FAT32  75  PC/IX           bc  Acronis FAT32 L fe  LANstep
1e  隠し W95 FAT16  80  古い Minix      be  Solaris ブート  ff  BBT

16 進数コード (L で利用可能なコードを一覧表示します): 82

パーティションのタイプを 'Linux' から 'Linux swap / Solaris' に変更しました。

コマンド (m でヘルプ): p
ディスク /dev/xvdf: 20 GiB, 21474836480 バイト, 41943040 セクタ
単位: セクタ (1 * 512 = 512 バイト)
セクタサイズ (論理 / 物理): 512 バイト / 512 バイト
I/O サイズ (最小 / 推奨): 512 バイト / 512 バイト
ディスクラベルのタイプ: dos
ディスク識別子: 0xa8d6149d

デバイス   起動 開始位置 最後から  セクタ サイズ Id タイプ
/dev/xvdf1          2048  2099199 2097152     1G 83 Linux
/dev/xvdf2       2099200  4196351 2097152     1G 82 Linux スワップ / Solaris

コマンド (m でヘルプ): w
パーティション情報が変更されました。
ioctl() を呼び出してパーティション情報を再読み込みします。
ディスクを同期しています。

# ファイルシステム有無の確認
file -s /dev/xvdf1
/dev/xvdf1: data

# ファイルシステムの作成
mkfs -t ext3 -c /dev/xvdf1

# マウント
mount -t <タイプ> -o <オプション> <デバイス> <マウントポイント>
mkdir /mnt/data
mount -t ext3 -o rw /dev/xvdf /mnt/data

# マウント解除
umount <マウントポイント>
```

## スワップ領域の作成

```bash
システムには最低1つのスワップ領域が必要

# スワップの作成
# /dev/xvdf2はfdiskでID:82(スワップ)でパーミッションを作成
mkswap -c /dev/xvdf2

-c 不良な部分を利用しない

# スワップの有効化/無効化
swapon /dev/xvdf2
swapoff /dev/xvdf2
```

## 自動マウント

```bash
# /etc/fstabに定義
デバイスファイル名　マウントポイント ファイルシステムのタイプ マウントオプション dump有無　fsckチェック順
/dev/xvdf1 /mnt/data ext3 defaults 1 2

dumpフラグ　1ならdumpコマンドのバックアップ対象
fsckチェック　起動時にfsckチェックを行う順序。ルートファイルシステムを必ず1にする

# マウントオプション
async    ファイルシステムへのI/Oを非同期で行う
dev      ファイルシステム上のデバイスファイルを利用可能にする
auto     mount -a を実行した時にマウントする
noauto   mount -a を実行してもマウントしない
defaults デフォルトのオプションを有効にする (async,auto,exec,nouser,rw,suid)
exec     バイナリの実行を許可する
noexec   バイナリの実行を許可しない
ro       読み取り専用でマウントする
rw       読み書き可能でマウントする
unhide   隠しファイルも表示する
suid     SUIDとSGIDを有効にする
user     一般ユーザーでもマウント可能にする
users    マウントしたユーザー以外でもアンマウント可能にする
nouser   一般ユーザーのマウントを許可しない

# /etc/fstabに指定されたswap以外のパーティションをマウント
mount -a

```

## 手動マウント

```bash
# ext3ファイルシステムの/dev/sdb1パーティションを、/dataにマウントする
mount -t ext3 /dev/sdb1 /data

# fstabに記述がある場合は、デバイスファイル名かマウントポイントのみ指定すれば実行できる
mount /dev/sdb1
mount /data

# CD-ROMをマウント
mount -t iso9660 -o ro /dev/cdrom /media/cdrom
-o　マウントオプションを指定する（この例では読み取り専用を指定）

```

## アンマウント

```bash
# すべてアンマウント
umount -a
-a　/etc/mtabに記載されているものをすべてアンマウント

# ファイルシステムを指定してアンマウント
umount -at ext3
-t　指定したファイルシステムだけをアンマウント

# デバイスファイル名かマウントポイントを指定
umount /dev/cdrom
umount /media/cdrom
```
