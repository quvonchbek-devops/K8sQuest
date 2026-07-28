#!/bin/bash

# Pod lar ishlayotganligini va doimiy qayta ishga tushmayotganligini tekshirish
# Barqarorlik VAQT OYNASIDA o'lchanadi, bir lahzalik o'qish bilan emas.
#
# Ilgari tekshiruv shunchaki "2 pod Running va restart < 3" derdi. Bu
# setup dan keyingi dastlabki ~20 soniyada HAR DOIM rost: buzuq liveness
# probe (`/nonexistent-healthz`, periodSeconds 5, failureThreshold 2) ilk
# restart ni ~15 soniyada beradi. Ya'ni foydalanuvchi levelni ochib darhol
# "Tekshirish" bossa, HECH NIMA QILMASDAN o'tib ketardi — o'lchadim,
# broken.yaml qo'yilgandan 12 soniya keyin validate exit 0 qaytardi.
#
# Endi uchta mustaqil signal:
#   1) CrashLoopBackOff — uzoq backoff ga tushgan pod (oyna uni ko'rmasligi
#      mumkin, chunki restart lar orasi bir necha daqiqagacha cho'ziladi);
#   2) restart lar OYNA ICHIDA o'sdimi — aynan buzuq probe ning izi;
#   3) deployment to'liq tayyormi.
DEPLOY="api-server"
NAMESPACE="k8squest"

restartlar() {
    kubectl get pods -n $NAMESPACE -l app=api \
        -o jsonpath='{.items[*].status.containerStatuses[*].restartCount}' 2>/dev/null \
        | awk '{for(i=1;i<=NF;i++) s+=$i} END {print s+0}'
}

echo "🔍 Pod lar barqarorligi o'lchanmoqda (30 soniyalik oyna)..."

CRASH=$(kubectl get pods -n $NAMESPACE -l app=api \
    -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' 2>/dev/null)
BOSHLANGICH=$(restartlar)
sleep 30
KEYINGI=$(restartlar)
OSISH=$((KEYINGI - BOSHLANGICH))

READY=$(kubectl get deployment $DEPLOY -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ -z "$READY" ] && READY=0
DESIRED=$(kubectl get deployment $DEPLOY -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ -z "$DESIRED" ] && DESIRED=0

if echo "$CRASH" | grep -q CrashLoopBackOff; then
    echo "❌ Pod CrashLoopBackOff da — liveness probe uni o'ldirib turibdi"
    echo "💡 kubectl describe pod -n $NAMESPACE -l app=api | grep -A5 Liveness"
    exit 1
fi
if [ "$OSISH" -gt 0 ]; then
    echo "❌ 30 soniyada $OSISH ta restart bo'ldi (jami: $KEYINGI)"
    echo "   Pod lar tirik, lekin liveness probe ularni qayta-qayta o'ldiryapti."
    echo "💡 Probe qaysi yo'lga uryapti? nginx / da javob beradi, /nonexistent-healthz da 404."
    exit 1
fi
if [ "$READY" != "$DESIRED" ] || [ "$READY" -eq 0 ]; then
    echo "❌ Tayyor pod: $READY/$DESIRED"
    exit 1
fi

echo "✅ $READY/$DESIRED pod tayyor va 30 soniya davomida BIRORTA restart bo'lmadi"
echo "   Jami restart: $KEYINGI"
exit 0
