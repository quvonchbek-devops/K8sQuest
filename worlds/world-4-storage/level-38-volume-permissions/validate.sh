#!/bin/bash

NAMESPACE="k8squest"
POD_NAME="writer-app"
PVC_NAME="app-data"

echo "🔍 1-bosqich: Tekshirilmoqda PVC mavjudligini and is Bound..."
PVC_STATUS=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" != "Bound" ]; then
    echo "❌ PVC is not Bound (current: $PVC_STATUS)"
    exit 1
fi
echo "✅ PVC Bound holatida"

echo ""
echo "🔍 2-bosqich: Tekshirilmoqda pod mavjudligini..."
if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Pod '$POD_NAME' topilmadi"
    exit 1
fi
echo "✅ Pod mavjud"

echo ""
echo "🔍 3-bosqich: Tekshirilmoqda fsGroup sozlanganligini..."
FS_GROUP=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.securityContext.fsGroup}')
if [ -z "$FS_GROUP" ]; then
    echo "❌ fsGroup is not set in pod securityContext"
    echo "💡 Maslahat: Set spec.securityContext.fsGroup to match runAsUser/runAsGroup"
    exit 1
fi
echo "✅ fsGroup is set to: $FS_GROUP"

echo ""
echo "🔍 4-bosqich: Tekshirilmoqda runAsUser sozlanganligini..."
RUN_AS_USER=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[0].securityContext.runAsUser}')
if [ -z "$RUN_AS_USER" ]; then
    echo "❌ runAsUser is not set"
    exit 1
fi
echo "✅ runAsUser is set to: $RUN_AS_USER"

echo ""
echo "🔍 5-bosqich: Tekshirilmoqda fsGroup va user/group mosligini..."
RUN_AS_GROUP=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[0].securityContext.runAsGroup}')
if [ "$FS_GROUP" != "$RUN_AS_GROUP" ]; then
    echo "⚠️  Warning: fsGroup ($FS_GROUP) doesn't match runAsGroup ($RUN_AS_GROUP)"
    echo "💡 Recommendation: Set fsGroup to match runAsGroup for proper permissions"
fi
echo "✅ Security context properly sozlangan"

echo ""
echo "🔍 6-bosqich: Tekshirilmoqda pod Running holatida ekanligini..."
POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ Pod is in '$POD_STATUS' state (expected Running)"
    echo "💡 Tekshiring: logs: kubectl logs $POD_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ Pod Running holatida"

echo ""
echo "🔍 7-bosqich: Tekshirilmoqda yozish ruxsatlarini..."
if ! kubectl logs "$POD_NAME" -n "$NAMESPACE" 2>/dev/null | grep -q "Write successful"; then
    echo "❌ Pod volume ga yoza olmadi"
    echo "💡 Tekshiring: logs: kubectl logs $POD_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ Pod muvaffaqiyatli wrote to volume"

echo ""
echo "🔍 8-bosqich: Tekshirilmoqda fayl yaratilganligini..."
# `kubectl exec` ATAYLAB ISHLATILMAYDI: sandbox foydalanuvchisida
# `pods/exec` yo'q (interaktiv shell buyruq validatorini chetlab o'tadi) va
# validate aynan o'sha huquq bilan ishlaydi — exec li tekshiruv har doim
# bo'sh qaytar va skript "Fayl yaratilmadi" deb YOLG'ON sabab bilan
# yiqilardi.
#
# Dars o'zgarmaydi: isbot ayni o'sha faylning MAZMUNI. Konteynerning o'zi
# yozgandan keyin `cat /data/test.txt` qiladi, ya'ni mazmun uning
# LOG ida turadi va `pods/log` sandbox da ruxsat etilgan. Ya'ni bu exec
# bilan bir xil narsani, o'sha manbadan tekshiradi.
#
# `fsGroup` ni to'g'ridan-to'g'ri o'qimaymiz ataylab: level ni boshqa
# to'g'ri yo'l bilan yechish ham mumkin (masalan initContainer bilan
# egalikni o'zgartirish). Tekshiruv NATIJANI baholaydi, retseptni emas.
if ! kubectl logs "$POD_NAME" -n "$NAMESPACE" 2>/dev/null | grep -q "^test data$"; then
    echo "❌ Fayl yaratilmadi yoki noto'g'ri tarkibga ega"
    echo "💡 Konteyner yozgach faylni o'zi chop etadi — logda ko'ring:"
    echo "   kubectl logs $POD_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ Fayl to'g'ri ruxsatlar bilan muvaffaqiyatli yaratildi"

echo ""
echo "🎉 SUCCESS! Volume permissions sozlangan to'g'ri with fsGroup!"
