#!/bin/bash

NAMESPACE="k8squest"
DB_POD="database"
BACKEND_POD="backend"

echo "🔍 TEKSHIRUV 1-BOSQICH: Tekshirilmoqda pod lar mavjudligini..."
if ! kubectl get pod $DB_POD -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Database pod topilmadi"
    exit 1
fi
if ! kubectl get pod $BACKEND_POD -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Backend pod topilmadi"
    exit 1
fi
echo "✅ Ikkala pod ham mavjud"

echo ""
echo "🔍 TEKSHIRUV 2-BOSQICH: Tekshirilmoqda pod lar ishlayotganligini..."
DB_STATUS=$(kubectl get pod $DB_POD -n $NAMESPACE -o jsonpath='{.status.phase}')
BACKEND_STATUS=$(kubectl get pod $BACKEND_POD -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$DB_STATUS" != "Running" ]; then
    echo "❌ FAILED: Database pod is $DB_STATUS, Running emas"
    exit 1
fi
if [ "$BACKEND_STATUS" != "Running" ]; then
    echo "❌ FAILED: Backend pod is $BACKEND_STATUS, Running emas"
    exit 1
fi
echo "✅ Both pod lar ishlayotganligini"

echo ""
echo "🔍 TEKSHIRUV 3-BOSQICH: Tekshirilmoqda NetworkPolicy ni lar mavjudligini..."
if ! kubectl get networkpolicy -n $NAMESPACE | grep -q "allow"; then
    echo "❌ FAILED: No NetworkPolicy ni with 'allow' found"
    echo "💡 Maslahat: Create NetworkPolicy ni to allow traffic between pods"
    exit 1
fi
echo "✅ NetworkPolicy lar mavjud"

echo ""
echo "🔍 TEKSHIRUV 4-BOSQICH: Tekshirilmoqda database ingress policy sini..."
DB_POLICY=$(kubectl get networkpolicy -n $NAMESPACE -o json | jq -r '.items[] | select(.spec.podSelector.matchLabels.app == "database") | .metadata.name' | head -1)
if [ -z "$DB_POLICY" ]; then
    echo "❌ FAILED: No NetworkPolicy ni targeting database pod"
    echo "💡 Maslahat: Create NetworkPolicy ni with podSelector matching app: database"
    exit 1
fi
echo "✅ Database has NetworkPolicy ni: $DB_POLICY"

echo ""
echo "🔍 TEKSHIRUV 5-BOSQICH: Tekshirilmoqda backend egress policy sini..."
BACKEND_POLICY=$(kubectl get networkpolicy -n $NAMESPACE -o json | jq -r '.items[] | select(.spec.podSelector.matchLabels.app == "backend") | .metadata.name' | head -1)
if [ -z "$BACKEND_POLICY" ]; then
    echo "❌ FAILED: No NetworkPolicy ni targeting backend pod"
    echo "💡 Maslahat: Create NetworkPolicy ni with podSelector matching app: backend"
    exit 1
fi
echo "✅ Backend has NetworkPolicy ni: $BACKEND_POLICY"

echo ""
echo "🔍 TEKSHIRUV 6-BOSQICH: Tekshirilmoqda Service va Endpoint lar (DNS)"

# Ensure a Service mavjud for the database so the name 'database' resolves
if ! kubectl get svc database -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Service 'database' topilmadi in namespace $NAMESPACE"
    echo "💡 Maslahat: Create a ClusterIP Service named 'database' selecting the database pod"
    exit 1
fi
echo "✅ Service 'database' mavjud"

# Check endpoints for the service
EP_COUNT=$(kubectl get endpoints database -n $NAMESPACE -o json | jq '.subsets | length')
if [ "$EP_COUNT" = "0" ] || [ "$EP_COUNT" = "null" ]; then
    echo "❌ FAILED: Service 'database' has no endpoints; pods may not match selector"
    echo "💡 Maslahat: Ensure the database pod has label app: database and Service selector matches it"
    exit 1
fi
echo "✅ Service has endpoints: $EP_COUNT subset(s)"

echo ""
echo "🔍 TEKSHIRUV 7-BOSQICH: Faol ulanish testi from backend pod"
echo "Policy lar kuchga kirishi uchun 5 soniya kutilmoqda..."
sleep 5

# Try to connect from backend to the service DNS name
kubectl exec $BACKEND_POD -n $NAMESPACE -- sh -c "nc -vz database 5432 -w 5" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Backend can reach database: TCP connection to database:5432 succeeded"
else
    echo "❌ FAILED: Backend cannot reach database (connection timed out or refused)"
    echo "   Tekshiring: NetworkPolicy ni rules and ensure backend egress + database ingress allow port 5432"
    echo "   Tekshiring: backend logs: kubectl logs $BACKEND_POD -n $NAMESPACE"
    exit 1
fi

echo ""
echo "🎉 SUCCESS! NetworkPolicy ni konfiguratsiya validated!"
echo ""
echo "Network policy lar quyidagilarga ruxsat berish uchun sozlangan:"
echo "  • Backend → Database on port 5432"
echo "  • Backend → DNS for name resolution"
echo "  • Database accepts connections from backend only"
