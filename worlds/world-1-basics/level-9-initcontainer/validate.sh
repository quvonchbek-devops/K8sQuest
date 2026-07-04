#!/bin/bash

echo "🔍 Pod va init container holati tekshirilmoqda..."

POD_STATUS=$(kubectl get pod web-with-init -n k8squest -o jsonpath='{.status.phase}' 2>/dev/null)
READY=$(kubectl get pod web-with-init -n k8squest -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
INIT_STATUS=$(kubectl get pod web-with-init -n k8squest -o jsonpath='{.status.initContainerStatuses[0].state}' 2>/dev/null)

echo "   Pod Phase: $POD_STATUS"
echo "   Ready: $READY"

if [[ "$POD_STATUS" == "Running" ]] && [[ "$READY" == "true" ]]; then
    echo "✅ Pod muvaffaqiyatli initsializatsiya qilindi va ishlayapti"
    exit 0
else
    echo "❌ Pod holati: $POD_STATUS (Tayyor: $READY)"
    echo "💡 Maslahat: Init container loglarini tekshiring:"
    echo "   kubectl logs web-with-init -n k8squest -c wait-for-service"
    echo "   kubectl describe pod web-with-init -n k8squest"
    exit 1
fi
