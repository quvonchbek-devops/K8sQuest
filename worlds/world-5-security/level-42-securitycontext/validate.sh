#!/bin/bash

NAMESPACE="k8squest"
POD_NAME="web-app"

echo "🔍 TEKSHIRUV 1-BOSQICH: Tekshirilmoqda pod mavjudligini..."
if ! kubectl get pod $POD_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Pod '$POD_NAME' topilmadi in namespace '$NAMESPACE'"
    exit 1
fi
echo "✅ Pod mavjud"

echo ""
echo "🔍 TEKSHIRUV 2-BOSQICH: Tekshirilmoqda pod ishlayotganligini..."
POD_STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ FAILED: Pod is in '$POD_STATUS' state, Running emas"
    echo "💡 Maslahat: Tekshiring: pod events with: kubectl describe pod $POD_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ Pod ishlayapti"

echo ""
echo "🔍 TEKSHIRUV 3-BOSQICH: Tekshirilmoqda runAsNonRoot ni is enabled..."
RUN_AS_NON_ROOT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].securityContext.runAsNonRoot}')
if [ "$RUN_AS_NON_ROOT" != "true" ]; then
    echo "❌ FAILED: runAsNonRoot ni is not set to true"
    echo "💡 Maslahat: Add 'runAsNonRoot ni: true' in securityContext"
    exit 1
fi
echo "✅ runAsNonRoot ni enabled"

echo ""
echo "🔍 TEKSHIRUV 4-BOSQICH: Tekshirilmoqda runAsUser is set to non-root..."
RUN_AS_USER=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].securityContext.runAsUser}')
if [ -z "$RUN_AS_USER" ] || [ "$RUN_AS_USER" = "0" ]; then
    echo "❌ FAILED: runAsUser not set or set to root (0)"
    echo "💡 Maslahat: Add 'runAsUser: 1000' (or any non-zero UID) in securityContext"
    exit 1
fi
echo "✅ runAsUser set to $RUN_AS_USER (non-root)"

echo ""
echo "🔍 TEKSHIRUV 5-BOSQICH: Tekshirilmoqda privilege escalation o'chirilganligini..."
ALLOW_PRIV_ESC=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}')
if [ "$ALLOW_PRIV_ESC" != "false" ]; then
    echo "❌ FAILED: allowPrivilegeEscalation ni is not set to false"
    echo "💡 Maslahat: Add 'allowPrivilegeEscalation ni: false' in securityContext"
    exit 1
fi
echo "✅ Privilege escalation o'chirilgan"

echo ""
echo "🔍 TEKSHIRUV 6-BOSQICH: Tekshirilmoqda konteyner haqiqatan non-root sifatida ishlayotganligini..."
# `kubectl exec` ATAYLAB ISHLATILMAYDI: sandbox foydalanuvchisida
# `pods/exec` yo'q (interaktiv shell terminaldagi buyruq validatorini
# chetlab o'tadi), validate esa aynan o'sha huquq bilan ishlaydi. Exec li
# tekshiruv HAR DOIM bo'sh qaytar va skript YOLG'ON sabab bilan yiqilardi.
# Buning o'rniga API dan o'qiymiz.
#
# `runAsNonRoot: true` bo'lganda tekshiruvni KUBELET bajaradi: image root
# sifatida ishlashga urinsa, konteyner umuman ishga tushmaydi
# (CreateContainerError: "container has runAsNonRoot and image will run as
# root"). Ya'ni pod ning Running bo'lishining O'ZI dalil. Shu sababli
# bu yerda effektiv UID ni pod spec idan o'qiymiz va nol emasligini
# tekshiramiz.
ACTUAL_USER=$(kubectl get pod $POD_NAME -n $NAMESPACE \
    -o jsonpath='{.spec.containers[0].securityContext.runAsUser}' 2>/dev/null)
[ -z "$ACTUAL_USER" ] && ACTUAL_USER=$(kubectl get pod $POD_NAME -n $NAMESPACE \
    -o jsonpath='{.spec.securityContext.runAsUser}' 2>/dev/null)
POD_PHASE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null)
if [ -z "$ACTUAL_USER" ] || [ "$ACTUAL_USER" = "0" ]; then
    echo "❌ FAILED: Konteyner root (UID 0) sifatida ishlayapti yoki runAsUser berilmagan"
    echo "💡 Maslahat: pod yoki konteyner securityContext ida runAsUser ni bering"
    exit 1
fi
if [ "$POD_PHASE" != "Running" ]; then
    echo "❌ FAILED: Pod Running emas ($POD_PHASE) — runAsNonRoot bilan image mos kelmayotgan bo'lishi mumkin"
    exit 1
fi
echo "✅ Konteyner UID $ACTUAL_USER bilan ishlayapti (non-root)"

echo ""
echo "🎉 SUCCESS! All security validations o'tdi!"
echo "Konteyneringiz endi xavfsiz ishlayapti:"
echo "  - Non-root foydalanuvchi sifatida (UID $RUN_AS_USER)"
echo "  - Privilege escalation o'chirilgan holda"
echo "  - Xavfsizlik eng yaxshi amaliyotlariga muvofiq"
