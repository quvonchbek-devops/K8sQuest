#!/bin/bash

NAMESPACE="k8squest"
PVC_NAME="app-storage"
POD_NAME="data-processor"

echo "🔍 1-bosqich: Tekshirilmoqda PVC mavjudligini..."
if ! kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ PVC '$PVC_NAME' topilmadi"
    exit 1
fi
echo "✅ PVC mavjud"

echo ""
echo "🔍 2-bosqich: Tekshirilmoqda PVC ning StorageClass ini..."
STORAGE_CLASS=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.storageClassName}')
if [ -z "$STORAGE_CLASS" ]; then
    echo "❌ No StorageClass specified in PVC"
    exit 1
fi
echo "✅ PVC references StorageClass: $STORAGE_CLASS"

echo ""
echo "🔍 3-bosqich: Tekshirilmoqda StorageClass mavjudligini..."
if ! kubectl get storageclass "$STORAGE_CLASS" &>/dev/null; then
    echo "❌ StorageClass '$STORAGE_CLASS' does not exist"
    echo "💡 Mavjud StorageClass lar:"
    kubectl get storageclass
    echo ""
    echo "💡 Maslahat: Update PVC to use an existing StorageClass"
    exit 1
fi
echo "✅ StorageClass '$STORAGE_CLASS' mavjud"

echo ""
echo "🔍 4-bosqich: Tekshirilmoqda PVC Bound holatida ekanligini..."
PVC_STATUS=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
if [ "$PVC_STATUS" != "Bound" ]; then
    echo "❌ PVC is in '$PVC_STATUS' state (expected Bound)"
    echo "💡 Describe PVC to see why: kubectl describe pvc $PVC_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ PVC Bound holatida"

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
echo "🔍 7-bosqich: Tekshirilmoqda volume ulangan ekanligini..."
# `kubectl exec` ATAYLAB ISHLATILMAYDI.
#
# Sandbox foydalanuvchisida `pods/exec` YO'Q va bu ataylab: interaktiv
# shell terminaldagi buyruq validatorini butunlay chetlab o'tadi. Validate
# esa aynan o'sha huquq bilan ishlaydi, ya'ni exec li tekshiruv HAR DOIM
# bo'sh natija qaytarar va skript "Volume ulanmagan" deb YOLG'ON sabab
# bilan yiqilardi — foydalanuvchi levelni to'g'ri yechgan bo'lsa ham.
#
# Buning o'rniga API dan o'qiymiz: (a) konteynerda /data ga mount
# E'LON QILINGANMI, (b) o'sha volume PVC ga bog'langanmi. Bu yetarli
# isbot — kubelet mount ni bajara olmasa, pod umuman Running bo'lmaydi
# (yuqoridagi bosqich buni allaqachon tekshirdi).
VOLUME_NAME=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath=="/data")].name}' 2>/dev/null)
if [ -z "$VOLUME_NAME" ]; then
    echo "❌ Konteynerda /data ga volumeMount e'lon qilinmagan"
    echo "💡 kubectl get pod $POD_NAME -n $NAMESPACE -o yaml | grep -A5 volumeMounts"
    exit 1
fi
CLAIM=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath="{.spec.volumes[?(@.name=='$VOLUME_NAME')].persistentVolumeClaim.claimName}" 2>/dev/null)
if [ "$CLAIM" != "$PVC_NAME" ]; then
    echo "❌ /data PVC $PVC_NAME ga bog'lanmagan; topilgani: ${CLAIM:-yoq}"
    echo "💡 Pod ning volumes bo'limida persistentVolumeClaim.claimName ni tekshiring"
    exit 1
fi
echo "✅ Volume muvaffaqiyatli ulandi"

echo ""
echo "🎉 SUCCESS! PVC bound with valid StorageClass and pod running!"
