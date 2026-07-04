#!/bin/bash

echo "🔍 Pod holati tekshirilmoqda..."

POD_STATUS=$(kubectl get pod hungry-app -n k8squest -o jsonpath='{.status.phase}' 2>/dev/null)
READY=$(kubectl get pod hungry-app -n k8squest -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)

echo "   Phase: $POD_STATUS"
echo "   Ready: $READY"

if [[ "$POD_STATUS" == "Running" ]] && [[ "$READY" == "true" ]]; then
    echo "✅ Pod muvaffaqiyatli schedule qilindi va ishlayapti"
    exit 0
else
    echo "❌ Pod to'g'ri ishlamayapti"
    echo "💡 Maslahat: Scheduling muammolarini ko'rish uchun 'kubectl describe pod hungry-app -n k8squest' ishlating"
    exit 1
fi
