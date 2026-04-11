# Kubernetes Bare-Metal Build Plan

Full step-by-step plan to build a working K8s cluster from scratch on Multipass VMs.

---

## Phase 1: OS Preparation (cloud-init)

All nodes need identical OS-level prep before K8s can run.

### 1.1 Kernel Modules
- Load `overlay` and `br_netfilter` modules
- Why: K8s networking (pod-to-pod, service routing) relies on Linux bridge and overlay networking. Without these, kube-proxy and CNI plugins can't function.

### 1.2 Sysctl Network Parameters
- Enable `net.bridge.bridge-nf-call-iptables`
- Enable `net.bridge.bridge-nf-call-ip6tables`
- Enable `net.ipv4.ip_forward`
- Why: Bridged traffic must pass through iptables for K8s service networking. IP forwarding allows packets to route between pods on different nodes.

### 1.3 Disable Swap
- Turn off swap and remove from fstab
- Why: kubelet refuses to start if swap is on. K8s manages memory itself and swap breaks resource guarantees.

### 1.4 Install containerd
- Install containerd package
- Configure it to use systemd cgroup driver
- Why: K8s needs a container runtime (CRI). containerd is the standard. Systemd cgroup driver must match kubelet's cgroup driver — mismatch causes node instability.

### 1.5 Install kubeadm, kubelet, kubectl
- Add Kubernetes apt repository (v1.30)
- Install and hold versions
- Enable kubelet service
- Why: kubeadm bootstraps the cluster, kubelet is the node agent, kubectl is the CLI. Version hold prevents accidental upgrades that break the cluster.

---

## Phase 2: Ansible Setup

### 2.1 Inventory
- Create inventory file with cp1, worker1, worker2
- Map Multipass VM IPs to hostnames
- Define groups: `[control_plane]` and `[workers]`

### 2.2 Ansible Connection
- Configure Ansible to connect via Multipass SSH keys
- Test connectivity with `ansible all -m ping`

---

## Phase 2.5: HA Load Balancer (keepalived + HAProxy)

Must run **before** kubeadm init so the VIP is available as the control plane endpoint.

### 2.5.1 Install keepalived + HAProxy on all CP nodes
- Run `setup-ha-lb.yaml` playbook
- Why: keepalived provides a floating VIP via VRRP. HAProxy load-balances API server traffic. Together they ensure the control plane endpoint survives node failure.

### 2.5.2 keepalived (VIP management)
- All CP nodes run keepalived in BACKUP state with priority-based election (cp1=101, cp2=100, cp3=99)
- VIP `192.168.2.100` floats to the highest-priority healthy node
- Health check script monitors local API server — drops priority on failure to trigger failover
- Why: VRRP gives you a single stable IP for the cluster endpoint. No DNS changes needed on failure.

### 2.5.3 HAProxy (API server load balancing)
- Listens on `*:8443` (TCP mode, no TLS termination)
- Backends: all CP nodes on port 6443
- Health checks every 3s remove downed API servers from the pool
- Why: Even though the VIP lands on one node, HAProxy distributes load across all healthy API servers.

### 2.5.4 Verify
- VIP responds to ping from any node
- `curl -sk https://192.168.2.100:8443/healthz` returns `ok` (after kubeadm init)
- HAProxy stats at `http://<cp-node>:9000/stats`

---

## Phase 3: Control Plane Bootstrap (Ansible Playbook)

### 3.1 kubeadm init
- Run `kubeadm init` on cp1 with:
  - `--pod-network-cidr=192.168.0.0/16` (Calico default)
  - `--apiserver-advertise-address` (cp1's IP)
  - `--control-plane-endpoint=192.168.2.100:8443` (VIP + HAProxy port)
- Why: This creates the entire control plane — etcd, kube-apiserver, kube-scheduler, kube-controller-manager as static pods.

### 3.2 kubeconfig Setup
- Copy admin kubeconfig to ubuntu user's home
- Why: kubectl needs a kubeconfig to authenticate with the API server.

### 3.3 Save Join Command
- Extract `kubeadm join` command with token
- Store it for worker nodes
- Why: Workers need the token + CA cert hash to securely join the cluster.

---

## Phase 4: CNI Plugin

### 4.1 Choose and Install CNI
- Options: Calico, Flannel, Cilium
  - **Flannel** — simplest, VXLAN overlay, good for learning
  - **Calico** — more features (network policy, BGP), production-grade
  - **Cilium** — eBPF-based, most advanced, steeper learning curve
- Apply CNI manifest to the cluster
- Why: Without a CNI plugin, pods stay in `Pending` state. CNI handles pod IP assignment and cross-node pod networking.

---

## Phase 5: Worker Nodes Join (Ansible Playbook)

### 5.1 kubeadm join
- Run the saved join command on worker1 and worker2
- Why: Registers the node with the API server, starts kubelet, and makes the node schedulable.

### 5.2 Verify Cluster
- `kubectl get nodes` — all 3 should be `Ready`
- `kubectl get pods -A` — all system pods running

---

## Phase 6: Validation

### 6.1 Deploy Test Workload
- Create a simple nginx deployment
- Expose via NodePort service
- Verify pod scheduling across workers
- Curl the service from host machine

### 6.2 Test Pod Networking
- Deploy two pods on different nodes
- Verify they can ping each other
- Why: Confirms CNI is working correctly across nodes.

### 6.3 Test DNS
- Verify CoreDNS is resolving service names
- `kubectl run` a busybox pod and `nslookup kubernetes`
- Why: Confirms cluster DNS works — critical for service discovery.

---

## Phase 7: Optional Extras

- [ ] Deploy metrics-server
- [ ] Set up Ingress controller (nginx-ingress)
- [ ] Try NetworkPolicy with Calico
- [ ] Dashboard UI
- [ ] RBAC — create restricted user/namespace
- [ ] Persistent storage with local-path-provisioner
