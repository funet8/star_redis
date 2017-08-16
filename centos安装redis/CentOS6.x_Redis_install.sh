#!/bin/bash
# -------------------------------------------------------------------------------
# Filename:    CentOS_Redis_install.sh
# Revision:    1.0
# Date:        2017/04/13
# Author:      star
# Email:       liuxing007xing@163.com
# Website:     www.funet8.com
# Description: centos 6.x ��װredis
# Notes:       ��Ҫ�л���root����,�汾���64λϵͳ������ϵͳΪCentOS6.3  
#��redis-stable.tar.gz�ϴ���/home/data/software/Ŀ¼��     
#�����صİ汾��redis_version_3.2.5   
#����wget http://download.redis.io/releases/redis-stable.tar.gz ���°汾
# -------------------------------------------------------------------------------
# Copyright:   2017 (c) star
# git��ַ��https://github.com/funet8/star_redis/blob/master/centos��װredis/CentOS6.x_Redis_install.sh


###############�������
redis_software="/home/data/software/"	#redis���Ŀ¼
redis_port="6379"						#redis�˿�
redis_conf="/data/conf/"			    #redis��������Ŀ¼	
redis_dir="/data/redis/${redis_port}"	#redis�־û�Ŀ¼
redis_passwd="123456"

###############1.��װredis
yum -y install tcl gcc gcc-c++ libstdc++-devel
if [ ! -e ${redis_software} ] 
then 
	mkdir -p ${redis_software}
fi
mkdir -p ${redis_software}
cd ${redis_software}
wget http://download.redis.io/releases/redis-stable.tar.gz
tar -zxf redis-stable.tar.gz 
cd redis-stable
make
cd src && make test
make install
###############2.����redis
cp ${redis_software}redis-stable/utils/redis_init_script /etc/init.d/redis_${redis_port}
#�޸������ļ���
#vi /etc/init.d/redis_${redis_port}
#REDISPORT=6379
#CONF="/data/conf/redis/${REDISPORT}.conf"
sed -i "s/REDISPORT\=6379/REDISPORT\=${redis_port}/g" /etc/init.d/redis_${redis_port}
#����$redis_conf ������"/"���� sed -i �޷�ʹ�ñ�����so����д�ɹ̶�
#sed -i "s/\/etc\/redis\/${redis_conf}/g" /etc/init.d/redis_${redis_port}  #����
sed -i "s/\/etc\/redis\//\/data\/conf\//g" /etc/init.d/redis_${redis_port}
#����Ŀ¼
if [ ! -e ${redis_conf} ] 
then 
	mkdir -p ${redis_conf}
fi
if [ ! -e ${redis_dir} ] 
then 
	mkdir -p ${redis_dir}
