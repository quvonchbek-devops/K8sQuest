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
# `kubectl exec` ATAYLAB ISHLATILMAYDI: sandbox foydalanuvchisida
# `pods/exec` yo'q (interaktiv shell terminaldagi buyruq validatorini
# chetlab o'tadi), validate esa aynan o'sha huquq bilan ishlaydi. Exec li
# tekshiruv HAR DOIM bo'sh qaytar va skript YOLG'ON sabab bilan yiqilardi.
# Buning o'rniga API dan o'qiymiz.
#
# Pod Running bo'lgani (yuqoridagi bosqich) allaqachon KUCHLI dalil: env
# manbasi bo'lgan ConfigMap kaliti yo'q bo'lsa, kubelet konteynerni umuman
# ishga tushira olmaydi (CreateContainerConfigError). Bu yerda esa
# manbaning O'ZI to'g'riligini tekshiramiz.
CM_REF=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].env[?(@.name=="DATABASE_HOST")].valueFrom.configMapKeyRef.name}' 2>/dev/null)
CM_KEY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].env[?(@.name=="DATABASE_HOST")].valueFrom.configMapKeyRef.key}' 2>/dev/null)
if [ -z "$CM_REF" ] || [ -z "$CM_KEY" ]; then
    echo "❌ DATABASE_HOST env i ConfigMap kalitidan olinmayapti"
    echo "💡 kubectl get pod $POD_NAME -n $NAMESPACE -o yaml | grep -A6 env:"
    exit 1
fi
ENV_DB_HOST=$(kubectl get configmap "$CM_REF" -n "$NAMESPACE" -o jsonpath="{.data.$CM_KEY}" 2>/dev/null)
if [ -z "$ENV_DB_HOST" ]; then
    echo "❌ ConfigMap '$CM_REF' da '$CM_KEY' kaliti yo'q yoki bo'sh"
    echo "💡 kubectl get configmap $CM_REF -n $NAMESPACE -o yaml"
    exit 1
fi
echo "✅ DATABASE_HOST manbasi: configmap/$CM_REF kaliti '$CM_KEY' = $ENV_DB_HOST"

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
