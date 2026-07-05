# Level 14 Yechimi: HPA Scale Qila Olmaydi

## Muammo
The HorizontalPodAutoscaler (HPA) cannot scale because metrics-server is not installed in the cluster.

## Yechim

### 1-variant: kubectl orqali metrics-server o'rnatish
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# For kind/minikube, you may need to add --kubelet-insecure-tls flag:
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

### 2-variant: kind cluster lar uchun (tavsiya etiladi)
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

### 3-variant: Helm orqali
```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system
```

## Tekshirish

metrics-server tayyor bo'lishini kuting:
```bash
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=60s
```

Check if metrics are available:
```bash
kubectl top nodes
kubectl top pods -n k8squest
```

HPA holatini tekshiring:
```bash
kubectl get hpa web-backend-hpa -n k8squest
```

HPA endi CPU metrikalarini ko'rsatishi va scale qila olishi kerak!

## Kutilgan Natija
- metrics-server pods running in kube-system namespace
- `kubectl top` commands work
- HPA shows current/target CPU metrics
- HPA can scale the deployment based on load
