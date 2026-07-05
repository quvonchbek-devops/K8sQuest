#!/bin/bash

# Client pod service DNS ni hal qila olishini tekshirish
LOGS=$(kubectl logs app-client -n k8squest --tail=10 2>/dev/null)

# pg_isready muvaffaqiyat xabarini to'g'ri service nomi bilan tekshirish
if echo "$LOGS" | grep -qE "(database-service|database):5432 - accepting connections"; then
  echo "✅ Level yakunlandi! DNS resolution ishlayapti"
  echo "   Client muvaffaqiyatli connected to database-service"
  exit 0
else
  echo "❌ DNS resolution muvaffaqiyatsiz. Tekshiring: the service name in client pod ni"
  echo "Maslahat: Service nomi 'database-service', 'database' emas"
  echo ""
  echo "Oxirgi loglar:"
  echo "$LOGS"
  exit 1
fi
