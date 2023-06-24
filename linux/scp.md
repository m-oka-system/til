## SCP

```bash
# ローカルのファイルをリモートに転送
scp ./dir1.tar.gz aws_admin@xx.xx.xx.xx:/home/aws_admin/

# リモートのファイルをローカルに転送
scp aws_admin@xx.xx.xx.xx:/home/aws_admin/dir1.tar.gz .

# リモートホストで圧縮してローカルに転送して解凍する
ssh aws_admin@RHEL01 'tar czf - dir1' | tar xzf -

# ローカルのファイルをEC2に転送
scp -i my-key-pair.pem ./alpine.tar ubuntu@xx.xx.xx.xx:/home/ubuntu/
```
