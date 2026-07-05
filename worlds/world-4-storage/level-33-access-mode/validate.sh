#!/bin/bash

NAMESPACE="k8squest"
DEPLOYMENT="web-servers"
PVC_NAME="shared-pvc"
PV_NAME="shared-storage"

echo "🔍 1-bosqich: Tekshirilmoqda PV mavjudligini..."
if ! kubectl get pv "$PV_NAME" &>/dev/null; then
    echo "❌ PersistentVolume '$PV_NAME' topilmadi"
    echo "💡 Maslahat: Deploy the resources first with 'kubectl apply -f solution.yaml'"
    exit 1
fi
echo "✅ PV mavjud"

echo ""
echo "🔍 2-bosqich: Tekshirilmoqda PVC bog'langanligini..."
PVC_STATUS=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" != "Bound" ]; then
    echo "❌ PVC is not Bound (current: $PVC_STATUS)"
    echo "💡 Maslahat: PVC should bind to the PV automatically"
    exit 1
fi
echo "✅ PVC Bound holatida"

echo ""
echo "🔍 3-bosqich: Tekshirilmoqda PV access mode ini..."
# Use jq for safer array checking
if ! kubectl get pv "$PV_NAME" -o json | jq -e '.spec.accessModes | index("ReadWriteMany")' &>/dev/null; then
    CURRENT_MODES=$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.accessModes[*]}')
    echo "❌ PV does not have ReadWriteMany access mode"
    echo "   Current modes: $CURRENT_MODES"
    echo "💡 Maslahat: For shared storage across multiple nodes, use ReadWriteMany"
    echo "💡 Note: You cannot edit PVC/PV access mode inis - you must delete and recreate!"
    exit 1
fi
echo "✅ PV has ReadWriteMany access mode"

echo ""
echo "🔍 4-bosqich: Tekshirilmoqda PVC access mode ini..."
# Use jq for safer array checking
if ! kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o json | jq -e '.spec.accessModes | index("ReadWriteMany")' &>/dev/null; then
    CURRENT_MODES=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.accessModes[*]}')
    echo "❌ PVC does not have ReadWriteMany access mode"
    echo "   Current modes: $CURRENT_MODES"
    echo "💡 Maslahat: PVC must match PV access mode ini"
    echo "💡 Remember: PVC spec is immutable - delete and recreate to change it!"
    exit 1
fi
echo "✅ PVC has ReadWriteMany access mode"

echo ""
echo "🔍 5-bosqich: Tekshirilmoqda deployment mavjudligini..."
if ! kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Deployment '$DEPLOYMENT' topilmadi"
    echo "💡 Maslahat: Deploy with 'kubectl apply -f solution.yaml'"
    exit 1
fi
echo "✅ Deployment mavjud"

echo ""
echo "ℹ️  Pod Status (informational only):"
READY_PODS=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
DESIRED_PODS=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null)
echo "   Ready: $READY_PODS/$DESIRED_PODS pods"

if [ "$READY_PODS" = "$DESIRED_PODS" ]; then
    echo "   ✅ All pod lar ishlayotganligini"
    echo ""
    echo "   💡 Note: In Kind (single-node), pods run even with ReadWriteOnce."
    echo "      Tekshiruv KONFIGURATSIYA to'g'riligini tekshiradi, ish vaqti xatti-harakatini emas."
    echo "      Production multi-node cluster larda ReadWriteOnce"
    echo "      turli node lardagi pod larning volume ni ulashiga to'sqinlik qiladi!"
else
    echo "   ⚠️  Hali barcha pod lar tayyor emas (this doesn't affect validation)"
fi

echo ""
echo "🎉 SUCCESS! Storage sozlangan to'g'ri with ReadWriteMany!"
echo ""
echo "📚 Siz nimani o'rgandingiz:"
echo "   ✅ ReadWriteMany allows multiple nodes to mount the volume"
echo "   ✅ Both PV and PVC must have matching access modes"
echo "   ✅ PVC spec is immutable (requires delete/recreate to change)"
echo "   ✅ Konfiguratsiya to'g'riligi muhim, hatto local testlar 'ishlasa' ham"
