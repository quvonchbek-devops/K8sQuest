#!/bin/bash

NAMESPACE="k8squest"
PV_NAME="important-data"
PVC_NAME="data-claim"
POD_NAME="data-writer"

echo "🔍 1-bosqich: Tekshirilmoqda PV mavjudligini..."
if ! kubectl get pv "$PV_NAME" &>/dev/null; then
    echo "❌ PersistentVolume '$PV_NAME' topilmadi"
    exit 1
fi
echo "✅ PV mavjud"

echo ""
echo "🔍 2-bosqich: Tekshirilmoqda PV reclaim policy sini..."
RECLAIM_POLICY=$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')
if [ "$RECLAIM_POLICY" != "Retain" ]; then
    echo "❌ PV reclaim policy sini is '$RECLAIM_POLICY' (should be 'Retain' for important data)"
    echo "💡 Maslahat: Change persistentVolumeReclaimPolicy to 'Retain' to preserve data"
    echo "💡 Retain = PVC o'chirilganda ma'lumotlar saqlanadi (qo'lda tozalash kerak)"
    echo "💡 Delete = PVC o'chirilganda ma'lumotlar avtomatik o'chiriladi (ma'lumot yo'qotilishi!)"
    exit 1
fi
echo "✅ PV has Retain reclaim policy (data will be preserved)"

echo ""
echo "🔍 3-bosqich: Tekshirilmoqda PVC mavjudligini and is Bound..."
PVC_STATUS=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" != "Bound" ]; then
    echo "❌ PVC is not Bound (current: $PVC_STATUS)"
    exit 1
fi
echo "✅ PVC Bound holatida"

echo ""
echo "🔍 4-bosqich: Tekshirilmoqda PVC to'g'ri PV ga bog'langanligini..."
BOUND_PV=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.volumeName}')
if [ "$BOUND_PV" != "$PV_NAME" ]; then
    echo "❌ PVC is bound to wrong PV: $BOUND_PV (expected: $PV_NAME)"
    exit 1
fi
echo "✅ PVC to'g'ri bound to PV with Retain policy"

echo ""
echo "🔍 5-bosqich: Tekshirilmoqda pod mavjudligini..."
if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Pod '$POD_NAME' topilmadi"
    exit 1
fi
echo "✅ Pod mavjud"

echo ""
echo "🔍 6-bosqich: Tekshirilmoqda pod Running holatida ekanligini..."
POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ Pod is in '$POD_STATUS' state (expected Running)"
    exit 1
fi
echo "✅ Pod Running holatida"

echo ""
echo "🔍 7-bosqich: Tekshirilmoqda ma'lumotlar yozilganligini..."
if ! kubectl logs "$POD_NAME" -n "$NAMESPACE" 2>/dev/null | grep -q "Data written successfully"; then
    echo "❌ Ma'lumotlar muvaffaqiyatli yozilmadi"
    exit 1
fi
echo "✅ Ma'lumotlar volume ga yozildi"

echo ""
echo "🔍 8-bosqich: Tekshirilmoqda ma'lumotlar saqlanishini guarantee..."
DATA_CONTENT=$(kubectl exec "$POD_NAME" -n "$NAMESPACE" -- cat /data/important.txt 2>/dev/null)
if [ -z "$DATA_CONTENT" ]; then
    echo "❌ Volume dan ma'lumotlarni o'qib bo'lmadi"
    exit 1
fi
echo "✅ Ma'lumotlar mavjud va PVC o'chirilsa ham saqlanadi"

echo ""
echo "🎉 SUCCESS! PV sozlangan with Retain policy - data is safe from accidental deletion!"
echo ""
echo "📝 Note: With Retain policy, when PVC is deleted:"
echo "   - PV holati 'Released' ga o'zgaradi"
echo "   - Ma'lumotlar diskda qoladi"
echo "   - PV ni qayta ishlatishdan oldin qo'lda tozalash kerak"
