#！/usr/bin/env python3
import requests,sys,json,os,redis,time
import urllib3
from requests.packages.urllib3.exceptions import InsecureRequestWarning
from requests.auth import HTTPBasicAuth
urllib3.disable_warnings()
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# API='api/v3/nodes/'
internal = 3

# emq url
emqx_url='http://xxx:8080/'
redis_host = 'localhost'
redis_port = 6379
pool = redis.ConnectionPool(host=redis_host, port=redis_port, db=0)
red = redis.Redis(connection_pool=pool)
# 发送请求函数
def send_api(request_url):
    Header = {
        "Content-Type": "application/json",
        "Charset": "UTF-8"
    }
    Auth = HTTPBasicAuth('lepai_zabbix', 'Mjg0NTYyNT9zNzgwNjMyNjU0NzY2NjQ2MjU2Mjk4ODg1MTC')
    r = requests.get(url=request_url,headers=Header,auth=Auth,verify=False)
    print(r.status_code)
    return r.status_code, r.json()['data']

# emqx集群基本信息查看
def emqx_cluster():
    api = 'api/v3/brokers/'
    return emqx_url + api

# emqx集群节点基本信息统计
def emqx_node_load(node):
    api = 'api/v3/nodes/'+ node
    return emqx_url + api

# emqx集群节点收发流量统计
def emq_node_package(node):
    api = 'api/v3/nodes/'+ node +'/metrics/'
    return emqx_url + api

# emqx集群节点连接会话统计
def emq_node_stats(node):
    api = 'api/v3/nodes/' + node + '/stats/'
    return emqx_url + api

# redis 数据插入
def redis_set(node, option, value):
    key = node + '-' + option
    red.set(key, value)

