#!/bin/bash

echo "🔍 Service va pod holati tekshirilmoqda..."

# Check if pod is running
POD_STATUS=$(kubectl get pod backend-app -n k8squest -o jsonpath='{.status.phase}' 2>/dev/null)
READY=$(kubectl get pod backend-app -n k8squest -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)

echo "   Pod Phase: $POD_STATUS"
echo "   Pod Ready: $READY"

# Check if service has endpoints
ENDPOINTS=$(kubectl get endpoints backend-service -n k8squest -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
echo "   Endpoints: ${ENDPOINTS:-none}"

if [[ "$POD_STATUS" == "Running" ]] && [[ "$READY" == "true" ]] && [[ -n "$ENDPOINTS" ]]; then
    echo "✅ Service pod ga muvaffaqiyatli ulandi!"
    exit 0
else
    echo "❌ Service da endpoint yo'q (mos pod topilmadi)"
    echo "💡 Maslahat: 'kubectl get endpoints backend-service -n k8squest' tekshiring"
    echo "💡 Debug: 'kubectl describe service backend-service -n k8squest'"
    exit 1
fi
