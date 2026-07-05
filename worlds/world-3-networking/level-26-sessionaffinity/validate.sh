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

# Stage 1: Check if Service mavjud
echo "1-bosqich: Tekshirilmoqda Service resursini..."
if ! kubectl get service $SERVICE_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Service '$SERVICE_NAME' topilmadi in namespace '$NAMESPACE'"
    echo ""
    echo "💡 Maslahat: Apply the YAML konfiguratsiya with: kubectl apply -f solution.yaml"
    exit 1
fi
echo "✅ Service '$SERVICE_NAME' mavjud"
echo ""

# Stage 2: Check if backend pod larni exist
echo "2-bosqich: Tekshirilmoqda backend pod larni..."
POD_COUNT=$(kubectl get pods -n $NAMESPACE -l app=session-app --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$POD_COUNT" -lt "2" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Kamida kerak 2 running backend pod larni, found: $POD_COUNT"
    echo ""
    echo "💡 Maslahat: Wait for pods to start or check: kubectl get pods -n $NAMESPACE -l app=session-app"
    exit 1
fi
echo "✅ Topildi $POD_COUNT backend pod larni running"
echo ""

# Stage 3: Check sessionAffinity configuration
echo "3-bosqich: Tekshirilmoqda sessionAffinity konfiguratsiyasini..."
SESSION_AFFINITY=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.sessionAffinity}')

if [ -z "$SESSION_AFFINITY" ] || [ "$SESSION_AFFINITY" = "None" ]; then
    echo "❌ VALIDATSIYA MUVAFFAQIYATSIZ!"
    echo ""
    echo "📋 Muammo: Service da sessionAffinity sozlanmagan sozlangan"
    echo ""
    echo "🔍 Joriy Konfiguratsiya:"
    echo "   sessionAffinity: ${SESSION_AFFINITY:-None} (should be: ClientIP)"
    echo ""
    echo "💡 Maslahat: Add 'sessionAffinity: ClientIP' to the Service spec"
    echo ""
    echo "🎯 Nima bo'lyapti:"
    echo "   sessionAffinity siz har bir so'rov boshqa pod ga ketishi mumkin"
    echo "   Bu session ma'lumotlarini xotirada saqlaydigan stateful ilovalarni buzadi"
    echo "   Misol: Foydalanuvchi Pod 1 ga kiradi, keyingi so'rov Pod 2 ga ketadi (session yo'q!)"
    echo ""
    echo "🔧 Qanday tuzatish kerak:"
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
    echo "📋 Muammo: sessionAffinity '$SESSION_AFFINITY' but should be 'ClientIP'"
    echo ""
    echo "💡 Maslahat: Valid values are 'None' (default) or 'ClientIP'"
    exit 1
fi
echo "✅ sessionAffinity is to'g'ri set to 'ClientIP'"
echo ""

# Stage 4: Check session affinity timeout ni (optional)
echo "4-bosqich: Tekshirilmoqda session affinity timeout ni..."
TIMEOUT_SECONDS=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.sessionAffinityConfig.clientIP.timeoutSeconds}' 2>/dev/null || echo "")

if [ -z "$TIMEOUT_SECONDS" ]; then
    echo "ℹ️  Using default timeout (10800 seconds / 3 hours)"
else
    echo "✅ Session timeout sozlangan: $TIMEOUT_SECONDS seconds"
fi
echo ""

# Stage 5: Check client pod ni
echo "5-bosqich: Tekshirilmoqda client pod ni..."
if ! kubectl get pod $CLIENT_POD -n $NAMESPACE &>/dev/null; then
    echo "⚠️  WARNING: Client pod topilmadi (optional for validation)"
    echo ""
else
    CLIENT_STATUS=$(kubectl get pod $CLIENT_POD -n $NAMESPACE -o jsonpath='{.status.phase}')
    if [ "$CLIENT_STATUS" = "Running" ]; then
        echo "✅ Client pod ishlayapti"
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
            echo "   Bu kutilgan holat, agar:"
            echo "   • The client pod ni restarted (new IP)"
            echo "   • Session timeout expired"
            echo "   • Service was recently updated"
            echo ""
            echo "   Oxirgi javoblar:"
            echo "$LOGS" | grep -E "Session Pod [0-9]" | tail -5
        fi
        echo ""
    else
        echo "⚠️  Client pod holatini: $CLIENT_STATUS (ishlamayapti)"
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
echo "📊 Siz nimani tuzatdingiz:"
echo "   • Service sozlangan with sessionAffinity: ClientIP"
echo "   • Requests from same client IP route to same backend pod"
echo "   • User sessions now persist across multiple requests"
if [ -n "$TIMEOUT_SECONDS" ]; then
echo "   • Session timeout: $TIMEOUT_SECONDS seconds"
fi
echo ""
echo "🎓 O'zlashtirilgan Asosiy Konsept:"
echo "   Session affinity bitta klientdan kelgan so'rovlar doimo bitta"
echo "   backend pod ga ketishini ta'minlaydi. Bu xotirada session"
echo "   ma'lumotlarini saqlaydigan stateful ilovalar uchun muhim."
echo ""
echo "🚀 Production da:"
echo "   • Use sessionAffinity for legacy apps with in-memory sessions"
echo "   • Better solution: Use shared session storage (Redis, databases)"
echo "   • sessionAffinity can cause uneven load distribution"
echo "   • If a pod dies, users lose their sessions anyway"
echo "   • Consider stateless design with JWT tokens or similar"
echo ""
echo "⚖️  Afzallik va Kamchiliklar:"
echo "   ✅ Pros: Simple, no code changes, works with legacy apps"
echo "   ❌ Cons: Uneven load, sessions lost on pod restart, not cloud-native"
echo ""

exit 0
