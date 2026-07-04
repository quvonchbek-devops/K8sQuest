#!/bin/bash

NAMESPACE="k8squest"

echo "🔍 VALIDATION STAGE 1: Tekshirilmoqda PriorityClasses exist..."
if ! kubectl get priorityclass high-priority &>/dev/null; then
    echo "❌ FAILED: PriorityClass 'high-priority' not found"
    exit 1
fi
echo "✅ PriorityClasses exist"

echo ""
echo "🔍 VALIDATION STAGE 2: Tekshirilmoqda critical pod..."
if ! kubectl get pod critical-api -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Pod 'critical-api' not found"
    exit 1
fi
echo "✅ Critical pod exists"

echo ""
echo "🔍 VALIDATION STAGE 3: Verifying priority assignment..."
PRIORITY_CLASS=$(kubectl get pod critical-api -n $NAMESPACE -o jsonpath='{.spec.priorityClassName}')
if [ "$PRIORITY_CLASS" != "high-priority" ]; then
    echo "❌ FAILED: Critical pod doesn't have high-priority class"
    exit 1
fi
echo "✅ Priority assigned to'g'ri"

echo ""
echo "🔍 VALIDATION STAGE 4: Tekshirilmoqda pod holati..."
POD_STATUS=$(kubectl get pod critical-api -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" = "Pending" ]; then
    echo "⚠️  Pod still Pending (may need more time or resources)"
else
    echo "✅ Pod is $POD_STATUS"
fi

echo ""
echo "🎉 SUCCESS! PriorityClass sozlangan!"
kubectl get priorityclass
