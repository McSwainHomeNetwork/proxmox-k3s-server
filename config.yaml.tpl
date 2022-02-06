ssh_authorized_keys:
- "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTBimUrhsOwZ91XQARNAuUwU0IzN2JRXPU+eUbBBNfnYCG1hS6CvEnqGUipTk+5zS4yNJDaf+Co4es7F3dAKqF4EYgICkwEgMV8EkPc0H9F8MXN4yaW4hfNne2dzHHx3vnHmqGuZnN157A9XKpJbf2elMgrRYNNVZ2Ko7vNrcyOURmkyNFZ8MiR6ZnVXn6jiUY6/QxiXjj0f6AlY4j/uM1rCJrb4xi3alGFAkWBK2KUkMGpJvi3gGHaxFw2PpkRcAXmKZNDg6K75dOyCdxCAPL3ehYUfwVDIjOEPA1p+GfW6nh8TZe4uJhuizz6Vddw9GwQJJP3kz1AHEaK131LIrPjGnLcVxrJNNDtSW1wtzNs7SWJAyDj3q1CSO9qH72CfrspAeFv03DtyLYNbjd/UhA91awMzEmA2NcmFm2lPaM07hhnJHn+TRVhPus4xzNKgvtAKjpWBzJoJIp1Bdfn1j0vPdiaa8EV6qcQ8gnWxsgdWvWXa93uryb1doItbqrPQnykgsi/+Xl+FETWCDkvl6+KKXsu9uFd08c9IPShBEmmveryr1dCBQXsWWxggvKfU529hfAQyKsH8FIhB5GsWxIYg6s/fwDy2OjGiD0IQ47hDDZfLMgCaFfzz3pOIuZi6nfgLh9kLB0wastCl8KHStIm3lAQLv+f7F61vXSMUdd0Q== reddragon@upstairs-pc"
- "github:USA-RedDragon"

write_files:
- path: /etc/conf.d/qemu-guest-agent
  content: |-
    # Specifies the transport method used to communicate to QEMU on the host side
    # Default: virtio-serial
    #GA_METHOD="virtio-serial"
    # Specifies the device path for the communications back to QEMU on the host
    # Default: /dev/virtio-ports/org.qemu.guest_agent.0
    GA_PATH="/dev/vport1p1"
  owner: root
  permissions: '0644'

hostname: k8s-${server_name}

k3os:
  modules:
  - wireguard
  dns_nameservers:
  - ${dns_server}
  password: "${node_password}"
  token: "${token}"

  k3s_args:
  - server
  - "--cluster-init"
  - "--etcd-expose-metrics"
  - "--datastore-endpoint"
  - "etcd"
  - "--etcd-snapshot-retention"
  - "7"
  - "--etcd-snapshot-schedule-cron"
  - "*/60 * * * *"
  - "--etcd-s3-endpoint"
  - "${s3_endpoint}"
  - "--etcd-s3-skip-ssl-verify"
  - "--etcd-s3-access-key"
  - "${s3_access_key}"
  - "--etcd-s3-secret-key"
  - "${s3_secret_key}"
  - "--etcd-s3-bucket"
  - "${s3_bucket}"
  - "--etcd-s3-folder"
  - "${s3_folder}"
  - "--with-node-id"
  - "--selinux"
  - "--kube-apiserver-arg"
  - "allow-privileged"
  - "--kube-apiserver-arg"
  - "anonymous-auth"
  - "false"
  - "--kube-apiserver-arg"
  - "enable-admission-plugins"
  - "CertificateSubjectRestrictions,DefaultIngressClass,DefaultStorageClass,LimitRanger,MutatingAdmissionWebhook,NamespaceExists,NamespaceLifecycle,PersistentVolumeClaimResize,PodSecurityPolicy,ResourceQuota,ServiceAccount,StorageObjectInUseProtection"
  - "--kube-apiserver-arg"
  - "feature-gates"
  - "AllBeta=true"
  - "--kube-scheduler-arg"
  - "feature-gates"
  - "AllBeta=true"
  - "--disable-cloud-controller"
  - "--disable"
  - "servicelb,traefik,local-storage"
  - "--kubelet-arg"
  - "anonymous-auth"
  - "false"
  - "--kubelet-arg"
  - "feature-gates"
  - "AllBeta=true"
  - "--kube-proxy-arg"
  - "feature-gates"
  - "AllBeta=true"
  - "--secrets-encryption"
