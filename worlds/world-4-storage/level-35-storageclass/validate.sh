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
MOUNT_CHECK=$(kubectl exec "$POD_NAME" -n "$NAMESPACE" -- sh -c 'test -d /data && echo "mounted"' 2>/dev/null)
if [ "$MOUNT_CHECK" != "mounted" ]; then
    echo "❌ Volume /data ga to'g'ri ulanmagan"
    exit 1
fi
echo "✅ Volume muvaffaqiyatli ulandi"

echo ""
echo "🎉 SUCCESS! PVC bound with valid StorageClass and pod running!"
