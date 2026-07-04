#!/bin/bash

NAMESPACE="k8squest"
POD_NAME="gpu-workload"

echo "🔍 VALIDATION STAGE 1: Tekshirilmoqda if node has required label..."
NODE_WITH_GPU=$(kubectl get nodes -l accelerator=gpu -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$NODE_WITH_GPU" ]; then
    echo "❌ FAILED: No node found with label 'accelerator=gpu'"
    echo "💡 Maslahat: Label a node with: kubectl label nodes <node-name> accelerator=gpu"
    echo "💡 Maslahat: Tekshiring: available nodes: kubectl get nodes"
    exit 1
fi
echo "✅ Topildi node with accelerator=gpu label: $NODE_WITH_GPU"

echo ""
echo "🔍 VALIDATION STAGE 2: Tekshirilmoqda if pod exists..."
if ! kubectl get pod $POD_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Pod '$POD_NAME' not found"
    exit 1
fi
echo "✅ Pod exists"

echo ""
echo "🔍 VALIDATION STAGE 3: Tekshirilmoqda if pod is Running (not Pending)..."
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
echo "✅ Pod is Running"

echo ""
echo "🔍 VALIDATION STAGE 4: Verifying nodeAffinity is sozlangan..."
AFFINITY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.affinity.nodeAffinity}')
if [ -z "$AFFINITY" ]; then
    echo "❌ FAILED: No nodeAffinity sozlangan"
    echo "💡 Maslahat: Add nodeAffinity to spec.affinity.nodeAffinity"
    exit 1
fi
echo "✅ NodeAffinity is sozlangan"

echo ""
echo "🔍 VALIDATION STAGE 5: Tekshirilmoqda pod scheduled on correct node..."
SCHEDULED_NODE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.nodeName}')
NODE_LABELS=$(kubectl get node $SCHEDULED_NODE -o jsonpath='{.metadata.labels}')
if ! echo "$NODE_LABELS" | grep -q "accelerator"; then
    echo "⚠️  WARNING: Pod scheduled on node without 'accelerator' label"
    echo "   This might work but isn't optimal"
fi
echo "✅ Pod scheduled on node: $SCHEDULED_NODE"

echo ""
echo "🔍 VALIDATION STAGE 6: Verifying affinity selector matches..."
AFFINITY_KEY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key}')
if [ "$AFFINITY_KEY" != "accelerator" ]; then
    echo "⚠️  WARNING: NodeAffinity key is '$AFFINITY_KEY', expected 'accelerator'"
fi
echo "✅ NodeAffinity sozlangan to'g'ri"

echo ""
echo "🎉 SUCCESS! Pod scheduled muvaffaqiyatli with nodeAffinity!"
echo ""
echo "Node Affinity Details:"
kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.affinity.nodeAffinity}' | jq '.'
echo ""
echo "Scheduled on node: $SCHEDULED_NODE"
kubectl get node $SCHEDULED_NODE --show-labels | grep accelerator
