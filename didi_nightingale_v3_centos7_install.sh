#!/bin/bash
#This is auto install didi nightingale server for centos7
#Run this script with root users
#Date:2021-01-13 v1.0 - beta -
#Date:2021-01-14 v3.6 - add support install agent -


#安装完成后mariadb的数据库root密码，yum默认安装root密码为空
DB_SYS=''

#监控程序需要创建的数据库用户名称
DB_USER='nightingale'

#监控程序需要创建的数据库用户的密码，会在mariadb中创建这个用户，用户密码不可以有 # $ & ! 这些字符
DB_PASS='user_pass123'


#server端的ip地址，打包agent的时候使用，采集数据会上传到这个ip地址上
#server使用阿里云等云服务器需要放行以下端口 8002,8005,8006,8009
SERVER_IP="49.10.10.10"

#---------------------------------------------------------------------------
#以下代码不要修改
N9E_URL="http://116.85.64.82/n9e.tar.gz"
N9E_PUB_URL="http://116.85.64.82/pub.tar.gz"


function stop_selinux 
{
  setenforce 0;
  sed -i 's#SELINUX=enforcing#SELINUX=disabled#' /etc/selinux/config;
  systemctl disable firewalld.service;
  systemctl stop firewalld.service;
  systemctl stop NetworkManager;
  systemctl disable NetworkManager;
}

function parpare_env 
{
  yum -y install epel-release;
  yum install -y mariadb-server redis nginx net-tools dstat;
  systemctl start mariadb;
  systemctl start redis;
  systemctl start nginx;
  systemctl enable mariadb;
  systemctl enable redis;
  systemctl enable nginx;
  
  CHECK_MARIADB=`ps -ef | grep -v grep | grep -ic mariadb`
  CHECK_REDIS=`ps -ef | grep -v grep | grep -ic redis`
  CHECK_NGINX=`ps -ef | grep -v grep | grep -ic nginx`
  if [[ "CHECK_MARIADB" -gt 0 ]] && [[ "CHECK_REDIS" -gt 0 ]] && [[ "CHECK_NGINX" -gt 0 ]]
  then
    echo "==`date +%F_%T`==  Parpare Success"
  else
    echo "==`date +%F_%T`==  Parpare Error! Exit1..."
    exit 1
  fi
}

function install_n9e_server 
{
  #install n9e
  mkdir -p /home/n9e && cd /home/n9e
  wget $N9E_URL;
  tar xvf n9e.tar.gz;
  /bin/cp -v etc/nginx.conf /etc/nginx/nginx.conf;
  systemctl restart nginx;

  #install pub
  cd /home/n9e;
  wget $N9E_PUB_URL;
  tar xvf pub.tar.gz;
}

function mysql_create_user
{
  #create mysql user and grant
  test -z $DB_SYS  && MYSQL_CONN_CONF_1="" || MYSQL_CONN_CONF_1="-p${DB_SYS}"
  test -z $DB_PASS && MYSQL_CONN_CONF_2="" || MYSQL_CONN_CONF_2="-p${DB_PASS}"
  echo "
  create user aaaaaa@localhost identified by 'bbbbbb';
  grant all on n9e_ams.* to aaaaaa@localhost;
  grant all on n9e_hbs.* to aaaaaa@localhost;
  grant all on n9e_job.* to aaaaaa@localhost;
  grant all on n9e_mon.* to aaaaaa@localhost;
  grant all on n9e_rdb.* to aaaaaa@localhost;
  " >/tmp/create_mysql_user.sql;
  
  sed -i "s/aaaaaa/$DB_USER/g" /tmp/create_mysql_user.sql;
  sed -i "s/bbbbbb/$DB_PASS/g" /tmp/create_mysql_user.sql;
  mysql -u root $MYSQL_CONN_CONF_1 < /tmp/create_mysql_user.sql;
  rm -f /tmp/create_mysql_user.sql;

  #import sql to database
  cd /home/n9e/sql/
  mysql -u $DB_USER $MYSQL_CONN_CONF_2 < n9e_ams.sql
  mysql -u $DB_USER $MYSQL_CONN_CONF_2 < n9e_hbs.sql
  mysql -u $DB_USER $MYSQL_CONN_CONF_2 < n9e_job.sql
  mysql -u $DB_USER $MYSQL_CONN_CONF_2 < n9e_mon.sql
  mysql -u $DB_USER $MYSQL_CONN_CONF_2 < n9e_rdb.sql
  
  sed -i "s/root/$DB_USER/g" /home/n9e/etc/mysql.yml
  sed -i "s/1234/$DB_PASS/g" /home/n9e/etc/mysql.yml
}

