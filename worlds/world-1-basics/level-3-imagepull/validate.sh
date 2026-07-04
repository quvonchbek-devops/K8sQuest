#!/bin/bash

echo "🔍 Pod holati tekshirilmoqda..."

POD_STATUS=$(kubectl get pod web-app -n k8squest -o jsonpath='{.status.phase}' 2>/dev/null)
READY=$(kubectl get pod web-app -n k8squest -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)

echo "   Phase: $POD_STATUS"
echo "   Ready: $READY"

if [[ "$POD_STATUS" == "Running" ]] && [[ "$READY" == "true" ]]; then
    echo "✅ Pod to'g'ri image bilan ishlayapti"
    exit 0
else
    echo "❌ Pod to'g'ri ishlamayapti"
    echo "💡 Maslahat: ImagePullBackOff xatolarini ko'rish uchun 'kubectl describe pod web-app -n k8squest' ishlating"
    exit 1
fi
