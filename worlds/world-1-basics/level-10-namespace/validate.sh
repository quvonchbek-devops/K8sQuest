#!/bin/bash

echo "🔍 Resurs namespace lari tekshirilmoqda..."

# k8squest namespace da resurslar mavjudligini tekshirish
POD_EXISTS=$(kubectl get pod client-app -n k8squest 2>/dev/null)
SERVICE_EXISTS=$(kubectl get service backend-service -n k8squest 2>/dev/null)

# Noto'g'ri namespace da ekanligini tekshirish
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
    echo "💡 Tekshiring: kubectl get all -n k8squest"
    echo "💡 Tekshiring: kubectl get all -n default"
    exit 1
fi
