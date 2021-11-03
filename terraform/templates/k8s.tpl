[haproxy]
${k8s_haproxy_ip}

[master]
${k8s_master_ip}

[node]
${k8s_node_ip}

[k8s_cluster:children]
master
node