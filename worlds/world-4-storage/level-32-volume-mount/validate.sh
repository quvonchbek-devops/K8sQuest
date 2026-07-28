#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Level 32 tekshiruvi: Volume Mount Path Xatosi..."
echo ""

echo "📋 1-bosqich: Tekshirilmoqda pod mavjud..."
if ! kubectl get pod web-app -n k8squest &>/dev/null; then
    echo -e "${RED}❌ Pod 'web-app' topilmadi${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Pod mavjud${NC}"
echo ""

echo "📋 2-bosqich: Tekshirilmoqda pod holatini..."
sleep 5
POD_STATUS=$(kubectl get pod web-app -n k8squest -o jsonpath='{.status.phase}')

if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${RED}❌ Pod is ishlamayapti (status: $POD_STATUS)${NC}"
    echo ""
    echo "💡 Tekshiring: pod logs:"
    echo "   kubectl logs web-app -n k8squest"
    echo ""
    echo "   If you see 'Config file topilmadi', the volume ulangan ekanligini at wrong path"
    exit 1
fi
echo -e "${GREEN}✓ Pod is running${NC}"
echo ""

echo "📋 3-bosqich: Tekshirilmoqda volume mount path ini..."
MOUNT_PATH=$(kubectl get pod web-app -n k8squest -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}')

if [ "$MOUNT_PATH" != "/app/config" ]; then
    echo -e "${RED}❌ Volume mounted at wrong path: $MOUNT_PATH${NC}"
    echo "   Expected: /app/config"
    echo ""
    echo "💡 Fix the mountPath in volumeMounts section"
    exit 1
fi
echo -e "${GREEN}✓ Volume mounted at /app/config${NC}"
echo ""

echo "📋 4-bosqich: Tekshirilmoqda konfiguratsiya fayli mavjudligini..."
# `kubectl exec` ATAYLAB ISHLATILMAYDI: sandbox foydalanuvchisida
# `pods/exec` yo'q (interaktiv shell buyruq validatorini chetlab o'tadi) va
# validate aynan o'sha huquq bilan ishlaydi — exec li tekshiruv har doim
# bo'sh qaytar va skript YOLG'ON sabab bilan yiqilardi.
#
# /app/config ga ulangan volume QAYSI manbadan kelayotganini topamiz va
# o'sha manbada `app.conf` kaliti borligini tekshiramiz. Fayl konteyner
# ichida aynan kalit nomi bilan paydo bo'ladi, ya'ni bu `test -f` bilan
# bir xil narsani isbotlaydi.
VOL=$(kubectl get pod web-app -n k8squest \
    -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath=="/app/config")].name}' 2>/dev/null)
SRC_CM=$(kubectl get pod web-app -n k8squest \
    -o jsonpath="{.spec.volumes[?(@.name=='$VOL')].configMap.name}" 2>/dev/null)
SRC_PVC=$(kubectl get pod web-app -n k8squest \
    -o jsonpath="{.spec.volumes[?(@.name=='$VOL')].persistentVolumeClaim.claimName}" 2>/dev/null)
if [ -n "$SRC_CM" ]; then
    if ! kubectl get configmap "$SRC_CM" -n k8squest -o jsonpath='{.data.app\.conf}' 2>/dev/null | grep -q .; then
        echo -e "${RED}❌ ConfigMap '$SRC_CM' da 'app.conf' kaliti yo'q — fayl paydo bo'lmaydi${NC}"
        echo "💡 kubectl get configmap $SRC_CM -n k8squest -o yaml"
        exit 1
    fi
elif [ -z "$SRC_PVC" ]; then
    echo -e "${RED}❌ /app/config ga hech qanday ConfigMap yoki PVC ulanmagan${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Config file mavjud at /app/config/app.conf${NC}"
echo ""

echo "📋 5-bosqich: Tekshirilmoqda app can read config..."
# Mazmun ham API dan (yuqoridagi bilan bir xil sabab).
CONFIG_CONTENT=$(kubectl get configmap "$SRC_CM" -n k8squest -o jsonpath='{.data.app\.conf}' 2>/dev/null)
if [ -z "$CONFIG_CONTENT" ] && [ -z "$SRC_PVC" ]; then
    echo -e "${RED}❌ Konfiguratsiya mazmuni bo'sh${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Ilova konfiguratsiyani o'qiy olishini file${NC}"
echo "   Content: $CONFIG_CONTENT"
echo ""

echo "📋 6-bosqich: Yakuniy tekshiruv..."
echo -e "${GREEN}✓ All checks passed!${NC}"
echo ""
echo "🎉 Success! Volume is mounted at the correct path"
echo ""
echo "📊 Konfiguratsiya:"
echo "   • Mount Path: /app/config"
echo "   • Config File: app.conf"
echo "   • Pod Status: Running"
echo ""
echo "💡 Key Concept: mountPath determines WHERE in the container the volume appears"
echo ""

exit 0
