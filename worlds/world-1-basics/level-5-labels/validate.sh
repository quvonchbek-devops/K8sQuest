#!/bin/bash

# Nomlar TOPSHIRIQDAN keladi (docs/DESIGN-generated-tasks.md):
# `__APP__` va `__TIER__` server tomonida, missiya matni bilan AYNI BIR
# qiymatlar to'plamidan almashtiriladi. Ya'ni bu skript matnda aytilgan
# resursning O'ZINI tekshiradi — boshqasini emas.
POD="__APP__-app"
SVC="__APP__-service"

echo "🔍 Service va pod holatini tekshirilmoqda..."

POD_STATUS=$(kubectl get pod "$POD" -n k8squest -o jsonpath='{.status.phase}' 2>/dev/null)
READY=$(kubectl get pod "$POD" -n k8squest -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
POD_TIER=$(kubectl get pod "$POD" -n k8squest -o jsonpath='{.metadata.labels.tier}' 2>/dev/null)

echo "   Pod: $POD"
echo "   Pod Phase: $POD_STATUS"
echo "   Pod Ready: $READY"
echo "   Pod tier label: ${POD_TIER:-none}"

# `tier` label i topshiriqdagi bilan bir xil qolishi SHART: aks holda
# muammoni "hamma label ni o'chirib tashlash" bilan ham "hal qilish" mumkin
# bo'lardi va dars — label lar MOS KELISHI — yo'qolardi.
if [ "$POD_TIER" != "__TIER__" ]; then
    echo "❌ Pod ning tier label i o'zgartirilgan yoki yo'qolgan"
    echo "   Kutilgan: tier=__TIER__, joriy: ${POD_TIER:-none}"
    exit 1
fi

# Service endpoint larga ega ekanligini tekshirish
ENDPOINTS=$(kubectl get endpoints "$SVC" -n k8squest -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
echo "   Service: $SVC"
echo "   Endpoint lar: ${ENDPOINTS:-none}"

if [[ "$POD_STATUS" == "Running" ]] && [[ "$READY" == "true" ]] && [[ -n "$ENDPOINTS" ]]; then
    echo "✅ Service pod ga muvaffaqiyatli ulandi!"
    exit 0
else
    echo "❌ Service da endpoint yo'q (mos pod topilmadi)"
    echo "💡 Maslahat: 'kubectl get endpoints $SVC -n k8squest' tekshiring"
    echo "💡 Debug: 'kubectl describe service $SVC -n k8squest'"
    exit 1
fi
