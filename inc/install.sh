f_create_user
f_create_swap

f_install_essential_packages

if [ $v_disable_root_ssh_login == true ]; then
  f_disable_root_ssh_login
fi

if [ $v_disable_ssh_password == true ]; then
  f_disable_ssh_password
fi

if [ $v_create_ssh_key == true ]; then
  f_create_ssh_key

fi

if [ $v_install_gui == true ]; then
  f_install_gui
fi

if [ $v_install_http_srv == true ]; then
  v_portslist+=(80 443)
  if [ $v_http_srv == "nginx" ]; then
    f_install_nginx
  elif [ $v_http_srv == "apache" ]; then
    f_install_apache
  fi
fi

if [ $v_install_php == true ]; then
  f_install_php
fi

if [ $v_install_mdb == true ]; then
  f_install_mariadb
  f_secure_db
fi

f_install_firewall

if [ $v_install_openvpn == true ]; then
  f_install_openvpn
fi

f_postinstall
