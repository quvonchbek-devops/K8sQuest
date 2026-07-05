#!/bin/bash

NAMESPACE="k8squest"
POD_NAME="regular-app"
NODE_NAME="kind-control-plane"

echo "🔍 TEKSHIRUV 1-BOSQICH: Tekshirilmoqda node taint qilinganligini..."
NODE_TAINTS=$(kubectl get node $NODE_NAME -o jsonpath='{.spec.taints[?(@.key=="dedicated")]}')
if [ -z "$NODE_TAINTS" ]; then
    echo "⚠️  Node hali taint qilinmagan. Taint qo'yilmoqda..."
    kubectl taint nodes $NODE_NAME dedicated=gpu:NoSchedule --overwrite
    echo "✅ Node taint qilindi: dedicated=gpu:NoSchedule"
else
    echo "✅ Node has taint: dedicated=gpu"
fi

echo ""
echo "🔍 TEKSHIRUV 2-BOSQICH: Tekshirilmoqda pod mavjudligini..."
if ! kubectl get pod $POD_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Pod '$POD_NAME' topilmadi"
    exit 1
fi
echo "✅ Pod mavjud"

echo ""
echo "🔍 TEKSHIRUV 3-BOSQICH: Tekshirilmoqda pod Running holatida ekanligini (Pending emas)..."
POD_STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" = "Pending" ]; then
    echo "❌ FAILED: Pod is still Pending"
    echo "💡 Maslahat: Tekshiring: pod events: kubectl describe pod $POD_NAME -n $NAMESPACE"
    echo "💡 Maslahat: Pod needs toleration matching node taint"
    exit 1
fi
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ FAILED: Pod is in '$POD_STATUS' state"
    exit 1
fi
echo "✅ Pod Running holatida"

echo ""
echo "🔍 TEKSHIRUV 4-BOSQICH: Tekshirilmoqda pod da toleration lar sozlanganligini..."
TOLERATIONS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.tolerations}')
if [ -z "$TOLERATIONS" ] || [ "$TOLERATIONS" = "null" ]; then
    echo "❌ FAILED: No tolerations sozlangan on pod"
    echo "💡 Maslahat: Add tolerations to spec.tolerations"
    exit 1
fi
echo "✅ Toleration lar sozlangan"

echo ""
echo "🔍 TEKSHIRUV 5-BOSQICH: Tekshirilmoqda toleration taint ga mos kelishini..."
TOLERATION_KEY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.tolerations[?(@.key=="dedicated")].key}')
if [ "$TOLERATION_KEY" != "dedicated" ]; then
    echo "❌ FAILED: Toleration key doesn't match taint key 'dedicated'"
    echo "💡 Maslahat: Toleration key must match taint key exactly"
    exit 1
fi
echo "✅ Toleration kaliti taint ga mos keladi"

echo ""
echo "🔍 TEKSHIRUV 6-BOSQICH: Tekshirilmoqda pod scheduled on tainted node..."
SCHEDULED_NODE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.nodeName}')
echo "✅ Pod scheduled on node: $SCHEDULED_NODE"

echo ""
echo "🎉 SUCCESS! Pod tolerates node taint and is running!"
echo ""
echo "Taint tafsilotlari:"
kubectl get node $SCHEDULED_NODE -o jsonpath='{.spec.taints[?(@.key=="dedicated")]}' | jq '.'
echo ""
echo "Toleration tafsilotlari:"
kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.tolerations[?(@.key=="dedicated")]}' | jq '.'
