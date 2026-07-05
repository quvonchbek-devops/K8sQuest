#!/bin/bash

echo "🔍 Pod va service konfiguratsiyasi tekshirilmoqda..."

# Pod ishlayotganligini tekshirish
POD_STATUS=$(kubectl get pod web-server -n k8squest -o jsonpath='{.status.phase}' 2>/dev/null)
READY=$(kubectl get pod web-server -n k8squest -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)

echo "   Pod Phase: $POD_STATUS"
echo "   Pod Ready: $READY"

# Service targetPort ni tekshirish
SERVICE_PORT=$(kubectl get service web-service -n k8squest -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)
echo "   Service targetPort: $SERVICE_PORT"

# Endpoint larni tekshirish
ENDPOINTS=$(kubectl get endpoints web-service -n k8squest -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
echo "   Endpoint lar: ${ENDPOINTS:-none}"

if [[ "$POD_STATUS" == "Running" ]] && [[ "$READY" == "true" ]] && [[ "$SERVICE_PORT" == "80" ]] && [[ -n "$ENDPOINTS" ]]; then
    echo "✅ Service targetPort to'g'ri sozlangan va pod ga ulangan"
    exit 0
else
    if [[ "$SERVICE_PORT" != "80" ]]; then
        echo "❌ Service targetPort $SERVICE_PORT (80 bo'lishi kerak)"
        echo "💡 Maslahat: nginx konteyner 80-portda tinglaydi, $SERVICE_PORT emas"
    else
        echo "❌ Konfiguratsiya muammosi aniqlandi"
    fi
    echo "💡 Tekshiring: kubectl describe service web-service -n k8squest"
    exit 1
fi
