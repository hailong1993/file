centos7系统部署滴滴夜莺v3
Date：2021-01-14 v1.0


1，服务器要求

   centos7系统
   yum能用
   有root权限
   服务器能上网，因为要下载软件

  
2，部署后环境，建议使用全新的刚刚安装的centos7的系统，安装比较顺利

   目前只是支持部署一个server端采集数据，agent部署到相关机器的操作，那些高级的分布式啥的不支持
   会关闭selinux，firewalld
   会自动安装mariadb，redis，nginx
   mariadb会自动创建指定用户，为夜莺使用的用户，相关配置文件会修改
   redis默认使用空密码
   n9e会部署到默认路径 /home/n9e
   mariadb，redis，nginx会开机自动启动，n9e没有部署开机启动！


3，server端部署
   上传脚本，配置脚本中的相关变量
   
   运行安装server端
   [root@centos7 ~]# bash didi_nightingale_v3_centos7_install.sh
   Usage: bash didi_nightingale_v3_centos7_install.sh server-install | agent-tar | agent-install
   [root@centos7 ~]# bash didi_nightingale_v3_centos7_install.sh server-install
   
   运行安装完成后的样子
   ---------------------------------
   This is you server install info
   ---------------------------------
   Your system version: CentOS Linux release 7.7.1908 (Core)
   Your mariadb username: nightingale
   Your mariadb password: user_pass123
   n9e-server install path:  /home/n9e
   n9e-server start command: /home/n9e/control start all
   
   Now you can enjoy with Nightingale
   -----------------------------------
   http://yourIP
   loginUser: root
   password:  root.2020
   WARING: you must change your root password when you first login!


4，agent部署方法
   首先，server端打包agent用的文件，【是在server端打包agent的文件！】
   [root@centos7 ~]# bash didi_nightingale_v3_centos7_install.sh agent-tar

   打包完成的样子
   ----------------------------
   This is tar agent file path:
   ----------------------------
   /home/n9e/n9e_agent_v3.tar.gz

   把这个文件想办法上传到要监控的服务器上，解压后，运行脚本安装agent
   [root@7-video home]# tar -xvf n9e_agent_v3.tar.gz
   [root@7-video home]# cd n9e_agent_v3
   [root@7-video n9e_agent_v3]# bash didi_nightingale_v3_centos7_install.sh agent-install
   
   安装完成的样子
   --------------------------------
    This is you agent install info
   --------------------------------
   Your system version: CentOS Linux release 7.6.1810 (Core)
   n9e-agent install path:   /home/n9e
   n9e-agent conf file path: /home/n9e/etc/address.yml
                             /home/n9e/etc/agent.yml
   n9e-agent start command:  /home/n9e/control start all


5，一些常见操作，做了一些判断，有一定的容错率，检测到错误的操作，会自动退出部署
