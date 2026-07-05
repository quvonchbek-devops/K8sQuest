#!/bin/bash

# Check if client pod ni can resolve service DNS
LOGS=$(kubectl logs app-client -n k8squest --tail=10 2>/dev/null)

# Check for pg_isready success message with correct service name
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
