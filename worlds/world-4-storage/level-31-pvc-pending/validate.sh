#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Level 31 tekshiruvi: PersistentVolumeClaim Pending..."
echo ""

# 1-bosqich: PVC mavjudligini tekshirish
echo "📋 1-bosqich: Tekshirilmoqda PVC mavjudligini..."
if ! kubectl get pvc app-storage-claim -n k8squest &>/dev/null; then
    echo -e "${RED}❌ PVC 'app-storage-claim' topilmadi in namespace 'k8squest'${NC}"
    echo ""
    echo "💡 Make sure to apply your fixed konfiguratsiya with the PVC definition."
    exit 1
fi
echo -e "${GREEN}✓ PVC mavjud${NC}"
echo ""

# 2-bosqich: PVC holatini tekshirish
echo "📋 2-bosqich: Tekshirilmoqda PVC bog'lanish holatini..."
PVC_STATUS=$(kubectl get pvc app-storage-claim -n k8squest -o jsonpath='{.status.phase}')

if [ "$PVC_STATUS" == "Pending" ]; then
    echo -e "${RED}❌ PVC is still in Pending state${NC}"
    echo ""
    echo "💡 PVC remains pending when:"
    echo "   1. Hech qanday PersistentVolume PVC talablariga mos kelmaydi"
    echo "   2. Saqlash hajmi mos kelmaydi (PV juda kichik)"
    echo "   3. StorageClass mos kelmaydi"
    echo "   4. Access mode lar mos kelmaydi"
    echo ""
    echo "🔍 Muammolarni hal qilish bosqichlari:"
    echo "   • Tekshiring: PVC requirements:"
    echo "     kubectl describe pvc app-storage-claim -n k8squest"
    echo ""
    echo "   • Look for available PVs:"
    echo "     kubectl get pv"
    echo ""
    echo "   • Tekshiring: PVC events:"
    echo "     kubectl get events -n k8squest | grep app-storage-claim"
    echo ""
    
    # Show what PVC is requesting
    REQUESTED_STORAGE=$(kubectl get pvc app-storage-claim -n k8squest -o jsonpath='{.spec.resources.requests.storage}')
    REQUESTED_CLASS=$(kubectl get pvc app-storage-claim -n k8squest -o jsonpath='{.spec.storageClassName}')
    REQUESTED_MODE=$(kubectl get pvc app-storage-claim -n k8squest -o jsonpath='{.spec.accessModes[0]}')
    
    echo "📊 PVC Talablari:"
    echo "   • Storage: $REQUESTED_STORAGE"
    echo "   • StorageClass: $REQUESTED_CLASS"
    echo "   • AccessMode: $REQUESTED_MODE"
    echo ""
    
    # Check PV mavjudligini and show its specs
    if kubectl get pv app-storage &>/dev/null; then
        PV_CAPACITY=$(kubectl get pv app-storage -o jsonpath='{.spec.capacity.storage}')
        PV_CLASS=$(kubectl get pv app-storage -o jsonpath='{.spec.storageClassName}')
        PV_MODE=$(kubectl get pv app-storage -o jsonpath='{.spec.accessModes[0]}')
        
        echo "📊 Mavjud PV 'app-storage':"
        echo "   • Storage: $PV_CAPACITY"
        echo "   • StorageClass: $PV_CLASS"
        echo "   • AccessMode: $PV_MODE"
        echo ""
        
        # Check mismatches
        if [ "$PV_CAPACITY" != "$REQUESTED_STORAGE" ]; then
            echo -e "${YELLOW}⚠️  Storage mismatch: PV has $PV_CAPACITY, PVC needs $REQUESTED_STORAGE${NC}"
        fi
        if [ "$PV_CLASS" != "$REQUESTED_CLASS" ]; then
            echo -e "${YELLOW}⚠️  StorageClass mismatch: PV has '$PV_CLASS', PVC needs '$REQUESTED_CLASS'${NC}"
        fi
        if [ "$PV_MODE" != "$REQUESTED_MODE" ]; then
            echo -e "${YELLOW}⚠️  AccessMode mismatch: PV has $PV_MODE, PVC needs $REQUESTED_MODE${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No PersistentVolume named 'app-storage' found${NC}"
        echo "   Create a PV that matches the PVC requirements above."
    fi
    echo ""
    echo "🔧 Fix the PV to match all PVC requirements!"
    exit 1
