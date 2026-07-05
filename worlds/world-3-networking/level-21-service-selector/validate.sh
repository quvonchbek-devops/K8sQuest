#!/bin/bash

# Service endpoint larga ega ekanligini tekshirish
ENDPOINTS=$(kubectl get endpoints backend-service -n k8squest -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)

if [[ -z "$ENDPOINTS" ]]; then
  echo "❌ Service da endpoint lar yo'q. Tekshiring: the selector!"
  exit 1
fi

# Test connectivity from test-client pod ni
RESPONSE=$(kubectl exec test-client -n k8squest -- curl -s -o /dev/null -w "%{http_code}" http://backend-service 2>/dev/null)

if [[ "$RESPONSE" == "200" ]]; then
  echo "✅ Level yakunlandi! Service traffic ni to'g'ri yo'naltirmoqda"
  exit 0
else
  echo "❌ Service ga ulanib bo'lmaydi. Response code: $RESPONSE"
  exit 1
fi
