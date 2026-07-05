#!/bin/bash

NAMESPACE="k8squest"
STATEFULSET="postgres-cluster"

echo "🔍 1-bosqich: Tekshirilmoqda StatefulSet mavjudligini..."
if ! kubectl get statefulset "$STATEFULSET" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ StatefulSet '$STATEFULSET' topilmadi"
    exit 1
fi
echo "✅ StatefulSet mavjud"

echo ""
echo "🔍 2-bosqich: Tekshirilmoqda volumeClaimTemplates sozlanganligini..."
VOLUME_CLAIM_TEMPLATES=$(kubectl get statefulset "$STATEFULSET" -n "$NAMESPACE" -o jsonpath='{.spec.volumeClaimTemplates}')
if [ "$VOLUME_CLAIM_TEMPLATES" == "null" ] || [ -z "$VOLUME_CLAIM_TEMPLATES" ]; then
    echo "❌ volumeClaimTemplates is not sozlangan in StatefulSet"
    echo "💡 Maslahat: StatefulSets should use volumeClaimTemplates for per-pod storage"
    exit 1
fi
echo "✅ volumeClaimTemplates is sozlangan"

echo ""
echo "🔍 3-bosqich: Tekshirilmoqda 3 ta pod tayyor ekanligini..."
READY_PODS=$(kubectl get statefulset "$STATEFULSET" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY_PODS" != "3" ]; then
    echo "❌ Only $READY_PODS out of 3 pods are ready"
    echo "💡 Check: kubectl get pods -n $NAMESPACE -l app=postgres"
    exit 1
fi
echo "✅ All 3 pods are ready"

echo ""
echo "🔍 4-bosqich: Tekshirilmoqda har bir pod o'zining PVC siga ega ekanligini..."
PVC_COUNT=$(kubectl get pvc -n "$NAMESPACE" -l app=postgres 2>/dev/null | grep -c "database-storage")
if [ "$PVC_COUNT" -lt "3" ]; then
    echo "❌ Topildi only $PVC_COUNT PVCs (expected 3, one per pod)"
    echo "💡 Each StatefulSet pod should have its own PVC"
    exit 1
fi
echo "✅ Topildi $PVC_COUNT PVCs (one per pod)"

echo ""
echo "🔍 5-bosqich: Tekshirilmoqda PVC nomlash pattern ini..."
# StatefulSet PVCs should follow pattern: <template-name>-<statefulset-name>-<ordinal>
if ! kubectl get pvc -n "$NAMESPACE" | grep -q "database-storage-postgres-cluster-0"; then
    echo "❌ PVCs don't follow StatefulSet naming pattern"
    echo "💡 Expected: database-storage-postgres-cluster-0, database-storage-postgres-cluster-1, etc."
    exit 1
fi
echo "✅ PVCs follow correct naming pattern"

echo ""
echo "🔍 6-bosqich: Tekshirilmoqda barcha PVC lar Bound ekanligini..."
UNBOUND_PVCS=$(kubectl get pvc -n "$NAMESPACE" -l app=postgres -o jsonpath='{.items[?(@.status.phase!="Bound")].metadata.name}')
if [ -n "$UNBOUND_PVCS" ]; then
    echo "❌ Some PVCs are not Bound: $UNBOUND_PVCS"
    exit 1
fi
echo "✅ Barcha PVC lar Bound holatida"

echo ""
echo "🔍 7-bosqich: Tekshirilmoqda pod-PVC bog'lanishini..."
for i in 0 1 2; do
    POD_NAME="postgres-cluster-$i"
    EXPECTED_PVC="database-storage-postgres-cluster-$i"
    ACTUAL_PVC=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.volumes[?(@.name=="database-storage")].persistentVolumeClaim.claimName}' 2>/dev/null)
    
    if [ "$ACTUAL_PVC" != "$EXPECTED_PVC" ]; then
        echo "❌ Pod $POD_NAME is using PVC '$ACTUAL_PVC' instead of '$EXPECTED_PVC'"
        exit 1
    fi
done
echo "✅ Har bir pod o'zining PVC siga to'g'ri bog'langan"

echo ""
echo "🎉 SUCCESS! StatefulSet sozlangan with per-pod persistent storage!"
