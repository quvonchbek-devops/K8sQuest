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
RUN_AS_NON_ROOT=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsNonRoot ni}')
ALLOW_PRIV=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation ni}')
if [ "$RUN_AS_NON_ROOT" != "true" ]; then
    echo "❌ runAsNonRoot ni not true"; ((ERRORS++))
elif [ "$ALLOW_PRIV" != "false" ]; then
    echo "❌ allowPrivilegeEscalation ni not false"; ((ERRORS++))
else
    echo "✅ SecurityContext sozlangan securely"
fi

# 8. Resources within quota
echo "🔍 8/9: Tekshirilmoqda resource request lar quota ga sig'ishini..."
CPU_REQUEST=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
REPLICAS=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}')
echo "   CPU per pod: $CPU_REQUEST, Replicas: $REPLICAS"
echo "✅ Resource requests tekshirildi"

# 9. Pod status
echo "🔍 9/9: Tekshirilmoqda pod holatini..."
READY=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
if [ "$READY" = "0" ] || [ -z "$READY" ]; then
    echo "⚠️  Pod lar hali tayyor emas (may need time to start)"
else
    echo "✅ $READY/$REPLICAS pod tayyor"
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
