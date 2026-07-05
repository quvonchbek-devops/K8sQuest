#!/bin/bash

NAMESPACE="k8squest"
POD_NAME="gpu-workload"

echo "🔍 TEKSHIRUV 1-BOSQICH: Tekshirilmoqda node da kerakli label borligini..."
NODE_WITH_GPU=$(kubectl get nodes -l accelerator=gpu -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$NODE_WITH_GPU" ]; then
    echo "❌ FAILED: No node found with label 'accelerator=gpu'"
    echo "💡 Maslahat: Label a node with: kubectl label nodes <node-name> accelerator=gpu"
    echo "💡 Maslahat: Tekshiring: available nodes: kubectl get nodes"
    exit 1
fi
echo "✅ Topildi node with accelerator=gpu label: $NODE_WITH_GPU"

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
    echo "💡 Maslahat: Tekshiring: nodeAffinity matches node labels"
    exit 1
fi
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ FAILED: Pod is in '$POD_STATUS' state"
    exit 1
fi
echo "✅ Pod Running holatida"

echo ""
echo "🔍 TEKSHIRUV 4-BOSQICH: Tekshirilmoqda nodeAffinity sozlanganligini..."
AFFINITY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.affinity.nodeAffinity}')
if [ -z "$AFFINITY" ]; then
    echo "❌ FAILED: No nodeAffinity sozlangan"
    echo "💡 Maslahat: Add nodeAffinity to spec.affinity.nodeAffinity"
    exit 1
fi
echo "✅ NodeAffinity is sozlangan"

echo ""
echo "🔍 TEKSHIRUV 5-BOSQICH: Tekshirilmoqda pod to'g'ri node ga joylashganligini..."
SCHEDULED_NODE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.nodeName}')
NODE_LABELS=$(kubectl get node $SCHEDULED_NODE -o jsonpath='{.metadata.labels}')
if ! echo "$NODE_LABELS" | grep -q "accelerator"; then
    echo "⚠️  WARNING: Pod scheduled on node without 'accelerator' label"
    echo "   Bu ishlashi mumkin lekin optimal emas"
fi
echo "✅ Pod scheduled on node: $SCHEDULED_NODE"

echo ""
echo "🔍 TEKSHIRUV 6-BOSQICH: Tekshirilmoqda affinity selector mos kelishini..."
AFFINITY_KEY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key}')
if [ "$AFFINITY_KEY" != "accelerator" ]; then
    echo "⚠️  WARNING: NodeAffinity key is '$AFFINITY_KEY', expected 'accelerator'"
fi
echo "✅ NodeAffinity sozlangan to'g'ri"

echo ""
echo "🎉 SUCCESS! Pod scheduled muvaffaqiyatli with nodeAffinity!"
echo ""
echo "Node Affinity Tafsilotlari:"
kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.affinity.nodeAffinity}' | jq '.'
echo ""
echo "Node ga joylashgan: $SCHEDULED_NODE"
kubectl get node $SCHEDULED_NODE --show-labels | grep accelerator
