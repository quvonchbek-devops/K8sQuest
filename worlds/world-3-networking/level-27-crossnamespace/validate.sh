#!/bin/bash

# Level 27 Validation: Cross-namespace Service Communication
# Frontend namespace lar arasi backend service ni ga kira olishini tekshiradi

set -e

FRONTEND_NAMESPACE="k8squest"
BACKEND_NAMESPACE="backend-ns"
FRONTEND_POD="frontend-app"
BACKEND_SERVICE="api-service"

echo "🔍 Level 27: Cross-namespace Service Communication - Validation"
echo "================================================================="
echo ""

# Stage 1: Check if backend namespace ini mavjud
echo "1-bosqich: Tekshirilmoqda backend namespace ini..."
if ! kubectl get namespace $BACKEND_NAMESPACE &>/dev/null; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Namespace '$BACKEND_NAMESPACE' topilmadi"
    echo ""
    echo "💡 Maslahat: Apply the YAML konfiguratsiya with: kubectl apply -f solution.yaml"
    exit 1
fi
echo "✅ Backend namespace '$BACKEND_NAMESPACE' mavjud"
echo ""

# Stage 2: Check if backend service ni mavjud
echo "2-bosqich: Tekshirilmoqda backend service ni..."
if ! kubectl get service $BACKEND_SERVICE -n $BACKEND_NAMESPACE &>/dev/null; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Service '$BACKEND_SERVICE' topilmadi in namespace '$BACKEND_NAMESPACE'"
    echo ""
    echo "💡 Maslahat: The backend service ni should be deployed in the backend-ns namespace"
    exit 1
fi
echo "✅ Backend service '$BACKEND_SERVICE' mavjud in '$BACKEND_NAMESPACE'"
echo ""

# Stage 3: Check backend service ni has endpoints
echo "3-bosqich: Tekshirilmoqda backend service ni endpoints..."
ENDPOINTS=$(kubectl get endpoints $BACKEND_SERVICE -n $BACKEND_NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)