# 主函数
def main():
    # 首先检查当前集群的状态
    request_url = emqx_cluster()
    status_code, request_content = send_api(request_url)
    if status_code != 200:
        return
    for request in request_content:
        # 获取节点名称
        node = request['node']

        # emqx集群节点收发流量统计
        node_request_url = emq_node_package(node)
        node_status_code, node_request_content = send_api(node_request_url)
        # print(node_request_content)

        # emqx集群节点负载以及连接数信息统计
        node_load_request_url = emqx_node_load(node)
        node_load_status_code, node_load_request_content = send_api(node_load_request_url)
        # print(node_load_request_content)

        # emqx集群节点连接会话统计
        node_stats_request_url = emq_node_stats(node)
        node_stats_status_code, node_stats_request_content = send_api(node_stats_request_url)
        # print(node_stats_request_content)

        # 负载信息
        connections = node_load_request_content['connections']
        load1 = node_load_request_content['load1']
        load5 = node_load_request_content['load5']
        load15 = node_load_request_content['load15']
        memory_total = node_load_request_content['memory_total']
        memory_used = node_load_request_content['memory_used']
        process_available = node_load_request_content['process_available']
        process_used = node_load_request_content['process_used']

        # 收发流量统计
        bytes_sent = node_request_content['bytes.sent']
        bytes_received = node_request_content['bytes.received']
        messages_sent = node_request_content['messages.sent']
        messages_received = node_request_content['messages.received']
        messages_dropped = node_request_content['messages.dropped']
        messages_retained = node_request_content['messages.retained']
        messages_qos1_received = node_request_content['messages.qos1.received']
        messages_qos1_sent = node_request_content['messages.qos1.sent']
        messages_expired = node_request_content['messages.expired']
        messages_forward = node_request_content['messages.forward']
        packets_sent = node_request_content['packets.sent']
        packets_received = node_request_content['packets.received']
        try:
            if node_request_content['auth.mysql.success'] :
                pass
            auth_mysql_success = node_request_content['auth.mysql.success']
            auth_mysql_failure = node_request_content['auth.mysql.failure']
            redis_set(node, 'auth_mysql_success', auth_mysql_success)
            redis_set(node, 'auth_mysql_failure', auth_mysql_failure)
        except:
            auth_mysql_success = 0
            auth_mysql_failure = 0
            redis_set(node, 'auth_mysql_success', auth_mysql_success)
            redis_set(node, 'auth_mysql_failure', auth_mysql_failure)

        # 连接会话统计
        subscriptions_max = node_stats_request_content['subscriptions.max']
        subscriptions_count = node_stats_request_content['subscriptions.count']
        subscribers_max = node_stats_request_content['subscribers.max']
        subscribers_count = node_stats_request_content['subscribers.count']
        topics_max = node_stats_request_content['topics.max']
        topics_count = node_stats_request_content['topics.count']
        sessions_max = node_stats_request_content['sessions.max']
        sessions_count = node_stats_request_content['sessions.count']
        connections_max = node_stats_request_content['connections.max']
        connections_count = node_stats_request_content['connections.count']
        retained_max = node_stats_request_content['retained.max']
        retained_count = node_stats_request_content['retained.count']

        print('NODE: ',node)
        # 负载信息
        print('connections: ', connections)
        print('load1: ', load1)
        print('load5: ', load5)
        print('load15: ', load15)
        print('memory_total: ', memory_total)
        print('memory_used: ', memory_used)
        print('process_available: ', process_available)
        print('process_used: ', process_used)
        print('auth_mysql_success: ', auth_mysql_success)
        print('auth_mysql_failure: ', auth_mysql_failure)

        # 收发流量统计
        print('bytes_sent: ',bytes_sent)
        print('bytes_received: ',bytes_received)
        print('messages_sent: ',messages_sent)
        print('messages_received: ',messages_received)
        print('messages_dropped: ',messages_dropped)
        print('messages_retained: ',messages_retained)
        print('messages_qos1_sent: ',messages_qos1_sent)
        print('messages_qos1_received: ',messages_qos1_received)
        print('messages_expired: ',messages_expired)
        print('messages_forward: ',messages_forward)
        print('packets_sent: ',packets_sent)
        print('packets_received: ',packets_received)
        # 连接会话统计
        print('subscriptions_max: ',subscriptions_max)
        print('subscriptions_count: ',subscriptions_count)
        print('subscribers_max: ',subscribers_max)
        print('subscribers_count: ',subscribers_count)
        print('topics_max: ',topics_max)
        print('topics_count: ',topics_count)
        print('sessions_max: ',sessions_max)
        print('sessions_count: ',sessions_count)
        print('connections_max: ',connections_max)
        print('connections_count: ',connections_count)
        print('retained_max: ',retained_max)
        print('retained_count: ',retained_count)

        # redis 注入
        redis_set(node, 'connections', connections)
        redis_set(node, 'load1', load1)
        redis_set(node, 'load5', load5)
        redis_set(node, 'load15', load15)
        redis_set(node, 'memory_total', memory_total)
        redis_set(node, 'memory_used', memory_used)
        redis_set(node, 'process_available', process_available)
        redis_set(node, 'process_used', process_used)
        redis_set(node, 'bytes_sent', bytes_sent)
        redis_set(node, 'bytes_received', bytes_received)
        redis_set(node, 'messages_sent', messages_sent)
        redis_set(node, 'messages_received', messages_received)
        redis_set(node, 'messages_dropped', messages_dropped)
        redis_set(node, 'messages_retained', messages_retained)
        redis_set(node, 'messages_qos1_sent', messages_qos1_sent)
        redis_set(node, 'messages_qos1_received', messages_qos1_received)
        redis_set(node, 'messages_expired', messages_expired)
        redis_set(node, 'messages_forward', messages_forward)
        redis_set(node, 'packets_sent', packets_sent)
        redis_set(node, 'packets_received', packets_received)
        redis_set(node, 'subscriptions_max', subscriptions_max)
        redis_set(node, 'subscriptions_count', subscriptions_count)
        redis_set(node, 'subscribers_max', subscribers_max)
        redis_set(node, 'subscribers_count', subscribers_count)
        redis_set(node, 'topics_max', topics_max)
        redis_set(node, 'topics_count', topics_count)
        redis_set(node, 'sessions_max', sessions_max)
        redis_set(node, 'sessions_count', sessions_count)
        redis_set(node, 'connections_max', connections_max)
        redis_set(node, 'connections_count', connections_count)
        redis_set(node, 'retained_max', retained_max)
        redis_set(node, 'retained_count', retained_count)

while True:
    time.sleep(internal)
    try:
        main()
    except:
        continue
# main()