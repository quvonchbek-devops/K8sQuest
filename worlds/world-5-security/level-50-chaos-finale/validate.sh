#!/bin/bash

NAMESPACE="k8squest"
DEPLOYMENT="chaos-app"

echo "🔥 CHAOS FINALE TEKSHIRUVI 🔥"
echo "Tekshirilmoqda World 5 ning BARCHA konseptlari..."
echo ""

ERRORS=0

# 1. RBAC
echo "🔍 1/9: Tekshirilmoqda RBAC (ServiceAccount, Role, RoleBinding)..."
if ! kubectl get serviceaccount app-sa -n $NAMESPACE &>/dev/null; then
    echo "❌ ServiceAccount topilmadi"; ((ERRORS++))
elif ! kubectl get role app-role -n $NAMESPACE &>/dev/null; then
    echo "❌ Role topilmadi"; ((ERRORS++))
elif ! kubectl get rolebinding app-binding -n $NAMESPACE &>/dev/null; then
    echo "❌ RoleBinding topilmadi"; ((ERRORS++))
else
    echo "✅ RBAC sozlangan"
fi

# 2. ResourceQuota
echo "🔍 2/9: Tekshirilmoqda ResourceQuota..."
QUOTA_CPU=$(kubectl get resourcequota chaos-quota -n $NAMESPACE -o jsonpath='{.spec.hard.requests\.cpu}' 2>/dev/null)
if [ -z "$QUOTA_CPU" ]; then
    echo "❌ ResourceQuota topilmadi"; ((ERRORS++))
else
    echo "✅ ResourceQuota: $QUOTA_CPU CPU"
fi

# 3. NetworkPolicy ni
echo "🔍 3/9: Tekshirilmoqda NetworkPolicy ni..."
if ! kubectl get networkpolicy -n $NAMESPACE | grep -q "allow"; then
    echo "❌ Allow NetworkPolicy ni topilmadi"; ((ERRORS++))
else
    echo "✅ NetworkPolicy ni sozlangan"
fi

# 4. PriorityClass
echo "🔍 4/9: Tekshirilmoqda PriorityClass (looking for: 'production-priority')..."
if ! kubectl get priorityclass production-priority &>/dev/null; then
    echo "❌ PriorityClass 'production-priority' topilmadi"; ((ERRORS++))
else
    echo "✅ PriorityClass 'production-priority' mavjud"
fi

# 5. PodDisruptionBudget
echo "🔍 5/9: Tekshirilmoqda PodDisruptionBudget..."
if ! kubectl get pdb chaos-pdb -n $NAMESPACE &>/dev/null; then
    echo "❌ PDB topilmadi"; ((ERRORS++))
else
    MIN_AVAIL=$(kubectl get pdb chaos-pdb -n $NAMESPACE -o jsonpath='{.spec.minAvailable}')
    echo "✅ PDB sozlangan (minAvailable: $MIN_AVAIL)"
fi

# 6. Deployment
echo "🔍 6/9: Tekshirilmoqda Deployment..."
if ! kubectl get deployment $DEPLOYMENT -n $NAMESPACE &>/dev/null; then
    echo "❌ Deployment topilmadi"; ((ERRORS++))
    exit 1
fi
echo "✅ Deployment mavjud"

# 7. SecurityContext
echo "🔍 7/9: Tekshirilmoqda SecurityContext (runAsNonRoot ni, allowPrivilegeEscalation ni)..."
RUN_AS_NON_ROOT=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsNonRoot}')
ALLOW_PRIV=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}')
if [ "$RUN_AS_NON_ROOT" != "true" ]; then
    echo "❌ runAsNonRoot not true"; ((ERRORS++))
elif [ "$ALLOW_PRIV" != "false" ]; then
    echo "❌ allowPrivilegeEscalation not false"; ((ERRORS++))
else
    echo "✅ SecurityContext sozlangan securely"
fi

# 8. Resources within quota
#
# Ilgari bu bosqich qiymatlarni CHOP ETIB, so'ngra shartsiz
# "✅ Resource requests tekshirildi" deb yozardi — ya'ni HECH NIMA
# tekshirmasdi. Endi haqiqatan ham quota ga sig'ishi hisoblanadi.
echo "🔍 8/9: Tekshirilmoqda resource request lar quota ga sig'ishini..."
CPU_REQUEST=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
REPLICAS=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null)
# Quota NOM bo'yicha o'qiladi: hosted sandbox da namespace da
# platformaning o'z quota si ham turadi va `.items[0]` qaysi biri
# birinchi kelishiga qarab tasodifiy javob berardi.
QUOTA_CPU=$(kubectl get resourcequota chaos-quota -n $NAMESPACE -o jsonpath='{.spec.hard.requests\.cpu}' 2>/dev/null)
[ -z "$QUOTA_CPU" ] && QUOTA_CPU=$(kubectl get resourcequota -n $NAMESPACE -o jsonpath='{.items[0].spec.hard.requests\.cpu}' 2>/dev/null)

