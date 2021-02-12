#!/bin/bash

# vars
ip=$1
mysql_pass=$2
vnc_pass=$3
# define the ip
#ip=$(hostname -I)
#ip=${ip// } #remove leading spaces
#ip=${ip%% } #remove trailing spaces
echo $ip

echo "----Welcome to limitless server setup script!!----"$'\r'$'\r'

echo "----Update YUM!!---------------------"$'\r'$'\r'
yum update -y

echo "----Setup firewalld!!---------------------"$'\r'$'\r'
systemctl enable firewalld
systemctl start firewalld
systemctl status firewalld

echo "----Install nano!!---------------------"$'\r'$'\r'
yum install nano -y
echo "----Install expect!!---------------------"$'\r'$'\r'
yum install expect -y

echo "----Setup mysql!!---------------------"$'\r'$'\r'
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
yum -y install epel-release
yum -y install mariadb-server mariadb
systemctl start mariadb.service
systemctl enable mariadb.service
# Download secure expect from limitless.media
curl -o secure.exp https://raw.githubusercontent.com/anotherawesomeprojects/centos-7-installer/main/secure.exp
chmod a+x ./secure.exp
echo "----Do Exepect mysql secure installation!!---------------------"$'\r'$'\r'
expect ./secure.exp $mysql_pass
echo "----Exepect mysql secure installation End!!---------------------"$'\r'$'\r'
systemctl restart mariadb.service
echo "----Mysql Installed!!---------------------"$'\r'$'\r'

echo "----Setup Apache and PHP!!---------------------"$'\r'$'\r'
yum install httpd -y
systemctl start httpd.service
systemctl enable httpd.service
echo "----Restart Firewalld!!---------------------"$'\r'$'\r'
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

yum install php -y
systemctl restart httpd.service
echo "----Apache and PHP Installed---------------------"$'\r'$'\r'

echo "----setup IP---------------------"$'\r'$'\r'
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
curl -o /etc/httpd/conf/httpd.conf https://raw.githubusercontent.com/anotherawesomeprojects/centos-7-installer/main/httpd_centos7.conf
sed -i "s/ServerName www.example.com:80/ServerName $ip:80/g" /etc/httpd/conf/httpd.conf
echo "----IP SET!!---------------------"$'\r'$'\r'

echo "----Getting MySQL Support In PHP5---------------------"$'\r'$'\r'
yum -y install php-mysql
yum -y install php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-snmp php-soap curl curl-devel
systemctl restart httpd.service
echo "----MySQL Support Installed!!---------------------"$'\r'$'\r'

echo "----Setup phpMyAdmin!!--------------------"$'\r'$'\r'
yum install phpMyAdmin -y
mv /etc/httpd/conf.d/phpmyadmin.conf /etc/httpd/conf.d/phpmyadmin.conf.bak
curl -o /etc/httpd/conf.d/phpmyadmin.conf https://raw.githubusercontent.com/anotherawesomeprojects/centos-7-installer/main/phpMyAdmin_centos7.conf
sed -i "s/cookie/http/g" /usr/share/phpmyadmin/config.inc.php
systemctl restart  httpd.service
echo "----phpMyAdmin Installed!!---------------------"$'\r'$'\r'

echo "----remove known_hosts---------------------"$'\r'$'\r'
rm -rf /root/.ssh/known_hosts
echo "----remove known_hosts SET!!---------------------"$'\r'$'\r'

echo "----install sshpass!!---------------------"$'\r'$'\r'
yum --enablerepo=epel -y install sshpass
echo "----install lynx!!---------------------"$'\r'$'\r'
yum install lynx -y
echo "----install CLI!!---------------------"$'\r'$'\r'
curl -O https://github.com/anotherawesomeprojects/centos-7-installer/raw/main/wp-cli.phar
chmod +x wp-cli.phar
sudo sh -c 'mv wp-cli.phar /usr/local/bin/wp'

systemctl restart  httpd.service

# just in case
file="./wp-cli.phar"
if [ -f "$file" ]
then
	mv wp-cli.phar /usr/local/bin/wp
fi
if [ -f "$file" ]
then
sudo mv wp-cli.phar /usr/local/bin/wp
fi

sed -i "s,export PATH,export PATH=/root/.wp-cli/bin:\$PATH,g" ~/.bash_profile
echo "

LANG=en_US.utf-8
LC_ALL=en_US.utf-8" >> /etc/environment


mkdir ~/.wp-cli
echo "apache_modules:
  - mod_rewrite" > ~/.wp-cli/config.yml

chown apache.root /var/www/html/ -R

echo "----Restart Firewalld!!---------------------"$'\r'$'\r'
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

systemctl restart httpd.service

echo "<?php phpinfo(); ?>" > /var/www/html/info.php

# setup VNC
echo "---- Lets Setup VNC ----"$'\r'$'\r'

yum groupinstall "GNOME Desktop" -y
yum install tigervnc-server xorg-x11-fonts-Type1 -y
# yum install libX11 -y
cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:1.service
sed -i "s/<USER>/root/g" /etc/systemd/system/vncserver@:1.service
sed -i "s,ExecStart=/usr/sbin/runuser -l root -c \"/usr/bin/vncserver %i\",ExecStart=/usr/sbin/runuser -l root -c \"/usr/bin/vncserver %i -geometry 1200x600\",g" /etc/systemd/system/vncserver@:1.service

# Configure firewall rules to allow the VNC connection.
firewall-cmd --permanent --zone=public --add-service vnc-server
firewall-cmd --reload

# set vars for vnc
vncpass=Bismillah

# expect
expect <<EOF

spawn vncpasswd

expect "Password:"
send "$vncpass\r"

expect "Verify:"
send "$vncpass\r"

expect eof
exit
EOF

systemctl daemon-reload
systemctl start vncserver@:1.service
systemctl enable vncserver@:1.service

# status
echo "<?php echo 'Install Server $ip Successfull!'; ?>" > /var/www/html/success.php

echo "----All SET------------------------------------"
reboot
