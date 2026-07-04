#!/bin/bash

echo "🔍 Resurs namespace lari tekshirilmoqda..."

# Check if resources exist in k8squest namespace
POD_EXISTS=$(kubectl get pod client-app -n k8squest 2>/dev/null)
SERVICE_EXISTS=$(kubectl get service backend-service -n k8squest 2>/dev/null)

# Check if they're in wrong namespace
POD_IN_DEFAULT=$(kubectl get pod client-app -n default 2>/dev/null)
SERVICE_IN_DEFAULT=$(kubectl get service backend-service -n default 2>/dev/null)

if [[ -n "$POD_EXISTS" ]] && [[ -n "$SERVICE_EXISTS" ]]; then
    echo "   Pod: ✅ k8squest namespace da topildi"
    echo "   Service: ✅ k8squest namespace da topildi"
    echo "✅ Resurslar k8squest namespace ga to'g'ri deploy qilindi"
    exit 0
else
    echo "❌ Resurslar k8squest namespace da topilmadi"
    if [[ -n "$POD_IN_DEFAULT" ]] || [[ -n "$SERVICE_IN_DEFAULT" ]]; then
        echo "💡 Resurslar 'default' namespace da topildi — ular 'k8squest' da bo'lishi kerak"
    fi
    echo "💡 Check: kubectl get all -n k8squest"
    echo "💡 Check: kubectl get all -n default"
    exit 1
fi
