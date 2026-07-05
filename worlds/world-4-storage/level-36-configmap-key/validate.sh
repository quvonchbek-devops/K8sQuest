#!/bin/bash

NAMESPACE="k8squest"
CONFIGMAP="app-config"
POD_NAME="web-app"

echo "🔍 1-bosqich: Tekshirilmoqda ConfigMap mavjudligini..."
if ! kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ ConfigMap '$CONFIGMAP' topilmadi"
    exit 1
fi
echo "✅ ConfigMap mavjud"

echo ""
echo "🔍 2-bosqich: Tekshirilmoqda ConfigMap da database_host kaliti borligini..."
DB_HOST=$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath='{.data.database_host}' 2>/dev/null)
if [ -z "$DB_HOST" ]; then
    echo "❌ Key 'database_host' topilmadi in ConfigMap"
    echo "💡 Maslahat: Add database_host key to ConfigMap data"
    echo "💡 Joriy kalitlar:"
    kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath='{.data}' | jq 'keys'
    exit 1
fi
echo "✅ database_host key mavjud: $DB_HOST"

echo ""
echo "🔍 3-bosqich: Tekshirilmoqda pod mavjudligini..."
if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Pod '$POD_NAME' topilmadi"
    exit 1
fi
echo "✅ Pod mavjud"

echo ""
echo "🔍 4-bosqich: Tekshirilmoqda pod Running holatida ekanligini..."
POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ Pod is in '$POD_STATUS' state (expected Running)"
    echo "💡 Tekshiring: pod events: kubectl describe pod $POD_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ Pod Running holatida"

echo ""
echo "🔍 5-bosqich: Tekshirilmoqda DATABASE_HOST muhit o'zgaruvchisini..."
ENV_DB_HOST=$(kubectl exec "$POD_NAME" -n "$NAMESPACE" -- sh -c 'echo $DATABASE_HOST' 2>/dev/null)
if [ -z "$ENV_DB_HOST" ]; then
    echo "❌ DATABASE_HOST muhit o'zgaruvchisini is not set in pod"
    exit 1
fi
echo "✅ DATABASE_HOST is set: $ENV_DB_HOST"

echo ""
echo "🔍 6-bosqich: Tekshirilmoqda pod log laridagi muvaffaqiyat xabarini..."
if ! kubectl logs "$POD_NAME" -n "$NAMESPACE" 2>/dev/null | grep -q "App started successfully"; then
    echo "❌ Pod muvaffaqiyatli ishga tushmadi"
    echo "💡 Tekshiring: logs: kubectl logs $POD_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ App started muvaffaqiyatli with config from ConfigMap"

echo ""
echo "🎉 SUCCESS! ConfigMap has all required keys and pod is running!"
