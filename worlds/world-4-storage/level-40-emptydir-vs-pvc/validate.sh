#!/bin/bash

NAMESPACE="k8squest"
POD_NAME="data-app"
PVC_NAME="app-data"

echo "🔍 1-bosqich: Tekshirilmoqda PVC mavjudligini..."
if ! kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ PersistentVolumeClaim '$PVC_NAME' topilmadi"
    echo "💡 Maslahat: Replace emptyDir with a PersistentVolumeClaim"
    exit 1
fi
echo "✅ PVC mavjud"

echo ""
echo "🔍 2-bosqich: Tekshirilmoqda PVC Bound holatida ekanligini..."
PVC_STATUS=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
if [ "$PVC_STATUS" != "Bound" ]; then
    echo "❌ PVC is not Bound (current: $PVC_STATUS)"
    exit 1
fi
echo "✅ PVC Bound holatida"

echo ""
echo "🔍 3-bosqich: Tekshirilmoqda pod mavjudligini..."
if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Pod '$POD_NAME' topilmadi"
    exit 1
fi
echo "✅ Pod mavjud"

echo ""
echo "🔍 4-bosqich: Tekshirilmoqda pod emptyDir ishlatmayotganligini..."
VOLUME_TYPE=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.volumes[0]}' | jq -r 'keys[0]')
if [ "$VOLUME_TYPE" == "emptyDir" ]; then
    echo "❌ Pod is still using emptyDir (ephemeral storage)"
    echo "💡 Maslahat: Change volume to use persistentVolumeClaim instead"
    exit 1
fi
echo "✅ Pod is not using emptyDir"

echo ""
echo "🔍 5-bosqich: Tekshirilmoqda pod PVC ishlatayotganligini..."
POD_PVC=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}' 2>/dev/null)
if [ "$POD_PVC" != "$PVC_NAME" ]; then
    echo "❌ Pod is not using the correct PVC (using: $POD_PVC, expected: $PVC_NAME)"
    exit 1
fi
echo "✅ Pod is using PVC: $PVC_NAME"

echo ""
echo "🔍 6-bosqich: Tekshirilmoqda pod Running holatida ekanligini..."
POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ Pod is in '$POD_STATUS' state (expected Running)"
    exit 1
fi
echo "✅ Pod Running holatida"

echo ""
echo "🔍 7-bosqich: Tekshirilmoqda ma'lumotlar saqlanishini..."
kubectl exec "$POD_NAME" -n "$NAMESPACE" -- cat /data/persistent.txt &>/dev/null
if [ $? -ne 0 ]; then
    echo "⚠️  Hali ma'lumot fayli yo'q (this is okay on first run)"
else
    DATA_LINES=$(kubectl exec "$POD_NAME" -n "$NAMESPACE" -- wc -l /data/persistent.txt 2>/dev/null | awk '{print $1}')
    echo "✅ Data file mavjud with $DATA_LINES lines"
fi

echo ""
echo "🔍 8-bosqich: Tekshirilmoqda restart simulyatsiyasi orqali saqlanishni..."
echo "   Test ma'lumotlari yozilmoqda..."
kubectl exec "$POD_NAME" -n "$NAMESPACE" -- sh -c 'echo "Test persistence: $(date)" > /data/test-persistence.txt' 2>/dev/null

echo "   Test ma'lumotlari o'qilmoqda..."
TEST_DATA=$(kubectl exec "$POD_NAME" -n "$NAMESPACE" -- cat /data/test-persistence.txt 2>/dev/null)
if [ -z "$TEST_DATA" ]; then
    echo "❌ Yozilgan ma'lumotlarni o'qib bo'lmadi"
    exit 1
fi
echo "✅ Ma'lumotlar muvaffaqiyatli yozildi va o'qildi"

echo ""
echo "🎉 SUCCESS! Pod sozlangan with PersistentVolumeClaim for ma'lumotlar saqlanishini!"
echo ""
echo "📝 Asosiy farq:"
echo "   emptyDir:      Pod o'chirilganda/qayta ishga tushganda ma'lumotlar YO'QOLADI"
echo "   PVC:           Ma'lumotlar pod hayot davrasi bo'ylab SAQLANADI"
echo ""
echo "💡 To verify persistence, try:"
echo "   1. kubectl delete pod $POD_NAME -n $NAMESPACE"
echo "   2. kubectl apply -f solution.yaml"
echo "   3. Tekshiring: logs - previous data should still exist!"
