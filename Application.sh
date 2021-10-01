#! /bin/bash

echo -e "\e[1;34m Starting.............\e[0m"
sleep 4

sudo yum -y install httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl status httpd

echo -e "\e[1;32m ----------------------------------------------------------------- \e[0m"
echo -e "\e[1;32m  \e[0m"
echo -e "\e[1;32m                 Apache Successfully Installed \e[0m"
echo -e "\e[1;36m \e[0m"
echo -e "\e[1;32m ----------------------------------------------------------------- \e[0m"



yum -y install java-11-openjdk-devel

echo -e "\e[1;36m java installed \e[0m"

java --version

read -p 'Enter Tomcat Home Directory: ' home
useradd -m -U -d  $home -s /bin/false tomcat
sudo wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.41/bin/apache-tomcat-9.0.41.tar.gz
tar -xf apache-tomcat-9.0.41.tar.gz
mv  apache-tomcat-9.0.41  $home/
sudo ln -s $home/apache-tomcat-9.0.41 $home/latest
sudo chown -R tomcat: $home
sudo  sh -c "chmod +x $home/latest/bin/*.sh"
sudo chmod -R g+r $home/latest/conf
sudo chmod g+x $home/latest/conf
touch  /etc/systemd/system/tomcat.service
cat << EOF >>  /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat 9 servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/jre"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"

Environment="CATALINA_BASE=$home/latest"
Environment="CATALINA_HOME=$home/latest"
Environment="CATALINA_PID=$home/latest/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=$home/latest/bin/startup.sh
ExecStop=$home/latest/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

cat << EOF >> /etc/httpd/conf/httpd.conf
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
<VirtualHost *:80>
ProxyPreserveHost On
ProxyPass /elastic http://127.0.0.1:9200
ProxyPassReverse /elastic http://127.0.0.1:9200
ProxyPass / http://127.0.0.1:8080/
ProxyPassReverse / http://127.0.0.1:8080/
</VirtualHost>
EOF
setsebool -P httpd_can_network_connect on
sudo systemctl daemon-reload
sudo systemctl enable tomcat.service
sudo systemctl start tomcat.service
sudo systemctl restart httpd
sudo systemctl status tomcat.service


echo -e "\e[1;32m ----------------------------------------------------------------- \e[0m"
echo -e "\e[1;32m  \e[0m"
echo -e "\e[1;32m                 Tomcat Successfully Installed \e[0m"
echo -e "\e[1;36m \e[0m"
echo -e "\e[1;32m ----------------------------------------------------------------- \e[0m"



echo -e "\e[1;35m Starting Elasticsearch Installation..... \e[0m"
sleep 3
sudo yum -y install java-1.8.0-openjdk-devel
echo -e "\e[1;35m Select java 11 version in below prompt, \e[0m"
sleep 4
alternatives --config java
sudo wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.16.rpm
sudo rpm -ivh elasticsearch-5.6.16.rpm
sed -i "64i network.host: 0.0.0.0" /etc/elasticsearch/elasticsearch.yml
sed -i "65i http.host: 0.0.0.0" /etc/elasticsearch/elasticsearch.yml
sed -i "66i http.port: 9200" /etc/elasticsearch/elasticsearch.yml
sed -i "67i http.cors.enabled: true" /etc/elasticsearch/elasticsearch.yml
sudo systemctl daemon-reload
sudo systemctl start elasticsearch.service
sudo systemctl enable elasticsearch.service
sudo systemctl status elasticsearch

echo -e "\e[1;32m ----------------------------------------------------------------- \e[0m"
echo -e "\e[1;32m  \e[0m"
echo -e "\e[1;32m                 Elasticsearch Successfully Installed \e[0m"
echo -e "\e[1;36m \e[0m"
echo -e "\e[1;32m ----------------------------------------------------------------- \e[0m"









echo -e "\e[1;35m Starting Logstash Installation..... \e[0m"
sleep 3
sudo  wget https://artifacts.elastic.co/downloads/logstash/logstash-5.5.0.rpm
sudo rpm -ivh logstash-5.5.0.rpm

sed -i '36i some="/usr/lib/jvm/java-1.8.0-openjdk" ' /usr/share/logstash/bin/logstash.lib.sh
sed -i 's/JAVA_HOME/some/g' /usr/share/logstash/bin/logstash.lib.sh


