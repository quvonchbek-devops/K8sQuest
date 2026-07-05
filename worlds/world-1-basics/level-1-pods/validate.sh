#!/bin/bash

echo "🔍 Pod holati tekshirilmoqda..."

# Check pod mavjudligini
if ! kubectl get pod nginx-broken -n k8squest &>/dev/null; then
  echo "❌ Pod 'nginx-broken' k8squest namespace da topilmadi"
  exit 1
fi

# Get pod status
STATUS=$(kubectl get pod nginx-broken -n k8squest -o jsonpath='{.status.phase}' 2>/dev/null)
READY=$(kubectl get pod nginx-broken -n k8squest -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)

echo "   Phase: $STATUS"
echo "   Ready: $READY"

# Check pod ishlayotganligini AND ready
if [[ "$STATUS" == "Running" ]] && [[ "$READY" == "true" ]]; then
  # Buyruq to'g'ri ekanligini tekshirish (not the broken "nginxzz")
  COMMAND=$(kubectl get pod nginx-broken -n k8squest -o jsonpath='{.spec.containers[0].command[0]}' 2>/dev/null)
  
  if [[ "$COMMAND" == "nginxzz" ]]; then
    echo "❌ Pod da hali ham buzilgan 'nginxzz' buyrug'i bor"
    echo "💡 Maslahat: Pod ni o'chirib, to'g'rilangan solution.yaml ni apply qiling"
    exit 1
  fi
  
  echo "✅ Level yakunlandi! Pod to'g'ri ishlayapti"
  exit 0
else
  echo "❌ Pod to'g'ri ishlamayapti"
  echo "💡 Joriy holat: $STATUS"
  echo "💡 Maslahat: Xatolarni ko'rish uchun 'kubectl describe pod nginx-broken -n k8squest' buyrug'ini ishlating"
  exit 1
fi
