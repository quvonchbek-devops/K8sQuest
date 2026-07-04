#!/bin/bash

echo "🔍 Ko'p konteynerli pod holati tekshirilmoqda..."

# Check if pod is running and all containers are ready
POD_STATUS=$(kubectl get pod app-with-logging -n k8squest -o jsonpath='{.status.phase}' 2>/dev/null)
READY_CONTAINERS=$(kubectl get pod app-with-logging -n k8squest -o jsonpath='{.status.containerStatuses[?(@.ready==true)].name}' 2>/dev/null | wc -w | tr -d ' ')
TOTAL_CONTAINERS=$(kubectl get pod app-with-logging -n k8squest -o jsonpath='{.spec.containers[*].name}' 2>/dev/null | wc -w | tr -d ' ')

echo "   Pod Phase: $POD_STATUS"
echo "   Ready containers: $READY_CONTAINERS/$TOTAL_CONTAINERS"

if [[ "$POD_STATUS" == "Running" ]] && [[ "$READY_CONTAINERS" -eq 2 ]]; then
    echo "✅ Pod ishlayapti, barcha 2 konteyner tayyor"
    exit 0
else
    echo "❌ Pod holati: $POD_STATUS, Tayyor konteynerlar: $READY_CONTAINERS/2"
    echo "💡 Maslahat: Har bir konteyner loglarini tekshiring:"
    echo "   kubectl logs app-with-logging -n k8squest -c main-app"
    echo "   kubectl logs app-with-logging -n k8squest -c log-sidecar"
    exit 1
fi
