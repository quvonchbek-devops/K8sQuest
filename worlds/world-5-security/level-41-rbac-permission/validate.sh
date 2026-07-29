#!/bin/bash

NAMESPACE="k8squest"
POD_NAME="pod-lister"
SA_NAME="pod-reader"
ROLE_NAME="pod-reader-role"
ROLEBINDING_NAME="pod-reader-binding"

echo "🔍 1-bosqich: Tekshirilmoqda ServiceAccount mavjudligini..."
if ! kubectl get serviceaccount "$SA_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ ServiceAccount '$SA_NAME' topilmadi"
    exit 1
fi
echo "✅ ServiceAccount mavjud"

echo ""
echo "🔍 2-bosqich: Tekshirilmoqda Role mavjudligini..."
if ! kubectl get role "$ROLE_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Role '$ROLE_NAME' topilmadi"
    echo "💡 Maslahat: Create a Role with permissions to list pods"
    exit 1
fi
echo "✅ Role mavjud"

echo ""
echo "🔍 3-bosqich: Tekshirilmoqda Role to'g'ri ruxsatlarga ega ekanligini..."
ROLE_VERBS=$(kubectl get role "$ROLE_NAME" -n "$NAMESPACE" -o jsonpath='{.rules[0].verbs}' | grep -o 'list')
if [ -z "$ROLE_VERBS" ]; then
    echo "❌ Role topilmadi 'list' permission for pods"
    echo "💡 Maslahat: Role needs verbs: [get, list, watch]"
    exit 1
fi
echo "✅ Role list ruxsatiga ega"

echo ""
echo "🔍 4-bosqich: Tekshirilmoqda RoleBinding mavjudligini..."
if ! kubectl get rolebinding "$ROLEBINDING_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ RoleBinding '$ROLEBINDING_NAME' topilmadi"
    echo "💡 Maslahat: Create RoleBinding to connect ServiceAccount to Role"
    exit 1
fi
echo "✅ RoleBinding mavjud"

echo ""
echo "🔍 5-bosqich: Tekshirilmoqda RoleBinding SA ni Role ga bog'lashini..."
BINDING_ROLE=$(kubectl get rolebinding "$ROLEBINDING_NAME" -n "$NAMESPACE" -o jsonpath='{.roleRef.name}')
BINDING_SA=$(kubectl get rolebinding "$ROLEBINDING_NAME" -n "$NAMESPACE" -o jsonpath='{.subjects[0].name}')

if [ "$BINDING_ROLE" != "$ROLE_NAME" ]; then
    echo "❌ RoleBinding not referencing correct Role (found: $BINDING_ROLE)"
    exit 1
fi

if [ "$BINDING_SA" != "$SA_NAME" ]; then
    echo "❌ RoleBinding not referencing correct ServiceAccount (found: $BINDING_SA)"
    exit 1
fi
echo "✅ RoleBinding to'g'ri configured"

echo ""
echo "🔍 6-bosqich: Tekshirilmoqda pod mavjudligini..."
if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Pod '$POD_NAME' topilmadi"
    exit 1
fi
echo "✅ Pod mavjud"

echo ""
echo "🔍 7-bosqich: Tekshirilmoqda pod Running holatida ekanligini..."
POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ Pod is in '$POD_STATUS' state (expected Running)"
    echo "💡 Tekshiring: logs: kubectl logs $POD_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ Pod Running holatida"

echo ""
echo "🔍 8-bosqich: Tekshirilmoqda pod muvaffaqiyatli pod larni ro'yxatini olganligini..."
sleep 2  # Give pod time to execute kubectl command
if ! kubectl logs "$POD_NAME" -n "$NAMESPACE" 2>/dev/null | grep -q "Success! Can list pods"; then
    echo "❌ Pod pod larni ko'ra olmadi — RBAC ruxsatlari ishlamayapti"
    echo "💡 Tekshiring: logs: kubectl logs $POD_NAME -n $NAMESPACE"
    exit 1
fi
echo "✅ Pod muvaffaqiyatli listed pods with RBAC permissions"

echo ""
echo "🔍 9-bosqich: Tekshirilmoqda RBAC ruxsatlarini bevosita..."
# `kubectl auth can-i --as=...` ATAYLAB ISHLATILMAYDI.
#
# `--as=` IMPERSONATSIYA, ya'ni chaqiruvchida `impersonate` verb i bo'lishi
# talab qilinadi. Sandbox foydalanuvchisida u yo'q va bo'lmasligi ham
# kerak: impersonatsiya butun RBAC modelini chetlab o'tish vositasi. Ya'ni
# bu bosqich hosted muhitda HAR DOIM yiqilardi — foydalanuvchi RBAC ni
# to'g'ri sozlagan bo'lsa ham.
#
# Dars o'zgarmaydi. RBAC ning HAQIQATAN ishlashi allaqachon isbotlangan:
# yuqoridagi bosqich pod ning O'Z logida "Success! Can list pods" ni
# ko'rdi — pod aynan shu ServiceAccount bilan ishlaydi va API ga o'zi
# murojaat qiladi. Bu impersonatsiyadan KUCHLIROQ dalil.
#
# Bu yerda esa bog'lanish ZANJIRINI yopamiz: RoleBinding aynan o'sha
# ServiceAccount ga va aynan o'sha Role ga ishora qilyaptimi.
BOUND_SA=$(kubectl get rolebinding "$ROLEBINDING_NAME" -n "$NAMESPACE" \
    -o jsonpath="{.subjects[?(@.kind=='ServiceAccount')].name}" 2>/dev/null)
if ! echo "$BOUND_SA" | grep -qw "$SA_NAME"; then
    echo "❌ RoleBinding '$ROLEBINDING_NAME' ServiceAccount '$SA_NAME' ga bog'lanmagan"
    echo "   topilgan subyekt(lar): ${BOUND_SA:-yoq}"
    echo "💡 kubectl get rolebinding $ROLEBINDING_NAME -n $NAMESPACE -o yaml"
    exit 1
fi
echo "✅ RBAC zanjiri to'liq: ServiceAccount -> RoleBinding -> Role"

echo ""
echo "🎉 SUCCESS! ServiceAccount has proper RBAC permissions to list pods!"