fi

if [ "$PVC_STATUS" != "Bound" ]; then
    echo -e "${RED}❌ PVC status is '$PVC_STATUS' (expected: Bound)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ PVC Bound holatida${NC}"
echo ""

# 3-bosqich: PV mavjud va bound ekanligini tekshirish
echo "📋 3-bosqich: Tekshirilmoqda PersistentVolume..."
PV_NAME=$(kubectl get pvc app-storage-claim -n k8squest -o jsonpath='{.spec.volumeName}')

if [ -z "$PV_NAME" ]; then
    echo -e "${RED}❌ PVC is not bound to any PV${NC}"
    exit 1
fi

if ! kubectl get pv "$PV_NAME" &>/dev/null; then
    echo -e "${RED}❌ PV '$PV_NAME' topilmadi${NC}"
    exit 1
fi

PV_STATUS=$(kubectl get pv "$PV_NAME" -o jsonpath='{.status.phase}')
if [ "$PV_STATUS" != "Bound" ]; then
    echo -e "${RED}❌ PV status is '$PV_STATUS' (expected: Bound)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ PV '$PV_NAME' is bound to PVC${NC}"
echo ""

# 4-bosqich: Saqlash hajmi mosligini tekshirish
echo "📋 4-bosqich: Tekshirilmoqda saqlash hajmini..."
PV_CAPACITY=$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.capacity.storage}')
PVC_REQUEST=$(kubectl get pvc app-storage-claim -n k8squest -o jsonpath='{.spec.resources.requests.storage}')

echo "   PV capacity: $PV_CAPACITY"
echo "   PVC request: $PVC_REQUEST"

# Solishtirish uchun byte larga aylantirish (oddiy holat uchun tekshiruv)
if [[ "$PV_CAPACITY" == *"Mi"* ]] && [[ "$PVC_REQUEST" == *"Gi"* ]]; then
    echo -e "${YELLOW}⚠️  Warning: PV capacity might be too small${NC}"
fi

echo -e "${GREEN}✓ Storage capacity validated${NC}"
echo ""

# 5-bosqich: Pod holatini tekshirish
echo "📋 5-bosqich: Tekshirilmoqda pod holatini..."
if ! kubectl get pod database-pod -n k8squest &>/dev/null; then
    echo -e "${RED}❌ Pod 'database-pod' topilmadi${NC}"
    exit 1
fi

# Pod ishga tushishi uchun biroz kutish
sleep 3

POD_STATUS=$(kubectl get pod database-pod -n k8squest -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${RED}❌ Pod is ishlamayapti (status: $POD_STATUS)${NC}"
    echo ""
    echo "💡 Tekshiring: pod events:"
    echo "   kubectl describe pod database-pod -n k8squest"
    exit 1
fi

echo -e "${GREEN}✓ Pod is running${NC}"
echo ""

# 6-bosqich: Volume ulangan ekanligini tekshirish
echo "📋 6-bosqich: Tekshirilmoqda volume mount..."
MOUNT_CHECK=$(kubectl exec database-pod -n k8squest -- ls /data 2>&1)
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Volume /data ga to'g'ri ulanmagan${NC}"
    echo "   Error: $MOUNT_CHECK"
    exit 1
fi

echo -e "${GREEN}✓ Volume mounted successfully at /data${NC}"
echo ""

# 7-bosqich: Yakuniy tekshiruv
echo "📋 7-bosqich: Yakuniy tekshiruv..."
echo -e "${GREEN}✓ All checks passed!${NC}"
echo ""
echo "🎉 Success! Your PVC is now bound and the pod is using persistent storage"
echo ""
echo "📊 Saqlash Tafsilotlari:"
echo "   • PVC: app-storage-claim (Bound)"
echo "   • PV: $PV_NAME (Bound)"
echo "   • Capacity: $PV_CAPACITY"
echo "   • Pod: database-pod (Running)"
echo "   • Mount: /data"
echo ""
echo "💡 Asosiy Konseptlar:"
echo "   • PVC requests storage, PV provides it"
echo "   • They must match: capacity, storage class, access mode"
echo "   • PVC stays Pending until a matching PV is available"
echo "   • Pod can't start until PVC Bound holatida"
echo ""

exit 0
