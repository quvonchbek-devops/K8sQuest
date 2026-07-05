#!/bin/bash

# Rollout strategiyasini tekshirish
MAX_UNAVAILABLE=$(kubectl get deployment critical-api -n k8squest -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' 2>/dev/null)

# Convert percentage to number if needed
if [[ "$MAX_UNAVAILABLE" == *"%"* ]]; then
    PERCENT=${MAX_UNAVAILABLE%\%}
    if [ "$PERCENT" -ge 100 ]; then
        echo "❌ maxUnavailable is set to $MAX_UNAVAILABLE (too dangerous!)"
        echo "   This can take down ALL pods simultaneously during updates!"
        exit 1
    fi
fi

# Xavfsiz mutlaq son ekanligini tekshirish (3 replica uchun max 1 yoki 2 unavailable xavfsiz)
REPLICAS=$(kubectl get deployment critical-api -n k8squest -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$MAX_UNAVAILABLE" -ge "$REPLICAS" ]; then
    echo "❌ maxUnavailable ($MAX_UNAVAILABLE) >= replicas ($REPLICAS)"
    echo "   This can take down ALL pods simultaneously!"
    exit 1
fi

# Barcha pod lar tayyor ekanligini tekshirish
READY=$(kubectl get deployment critical-api -n k8squest -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
DESIRED=$(kubectl get deployment critical-api -n k8squest -o jsonpath='{.spec.replicas}' 2>/dev/null)

if [ "$READY" = "$DESIRED" ] && [ "$MAX_UNAVAILABLE" -lt "$REPLICAS" ]; then
    echo "✅ Rollout strategy is safe"
    echo "   maxUnavailable: $MAX_UNAVAILABLE (ensures at least $((REPLICAS - MAX_UNAVAILABLE)) pods always running)"
    echo "   All $READY/$DESIRED pods are ready"
    exit 0
else
    echo "⏳ Rollout tugashi kutilmoqda"
    echo "   Ready: $READY/$DESIRED"
    exit 1
fi
