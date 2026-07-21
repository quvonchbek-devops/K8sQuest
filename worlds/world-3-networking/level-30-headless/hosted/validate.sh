#!/bin/bash
# HOSTED validate — exec/nslookup SIZ (sandbox pods/exec bermaydi, timeout 15s).
# Headless-lik isboti: clusterIP: None + StatefulSet pod lari Ready + endpoint soni.
# Dars o'zgarmaydi: fix baribir `clusterIP: None`. Asos: CHANGELOG (§3.2).
NS="k8squest"

echo "🔍 StatefulSet uchun Headless Service tekshirilmoqda..."

# 1) Service mavjudmi
if ! kubectl get service web-cluster -n "$NS" &>/dev/null; then
  echo "❌ Service 'web-cluster' topilmadi"
  echo "💡 Tuzatilgan konfiguratsiyani apply qiling: kubectl apply -f solution.yaml"
  exit 1
fi
echo "✅ Service mavjud"

# 2) Headless (clusterIP: None) — DARSNING O'ZI
CLUSTER_IP=$(kubectl get service web-cluster -n "$NS" -o jsonpath='{.spec.clusterIP}')
if [ "$CLUSTER_IP" != "None" ]; then
  echo "❌ Service headless emas: clusterIP=$CLUSTER_IP (kutilgan: None)"
  echo "💡 StatefulSet ga per-pod DNS uchun headless service kerak."
  echo "   spec.clusterIP: None  # ni qo'shing"
  exit 1
fi
echo "✅ Service headless (clusterIP: None)"

# 3) StatefulSet mavjudmi
if ! kubectl get statefulset web -n "$NS" &>/dev/null; then
  echo "❌ StatefulSet 'web' topilmadi"
  exit 1
fi
REPLICAS=$(kubectl get statefulset web -n "$NS" -o jsonpath='{.spec.replicas}')
echo "✅ StatefulSet mavjud (replicas: $REPLICAS)"

# 4) Pod lar Ready (qisqa kutish — 15s timeout ichida)
for i in $(seq 1 6); do
  READY=$(kubectl get pods -n "$NS" -l app=web-cluster \
    -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' \
    2>/dev/null | grep -c "True")
  [ "$READY" = "$REPLICAS" ] && break
  sleep 1
done
if [ "$READY" != "$REPLICAS" ]; then
  echo "❌ Pod lar tayyor emas ($READY/$REPLICAS Ready)"
  echo "💡 kubectl get pods -n $NS -l app=web-cluster"
  exit 1
fi
echo "✅ Barcha $REPLICAS pod Ready"

# 5) Endpoint soni pod soniga teng (headless service pod IP larini oshkor qiladi)
EP=$(kubectl get endpoints web-cluster -n "$NS" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w)
if [ "$EP" != "$REPLICAS" ]; then
  echo "❌ Endpoint soni mos emas ($EP, kutilgan $REPLICAS)"
  exit 1
fi
echo "✅ Service $EP endpoint ni oshkor qilyapti (pod soniga teng)"

echo ""
echo "🎉 Headless service to'g'ri! Har pod barqaror DNS oldi:"
for i in $(seq 0 $((REPLICAS - 1))); do
  echo "   • web-$i.web-cluster.$NS.svc.cluster.local"
done
exit 0
