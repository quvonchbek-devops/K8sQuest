#!/bin/bash

# Level 26 Validation: Session Affinity Missing
# Validates that the Service has sessionAffinity configured

set -e

NAMESPACE="k8squest"
SERVICE_NAME="session-service"
CLIENT_POD="client"

echo "🔍 Level 26: Session Affinity Missing - Validation"
echo "===================================================="
echo ""

# Stage 1: Check if Service exists
echo "Stage 1: Tekshirilmoqda Service resource..."
if ! kubectl get service $SERVICE_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Issue: Service '$SERVICE_NAME' not found in namespace '$NAMESPACE'"
    echo ""
    echo "💡 Maslahat: Apply the YAML konfiguratsiya with: kubectl apply -f solution.yaml"
    exit 1
fi
echo "✅ Service '$SERVICE_NAME' exists"
echo ""

# Stage 2: Check if backend pods exist
echo "Stage 2: Tekshirilmoqda backend pods..."
POD_COUNT=$(kubectl get pods -n $NAMESPACE -l app=session-app --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$POD_COUNT" -lt "2" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Issue: Need at least 2 running backend pods, found: $POD_COUNT"
    echo ""
    echo "💡 Maslahat: Wait for pods to start or check: kubectl get pods -n $NAMESPACE -l app=session-app"
    exit 1
fi
echo "✅ Topildi $POD_COUNT backend pods running"
echo ""

# Stage 3: Check sessionAffinity configuration
echo "Stage 3: Tekshirilmoqda sessionAffinity konfiguratsiya..."
SESSION_AFFINITY=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.sessionAffinity}')

if [ -z "$SESSION_AFFINITY" ] || [ "$SESSION_AFFINITY" = "None" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Issue: Service does NOT have sessionAffinity sozlangan"
    echo ""
    echo "🔍 Current Configuration:"
    echo "   sessionAffinity: ${SESSION_AFFINITY:-None} (should be: ClientIP)"
    echo ""
    echo "💡 Maslahat: Add 'sessionAffinity: ClientIP' to the Service spec"
    echo ""
    echo "🎯 What's happening:"
    echo "   Without sessionAffinity, each request can go to a different pod"
    echo "   This breaks stateful applications that store session data in memory"
    echo "   Example: User logs in on Pod 1, next request goes to Pod 2 (no session!)"
    echo ""
    echo "🔧 How to fix:"
    echo "   Add these lines to your Service spec:"
    echo "   spec:"
    echo "     sessionAffinity: ClientIP"
    echo "     sessionAffinityConfig:"
    echo "       clientIP:"
    echo "         timeoutSeconds: 10800  # Optional: 3 hours (default)"
    exit 1
fi

if [ "$SESSION_AFFINITY" != "ClientIP" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Issue: sessionAffinity is set to '$SESSION_AFFINITY' but should be 'ClientIP'"
    echo ""
    echo "💡 Maslahat: Valid values are 'None' (default) or 'ClientIP'"
    exit 1
fi
echo "✅ sessionAffinity is to'g'ri set to 'ClientIP'"
echo ""

# Stage 4: Check session affinity timeout (optional)
echo "Stage 4: Tekshirilmoqda session affinity timeout..."
TIMEOUT_SECONDS=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.sessionAffinityConfig.clientIP.timeoutSeconds}' 2>/dev/null || echo "")

if [ -z "$TIMEOUT_SECONDS" ]; then
    echo "ℹ️  Using default timeout (10800 seconds / 3 hours)"
else
    echo "✅ Session timeout sozlangan: $TIMEOUT_SECONDS seconds"
fi
echo ""

# Stage 5: Check client pod
echo "Stage 5: Tekshirilmoqda client pod..."
if ! kubectl get pod $CLIENT_POD -n $NAMESPACE &>/dev/null; then
    echo "⚠️  WARNING: Client pod topilmadi (optional for validation)"
    echo ""
else
    CLIENT_STATUS=$(kubectl get pod $CLIENT_POD -n $NAMESPACE -o jsonpath='{.status.phase}')
    if [ "$CLIENT_STATUS" = "Running" ]; then
        echo "✅ Client pod is running"
        echo ""
        
        # Stage 6: Verify sticky sessions (optional advanced check)
        echo "6-bosqich: Sticky session xatti-harakatini tekshirish..."
        echo "   Tekshirilmoqda client logs for consistent pod responses..."
        sleep 10  # Wait for some requests
        
        LOGS=$(kubectl logs $CLIENT_POD -n $NAMESPACE --tail=10 2>&1)
        
        # Count how many different pods responded
        UNIQUE_PODS=$(echo "$LOGS" | grep -E "Session Pod [0-9]" | sort -u | wc -l | tr -d ' ')
        
        if [ "$UNIQUE_PODS" = "1" ]; then
            echo "✅ All requests going to the same pod (sticky sessions working!)"
        elif [ "$UNIQUE_PODS" -gt "1" ]; then
            echo "⚠️  Requests going to $UNIQUE_PODS different pods"
            echo "   This is expected if:"
            echo "   • The client pod restarted (new IP)"
            echo "   • Session timeout expired"
            echo "   • Service was recently updated"
            echo ""
            echo "   Recent responses:"
            echo "$LOGS" | grep -E "Session Pod [0-9]" | tail -5
        fi
        echo ""
    else
        echo "⚠️  Client pod holati: $CLIENT_STATUS (not running)"
        echo ""
    fi
fi

# Final Success
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  ✅ VALIDATSIYA O'TDI! ✅                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🎉 Excellent work! Your Service has session affinity sozlangan!"
echo ""
echo "📊 What you fixed:"
echo "   • Service sozlangan with sessionAffinity: ClientIP"
echo "   • Requests from same client IP route to same backend pod"
echo "   • User sessions now persist across multiple requests"
if [ -n "$TIMEOUT_SECONDS" ]; then
echo "   • Session timeout: $TIMEOUT_SECONDS seconds"
fi
echo ""
echo "🎓 Key Concept Mastered:"
echo "   Session affinity ensures requests from the same client always go to"
echo "   the same backend pod. This is critical for stateful apps that store"
echo "   session data in memory (like user logins, shopping carts, etc.)."
echo ""
echo "🚀 In production:"
echo "   • Use sessionAffinity for legacy apps with in-memory sessions"
echo "   • Better solution: Use shared session storage (Redis, databases)"
echo "   • sessionAffinity can cause uneven load distribution"
echo "   • If a pod dies, users lose their sessions anyway"
echo "   • Consider stateless design with JWT tokens or similar"
echo ""
echo "⚖️  Tradeoffs:"
echo "   ✅ Pros: Simple, no code changes, works with legacy apps"
echo "   ❌ Cons: Uneven load, sessions lost on pod restart, not cloud-native"
echo ""

exit 0
