#!/bin/bash
if [ "$PWD" != "/opt/local/zabbix/" ]; then mkdir -p /opt/local/zabbix/ && cp -ap ../* /opt/local/zabbix/ && cd /opt/local/zabbix/; fi
if [ ! $1 ]; then echo "Usage: $0 Sigla Hostname Versao, ex: $0 CTL servidorweb zbx5"; exit; fi

function LINUX(){
        if [ ! $2 ]; then export HOSTNAME=$(hostname); else HOSTNAME=$2; fi
	if [ "$3" = "zbx3" ] || [ "$3" = "zbx4" ] || [ "$3" = "zbx5" ]; then tar --overwrite -xf /opt/local/zabbix/$3amd64.tar.gz ./bin ./sbin -C /opt/local/zabbix/ && rm -rf /opt/local/zabbix/bin/ /opt/local/zabbix/sbin/ && mv -f ./bin /opt/local/zabbix/ && mv -f ./sbin /opt/local/zabbix/ ;fi
        CLIENTE=$1
        SERVER=`/opt/local/zabbix/install/getserverip.sh $1`

        if [ ! -f /etc/zabbix_agentd.conf ]; then
        echo "Hostname=$HOSTNAME
        Server=$SERVER
        ServerActive=$SERVER
        LogFile=/tmp/zabbix_agent.log
        LogFileSize=20
        PidFile=/tmp/zabbix_agent.pid
        Include=/opt/local/zabbix/conf/zabbix_agentd/" > /etc/zabbix_agentd.conf
        fi

        cp /opt/local/zabbix/install/zabbix-agent-init.linux /etc/init.d/zabbix-agent
        #update-rc.d -f zabbix-agent defaults
        groupadd -g 7789 zabbix
        useradd -u 7789 -g zabbix zabbix
        #echo "0 0 * * * /opt/local/zabbix/install/update.sh $1" >> /var/spool/cron/crontabs/root
        #/etc/init.d/cron restart
        ln -s /opt/local/zabbix/install/zabbix-java.sh /etc/init.d/zabbix-java
        #update-rc.d -f zabbix-java defaults

	if command -v update-rc.d &> /dev/null; then
	update-rc.d -f zabbix-agent defaults
	update-rc.d -f zabbix-java defaults
	fi

	if command -v chkconfig &> /dev/null; then
	cp -afp /opt/local/zabbix/install/zabbix-agent-init-centos.linux /etc/init.d/zabbix-agent
	sudo chkconfig zabbix-agent on
	sudo chkconfig --add zabbix-agent
	sudo chkconfig --level 345 zabbix-agent on
	fi

	/etc/init.d/zabbix-java
        touch /tmp/zabbix_agent.log && chown zabbix /tmp/zabbix_agent.log
	chown -R zabbix: /opt/local/zabbix/
        CHECKINIT
	systemctl enable zabbix.service
	ps -C zabbix_agentd >/dev/null && echo "Zabbix is already running." || systemctl start zabbix.service
	sleep 3
	ps -C zabbix_agentd >/dev/null && echo "Zabbix is already running." || bash /etc/init.d/zabbix-agent start
}

function SOLARIS(){
        HOSTNAME=$2
        CLIENTE=$1
        SERVER=`/opt/local/zabbix/install/getserverip.sh $1`

        echo "Hostname=$HOSTNAME
        Server=$SERVER
        ServerActive=$SERVER
        Include=/opt/local/zabbix/conf/zabbix_agentd/" > /etc/zabbix_agentd.conf

        cp /opt/local/zabbix/install/zabbix-agent.xml /var/svc/manifest/site/
        svccfg import /var/svc/manifest/site/zabbix-agent.xml
        svcadm restart svc:/system/manifest-import
        groupadd -g 7789 zabbix
        useradd -u 7789 -g zabbix zabbix
        sleep 5
        svcadm enable application/zabbix-agent
        sleep 5
        svcs -xv application/zabbix-agent
        #echo "0 0 * * * /opt/local/zabbix/install/update.sh $1" >> /var/spool/cron/crontabs/root
        svcadm disable cron
        svcadm enable cron
        ln -s /opt/local/zabbix/install/zabbix-java.sh /etc/rc3.d/S99zabbix-java
        /etc/rc3.d/S99zabbix-java
}

function CHECKINIT(){
if command -v systemctl &> /dev/null
then
        cp /opt/local/zabbix/install/zabbix.service /etc/systemd/system/zabbix.service
        chmod 744 /etc/init.d/zabbix-agent
        chmod 664 /etc/systemd/system/zabbix.service
	chmod +x /etc/init.d/zabbix-agent
	chown -R zabbix /opt/local/zabbix/
        systemctl daemon-reload
        systemctl enable zabbix.service
	systemctl start zabbix.service
    exit
fi
}

cp -f /opt/local/zabbix/install/zabbix.txt /
chmod 777 /zabbix.txt
SO=`uname -s`

if [ "$SO" == "SunOS" ]; then
        SOLARIS "$1" "$2"
else
        LINUX "$1" "$2" "$3"
fi
