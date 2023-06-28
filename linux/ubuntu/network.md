## ネットワーク設定

```bash
#　ネットワークインターフェイスの確認
networkctl

IDX LINK      TYPE     OPERATIONAL SETUP
  1 lo        loopback carrier     unmanaged
  2 eth0      ether    routable    configured
  3 enP6376s1 ether    enslaved    unmanaged

3 links listed.

# IPアドレスの確認 (networkctl)
networkctl status eth0

● 2: eth0
                     Link File: /run/systemd/network/10-netplan-eth0.link
                  Network File: /run/systemd/network/10-netplan-eth0.network
                          Type: ether
                         State: routable (configured)
                  Online state: online
                          Path: acpi-VMBUS:00
                        Driver: hv_netvsc
                    HW Address: 00:22:48:e8:51:13 (Microsoft Corporation)
                           MTU: 1500 (min: 68, max: 65521)
                         QDisc: mq
  IPv6 Address Generation Mode: eui64
          Queue Length (Tx/Rx): 64/64
              Auto negotiation: no
                         Speed: 50Gbps
                       Address: 10.0.1.4 (DHCP4 via 168.63.129.16)
                                fe80::222:48ff:fee8:5113
                       Gateway: 10.0.1.1
                           DNS: 168.63.129.16
                Search Domains: 3dhget43mkduzaatzyphgahk5a.lx.internal.cloudapp.net
             Activation Policy: up
           Required For Online: yes
               DHCP4 Client ID: IAID:0x9d848f74/DUID
             DHCP6 Client DUID: DUID-EN/Vendor:0000ab11b3782c590fcd68060000

# IPアドレスの確認 (ip)
ip a

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:22:48:e8:51:13 brd ff:ff:ff:ff:ff:ff
    inet 10.0.1.4/24 metric 100 brd 10.0.1.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::222:48ff:fee8:5113/64 scope link
       valid_lft forever preferred_lft forever
3: enP6376s1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master eth0 state UP group default qlen 1000
    link/ether 00:22:48:e8:51:13 brd ff:ff:ff:ff:ff:ff
    altname enP6376p0s2

# ネットワーク設定の上書き (50-cloud-init.yaml は編集しない)
sudo vi /etc/netplan/99-custom.yaml
sudo netplan try
sudo netplan apply
```

## ソケット

```bash
# TCPソケットを表示
ss -t

# UDPソケットを表示
ss -u

# 待ち受け中のソケットを表示
ss -l

# ソケットを使用しているプロセスも表示
ss -p

# TCPで待ち受けているサービスを表示
ss -ltp
```
