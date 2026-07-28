#!/bin/bash

NAMESPACE="k8squest"
SECRET="db-credentials"
POD_NAME="database-client"

echo "🔍 1-bosqich: Tekshirilmoqda Secret mavjudligini..."
if ! kubectl get secret "$SECRET" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Secret '$SECRET' topilmadi"
    exit 1
fi
echo "✅ Secret mavjud"

echo ""
echo "🔍 2-bosqich: Tekshirilmoqda username base64 kodlanganligini..."
USERNAME_RAW=$(kubectl get secret "$SECRET" -n "$NAMESPACE" -o jsonpath='{.data.username}')
if [ -z "$USERNAME_RAW" ]; then
    echo "❌ username key topilmadi in Secret data"
    exit 1
fi

# Try to decode - if it fails, it's not valid base64
USERNAME_DECODED=$(echo "$USERNAME_RAW" | base64 -d 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "❌ username is not properly base64 encoded"
    echo "💡 Maslahat: Kodlash uchun 'echo -n \"qiymat\" | base64' ishlating"
    exit 1
fi
echo "✅ username is base64 encoded (decodes to: $USERNAME_DECODED)"

echo ""
echo "🔍 3-bosqich: Tekshirilmoqda password base64 kodlanganligini..."
PASSWORD_RAW=$(kubectl get secret "$SECRET" -n "$NAMESPACE" -o jsonpath='{.data.password}')
if [ -z "$PASSWORD_RAW" ]; then
    echo "❌ password key topilmadi in Secret data"
    exit 1
fi

PASSWORD_DECODED=$(echo "$PASSWORD_RAW" | base64 -d 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "❌ password is not properly base64 encoded"
    exit 1
fi
echo "✅ password base64 kodlangan"

echo ""
echo "🔍 4-bosqich: Tekshirilmoqda pod mavjudligini..."
if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Pod '$POD_NAME' topilmadi"
    exit 1
fi
echo "✅ Pod mavjud"

echo ""
echo "🔍 5-bosqich: Tekshirilmoqda pod Running holatida ekanligini..."
POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ Pod is in '$POD_STATUS' state (expected Running)"
    exit 1
fi
echo "✅ Pod Running holatida"

echo ""
echo "🔍 6-bosqich: Tekshirilmoqda credentials pod da to'g'ri dekodlanganligini..."
if ! kubectl logs "$POD_NAME" -n "$NAMESPACE" 2>/dev/null | grep -q "Connected successfully"; then
    echo "❌ Pod muvaffaqiyatli ulana olmadi"
    echo "💡 Tekshiring: logs: kubectl logs $POD_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ Credentials to'g'ri dekodlandi va ishlatildi"

echo ""
echo "🔍 7-bosqich: Secret qiymatlar tekshirilmoqda..."
# `kubectl exec` ATAYLAB ISHLATILMAYDI: sandbox foydalanuvchisida
# `pods/exec` yo'q (interaktiv shell terminaldagi buyruq validatorini
# chetlab o'tadi), validate esa aynan o'sha huquq bilan ishlaydi. Exec li
# tekshiruv HAR DOIM bo'sh qaytar va skript YOLG'ON sabab bilan yiqilardi.
# Buning o'rniga API dan o'qiymiz.
#
# Pod ning DB_USER env i qaysi Secret kalitidan kelayotganini o'qiymiz va
# o'sha kalitning DEKODLANGAN qiymatini kutilgani bilan solishtiramiz —
# bu exec bilan bir xil narsani isbotlaydi, chunki kubelet konteynerga
# aynan shu qiymatni beradi.
SEC_REF=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].env[?(@.name=="DB_USER")].valueFrom.secretKeyRef.name}' 2>/dev/null)
SEC_KEY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].env[?(@.name=="DB_USER")].valueFrom.secretKeyRef.key}' 2>/dev/null)
if [ -z "$SEC_REF" ] || [ -z "$SEC_KEY" ]; then
    echo "❌ DB_USER env i Secret kalitidan olinmayapti"
    echo "💡 kubectl get pod $POD_NAME -n $NAMESPACE -o yaml | grep -A6 env:"
    exit 1
fi
POD_USERNAME=$(kubectl get secret "$SEC_REF" -n "$NAMESPACE" \
    -o jsonpath="{.data.$SEC_KEY}" 2>/dev/null | base64 -d 2>/dev/null)
if [ "$POD_USERNAME" != "$USERNAME_DECODED" ]; then
    echo "❌ Pod noto'g'ri username oladi (secret/$SEC_REF kaliti '$SEC_KEY')"
    echo "   kutilgan: $USERNAME_DECODED, kelgan: $POD_USERNAME"
    exit 1
fi
echo "✅ Secret qiymati to'g'ri kodlangan va pod ga to'g'ri yetib boradi"

echo ""
echo "🎉 SUCCESS! Secret properly base64 encoded and pod using credentials!"
