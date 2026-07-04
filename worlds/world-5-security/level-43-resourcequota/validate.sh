#!/bin/bash

NAMESPACE="k8squest"
POD_NAME="resource-hungry-app"
QUOTA_NAME="compute-quota"

echo "🔍 VALIDATION STAGE 1: Tekshirilmoqda if ResourceQuota exists..."
if ! kubectl get resourcequota $QUOTA_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: ResourceQuota '$QUOTA_NAME' not found"
    exit 1
fi
echo "✅ ResourceQuota exists"

echo ""
echo "🔍 VALIDATION STAGE 2: Tekshirilmoqda if pod exists..."
if ! kubectl get pod $POD_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Pod '$POD_NAME' not found"
    exit 1
fi
echo "✅ Pod exists"

echo ""
echo "🔍 VALIDATION STAGE 3: Tekshirilmoqda if pod is Running (not Pending)..."
POD_STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" = "Pending" ]; then
    echo "❌ FAILED: Pod is still Pending - likely quota exceeded"
    echo "💡 Maslahat: Tekshiring: pod events: kubectl describe pod $POD_NAME -n $NAMESPACE"
    echo "💡 Maslahat: Tekshiring: quota: kubectl describe resourcequota $QUOTA_NAME -n $NAMESPACE"
    exit 1
fi
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ FAILED: Pod is in '$POD_STATUS' state"
    exit 1
fi
echo "✅ Pod is Running"

echo ""
echo "🔍 VALIDATION STAGE 4: Verifying CPU request is within quota..."

CPU_REQUEST=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].resources.requests.cpu}')
QUOTA_CPU=$(kubectl get resourcequota $QUOTA_NAME -n $NAMESPACE -o jsonpath='{.spec.hard.requests\.cpu}')

# Convert both to millicores for comparison
to_millicores() {
    local val="$1"
    if [[ $val == *m ]]; then
        echo "${val%m}"
    else
        echo $((val * 1000))
    fi
}

CPU_REQUEST_MILLI=$(to_millicores "$CPU_REQUEST")
QUOTA_CPU_MILLI=$(to_millicores "$QUOTA_CPU")

if [ "$CPU_REQUEST_MILLI" -gt "$QUOTA_CPU_MILLI" ]; then
        echo "❌ FAILED: CPU request ($CPU_REQUEST) exceeds quota ($QUOTA_CPU)"
        echo "💡 Maslahat: Reduce resources.requests.cpu to fit within quota"
        exit 1
fi
echo "✅ CPU request ($CPU_REQUEST) within quota ($QUOTA_CPU)"

echo ""
echo "🔍 VALIDATION STAGE 5: Tekshirilmoqda quota status..."
QUOTA_USED=$(kubectl get resourcequota $QUOTA_NAME -n $NAMESPACE -o jsonpath='{.status.used}')
if [ -z "$QUOTA_USED" ]; then
    echo "❌ FAILED: Quota not tracking usage properly"
    exit 1
fi
echo "✅ Quota tracking usage to'g'ri"

echo ""
echo "🔍 VALIDATION STAGE 6: Verifying resource requests are set..."
if [ -z "$CPU_REQUEST" ]; then
    echo "❌ FAILED: No CPU request set on container"
    echo "💡 Maslahat: Add resources.requests.cpu to container spec"
    exit 1
fi
MEM_REQUEST=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].resources.requests.memory}')
if [ -z "$MEM_REQUEST" ]; then
    echo "❌ FAILED: No memory request set on container"
    echo "💡 Maslahat: Add resources.requests.memory to container spec"
    exit 1
fi
echo "✅ Resource requests sozlangan (CPU: $CPU_REQUEST, Memory: $MEM_REQUEST)"

echo ""
echo "🎉 SUCCESS! All quota validations o'tdi!"
echo "Your pod is running within namespace resource quotas:"
kubectl describe resourcequota $QUOTA_NAME -n $NAMESPACE | grep -A 6 "Resource"
