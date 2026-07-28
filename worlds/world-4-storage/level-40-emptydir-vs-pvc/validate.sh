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
echo "🔍 7-bosqich: Tekshirilmoqda ma'lumot QAYERDA saqlanishini..."

# `kubectl exec` ATAYLAB ISHLATILMAYDI: sandbox foydalanuvchisida
# `pods/exec` yo'q (interaktiv shell buyruq validatorini chetlab o'tadi) va
# validate aynan o'sha huquq bilan ishlaydi — exec li tekshiruvlar har doim
# bo'sh qaytar va skript YOLG'ON sabab bilan yiqilardi.
#
# Darsning MOHIYATI o'zgarmaydi. Bu level "faylni yozib ko'ring" haqida
# emas — u ma'lumot QAYERDA turishi haqida: `emptyDir` pod bilan birga
# tug'iladi va pod bilan birga O'LADI, `persistentVolumeClaim` esa pod dan
# uzoq yashaydi. Faylni yozib-o'qish buni ISBOTLAMAYDI ham: emptyDir ga
# yozilgan fayl ham bemalol o'qiladi — pod o'lmaguncha. Ya'ni eski
# tekshiruv noto'g'ri narsani o'lchardi.
#
# Shuning uchun volume ning TURINI tekshiramiz: bu aynan foydalanuvchi
# o'zgartirishi kerak bo'lgan narsa va u darsning yagona to'g'ri javobi.
VOL_NAME=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath=="/data")].name}' 2>/dev/null)
if [ -z "$VOL_NAME" ]; then
    echo "❌ Konteynerda /data ga volumeMount yo'q"
    exit 1
fi

IS_EMPTYDIR=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath="{.spec.volumes[?(@.name=='$VOL_NAME')].emptyDir}" 2>/dev/null)
CLAIM=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath="{.spec.volumes[?(@.name=='$VOL_NAME')].persistentVolumeClaim.claimName}" 2>/dev/null)

if [ -n "$IS_EMPTYDIR" ]; then
    echo "❌ /data hamon emptyDir — ma'lumot pod bilan birga yo'q bo'ladi"
    echo "💡 emptyDir pod bilan tug'iladi va pod bilan o'ladi. Pod qayta"
    echo "   yaratilganda (deploy, node almashishi, crash) hamma narsa ketadi."
    echo "💡 Uni PersistentVolumeClaim ga almashtiring."
    exit 1
fi
if [ -z "$CLAIM" ]; then
    echo "❌ /data ga PersistentVolumeClaim ulanmagan"
    echo "💡 kubectl get pod $POD_NAME -n $NAMESPACE -o yaml | grep -A5 volumes:"
    exit 1
fi
echo "✅ /data PersistentVolumeClaim '$CLAIM' dan kelyapti (pod dan uzoq yashaydi)"

echo ""
echo "🔍 8-bosqich: PVC haqiqatan bog'langanmi..."
PVC_PHASE=$(kubectl get pvc "$CLAIM" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_PHASE" != "Bound" ]; then
    echo "❌ PVC '$CLAIM' holati: ${PVC_PHASE:-topilmadi} (Bound bo'lishi kerak)"
    echo "💡 kubectl describe pvc $CLAIM -n $NAMESPACE"
    exit 1
fi
echo "✅ PVC Bound — saqlash joyi haqiqatan ajratilgan"

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
