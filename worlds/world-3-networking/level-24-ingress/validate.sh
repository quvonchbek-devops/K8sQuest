#!/bin/bash

# Level 24 Validation: Ingress Path Mismatch
# Validates that the Ingress configuration uses correct path routing

set -e

NAMESPACE="k8squest"
INGRESS_NAME="web-ingress"
SERVICE_NAME="web-service"

echo "🔍 Level 24: Ingress Path Mismatch - Validation"
echo "================================================"
echo ""

# Stage 1: Check if Ingress exists
echo "Stage 1: Tekshirilmoqda Ingress resource..."
if ! kubectl get ingress $INGRESS_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Issue: Ingress '$INGRESS_NAME' not found in namespace '$NAMESPACE'"
    echo ""
    echo "💡 Maslahat: Apply the YAML konfiguratsiya with: kubectl apply -f solution.yaml"
    exit 1
fi
echo "✅ Ingress '$INGRESS_NAME' exists"
echo ""

# Stage 2: Check if Service exists
echo "Stage 2: Tekshirilmoqda Service resource..."
if ! kubectl get service $SERVICE_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Issue: Service '$SERVICE_NAME' not found in namespace '$NAMESPACE'"
    echo ""
    echo "💡 Maslahat: The Ingress needs a backend service to route traffic to"
    exit 1
fi
echo "✅ Service '$SERVICE_NAME' exists"
echo ""

# Stage 3: Check Ingress path configuration
echo "Stage 3: Tekshirilmoqda Ingress path konfiguratsiya..."
INGRESS_PATH=$(kubectl get ingress $INGRESS_NAME -n $NAMESPACE -o jsonpath='{.spec.rules[0].http.paths[0].path}')

if [ "$INGRESS_PATH" != "/" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Issue: Ingress path is '$INGRESS_PATH' but should be '/'"
    echo ""
    echo "🔍 Current Configuration:"
    echo "   Path: $INGRESS_PATH"
    echo "   Expected: /"
    echo ""
    echo "💡 Maslahat: The application serves content at the root path (/), not at a subpath"
    echo "💡 Maslahat: Tekshiring: the 'path:' field in your Ingress spec.rules[].http.paths[]"
    echo ""
    echo "🎯 What to check:"
    echo "   1. Look at the Ingress path konfiguratsiya"
    echo "   2. The path should be '/' to match all requests to myapp.local"
    echo "   3. Common mistake: Using '/api' or '/app' when the service expects root '/'"
    exit 1
fi
echo "✅ Ingress path is to'g'ri set to '/'"
echo ""

# Stage 4: Check pathType
echo "Stage 4: Tekshirilmoqda Ingress pathType..."
PATH_TYPE=$(kubectl get ingress $INGRESS_NAME -n $NAMESPACE -o jsonpath='{.spec.rules[0].http.paths[0].pathType}')

if [ "$PATH_TYPE" != "Prefix" ] && [ "$PATH_TYPE" != "Exact" ]; then
    echo "⚠️  WARNING: pathType is '$PATH_TYPE'"
    echo "   Recommended: Use 'Prefix' or 'Exact'"
    echo ""
fi
echo "✅ Ingress pathType is '$PATH_TYPE'"
echo ""

# Stage 5: Check backend service configuration
echo "Stage 5: Tekshirilmoqda backend service konfiguratsiya..."
BACKEND_SERVICE=$(kubectl get ingress $INGRESS_NAME -n $NAMESPACE -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')
BACKEND_PORT=$(kubectl get ingress $INGRESS_NAME -n $NAMESPACE -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}')

if [ "$BACKEND_SERVICE" != "$SERVICE_NAME" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Issue: Backend service is '$BACKEND_SERVICE' but should be '$SERVICE_NAME'"
    exit 1
fi

if [ "$BACKEND_PORT" != "80" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Issue: Backend port is '$BACKEND_PORT' but should be '80'"
    exit 1
fi
echo "✅ Backend service konfiguratsiya correct: $BACKEND_SERVICE:$BACKEND_PORT"
echo ""

# Stage 6: Check host configuration
echo "Stage 6: Tekshirilmoqda host konfiguratsiya..."
INGRESS_HOST=$(kubectl get ingress $INGRESS_NAME -n $NAMESPACE -o jsonpath='{.spec.rules[0].host}')

if [ "$INGRESS_HOST" != "myapp.local" ]; then
    echo "⚠️  WARNING: Host is '$INGRESS_HOST' (expected: myapp.local)"
    echo "   This might still work depending on your setup"
    echo ""
fi
echo "✅ Ingress host sozlangan: $INGRESS_HOST"
echo ""

# Final Success
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  ✅ VALIDATSIYA O'TDI! ✅                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🎉 Excellent work! Your Ingress is to'g'ri configured!"
echo ""
echo "📊 What you fixed:"
echo "   • Ingress path set to '/' (root path)"
echo "   • Path type sozlangan as '$PATH_TYPE'"
echo "   • Backend service to'g'ri points to $SERVICE_NAME:$BACKEND_PORT"
echo "   • Host sozlangan for $INGRESS_HOST"
echo ""
echo "🎓 Key Concept Mastered:"
echo "   Ingress path routing must match where your application serves content."
echo "   Using '/api' when the app expects '/' results in 404 errors!"
echo ""
echo "🚀 In production:"
echo "   • Always test Ingress paths with curl or browser"
echo "   • Use 'Prefix' for matching /api/* or 'Exact' for specific paths"
echo "   • Monitor Ingress controller logs for routing issues"
echo "   • Consider using path rewrites for legacy applications"
echo ""

exit 0
