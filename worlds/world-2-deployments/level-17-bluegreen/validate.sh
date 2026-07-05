#!/bin/bash

# Service selector ni tekshirish
SELECTOR=$(kubectl get service app-service -n k8squest -o jsonpath='{.spec.selector.version}' 2>/dev/null)

# Service orqasida qaysi pod lar borligini ko'rish uchun endpoint IP larni olish
ENDPOINTS=$(kubectl get endpoints app-service -n k8squest -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')

if [ "$SELECTOR" = "green" ] && [ "$ENDPOINTS" -gt 0 ]; then
    echo "✅ Service is to'g'ri pointing to GREEN version"
    echo "   Selector: version=$SELECTOR"
    echo "   Endpoints: $ENDPOINTS pods"
    exit 0
else
    if [ "$SELECTOR" != "green" ]; then
        echo "❌ Service is pointing to wrong version!"
        echo "   Current selector: version=$SELECTOR"
        echo "   Should be: version=green"
    fi
    if [ "$ENDPOINTS" -eq 0 ]; then
        echo "❌ Service da endpoint lar yo'q (no pods match selector)"
    fi
    exit 1
fi
