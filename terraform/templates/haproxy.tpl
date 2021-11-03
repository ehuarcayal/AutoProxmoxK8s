
frontend kubernetes
bind ${k8s_haproxy_ip_bind}:6443
option tcplog
mode tcp
default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
mode tcp
balance roundrobin
option tcp-check
${k8s_master_ip_bind}

listen stats 
    bind ${k8s_haproxy_ip_bind}:8080
    mode http
    stats enable
    stats uri /
    stats realm HAProxy\ Statistics
    stats auth admin:haproxy