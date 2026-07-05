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
if ! kubectl exec web-app -n k8squest -- test -f /app/config/app.conf 2>/dev/null; then
    echo -e "${RED}❌ Config file topilmadi at /app/config/app.conf${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Config file mavjud at /app/config/app.conf${NC}"
echo ""

echo "📋 5-bosqich: Tekshirilmoqda app can read config..."
CONFIG_CONTENT=$(kubectl exec web-app -n k8squest -- cat /app/config/app.conf 2>/dev/null)
if [ -z "$CONFIG_CONTENT" ]; then
    echo -e "${RED}❌ Cannot read config file${NC}"
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
