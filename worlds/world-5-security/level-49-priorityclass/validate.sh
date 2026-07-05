#!/bin/bash

NAMESPACE="k8squest"

echo "🔍 TEKSHIRUV 1-BOSQICH: Tekshirilmoqda PriorityClass lar mavjudligini..."
if ! kubectl get priorityclass high-priority &>/dev/null; then
    echo "❌ FAILED: PriorityClass 'high-priority' topilmadi"
    exit 1
fi
echo "✅ PriorityClass lar mavjudligini"

echo ""
echo "🔍 TEKSHIRUV 2-BOSQICH: Tekshirilmoqda muhim pod..."
if ! kubectl get pod critical-api -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Pod 'critical-api' topilmadi"
    exit 1
fi
echo "✅ Critical pod mavjud"

echo ""
echo "🔍 TEKSHIRUV 3-BOSQICH: Tekshirilmoqda priority tayinlanganligini..."
PRIORITY_CLASS=$(kubectl get pod critical-api -n $NAMESPACE -o jsonpath='{.spec.priorityClassName}')
if [ "$PRIORITY_CLASS" != "high-priority" ]; then
    echo "❌ FAILED: Critical pod doesn't have high-priority class"
    exit 1
fi
echo "✅ Priority assigned to'g'ri"

echo ""
echo "🔍 TEKSHIRUV 4-BOSQICH: Tekshirilmoqda pod holatini..."
POD_STATUS=$(kubectl get pod critical-api -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" = "Pending" ]; then
    echo "⚠️  Pod hali Pending holatida (may need more time or resources)"
else
    echo "✅ Pod is $POD_STATUS"
fi

echo ""
echo "🎉 SUCCESS! PriorityClass sozlangan!"
kubectl get priorityclass
