#!/bin/bash

NAMESPACE="k8squest"
POD_NAME="writer-app"
PVC_NAME="app-data"

echo "🔍 Stage 1: Tekshirilmoqda if PVC exists and is Bound..."
PVC_STATUS=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" != "Bound" ]; then
    echo "❌ PVC is not Bound (current: $PVC_STATUS)"
    exit 1
fi
echo "✅ PVC is Bound"

echo ""
echo "🔍 Stage 2: Tekshirilmoqda if pod exists..."
if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Pod '$POD_NAME' not found"
    exit 1
fi
echo "✅ Pod exists"

echo ""
echo "🔍 Stage 3: Tekshirilmoqda if fsGroup is sozlangan..."
FS_GROUP=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.securityContext.fsGroup}')
if [ -z "$FS_GROUP" ]; then
    echo "❌ fsGroup is not set in pod securityContext"
    echo "💡 Maslahat: Set spec.securityContext.fsGroup to match runAsUser/runAsGroup"
    exit 1
fi
echo "✅ fsGroup is set to: $FS_GROUP"

echo ""
echo "🔍 Stage 4: Tekshirilmoqda if runAsUser is sozlangan..."
RUN_AS_USER=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[0].securityContext.runAsUser}')
if [ -z "$RUN_AS_USER" ]; then
    echo "❌ runAsUser is not set"
    exit 1
fi
echo "✅ runAsUser is set to: $RUN_AS_USER"

echo ""
echo "🔍 Stage 5: Verifying fsGroup and user/group alignment..."
RUN_AS_GROUP=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[0].securityContext.runAsGroup}')
if [ "$FS_GROUP" != "$RUN_AS_GROUP" ]; then
    echo "⚠️  Warning: fsGroup ($FS_GROUP) doesn't match runAsGroup ($RUN_AS_GROUP)"
    echo "💡 Recommendation: Set fsGroup to match runAsGroup for proper permissions"
fi
echo "✅ Security context properly sozlangan"

echo ""
echo "🔍 Stage 6: Tekshirilmoqda if pod is Running..."
POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ Pod is in '$POD_STATUS' state (expected Running)"
    echo "💡 Tekshiring: logs: kubectl logs $POD_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ Pod is Running"

echo ""
echo "🔍 Stage 7: Verifying write permissions..."
if ! kubectl logs "$POD_NAME" -n "$NAMESPACE" 2>/dev/null | grep -q "Write successful"; then
    echo "❌ Pod unable to write to volume"
    echo "💡 Tekshiring: logs: kubectl logs $POD_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ Pod muvaffaqiyatli wrote to volume"

echo ""
echo "🔍 Stage 8: Verifying file was created..."
FILE_CHECK=$(kubectl exec "$POD_NAME" -n "$NAMESPACE" -- cat /data/test.txt 2>/dev/null)
if [ "$FILE_CHECK" != "test data" ]; then
    echo "❌ File not created or has wrong content"
    exit 1
fi
echo "✅ File created muvaffaqiyatli with correct permissions"

echo ""
echo "🎉 SUCCESS! Volume permissions sozlangan to'g'ri with fsGroup!"
