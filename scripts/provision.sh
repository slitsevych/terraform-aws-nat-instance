#!/bin/bash -xe

sudo sysctl -w net.ipv4.ip_forward=1
sudo /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sudo yum install iptables-services -y
sudo service iptables save
sudo service iptables start
sudo chkconfig iptables on

sudo systemctl disable sshd --now
sudo systemctl disable rpcbind --now