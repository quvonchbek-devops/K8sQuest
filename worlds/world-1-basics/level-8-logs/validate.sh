#!/bin/bash

echo "🔍 Pod holati va barqarorligi tekshirilmoqda..."

POD_STATUS=$(kubectl get pod database-app -n k8squest -o jsonpath='{.status.phase}' 2>/dev/null)
READY=$(kubectl get pod database-app -n k8squest -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
RESTART_COUNT=$(kubectl get pod database-app -n k8squest -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)

echo "   Pod Phase: $POD_STATUS"
echo "   Ready: $READY"
echo "   Restarts: $RESTART_COUNT"

if [[ "$POD_STATUS" == "Running" ]] && [[ "$READY" == "true" ]] && [[ "$RESTART_COUNT" -eq 0 ]]; then
    echo "✅ Pod restartsiz ishlayapti"
    exit 0
else
    echo "❌ Pod barqaror emas — Holat: $POD_STATUS, Restartlar: $RESTART_COUNT"
    echo "💡 Maslahat: 'kubectl logs database-app -n k8squest' bilan loglarni tekshiring"
    echo "💡 Yetishmayotgan konfiguratsiya haqida xato xabarlarini qidiring"
    exit 1
fi
