#!/bin/bash

# Level 25 Validation: NetworkPolicy ni Too Restrictive
# NetworkPolicy ni frontend ga backend ga kirish ruxsati berganini tekshiradi

set -e

NAMESPACE="k8squest"
FRONTEND_POD="frontend"
BACKEND_POD="backend"
NETWORK_POLICY="backend-network-policy"

echo "🔍 Level 25: NetworkPolicy ni Too Restrictive - Validation"
echo "========================================================="
echo ""

# Stage 1: Check if all pods exist
echo "1-bosqich: Tekshirilmoqda pod existence..."
if ! kubectl get pod $FRONTEND_POD -n $NAMESPACE &>/dev/null; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Frontend pod '$FRONTEND_POD' topilmadi in namespace '$NAMESPACE'"
    echo ""
    echo "💡 Maslahat: Apply the YAML konfiguratsiya with: kubectl apply -f solution.yaml"
    exit 1
fi

if ! kubectl get pod $BACKEND_POD -n $NAMESPACE &>/dev/null; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Backend pod '$BACKEND_POD' topilmadi in namespace '$NAMESPACE'"
    echo ""
    echo "💡 Maslahat: Apply the YAML konfiguratsiya with: kubectl apply -f solution.yaml"
    exit 1
fi
echo "✅ Both frontend and backend pod larni exist"
echo ""

# Stage 2: Check pod lar ishlayotganligini
echo "2-bosqich: Tekshirilmoqda pod holatini..."
FRONTEND_STATUS=$(kubectl get pod $FRONTEND_POD -n $NAMESPACE -o jsonpath='{.status.phase}')
BACKEND_STATUS=$(kubectl get pod $BACKEND_POD -n $NAMESPACE -o jsonpath='{.status.phase}')