# "100m" yoki "0.5"/"2" ni millicore ga keltiramiz (jq/bc siz — ular
# hamma image da yo'q).
to_milli() {
    case "$1" in
        "")      echo "" ;;
        *m)      echo "${1%m}" ;;
        *)       awk -v v="$1" 'BEGIN{printf "%d", v*1000}' ;;
    esac
}
REQ_M=$(to_milli "$CPU_REQUEST")
QUOTA_M=$(to_milli "$QUOTA_CPU")

if [ -z "$REQ_M" ]; then
    echo "❌ Container da CPU request yo'q — ResourceQuota li namespace da"
    echo "   request siz pod UMUMAN yaratilmaydi"
    ((ERRORS++))
elif [ -n "$QUOTA_M" ] && [ $((REQ_M * REPLICAS)) -gt "$QUOTA_M" ]; then
    echo "❌ $REPLICAS × ${CPU_REQUEST} = $((REQ_M * REPLICAS))m > quota ${QUOTA_CPU}"
    echo "   Barcha replika ko'tarila olmaydi — yo request ni, yo replicas ni kamaytiring"
    ((ERRORS++))
else
    echo "✅ CPU: $REPLICAS × ${CPU_REQUEST} = $((REQ_M * REPLICAS))m, quota: ${QUOTA_CPU:-cheklanmagan}"
fi

# 9. Pod status
#
# Ilgari pod lar tayyor bo'lmasa faqat ⚠️ chiqarib, ERRORS ni
# OSHIRMASDI — ya'ni butun finalni BITTA ham ishlaydigan pod siz
# topshirish mumkin edi. Endi bu xato, lekin avval haqiqiy imkon
# beramiz: image tortish sekin bo'lishi mumkin.
echo "🔍 9/9: Tekshirilmoqda pod holatini..."
READY=0
for i in $(seq 1 20); do
    READY=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    [ -z "$READY" ] && READY=0
    [ "$READY" -ge "${REPLICAS:-1}" ] && break
    sleep 3
done
if [ "$READY" -ge "${REPLICAS:-1}" ]; then
    echo "✅ $READY/$REPLICAS pod tayyor"
elif [ "$READY" -gt 0 ]; then
    echo "❌ Faqat $READY/$REPLICAS pod tayyor — qolganlari ko'tarilmadi"
    echo "   Sabab: kubectl describe deployment $DEPLOYMENT -n $NAMESPACE"
    ((ERRORS++))
else
    echo "❌ Birorta ham pod tayyor emas ($READY/$REPLICAS)"
    echo "   Sabab: kubectl get pods -n $NAMESPACE; kubectl describe deployment $DEPLOYMENT -n $NAMESPACE"
    ((ERRORS++))
fi

echo ""
echo "================================"
if [ $ERRORS -eq 0 ]; then
    echo "🎉🎉🎉 SUCCESS! 🎉🎉🎉"
    echo ""
    echo "SIZ CHAOS FINALE NI YENGA OLDINGIZ!"
    echo ""
    echo "World 5 ning barcha konseptlari o'zlashtirildi:"
    echo "  ✅ RBAC"
    echo "  ✅ SecurityContext"
    echo "  ✅ ResourceQuota"
    echo "  ✅ NetworkPolicy ni"
    echo "  ✅ Node Affinity"
    echo "  ✅ Taints & Tolerations"
    echo "  ✅ PodDisruptionBudget"
    echo "  ✅ Pod Security Standards"
    echo "  ✅ PriorityClass"
    echo ""
    echo "🏆 KUBERNETES MASTER! 🏆"
    echo ""
    echo "Siz BARCHA 50 TA LEVEL ni tamomladingiz!"
    echo "Jami XP: 10,200 XP!"
    echo ""
    echo "BO'RON O'TDI! 🌈"
    echo "================================"
else
    echo "❌ $ERRORS issue(s) found"
    echo "Tuzatishda davom eting! Deyarli tamom!"
    echo "================================"
    exit 1
fi