function start_n9e_server
{
  /home/n9e/control start all;
  sleep 3s;
  /home/n9e/control status all;
}

function install_server_info
{
  echo ""
  echo "---------------------------------"
  echo " This is you server install info"
  echo "---------------------------------"
  echo "Your system version: `cat /etc/redhat-release`"
  echo "Your mariadb username: $DB_USER"
  echo "Your mariadb password: $DB_PASS"
  echo "n9e-server install path:  /home/n9e"
  echo "n9e-server start command: /home/n9e/control start all"
  echo ""
  echo "Now you can enjoy with Nightingale"
  echo "-----------------------------------"
  echo "http://yourIP"
  echo "loginUser: root "
  echo "password:  root.2020 "
  echo "WARING: you must change your root password when you first login!"
  echo ""
}

function install_agent_info
{
  echo ""
  echo "--------------------------------"
  echo " This is you agent install info"
  echo "--------------------------------"
  echo "Your system version: `cat /etc/redhat-release`"
  echo "n9e-agent install path:   /home/n9e"
  echo "n9e-agent conf file path: /home/n9e/etc/address.yml"
  echo "                          /home/n9e/etc/agent.yml"
  echo "n9e-agent start command:  /home/n9e/control start all"
  echo ""
}

function agent_tar
{
  if [[ -d /home/n9e ]];
  then
    SCRIPT_PATH=`readlink -f $0`
    cd /home/n9e || exit 3
    mkdir n9e_agent_v3/etc -p
    cp -v $SCRIPT_PATH n9e-agent control n9e_agent_v3/
    cp -v etc/address.yml etc/agent.yml etc/identity.yml n9e_agent_v3/etc/
    sed -i "s/127.0.0.1/$SERVER_IP/g" n9e_agent_v3/etc/address.yml
    tar -zcvf n9e_agent_v3.tar.gz n9e_agent_v3
    echo ""
    echo "----------------------------"
    echo "This is tar agent file path:"
    echo "----------------------------"
    readlink -f n9e_agent_v3.tar.gz
    echo ""
  else
    echo "file path [/home/n9e] not exits! Exit5..."
    exit 5
  fi
}

function agent_install
{
  echo "==`date +%F_%T`==  Start install n9e-agent...";
  stop_selinux;
  yum install -y net-tools dstat;
  mkdir /home/n9e -p;
  mv -v control n9e-agent etc /home/n9e/;
  /home/n9e/control start all;
  sleep 3s;
  /home/n9e/control status all;
  install_agent_info;
  echo "==`date +%F_%T`==  Finish install n9e-agent...";
}

#main

if [[ "$1" == "server-install" ]];
then
  if [[ -f n9e-agent ]]; 
  then
    echo "Found [n9e-agent] file!";
    echo "Maybe you want to install agent, Exit2...";
    exit 2;
  fi  
  echo "==`date +%F_%T`==  Start install n9e-server...";
  stop_selinux;
  parpare_env;
  install_n9e_server;
  mysql_create_user;
  start_n9e_server;
  install_server_info;
  echo "==`date +%F_%T`==  Finish install n9e-server...";
elif [[ "$1" == "agent-tar" ]];
then
  agent_tar
elif [[ "$1" == "agent-install" ]];
then
  agent_install
else
  echo "Usage: bash $0 server-install | agent-tar | agent-install "
fi

