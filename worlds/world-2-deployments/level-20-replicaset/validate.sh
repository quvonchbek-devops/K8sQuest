#!/bin/bash

# Nom ham, replika soni ham TOPSHIRIQDAN keladi
# (docs/DESIGN-generated-tasks.md): `__APP__` va `__REPLICAS__` missiya
# matni bilan AYNI BIR qiymatlar to'plamidan almashtiriladi. Boshqa
# odamning yechimini ko'chirgan foydalanuvchi shu yerda yiqiladi.
DEP="__APP__"
WANT_REPLICAS="__REPLICAS__"

# Deployment ishlatilayotganligini tekshirish (mustaqil ReplicaSet emas)
if kubectl get deployment "$DEP" -n k8squest &>/dev/null; then
    READY=$(kubectl get deployment "$DEP" -n k8squest -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    DESIRED=$(kubectl get deployment "$DEP" -n k8squest -o jsonpath='{.spec.replicas}' 2>/dev/null)

    if [ "$DESIRED" != "$WANT_REPLICAS" ]; then
        echo "❌ Replika soni topshiriqqa mos emas"
        echo "   Kutilgan: $WANT_REPLICAS, joriy: ${DESIRED:-0}"
        echo "   Tuzatish: kubectl scale deployment $DEP -n k8squest --replicas=$WANT_REPLICAS"
        exit 1
    fi

    if [ "$READY" = "$DESIRED" ]; then
        echo "✅ Using Deployment (correct approach)"
        echo "   Deployment: $DEP"
        echo "   Ready: $READY/$DESIRED pods"

        # Check that it's managing ReplicaSets
        RS_COUNT=$(kubectl get replicaset -n k8squest -l app="$DEP" -o name 2>/dev/null | wc -l | tr -d ' ')
        echo "   Managed ReplicaSets: $RS_COUNT"

        exit 0
    else
        echo "⏳ Deployment tayyor bo'lishi kutilmoqda"
        echo "   Ready: ${READY:-0}/$DESIRED"
        exit 1
    fi
else
    # Check if still using standalone ReplicaSet
    if kubectl get replicaset "$DEP-rs" -n k8squest &>/dev/null; then
        echo "❌ Still using standalone ReplicaSet ($DEP-rs)"
        echo "   ReplicaSets should be managed by Deployments, not created directly"
        echo ""
        echo "   Problems with standalone ReplicaSets:"
        echo "   - No rolling updates"
        echo "   - No rollback capability"
        echo "   - Can't declaratively update (must create new RS manually)"
        echo ""
        echo "   Convert to Deployment named '$DEP' for better management!"
        exit 1
    else
        echo "❌ $DEP nomli Deployment topilmadi"
        exit 1
    fi
fi
