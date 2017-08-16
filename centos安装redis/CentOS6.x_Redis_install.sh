#!/bin/bash
# -------------------------------------------------------------------------------
# Filename:    CentOS_Redis_install.sh
# Revision:    1.0
# Date:        2017/04/13
# Author:      star
# Email:       liuxing007xing@163.com
# Website:     www.funet8.com
# Description: centos 6.x 安装redis
# Notes:       需要切换到root运行,版本针对64位系统，操作系统为CentOS6.3  
#将redis-stable.tar.gz上传到/home/data/software/目录中     
#我下载的版本是redis_version_3.2.5   
#或者wget http://download.redis.io/releases/redis-stable.tar.gz 最新版本
# -------------------------------------------------------------------------------
# Copyright:   2017 (c) star
# git地址：https://github.com/funet8/star_redis/blob/master/centos安装redis/CentOS6.x_Redis_install.sh


###############定义变量
redis_software="/home/data/software/"	#redis软件目录
redis_port="6379"						#redis端口
redis_conf="/data/conf/"			    #redis配置所在目录	
redis_dir="/data/redis/${redis_port}"	#redis持久化目录
redis_passwd="123456"

###############1.安装redis
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
###############2.配置redis
cp ${redis_software}redis-stable/utils/redis_init_script /etc/init.d/redis_${redis_port}
#修改配置文件：
#vi /etc/init.d/redis_${redis_port}
#REDISPORT=6379
#CONF="/data/conf/redis/${REDISPORT}.conf"
sed -i "s/REDISPORT\=6379/REDISPORT\=${redis_port}/g" /etc/init.d/redis_${redis_port}
#由于$redis_conf 里面有"/"导致 sed -i 无法使用变量，so这里写成固定
#sed -i "s/\/etc\/redis\/${redis_conf}/g" /etc/init.d/redis_${redis_port}  #报错
sed -i "s/\/etc\/redis\//\/data\/conf\//g" /etc/init.d/redis_${redis_port}
#创建目录
if [ ! -e ${redis_conf} ] 
then 
	mkdir -p ${redis_conf}
fi
if [ ! -e ${redis_dir} ] 
then 
	mkdir -p ${redis_dir}
