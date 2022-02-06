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
  - "--kube-apiserver-arg"
  - "allow-privileged"
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
  - "--disable-cloud-controller"
  - "--disable=servicelb,traefik,local-storage"
  - "--kubelet-arg"
  - "anonymous-auth=false"
  - "--kubelet-arg"
  - "feature-gates=AllBeta=true"
  - "--kube-proxy-arg"
  - "feature-gates=AllBeta=true"
  - "--secrets-encryption"
