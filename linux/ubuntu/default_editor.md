## デフォルトのエディタを変更する

- editor コマンド実行時のエディタを変更する

```bash
# デフォルトのエディタを確認 (nano)
azureuser@ubuntu01:~$ ls -l /usr/bin/editor
lrwxrwxrwx 1 root root 24 Jun 20 02:12 /usr/bin/editor -> /etc/alternatives/editor

azureuser@ubuntu01:~$ ls -l /etc/alternatives/editor
lrwxrwxrwx 1 root root 9 Jun 20 02:13 /etc/alternatives/editor -> /bin/nano

# デフォルトのエディタを変更
azureuser@ubuntu01:~$ sudo update-alternatives --config editor
There are 4 choices for the alternative editor (providing /usr/bin/editor).

  Selection    Path                Priority   Status
------------------------------------------------------------
* 0            /bin/nano            40        auto mode
  1            /bin/ed             -100       manual mode
  2            /bin/nano            40        manual mode
  3            /usr/bin/vim.basic   30        manual mode
  4            /usr/bin/vim.tiny    15        manual mode

Press <enter> to keep the current choice[*], or type selection number:
```