fi
cp /data/software/redis-stable/redis.conf ${redis_conf}${redis_port}.conf
#�޸������ļ���
#vi /data/conf/6379.conf
#vi ${redis_conf}${redis_port}.conf
#pidfile /var/run/redis_6379.pid
#port 6379
#daemonize yes  			# ʹRedis���ػ�����ģʽ����
#dir /var/redis/6379  		# ���ó־û��ļ���ŵ�λ��
cat > ${redis_conf}${redis_port}.conf << EOFI
#�󶨵�������ַ��Ĭ�ϣ�bind 127.0.0.1
bind 0.0.0.0
#�˿�
port ${redis_port}
# TCP �����������������
# �ڸ߲����Ļ����£�����Ҫ�����ֵ�����Ա���ͻ������ӻ��������⡣
# Linux �ں˻�һ������İ����ֵ��С�� /proc/sys/net/core/somaxconn ��Ӧ��ֵ��
# ������Ҫ�޸�������ֵ���ܴﵽ���Ԥ�ڡ�
tcp-backlog 511
# ָ����һ�� client ���ж�����֮��ر����ӣ�0 ���ǲ�������
timeout 20
# tcp ��������
# �������Ϊ���㣬������ͻ���ȱ��ͨѶ��ʱ��ʹ�� SO_KEEPALIVE ���� tcp acks ���ͻ��ˡ�
# ���֮�������ã���Ҫ������ԭ��
# 1) ��ֹ���� peers
# 2) Take the connection alive from the point of view of network
#    equipment in the middle.
# �Ƽ�һ�������ֵ����60��
tcp-keepalive 60
# Ĭ������� redis ������Ϊ�ػ��������еģ�������������ں�̨���У���Ͱ����ĳ� yes��
# ��redis��Ϊ�ػ��������е�ʱ������дһ�� pid �� /var/run/redis.pid �ļ����档
daemonize yes
#����ͨ��upstart��systemd����Redis�ػ����̣���������Ǻ;���Ĳ���ϵͳ��صġ�
supervised no
#��redis���ػ�ģʽ����ʱָ��pid
pidfile /var/run/redis_${redis_port}.pid
#loglevel��־����
#debug-->��¼������־��Ϣ�������ڿ��������Խ׶�
#verbose-->�϶���־��Ϣ
#notice-->������־��Ϣ��ʹ������������
#warning-->���в�����Ҫ���ؼ���Ϣ�Żᱻ��¼
loglevel notice
#��־�ļ���λ�� 
logfile "/data/wwwroot/log/redis_${redis_port}.log"
#�������ݿ����Ŀ
databases 16
#�������ݵ����̡���ʽ�ǣ�save <seconds> <changes> ���������� seconds ��֮�������� changes��keys �����ı��򱣴�һ�Ρ�
#Ĭ��������˼�ǣ���60 ��֮����10000 ��keys �����仯ʱ����300 ��֮����10 ��keys �����˱仯����900 ��֮����1 ��keys �����˱仯�����񱸷ݡ�
save 900 1
save 300 10
save 60 10000
#Ĭ������£���� redis ���һ�εĺ�̨����ʧ�ܣ�redis ��ֹͣ����д������������һ��ǿӲ�ķ�ʽ���û�֪�����ݲ�����ȷ�ĳ־û������̣� ����ͻ�û��ע�⵽���ѵķ����� �����̨��������������������ˣ�redis Ҳ���Զ�������д������Ȼ����Ҫ�ǰ�װ�˿��׵ļ�أ�����ܲ�ϣ�� redis ������������͸ĳ� no ���ˡ�
stop-writes-on-bgsave-error yes
#�Ƿ���dump  .rdb���ݿ��ʱ��ѹ���ַ�����Ĭ������Ϊyes����������ԼһЩcpu��Դ�Ļ������԰�������Ϊno�������Ļ����ݼ��Ϳ��ܻ�Ƚϴ�
rdbcompression yes
#�Ƿ�CRC64У��rdb�ļ�������һ����������ʧ�����10%����
rdbchecksum yes
#rdb�ļ�
dbfilename dump.rdb
#���ݿ���Ŀ¼��������һ��Ŀ¼��aof�ļ�Ҳ�ᱣ�浽��Ŀ¼�¡�
dir ${redis_dir}
#���ñ���Ϊslave���񡣸�ʽ��slaveof <masterip> <masterport>������master�����IP��ַ���˿ڣ���Redis����ʱ�������Զ���master��������ͬ��
# slaveof  192.168.1.3  6379
# slaveof <masterip> <masterport>
#��master�������������뱣��ʱ��slave��������master�����롣
#masterauth
#��һ��slave��masterʧȥ��ϵʱ�����߸������ڽ��е�ʱ��slaveӦ���������Ϊ��1) ���Ϊ yes��Ĭ��ֵ�� ��slave ��Ȼ��Ӧ��ͻ������󣬵����ص����ݿ����ǹ�ʱ���������ݿ����ǿյ��ڵ�һ��ͬ����ʱ��2) ���Ϊ no ������ִ�г��� info �� salveof ֮�����������ʱ��slave ��������һ�� "SYNC with master in progress" �Ĵ���
slave-serve-stale-data yes
#����slave�Ƿ���ֻ���ġ���2.6����slaveĬ����ֻ���ġ�
slave-read-only yes
#�������ݸ����Ƿ�ʹ����Ӳ�̸��ƹ��ܡ�
repl-diskless-sync no
repl-diskless-sync-delay 5
#ָ����slaveͬ������ʱ���Ƿ����socket��NO_DELAYѡ �������Ϊ��yes���������NO_DELAY����TCPЭ��ջ��ϲ�С��ͳһ���ͣ��������Լ������ӽڵ��İ���������ʡ����������������ͬ���� slave��ʱ�䡣������Ϊ��no������������NO_DELAY����TCPЭ��ջ�����ӳ�С���ķ���ʱ������������ͬ������ʱ����٣�����Ҫ����Ĵ��� ͨ������£�Ӧ������Ϊno�Խ���ͬ����ʱ���������ӽڵ�����縺���Ѿ��ܸߵ�����£���������Ϊyes��
repl-disable-tcp-nodelay yes
#�� master ��������������ʱ��Redis Sentinel ��� slaves ��ѡ��һ���µ� master�����ֵԽС����Խ�ᱻ����ѡ�У���������� 0 �� ������ζ����� slave �����ܱ�ѡ�С� Ĭ�����ȼ�Ϊ 100��
slave-priority 100
#����redis�������롣
requirepass ${redis_passwd}
#�Ƿ�����aof�־û���ʽ �����Ƿ���ÿ�θ��²����������־��¼��Ĭ��������no�����ڲ����첽��ʽ������д�뵽���̣���������������ܻ��ڶϵ�ʱ���²������ݶ�ʧ��
appendonly no
#������־�ļ�����Ĭ��ֵΪappendonly.aof ��
appendfilename "appendonly.aof"
#aof�ļ�ˢ�µ�Ƶ�ʡ������֣�
#no ����OS����ˢ�£�redis������ˢ��AOF��������죬����ȫ�ԾͲ
#always ÿ�ύһ���޸��������fsyncˢ�µ�AOF�ļ����ǳ��ǳ�������Ҳ�ǳ���ȫ��
#everysec ÿ���Ӷ�����fsyncˢ�µ�AOF�ļ����ܿ죬�����ܻᶪʧһ�����ڵ����ݡ�
appendfsync everysec
#ָ���Ƿ��ں�̨aof�ļ�rewrite�ڼ����fsync��Ĭ��Ϊno����ʾҪ����fsync�����ۺ�̨�Ƿ����ӽ�����ˢ�̣���Redis�ں�̨дRDB�ļ�����дAOF�ļ��ڼ����ڴ�������IO����ʱ����ĳЩlinuxϵͳ�У�����fsync���ܻ�������
no-appendfsync-on-rewrite no
#��AOF�ļ�������һ����С��ʱ��Redis�ܹ����� BGREWRITEAOF ����־�ļ�������д ����AOF�ļ���С�������ʴ��ڸ�������ʱ�Զ�������д��
auto-aof-rewrite-percentage 100
#��AOF�ļ�������һ����С��ʱ��Redis�ܹ����� BGREWRITEAOF ����־�ļ�������д ����AOF�ļ���С���ڸ�������ʱ�Զ�������д��
auto-aof-rewrite-min-size 64mb
#redis������ʱ���Լ��ر��ضϵ�AOF�ļ���������Ҫ��ִ�� redis-check-aof ���ߡ�
aof-load-truncated yes
#һ��Lua�ű����ִ��ʱ�䣬��λΪ���룬���Ϊ0������ʾ����ִ��ʱ�䣬Ĭ��Ϊ5000��
lua-time-limit 5000
#�趨ִ��ʱ�䣬��λ�Ǻ��룬ִ��ʱ��������ʱ�������ᱻ����log��-1��ʾ����¼slow log; 0ǿ�Ƽ�¼��������
slowlog-log-slower-than 10000
#slow log�ĳ��ȡ���СֵΪ0�������־�����ѳ�����󳤶ȣ�������ļ�¼�ᱻ�Ӷ���������� 
slowlog-max-len 128
#������ڲ����ӳټ��,����һ���������ֵ��������100ms
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
#����ڴ����ã�Ĭ��Ϊ0,��ʾ"������",�Ƽ�Ϊ�����ڴ��3/4,��������Ҫ��"maxmemory-policy"���ʹ��,��redis���ڴ����ݴﵽmaxmemoryʱ,����"�������"
maxmemory 512m
#�ڴ治��"ʱ,�����������,Ĭ��Ϊ"volatile-lru"��
maxmemory-policy volatile-lru
#����ͬʱ���ӵĿͻ������������׹��������ٸ��ݾ����������
maxclients 30000
EOFI
# �����ע�͵������ļ����ݣ�����鿴
#awk '! /^(#|$)/' ${redis_conf}${redis_port}.conf
###############3.����redis������������
/etc/init.d/redis_${redis_port} start
echo "/etc/init.d/redis_${redis_port} start" >> /etc/rc.d/rc.local
###############4.����ǽ�����˿�
#����˿�
iptables -I INPUT 4 -p tcp -m state --state NEW -m tcp --dport ${redis_port} -j ACCEPT
/etc/init.d/iptables save 
/etc/init.d/iptables restart


######################################
#�����˿�: 63921
#cp /data/conf/63920.conf /data/conf/63921.conf 
#vi /data/conf/63921.conf 
#�޸����£� 
#port 63921
#pidfile /var/run/redis_63921.pid
#logfile "/data/wwwroot/log/redis_63921.log"
#dir /data/redis/63921
#mkdir /data/redis/63921

#cp -a /etc/init.d/redis_63920 /etc/init.d/redis_63921
#vi /etc/init.d/redis_63921
#�޸Ķ˿ڣ� REDISPORT=63921
#������
#/etc/init.d/redis_63921 start

