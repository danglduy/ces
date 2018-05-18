# Description
Linux Environment Install for CentOS 6/7

This script will:
- Install LAMP/LEMP: Apache/Nginx + MariaDB + PHP-FPM
- Install GUI (XFCE), VNC Server and Sublime Text (not enabled by default)
- Disable root ssh access
- Disable ssh password authentication
- Create one user with sudo

This script is under development. Use at your own risk!

# Install
```Shell
#Get the script
wget https://raw.githubusercontent.com/zldang/ces/master/ces.sh

#Change variables for your environment
nano ces.sh 

#Add run permission
chmod +x ces.sh

#Run
./ces.sh
```
