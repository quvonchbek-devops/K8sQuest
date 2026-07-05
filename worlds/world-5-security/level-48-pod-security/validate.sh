#!/bin/bash

NAMESPACE="k8squest"
POD_NAME="secure-app"

echo "🔍 TEKSHIRUV 1-BOSQICH: Tekshirilmoqda namespace xavfsizlik label lari..."
PSS_ENFORCE=$(kubectl get namespace $NAMESPACE -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')
if [ "$PSS_ENFORCE" != "restricted" ]; then
    echo "⚠️  Namespace doesn't enforce 'restricted' standard"
    echo "   Bu level restricted enforcement bilan eng yaxshi ishlaydi"
fi
echo "✅ Namespace tekshirildi"

echo ""
echo "🔍 TEKSHIRUV 2-BOSQICH: Tekshirilmoqda pod mavjudligini..."
if ! kubectl get pod $POD_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Pod '$POD_NAME' topilmadi"
    echo "💡 Maslahat: Pod may have been rejected by admission controller"
    echo "💡 Maslahat: Tekshiring: events: kubectl get events -n $NAMESPACE"
    exit 1
fi
echo "✅ Pod mavjud"

echo ""
echo "🔍 TEKSHIRUV 3-BOSQICH: Tekshirilmoqda runAsNonRoot ni..."
RUN_AS_NON_ROOT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].securityContext.runAsNonRoot ni}')
if [ "$RUN_AS_NON_ROOT" != "true" ]; then
    echo "❌ FAILED: runAsNonRoot ni not set to true"
    exit 1
fi
echo "✅ runAsNonRoot ni: true"

echo ""
echo "🔍 TEKSHIRUV 4-BOSQICH: Tekshirilmoqda runAsUser ni (noldan farqli bo'lishi kerak)..."
RUN_AS_USER=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].securityContext.runAsUser}')
if [ -z "$RUN_AS_USER" ] || [ "$RUN_AS_USER" = "0" ]; then
    echo "❌ FAILED: runAsUser is 0 (root) or not set"
    exit 1
fi
echo "✅ runAsUser: $RUN_AS_USER (non-root)"

echo ""
echo "🔍 TEKSHIRUV 5-BOSQICH: Tekshirilmoqda allowPrivilegeEscalation ni..."
ALLOW_PRIV=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation ni}')
if [ "$ALLOW_PRIV" != "false" ]; then
    echo "❌ FAILED: allowPrivilegeEscalation ni not set to false"
    exit 1
fi
echo "✅ allowPrivilegeEscalation ni: false"

echo ""
echo "🔍 TEKSHIRUV 6-BOSQICH: Tekshirilmoqda capabilities drop qilinganligini..."
CAPS_DROP=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop}')
if ! echo "$CAPS_DROP" | grep -q "ALL"; then
    echo "❌ FAILED: capabilities.drop does not include ALL"
    exit 1
fi
echo "✅ capabilities drop qilinganligini: ALL"

echo ""
echo "🔍 TEKSHIRUV 7-BOSQICH: Tekshirilmoqda seccompProfile ni..."
SECCOMP=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.securityContext.seccompProfile ni.type}')
if [ "$SECCOMP" != "RuntimeDefault" ] && [ "$SECCOMP" != "Localhost" ]; then
    echo "⚠️  seccompProfile ni not set to RuntimeDefault or Localhost"
    echo "   Bu restricted standart uchun talab qilinadi"
fi
echo "✅ seccompProfile ni: $SECCOMP"

echo ""
echo "🔍 TEKSHIRUV 8-BOSQICH: Tekshirilmoqda pod holatini..."
POD_STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "⚠️  Pod is $POD_STATUS, Running emas"
else
    echo "✅ Pod Running holatida"
fi

echo ""
echo "🎉 SUCCESS! Pod meets restricted Pod Security Standards!"
echo ""
echo "Xavfsizlik konfiguratsiyasi:"
echo "  • runAsNonRoot ni: true"
echo "  • runAsUser: $RUN_AS_USER"
echo "  • allowPrivilegeEscalation ni: false"
echo "  • capabilities: drop ALL"
echo "  • seccompProfile ni: $SECCOMP"
echo ""
echo "Bu pod xavfsizlik eng yaxshi amaliyotlariga amal qiladi! 🔒"
