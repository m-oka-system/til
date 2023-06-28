## ホスト名

```bash
# ホスト名を確認
hostnamectl
 Static hostname: ubuntu01
       Icon name: computer-vm
         Chassis: vm
      Machine ID: ae9f1168669a48749bef49d7958838b7
         Boot ID: 8a06bf2cc17e41819d4770b0e33fe6b9
  Virtualization: microsoft
Operating System: Ubuntu 22.04.2 LTS
          Kernel: Linux 5.15.0-1040-azure
    Architecture: x86-64
 Hardware Vendor: Microsoft Corporation
  Hardware Model: Virtual Machine

# ホスト名を変更
sudo hostnamectl set-hostname ubuntu-server
```