if [ "$FRONTEND_STATUS" != "Running" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Frontend pod is in '$FRONTEND_STATUS' state, not 'Running'"
    echo ""
    echo "💡 Maslahat: Wait for the pod to start or check: kubectl describe pod $FRONTEND_POD -n $NAMESPACE"
    exit 1
fi

if [ "$BACKEND_STATUS" != "Running" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Backend pod is in '$BACKEND_STATUS' state, not 'Running'"
    echo ""
    echo "💡 Maslahat: Wait for the pod to start or check: kubectl describe pod $BACKEND_POD -n $NAMESPACE"
    exit 1
fi
echo "✅ Both pod lar ishlayotganligini"
echo ""

# Stage 3: Check if NetworkPolicy ni mavjud
echo "3-bosqich: Tekshirilmoqda NetworkPolicy ni..."
if ! kubectl get networkpolicy $NETWORK_POLICY -n $NAMESPACE &>/dev/null; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: NetworkPolicy ni '$NETWORK_POLICY' topilmadi in namespace '$NAMESPACE'"
    echo ""
    echo "💡 Maslahat: The NetworkPolicy ni should be defined in your YAML"
    exit 1
fi
echo "✅ NetworkPolicy ni '$NETWORK_POLICY' mavjud"
echo ""

# Stage 4: Check NetworkPolicy ni configuration
MATCHING_SELECTOR=$(kubectl get networkpolicy $NETWORK_POLICY -n $NAMESPACE \
  -o jsonpath='{.spec.ingress[*].from[*].podSelector.matchLabels.app}')

if echo "$MATCHING_SELECTOR" | tr ' ' '\n' | grep -qx "frontend"; then
  echo "✅ NetworkPolicy ni allows traffic from 'app=frontend' pods"
  echo ""
else
  echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
  echo ""
  echo "📋 Issue: No NetworkPolicy ni ingress rule allows traffic from 'app=frontend'"
  echo ""
  echo "🔍 Joriy Konfiguratsiya:"
  echo "   NetworkPolicy ni allows: ${MATCHING_SELECTOR:-<none found>}"
  echo "   Frontend pod has label: app=frontend"
  echo ""
  echo "💡 Maslahat: The NetworkPolicy ni podSelector should match the frontend pod ni's labels"
  echo "💡 Maslahat: Tekshiring: the 'ingress.from.podSelector.matchLabels' in the NetworkPolicy ni"
  echo ""
  echo "🎯 Nimani tuzatish kerak:"
  echo "   Add or update a NetworkPolicy ni ingress rule to allow traffic from pods with label 'app: frontend'"
  exit 1
fi

# Stage 5: Wait for frontend to start making requests
echo "5-bosqich: Frontend ishga tushishini kutish (15 soniya)..."
sleep 15
echo "✅ Frontend should have attempted connections"
echo ""

# Stage 6: Check frontend logs for successful connection
echo "6-bosqich: Tekshirilmoqda frontend ulanishini..."
LOGS=$(kubectl logs $FRONTEND_POD -n $NAMESPACE --tail=20 2>&1)

if echo "$LOGS" | grep -q "API Response: Success"; then
    echo "✅ Frontend muvaffaqiyatli connected to backend!"
elif echo "$LOGS" | grep -iq "timeout\|connection refused\|network is unreachable"; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Frontend ulana olmaydi to backend (network policy blocking)"
    echo ""
    echo "🔍 Frontend log larida ulanish xatolari:"
    echo "$LOGS" | tail -5
    echo ""
    echo "💡 Maslahat: The NetworkPolicy ni is still blocking the frontend's traffic"
    echo "💡 Maslahat: Verify the podSelector matchLabels allow 'app: frontend'"
    echo ""
    echo "🎯 Debug buyruqlari:"
    echo "   kubectl logs $FRONTEND_POD -n $NAMESPACE"
    echo "   kubectl describe networkpolicy $NETWORK_POLICY -n $NAMESPACE"
    echo "   kubectl get pod $FRONTEND_POD -n $NAMESPACE --show-labels"
    exit 1
else
    echo "⚠️  WARNING: No clear success or failure in logs yet"
    echo "   Logs so far:"
    echo "$LOGS" | tail -5
    echo ""
    echo "💡 Maslahat: Wait a bit longer and check logs manually:"
    echo "   kubectl logs $FRONTEND_POD -n $NAMESPACE -f"
    exit 1
fi
echo ""

# Stage 7: Verify backend received requests
echo "7-bosqich: Backend so'rovlar qabul qilganini tekshirish..."
BACKEND_LOGS=$(kubectl logs $BACKEND_POD -n $NAMESPACE 2>&1)

# The http-echo image doesn't log requests, so we just verify it's running
if [ -z "$BACKEND_LOGS" ] || echo "$BACKEND_LOGS" | grep -q "listening"; then
    echo "✅ Backend is serving requests"
else
    echo "⚠️  Backend holati noma'lum (http-echo doesn't log requests)"
fi
echo ""

# Final Success
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  ✅ VALIDATSIYA O'TDI! ✅                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🎉 Excellent work! Your NetworkPolicy ni is to'g'ri configured!"
echo ""
echo "📊 Siz nimani tuzatdingiz:"
echo "   • NetworkPolicy ni now allows traffic from frontend pod nis (app=frontend)"
echo "   • Frontend muvaffaqiyatli connects to backend service ni"
echo "   • Network security maintained (only frontend can access backend)"
echo ""
echo "🎓 O'zlashtirilgan Asosiy Konsept:"
echo "   NetworkPolicies use label selectors to control pod-to-pod traffic."
echo "   The 'podSelector' in 'ingress.from' must match the SOURCE pod's labels!"
echo ""
echo "🚀 Production da:"
echo "   • Start with permissive policies, then gradually tighten"
echo "   • Test connectivity after applying NetworkPolicies"
echo "   • Use namespace selectors for cross-namespace traffic"
echo "   • Document which pods need to communicate"
echo "   • Monitor denied connections in NetworkPolicy ni logs"
echo ""

exit 0
