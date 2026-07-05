#!/bin/bash

# NodePort aniq sozlanganligini tekshirish
NODEPORT=$(kubectl get svc web-nodeport -n k8squest -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

if [[ -z "$NODEPORT" ]]; then
  echo "❌ Service topilmadi"
  exit 1
fi

# NodePort to'g'ri oraliqda va aniq sozlanganligini tekshirish (30080)
if [[ "$NODEPORT" == "30080" ]]; then
  echo "✅ Level yakunlandi! NodePort aniq sozlangan"
  exit 0
else
  echo "❌ NodePort is $NODEPORT (random). Set nodePort: 30080 explicitly"
  exit 1
fi