echo -e "\e[1;32m ----------------------------------------------------------------- \e[0m"
echo -e "\e[1;32m  \e[0m"
echo -e "\e[1;32m                 Logstash Successfully Installed \e[0m"
echo -e "\e[1;36m \e[0m"
echo -e "\e[1;32m ----------------------------------------------------------------- \e[0m"

echo -e "\e[1;32m  \e[0m"
echo -e "\e[1;32m  \e[0m"
echo -e "\e[1;35m Starting Mysql Installation....  \e[0m"

sleep 3
sudo  wget https://repo.mysql.com/mysql80-community-release-el7-1.noarch.rpm
sudo yum -y localinstall mysql80-community-release-el7-1.noarch.rpm
sudo yum repolist enabled | grep "mysql.*-community.*"
sudo yum -y install mysql-community-server
cat << EOF >> /etc/my.cnf
sql_mode=""
lower_case_table_names=1
EOF

sudo systemctl start mysqld
sudo systemctl enable mysqld

OUTPUT=$( sudo grep 'temporary password' /var/log/mysqld.log |  awk 'END {print $NF}')
echo -e "\e[1;36m Enter this password for the below mysql root password  :  $OUTPUT  \e[0m"
sleep 3
mysql_secure_installation
read -s -p 'To confirm please enter the mysql password for user root : ' updatedpass
echo
echo -e "\e[1;36m Creating new mysql Username & Database  \e[0m"
sleep 4
read -p 'Enter new mysql UserName: ' user
read -s -p "Enter mysql password for user $user: " pass
echo
read -p 'Enter mysql Database Name: ' db
echo "create database $db; CREATE USER  '$user'@'%' IDENTIFIED BY  '$pass'; GRANT ALL ON $db.* TO  '$user'@'%'; ALTER USER '$user'@'%' IDENTIFIED WITH mysql_native_password BY '$pass';flush privileges;" | mysql -u root -p"$updatedpass"



read -p 'Enter path to DB bundle Directory: ' dbpath

cd $dbpath/DB-main
echo -e "\e[1;33m Database importing,Please wait.......  \e[0m"
sudo mysql -u root -p"$updatedpass" $db < all.sql
echo -e "\e[1;32m Database Imported Successfully  \e[0m"


read -p 'Enter path to  build Directory: ' buildpath
sudo  cp -R  /$buildpath/build/frontend $home/latest/webapps
sudo cp  /$buildpath/build/backend.war $home/latest/webapps
sudo systemctl restart tomcat.service

echo -e "\e[1;94m Please wait while the setup is complete....\e[0m"
sleep 18
read -p 'Enter your domain name/ip address: ' domain
sed -i "s/base123/$domain/g" $home/latest/webapps/frontend/assets/app-config.json
sed -i "s/elastic123/$domain/g" $home/latest/webapps/frontend/assets/app-config.json
sed -i "s/192.168.1.6/$domain/g" $home/latest/webapps/backend/WEB-INF/classes/application.properties
sed -i "s/usernaname/$user/g" $home/latest/webapps/backend/WEB-INF/classes/application.properties
sed -i "s/Password/$pass/g" $home/latest/webapps/backend/WEB-INF/classes/application.properties
sed -i "s/database/$db/g" $home/latest/webapps/backend/WEB-INF/classes/application.properties
systemctl restart tomcat.service
echo -e "\e[1;36m Please wait while Tomcat Restarting...  \e[0m"
sleep 10
echo -e "\e[1;36m Starting up.....  \e[0m"
sleep 8
echo -e "\e[1;32m Tomcat Successfully Restarted  \e[0m"

echo -e "\e[1;32m =================================================================================================\e[0m"
echo  -e "\e[1;32m \e[0m"
echo -e "\e[1;32m \e[0m"
GREEN="\e[92m"
printf "${GREEN}"
figlet -c  "Welcome To Application"
printf "${STOP}"

echo  -e "\e[1;32m \e[0m"
echo -e "\e[1;32m \e[0m"

echo -e "\e[1;32m =================================================================================================\e[0m"
echo -e "\e[1;32m \e[0m"
echo -e "\e[1;32m Application Is Available From The Below Url \e[0m"
echo $domain/Application


