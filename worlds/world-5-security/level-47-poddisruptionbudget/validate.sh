#!/bin/bash

NAMESPACE="k8squest"
DEPLOYMENT="web-app"
PDB_NAME="web-pdb"

echo "🔍 TEKSHIRUV 1-BOSQICH: Tekshirilmoqda deployment mavjudligini..."
if ! kubectl get deployment $DEPLOYMENT -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Deployment '$DEPLOYMENT' topilmadi"
    exit 1
fi
echo "✅ Deployment mavjud"

echo ""
echo "🔍 TEKSHIRUV 2-BOSQICH: Tekshirilmoqda PodDisruptionBudget mavjudligini..."
if ! kubectl get pdb $PDB_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: PodDisruptionBudget '$PDB_NAME' topilmadi"
    exit 1
fi
echo "✅ PodDisruptionBudget mavjud"

echo ""
echo "🔍 TEKSHIRUV 3-BOSQICH: Tekshirilmoqda deployment replica sonini..."
REPLICAS=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}')
if [ "$REPLICAS" -lt 2 ]; then
    echo "❌ FAILED: Deployment has $REPLICAS replica(s), need at least 2"
    exit 1
fi
echo "✅ Deployment has $REPLICAS replicas"

echo ""
echo "🔍 TEKSHIRUV 4-BOSQICH: Tekshirilmoqda PDB konfiguratsiyasini..."
MIN_AVAILABLE=$(kubectl get pdb $PDB_NAME -n $NAMESPACE -o jsonpath='{.spec.minAvailable}')
MAX_UNAVAILABLE=$(kubectl get pdb $PDB_NAME -n $NAMESPACE -o jsonpath='{.spec.maxUnavailable}')

if [ -n "$MIN_AVAILABLE" ]; then
    echo "PDB minAvailable: $MIN_AVAILABLE"
    if [ "$MIN_AVAILABLE" -gt "$REPLICAS" ]; then
        echo "❌ FAILED: minAvailable ($MIN_AVAILABLE) > replicas ($REPLICAS)"
        echo "💡 Maslahat: minAvailable must be ≤ replicas"
        exit 1
    fi
elif [ -n "$MAX_UNAVAILABLE" ]; then
    echo "PDB maxUnavailable: $MAX_UNAVAILABLE"
else
    echo "❌ FAILED: PDB has neither minAvailable nor maxUnavailable"
    exit 1
fi
echo "✅ PDB konfiguratsiyasini is valid"

echo ""
echo "🔍 TEKSHIRUV 5-BOSQICH: Tekshirilmoqda PDB holatini..."
ALLOWED_DISRUPTIONS=$(kubectl get pdb $PDB_NAME -n $NAMESPACE -o jsonpath='{.status.disruptionsAllowed}')
if [ -z "$ALLOWED_DISRUPTIONS" ]; then
    echo "⚠️  PDB holatini not yet available (pods may still be starting)"
    sleep 5
    ALLOWED_DISRUPTIONS=$(kubectl get pdb $PDB_NAME -n $NAMESPACE -o jsonpath='{.status.disruptionsAllowed}')
fi

if [ "$ALLOWED_DISRUPTIONS" = "0" ]; then
    echo "⚠️  WARNING: Hech qanday uzilishga ruxsat yo'q (disruptionsAllowed: 0)"
    echo "   Bu node drain bloklanishini bildiradi"
    echo "💡 Maslahat: Increase replicas or reduce minAvailable"
else
    echo "✅ Ruxsat etilgan uzilishlar: $ALLOWED_DISRUPTIONS"
fi

echo ""
echo "🔍 TEKSHIRUV 6-BOSQICH: Tekshirilmoqda pod lar ishlayotganligini..."
READY_REPLICAS=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" != "$REPLICAS" ]; then
    echo "⚠️  Only $READY_REPLICAS/$REPLICAS pod tayyor"
else
    echo "✅ All $REPLICAS pods are ready"
fi

echo ""
echo "🎉 SUCCESS! PodDisruptionBudget sozlangan to'g'ri!"
echo ""
echo "PDB Holati:"
kubectl get pdb $PDB_NAME -n $NAMESPACE
echo ""
echo "Konfiguratsiya $ALLOWED_DISRUPTIONS ta ixtiyoriy uzilishga ruxsat beradi"
echo "Bu mavjudlikni saqlab node texnik xizmatini amalga oshirish imkonini beradi!"
