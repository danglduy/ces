function f_create_user() {
  # Create new user & prompt for password creation
  read -p "Your username: " user
  printf "\n"
  adduser $user
  passwd $user
  #Add user $user to sudo group
  usermod -a -G wheel $user
}

function f_disable_root_ssh_login() {
  #Disable SSH Root Login
  sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
}

function f_disable_ssh_password() {
  #Disable SSH Password Authentication
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
  sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
}

function f_create_ssh_key() {
  v_root_ssh_keypath="/root/.ssh/authorized_keys"
  #Check root ssh key exist
  if [ -f "$v_root_ssh_keypath" ]; then
    #If exist copy the key to the user and delete the root's key folder
    cp -R /root/.ssh /home/$user/.ssh
    chown -R $user:$user /home/$user/.ssh
    chmod 700 /home/$user/.ssh
    chmod 600 /home/$user/.ssh/authorized_keys
    rm -R /root/.ssh
  else
    sudo -u $user mkdir -p /home/$user/.ssh
    #If not exist create key file to the user
    cat <<EOT >> /home/$user/.ssh/authorized_keys
    $publickey
EOT
    chown -R $user:$user /home/$user/.ssh
    chmod 700 /home/$user/.ssh
    chmod 600 /home/$user/.ssh/authorized_keys
  fi
  service sshd restart
}

function f_create_swap() {
  #Create swap disk image if the system doesn't have swap.
  checkswap="$(swapon --show)"
  if [ -z "$checkswap" ]; then
    mkdir -v /var/cache/swap
    dd if=/dev/zero of=/var/cache/swap/swapfile bs=$v_swap_bs count=1M
    chmod 600 /var/cache/swap/swapfile
    mkswap /var/cache/swap/swapfile
    swapon /var/cache/swap/swapfile
    echo "/var/cache/swap/swapfile none swap sw 0 0" | tee -a /etc/fstab
  fi
}

function f_config_nano_erb() {
  #Nano config for erb
  wget -P /usr/share/nano/ https://raw.githubusercontent.com/scopatz/nanorc/master/erb.nanorc
  sudo -u $user cat <<EOT >> /home/$user/.nanorc
  set tabsize 2
  set tabstospaces
  include "/usr/share/nano/erb.nanorc"
EOT
}

function f_disable_sudo_password_for_yum() {
  echo "$user ALL=(ALL) NOPASSWD: /usr/bin/yum" >> /etc/sudoers.d/tmpsudo$user
  chmod 0440 /etc/sudoers.d/tmpsudo$user
}

function f_enable_sudo_password_for_yum() {
  rm /etc/sudoers.d/tmpsudo$user

}

function f_install_sublimetext() {
  #Sublime Text
  rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
  yum-config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
  yum -y install sublime-text
}

function f_install_vncserver() {
  yum install tigervnc-server
  #Create vncserver launch file
  sudo -u $user touch /home/$user/vncserver.sh
  sudo -u $user chmod +x /home/$user/vncserver.sh
  if [ $v_vnc_localhost == true ]; then
    sudo -u $user echo "vncserver -geometry 1280x650 -localhost" > /home/$user/vncserver.sh
  else
    sudo -u $user echo "vncserver -geometry 1280x650" > /home/$user/vncserver.sh
  fi
}

function f_install_gui() {
  #Install xfce, vnc server, sublime-text
  yum groupinstall "Xfce" -y
  f_install_sublimetext
  f_install_vncserver
}

function f_install_essential_packages() {
  yum -y install epel-release
  yum -y install centos-release-scl
  yum -y install curl whois unzip sudo
}

function f_install_apache() {
  yum -y install httpd
}

function f_install_nginx() {
  yum -y install nginx
  systemctl enable nginx
}

function f_install_php() {
  #PHP
  yum -y install rh-php70 rh-php70-php rh-php70-php-bcmath \
                  rh-php70-php-cli rh-php70-php-common rh-php70-php-dba \
                  rh-php70-php-embedded rh-php70-php-enchant rh-php70-php-fpm \
                  rh-php70-php-gd rh-php70-php-intl rh-php70-php-ldap \
                  rh-php70-php-mbstring rh-php70-php-mysqlnd rh-php70-php-odbc \
                  rh-php70-php-pdo rh-php70-php-pear rh-php70-php-pgsql \
                  rh-php70-php-process rh-php70-php-pspell rh-php70-php-recode \
                  rh-php70-php-snmp rh-php70-php-soap rh-php70-php-xml \
                  rh-php70-php-xmlrpc \
                  sclo-php70-php-imap sclo-php70-php-mcrypt \
                  sclo-php70-php-tidy \
                  sclo-php70-php-pecl-memcached sclo-php70-php-pecl-redis sclo-php70-php-pecl-imagick
  systemctl enable rh-php70-php-fpm
  if [ $v_install_http_srv == true ]; then
    if [ $v_http_srv == "nginx" ]; then
      chown -R root:nginx /var/opt/rh/rh-php70/lib/php/session
      chown -R root:nginx /var/opt/rh/rh-php70/lib/php/opcache
      chown -R root:nginx /var/opt/rh/rh-php70/lib/php/wsdlcache
    elif [ $v_http_srv == "apache" ]; then
      chown -R root:apache /var/opt/rh/rh-php70/lib/php/session
      chown -R root:apache /var/opt/rh/rh-php70/lib/php/opcache
      chown -R root:apache /var/opt/rh/rh-php70/lib/php/wsdlcache
    fi
  fi
}

function f_install_openvpn() {
  wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh
  mv /root/*.ovpn /home/$user/
  chown -R $user:$user /home/$user/
}

function f_install_mariadb() {
  cat <<EOT >> /etc/yum.repos.d/MariaDB.repo
# MariaDB 10.1 CentOS repository list - created 2018-05-16 04:23 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOT
  yum -y install MariaDB-server MariaDB-client
  systemctl enable mariadb.service
  systemctl start mariadb.service
}

function f_secure_db() {
  read -sp "Set mysql root password: " MYSQL_ROOT_PASSWORD
  sudo mysql -uroot << EOF
  UPDATE mysql.user SET Password=PASSWORD("$MYSQL_ROOT_PASSWORD") WHERE User='root';
  DELETE FROM mysql.user WHERE user='root' AND host NOT IN ('localhost', '127.0.0.1', '::1');
  DELETE FROM mysql.user WHERE user='';
  DROP DATABASE IF EXISTS test;
  UPDATE mysql.user SET plugin='' WHERE user='root';
  FLUSH PRIVILEGES;
EOF
}

function f_install_firewall() {
  for i in "${v_portslist[@]}"
  do
    :
    echo "Added port $i to firewall ports open list"; firewall-cmd --zone=public --permanent --add-port=$i/tcp &> /dev/null
    done
  firewall-cmd --zone=public --remove-service=ssh --permanent
  firewall-cmd --reload
}

function f_postinstall() {
  yum update
}