fi
cp /data/software/redis-stable/redis.conf ${redis_conf}${redis_port}.conf
#修改配置文件：
#vi /data/conf/6379.conf
#vi ${redis_conf}${redis_port}.conf
#pidfile /var/run/redis_6379.pid
#port 6379
#daemonize yes  			# 使Redis以守护进程模式运行
#dir /var/redis/6379  		# 设置持久化文件存放的位置
cat > ${redis_conf}${redis_port}.conf << EOFI
#绑定的主机地址，默认：bind 127.0.0.1
bind 0.0.0.0
#端口
port ${redis_port}
# TCP 监听的最大容纳数量
# 在高并发的环境下，你需要把这个值调高以避免客户端连接缓慢的问题。
# Linux 内核会一声不响的把这个值缩小成 /proc/sys/net/core/somaxconn 对应的值，
# 所以你要修改这两个值才能达到你的预期。
tcp-backlog 511
# 指定在一个 client 空闲多少秒之后关闭连接（0 就是不管它）
timeout 20
# tcp 心跳包。
# 如果设置为非零，则在与客户端缺乏通讯的时候使用 SO_KEEPALIVE 发送 tcp acks 给客户端。
# 这个之所有有用，主要由两个原因：
# 1) 防止死的 peers
# 2) Take the connection alive from the point of view of network
#    equipment in the middle.
# 推荐一个合理的值就是60秒
tcp-keepalive 60
# 默认情况下 redis 不是作为守护进程运行的，如果你想让它在后台运行，你就把它改成 yes。
# 当redis作为守护进程运行的时候，它会写一个 pid 到 /var/run/redis.pid 文件里面。
daemonize yes
#可以通过upstart和systemd管理Redis守护进程，这个参数是和具体的操作系统相关的。
supervised no
#当redis以守护模式启动时指定pid
pidfile /var/run/redis_${redis_port}.pid
#loglevel日志级别
#debug-->记录大量日志信息，适用于开发、测试阶段
#verbose-->较多日志信息
#notice-->适量日志信息，使用于生产环境
#warning-->仅有部分重要、关键信息才会被记录
loglevel notice
#日志文件的位置 
logfile "/data/wwwroot/log/redis_${redis_port}.log"
#设置数据库的数目
databases 16
#保存数据到磁盘。格式是：save <seconds> <changes> ，含义是在 seconds 秒之后至少有 changes个keys 发生改变则保存一次。
#默认设置意思是：在60 秒之内有10000 个keys 发生变化时、在300 秒之内有10 个keys 发生了变化、在900 秒之内有1 个keys 发生了变化，则镜像备份。
save 900 1
save 300 10
save 60 10000
#默认情况下，如果 redis 最后一次的后台保存失败，redis 将停止接受写操作，这样以一种强硬的方式让用户知道数据不能正确的持久化到磁盘， 否则就会没人注意到灾难的发生。 如果后台保存进程重新启动工作了，redis 也将自动的允许写操作。然而你要是安装了靠谱的监控，你可能不希望 redis 这样做，那你就改成 no 好了。
stop-writes-on-bgsave-error yes
#是否在dump  .rdb数据库的时候压缩字符串，默认设置为yes。如果你想节约一些cpu资源的话，可以把它设置为no，这样的话数据集就可能会比较大。
rdbcompression yes
#是否CRC64校验rdb文件，会有一定的性能损失（大概10%）。
rdbchecksum yes
#rdb文件
dbfilename dump.rdb
#数据库存放目录。必须是一个目录，aof文件也会保存到该目录下。
dir ${redis_dir}
#设置本机为slave服务。格式：slaveof <masterip> <masterport>。设置master服务的IP地址及端口，在Redis启动时，它会自动从master进行数据同步
# slaveof  192.168.1.3  6379
# slaveof <masterip> <masterport>
#当master服务设置了密码保护时，slave服务连接master的密码。
#masterauth
#当一个slave与master失去联系时，或者复制正在进行的时候，slave应对请求的行为：1) 如果为 yes（默认值） ，slave 仍然会应答客户端请求，但返回的数据可能是过时，或者数据可能是空的在第一次同步的时候；2) 如果为 no ，在你执行除了 info 和 salveof 之外的其他命令时，slave 都将返回一个 "SYNC with master in progress" 的错误。
slave-serve-stale-data yes
#设置slave是否是只读的。从2.6版起，slave默认是只读的。
slave-read-only yes
#主从数据复制是否使用无硬盘复制功能。
repl-diskless-sync no
repl-diskless-sync-delay 5
#指定向slave同步数据时，是否禁用socket的NO_DELAY选 项。若配置为“yes”，则禁用NO_DELAY，则TCP协议栈会合并小包统一发送，这样可以减少主从节点间的包数量并节省带宽，但会增加数据同步到 slave的时间。若配置为“no”，表明启用NO_DELAY，则TCP协议栈不会延迟小包的发送时机，这样数据同步的延时会减少，但需要更大的带宽。 通常情况下，应该配置为no以降低同步延时，但在主从节点间网络负载已经很高的情况下，可以配置为yes。
repl-disable-tcp-nodelay yes
#当 master 不能正常工作的时候，Redis Sentinel 会从 slaves 中选出一个新的 master，这个值越小，就越会被优先选中，但是如果是 0 ， 那是意味着这个 slave 不可能被选中。 默认优先级为 100。
slave-priority 100
#设置redis连接密码。
requirepass ${redis_passwd}
#是否启用aof持久化方式 。即是否在每次更新操作后进行日志记录，默认配置是no，即在采用异步方式把数据写入到磁盘，如果不开启，可能会在断电时导致部分数据丢失。
appendonly no
#更新日志文件名，默认值为appendonly.aof 。
appendfilename "appendonly.aof"
#aof文件刷新的频率。有三种：
#no 依靠OS进行刷新，redis不主动刷新AOF，这样最快，但安全性就差。
#always 每提交一个修改命令都调用fsync刷新到AOF文件，非常非常慢，但也非常安全。
#everysec 每秒钟都调用fsync刷新到AOF文件，很快，但可能会丢失一秒以内的数据。
appendfsync everysec
#指定是否在后台aof文件rewrite期间调用fsync，默认为no，表示要调用fsync（无论后台是否有子进程在刷盘）。Redis在后台写RDB文件或重写AOF文件期间会存在大量磁盘IO，此时，在某些linux系统中，调用fsync可能会阻塞。
no-appendfsync-on-rewrite no
#当AOF文件增长到一定大小的时候Redis能够调用 BGREWRITEAOF 对日志文件进行重写 。当AOF文件大小的增长率大于该配置项时自动开启重写。
auto-aof-rewrite-percentage 100
#当AOF文件增长到一定大小的时候Redis能够调用 BGREWRITEAOF 对日志文件进行重写 。当AOF文件大小大于该配置项时自动开启重写。
auto-aof-rewrite-min-size 64mb
#redis在启动时可以加载被截断的AOF文件，而不需要先执行 redis-check-aof 工具。
aof-load-truncated yes
#一个Lua脚本最长的执行时间，单位为毫秒，如果为0或负数表示无限执行时间，默认为5000。
lua-time-limit 5000
#设定执行时间，单位是毫秒，执行时长超过该时间的命令将会被记入log。-1表示不记录slow log; 0强制记录所有命令
slowlog-log-slower-than 10000
#slow log的长度。最小值为0。如果日志队列已超出最大长度，则最早的记录会被从队列中清除。 
slowlog-max-len 128
#服务端内部的延迟监控,设置一个合理的阈值，如设置100ms
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
#最大内存设置，默认为0,表示"无限制",推荐为物理内存的3/4,此配置需要和"maxmemory-policy"配合使用,当redis中内存数据达到maxmemory时,触发"清除策略"
maxmemory 512m
#内存不足"时,数据清除策略,默认为"volatile-lru"。
maxmemory-policy volatile-lru
#限制同时连接的客户端数量，不易过大具体多少根据具体情况而定
maxclients 30000
EOFI
# 输出无注释的配置文件内容，方便查看
#awk '! /^(#|$)/' ${redis_conf}${redis_port}.conf
###############3.启动redis、开机自启动
/etc/init.d/redis_${redis_port} start
echo "/etc/init.d/redis_${redis_port} start" >> /etc/rc.d/rc.local
###############4.防火墙开启端口
#允许端口
iptables -I INPUT 4 -p tcp -m state --state NEW -m tcp --dport ${redis_port} -j ACCEPT
/etc/init.d/iptables save 
/etc/init.d/iptables restart


######################################
#新增端口: 63921
#cp /data/conf/63920.conf /data/conf/63921.conf 
#vi /data/conf/63921.conf 
#修改以下： 
#port 63921
#pidfile /var/run/redis_63921.pid
#logfile "/data/wwwroot/log/redis_63921.log"
#dir /data/redis/63921
#mkdir /data/redis/63921

#cp -a /etc/init.d/redis_63920 /etc/init.d/redis_63921
#vi /etc/init.d/redis_63921
#修改端口： REDISPORT=63921
#启动：
#/etc/init.d/redis_63921 start