if [ -z "$ENDPOINTS" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Backend service has no endpoints (no pods matching selector)"
    echo ""
    echo "💡 Maslahat: Tekshiring: backend pod ishlayotganligini: kubectl get pods -n $BACKEND_NAMESPACE"
    exit 1
fi
echo "✅ Backend service has endpoints: $ENDPOINTS"
echo ""

# Stage 4: Check if frontend pod ni mavjud
echo "4-bosqich: Tekshirilmoqda frontend pod ni..."
if ! kubectl get pod $FRONTEND_POD -n $FRONTEND_NAMESPACE &>/dev/null; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Frontend pod '$FRONTEND_POD' topilmadi in namespace '$FRONTEND_NAMESPACE'"
    echo ""
    echo "💡 Maslahat: Apply the solution YAML to create the frontend pod ni"
    exit 1
fi

FRONTEND_STATUS=$(kubectl get pod $FRONTEND_POD -n $FRONTEND_NAMESPACE -o jsonpath='{.status.phase}')
if [ "$FRONTEND_STATUS" != "Running" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Frontend pod is in '$FRONTEND_STATUS' state, not 'Running'"
    echo ""
    echo "💡 Maslahat: Wait for pod to start: kubectl get pod $FRONTEND_POD -n $FRONTEND_NAMESPACE -w"
    exit 1
fi
echo "✅ Frontend pod is running in '$FRONTEND_NAMESPACE'"
echo ""

# Stage 5: Check frontend pod ni command/args for FQDN
echo "5-bosqich: Tekshirilmoqda frontend pod dagi DNS konfiguratsiyasini ni..."
POD_COMMAND=$(kubectl get pod $FRONTEND_POD -n $FRONTEND_NAMESPACE -o jsonpath='{.spec.containers[0].command[2]}')

if echo "$POD_COMMAND" | grep -q "api-service.backend-ns"; then
    if echo "$POD_COMMAND" | grep -q "api-service.backend-ns.svc.cluster.local"; then
        echo "✅ Using full FQDN: api-service.backend-ns.svc.cluster.local (best practice)"
    elif echo "$POD_COMMAND" | grep -q "api-service.backend-ns.svc"; then
        echo "✅ Using FQDN: api-service.backend-ns.svc (works)"
    elif echo "$POD_COMMAND" | grep -q "api-service.backend-ns"; then
        echo "✅ Using namespace-qualified name: api-service.backend-ns (works)"
    fi
elif echo "$POD_COMMAND" | grep -q "http://api-service[^.]"; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Frontend QISQA NOM ishlatayapti 'api-service' instead of FQDN"
    echo ""
    echo "🔍 Current command uses: api-service"
    echo "   Bu faqat BIR XOL namespace ichida ishlaydi (k8squest)"
    echo "   But api-service is in a DIFFERENT namespace (backend-ns)"
    echo ""
    echo "💡 Fix: Use FQDN format: api-service.backend-ns.svc.cluster.local"
    echo ""
    echo "🎯 Kubernetes DNS Formati:"
    echo "   Within same namespace:  http://api-service"
    echo "   Cross-namespace:        http://api-service.backend-ns"
    echo "   Full FQDN:              http://api-service.backend-ns.svc.cluster.local"
    echo ""
    echo "🔧 Edit the frontend pod ni command to use:"
    echo "   wget -q -O- http://api-service.backend-ns.svc.cluster.local"
    exit 1
fi
echo ""

# Stage 6: Wait for frontend to make requests
echo "6-bosqich: Frontend ulanishga urinishini kutish (10 soniya)..."
sleep 10
echo "✅ Frontend should have attempted API calls"
echo ""

# Stage 7: Check frontend logs for successful response
echo "7-bosqich: Tekshirilmoqda frontend ulanishini..."
LOGS=$(kubectl logs $FRONTEND_POD -n $FRONTEND_NAMESPACE --tail=20 2>&1)

if echo "$LOGS" | grep -q "API Response from backend-ns"; then
    echo "✅ Frontend muvaffaqiyatli received response from backend!"
elif echo "$LOGS" | grep -iq "could not resolve host\|bad address\|name or service not known"; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: DNS resolution muvaffaqiyatsiz (cannot find service)"
    echo ""
    echo "🔍 Frontend log larida DNS xatolari:"
    echo "$LOGS" | tail -5
    echo ""
    echo "💡 Maslahat: The service name doesn't resolve in the frontend's namespace"
    echo "💡 Maslahat: Use FQDN: api-service.backend-ns.svc.cluster.local"
    echo ""
    echo "🎯 Debug buyruqlari:"
    echo "   kubectl logs $FRONTEND_POD -n $FRONTEND_NAMESPACE"
    echo "   kubectl exec $FRONTEND_POD -n $FRONTEND_NAMESPACE -- nslookup api-service"
    echo "   kubectl exec $FRONTEND_POD -n $FRONTEND_NAMESPACE -- nslookup api-service.backend-ns.svc.cluster.local"
    exit 1
elif echo "$LOGS" | grep -iq "connection refused\|connection timed out"; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Backend ga ulanish muvaffaqiyatsiz"
    echo ""
    echo "🔍 Frontend log larida ulanish xatolari:"
    echo "$LOGS" | tail -5
    echo ""
    echo "💡 Maslahat: DNS resolved but connection muvaffaqiyatsiz. Tekshiring: backend service ni and pod"
    echo ""
    echo "🎯 Debug buyruqlari:"
    echo "   kubectl get service $BACKEND_SERVICE -n $BACKEND_NAMESPACE"
    echo "   kubectl get endpoints $BACKEND_SERVICE -n $BACKEND_NAMESPACE"
    echo "   kubectl get pods -n $BACKEND_NAMESPACE"
    exit 1
else
    echo "⚠️  WARNING: No clear success or failure in logs yet"
    echo "   Oxirgi loglar:"
    echo "$LOGS" | tail -5
    echo ""
    echo "💡 Maslahat: Wait a bit longer or check logs manually:"
    echo "   kubectl logs $FRONTEND_POD -n $FRONTEND_NAMESPACE -f"
    exit 1
fi
echo ""

# Final Success
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  ✅ VALIDATSIYA O'TDI! ✅                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🎉 Excellent work! Cross-namespace communication is working!"
echo ""
echo "📊 Siz nimani tuzatdingiz:"
echo "   • Frontend pod uses FQDN to access backend service ni"
echo "   • DNS resolves: api-service.backend-ns.svc.cluster.local"
echo "   • Cross-namespace aloqa muvaffaqiyatli"
echo "   • Frontend receives: 'API Response from backend-ns'"
echo ""
echo "🎓 O'zlashtirilgan Asosiy Konsept:"
echo "   Kubernetes DNS naming:"
echo "   • Same namespace:    http://service-name"
echo "   • Cross-namespace:   http://service-name.namespace"
echo "   • Full FQDN:         http://service-name.namespace.svc.cluster.local"
echo ""
echo "🚀 Production da:"
echo "   • Use namespace isolation for security (dev, staging, prod)"
echo "   • Services can communicate across namespaces with FQDN"
echo "   • Use NetworkPolicies to control cross-namespace traffic"
echo "   • Document namespace dependencies"
echo "   • Consider using service mesh for advanced cross-namespace routing"
echo ""

exit 0
