# Azure VM (Ubuntu)のディスク管理

## ブロックデバイスの状態を確認

```bash
# デバイス名を確認（-f でファイルシステムも表示）
# sda1 OSディスク
# sdb1 一時ディスク
lsblk
NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0     7:0    0  63.5M  1 loop /snap/core20/1891
loop1     7:1    0 111.9M  1 loop /snap/lxd/24322
loop2     7:2    0  53.3M  1 loop /snap/snapd/19361
loop3     7:3    0  53.3M  1 loop /snap/snapd/19457
loop4     7:4    0  63.4M  1 loop /snap/core20/1950
sda       8:0    0    30G  0 disk
├─sda1    8:1    0  29.9G  0 part /
├─sda14   8:14   0     4M  0 part
└─sda15   8:15   0   106M  0 part /boot/efi
sdb       8:16   0     7G  0 disk
└─sdb1    8:17   0     7G  0 part /mnt

# ディスク使用状況を確認
df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        29G  1.8G   28G   7% /
tmpfs           1.7G     0  1.7G   0% /dev/shm
tmpfs           672M  956K  671M   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda15      105M  6.1M   99M   6% /boot/efi
/dev/sdb1       6.8G  2.0G  4.6G  30% /mnt
tmpfs           336M  4.0K  336M   1% /run/user/1000
```

## Swap ファイル作成

[Azure Linux VM の SWAP ファイルを作成する](https://learn.microsoft.com/ja-jp/troubleshoot/azure/virtual-machines/create-swap-file-linux-vm)

一時ディスクで使用可能な領域の 30% が Swap に割り当てられる

```bash
touch /var/lib/cloud/scripts/per-boot/swap.sh
chmod +x /var/lib/cloud/scripts/per-boot/swap.sh
sh /var/lib/cloud/scripts/per-boot/swap.sh
```

```bash
#!/bin/sh

# Percent of space on the ephemeral disk to dedicate to swap. Here 30% is being used. Modify as appropriate.
PCT=0.3

# Location of swap file. Modify as appropriate based on location of ephemeral disk.
LOCATION=/mnt

if [ ! -f ${LOCATION}/swapfile ]
then

    # Get size of the ephemeral disk and multiply it by the percent of space to allocate
    size=$(/bin/df -m --output=target,avail | /usr/bin/awk -v percent="$PCT" -v pattern=${LOCATION} '$0 ~ pattern {SIZE=int($2*percent);print SIZE}')
    echo "$size MB of space allocated to swap file"

     # Create an empty file first and set correct permissions
    /bin/dd if=/dev/zero of=${LOCATION}/swapfile bs=1M count=$size
    /bin/chmod 0600 ${LOCATION}/swapfile

    # Make the file available to use as swap
    /sbin/mkswap ${LOCATION}/swapfile
fi

# Enable swap
/sbin/swapon ${LOCATION}/swapfile
/sbin/swapon -a

# Display current swap status
/sbin/swapon -s
```

## データディスクの追加

[ポータルを利用し、データ ディスクを Linux VM に接続する](https://learn.microsoft.com/ja-jp/azure/virtual-machines/linux/attach-disk-portal)

```bash
# データディスクを接続 (sdc)
lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i "sd"
sda     0:0:0:0       30G
├─sda1              29.9G /
├─sda14                4M
└─sda15              106M /boot/efi
sdb     0:0:0:1        7G
└─sdb1                 7G /mnt
sdc     1:0:0:0       32G

# パーティションの作成とフォーマット
sudo parted /dev/sdc --script mklabel gpt mkpart xfspart xfs 0% 100%
sudo mkfs.xfs /dev/sdc1
sudo partprobe /dev/sdc1

# 手動マウント
sudo mkdir /datadrive
sudo mount /dev/sdc1 /datadrive

# UUIDを確認
sudo blkid

/dev/sdc1: UUID="<uuid>" BLOCK_SIZE="4096" TYPE="xfs" PARTLABEL="xfspart" PARTUUID="xxx"

# /etc/fstabに自動マウント設定を追記
UUID=<uuid>   /datadrive   xfs   defaults,nofail   1   2
```
