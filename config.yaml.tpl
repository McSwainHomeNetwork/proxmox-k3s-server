%{if length(ssh_keys) > 0 }
ssh_authorized_keys:
%{for line in ssh_keys}
- ${line}
%{endfor}
%{endif}

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
- path: /etc/sysctl.d/90-kubelet.conf
  content: |-
    vm.panic_on_oom=0
    vm.overcommit_memory=1
    kernel.panic=10
    kernel.panic_on_oops=1
  owner: root
  permissions: '0644'
- path: /etc/k3s-encryption-provider.yaml
  content: |-
    apiVersion: apiserver.config.k8s.io/v1
    kind: EncryptionConfiguration
    resources:
      - resources:
        - secrets
        providers:
        - aescbc:
            keys:
            - name: key
              secret: ${aescbc_encryption_key_b64}
        - identity: {}
  owner: root
  permissions: '0644'
- path: /var/lib/rancher/k3s/server/tls/client-ca.crt
  content: |-
    ${indent(4, client_ca_cert_pem)}
  owner: root
  permissions: '0644'
- path: /var/lib/rancher/k3s/server/tls/client-ca.key
  content: |-
    ${indent(4, client_ca_private_key_pem)}
  owner: root
  permissions: '0600'

hostname: k8s-${server_name}

k3os:
  modules:
  - wireguard
  %{if length(dns_servers) > 0 }
  dns_nameservers:
  %{for line in dns_servers}
  - ${line}
  %{endfor}
  %{endif}
  password: "${node_password}"
  token: "${token}"

  k3s_args:
  - server
  - "--cluster-init"
  - "--with-node-id"
  - "--selinux"
  - "--protect-kernel-defaults"
  - "--datastore-endpoint"
  - "${datastore_endpoint}"
  - "--kube-apiserver-arg"
  - "audit-log-path=/var/log/k3s-audit"
  - "--kube-apiserver-arg"
  - "audit-log-maxage=30"
  - "--kube-apiserver-arg"
  - "audit-log-maxbackup=10"
  - "--kube-apiserver-arg"
  - "audit-log-maxsize=100"
  - "--kube-apiserver-arg"
  - "request-timeout=60s"
  - "--kube-controller-manager-arg"
  - "terminated-pod-gc-threshold=10"
  - "--kube-apiserver-arg"
  - "insecure-port=0"
  - "--kube-apiserver-arg"
  - "profiling=false"
  - "--kube-apiserver-arg"
  - "service-account-issuer=k3s"
  - "--kube-apiserver-arg"
  - "service-account-key-file=/var/lib/rancher/k3s/server/tls/service.key"
  - "--kube-apiserver-arg"
  - "service-account-signing-key-file=/var/lib/rancher/k3s/server/tls/service.key"
  - "--kube-apiserver-arg"
  - "authorization-mode=Node,RBAC"
  - "--kube-apiserver-arg"
  - "requestheader-allowed-names=system:auth-proxy"
  - "--kube-apiserver-arg"
  - "requestheader-client-ca-file=/var/lib/rancher/k3s/server/tls/request-header-ca.crt"
  - "--kube-apiserver-arg"
  - "requestheader-extra-headers-prefix=X-Remote-Extra-"
  - "--kube-apiserver-arg"
  - "requestheader-group-headers=X-Remote-Group"
  - "--kube-apiserver-arg"
  - "requestheader-username-headers=X-Remote-User"
  - "--kube-apiserver-arg"
  - "encryption-provider-config=/etc/k3s-encryption-provider.yaml"
  - "--kube-apiserver-arg"
  - "service-account-lookup"
  - "--kube-apiserver-arg"
  - "anonymous-auth=false"
  - "--kube-apiserver-arg"
  - "enable-admission-plugins=DefaultIngressClass,DefaultStorageClass,LimitRanger,MutatingAdmissionWebhook,NamespaceExists,NamespaceLifecycle,NodeRestriction,PersistentVolumeClaimResize,PodSecurityPolicy,ResourceQuota,ServiceAccount,StorageObjectInUseProtection"
  - "--kube-apiserver-arg"
  - "feature-gates=AllBeta=true"
  - "--kube-scheduler-arg"
  - "feature-gates=AllBeta=true"
  - "--kube-scheduler-arg"
  - "address=127.0.0.1"
  - "--kube-scheduler-arg"
  - "bind-address=127.0.0.1"
  - "--kube-scheduler-arg"
  - "secure-port=0"
  - "--disable-cloud-controller"
  - "--disable=servicelb,traefik,local-storage"
  - "--kubelet-arg"
  - "anonymous-auth=false"
  - "--kubelet-arg"
  - "make-iptables-util-chains"
  - "--kubelet-arg"
  - "authentication-token-webhook=true"
  - "--kubelet-arg"
  - "authorization-mode=Webhook"
  - "--kubelet-arg"
  - "eviction-hard=imagefs.available<5%,nodefs.available<5%"
  - "--kubelet-arg"
  - "eviction-minimum-reclaim=imagefs.available=10%,nodefs.available=10%"
  - "--kubelet-arg"
  - "streaming-connection-idle-timeout=5m"
  - "--kubelet-arg"
  - "healthz-bind-address=127.0.0.1"
  - "--kubelet-arg"
  - "protect-kernel-defaults=true"
  - "--kubelet-arg"
  - "read-only-port=0"
  - "--kubelet-arg"
  - "feature-gates=AllBeta=true"
  - "--kube-proxy-arg"
  - "feature-gates=AllBeta=true"
  - "--kube-controller-manager-arg"
  - "bind-address=127.0.0.1"
  - "--kube-controller-manager-arg"
  - "address=127.0.0.1"
  - "--kube-controller-manager-arg"
  - "allocate-node-cidrs=true"
  - "--kube-controller-manager-arg"
  - "profiling=false"
  - "--kube-controller-manager-arg"
  - "secure-port=0"
  - "--kube-controller-manager-arg"
  - "service-account-private-key-file=/var/lib/rancher/k3s/server/tls/service.key"
  - "--kube-controller-manager-arg"
  - "use-service-account-credentials=true"
  - "--tls-san"
  - "${k8s_hostname}"
