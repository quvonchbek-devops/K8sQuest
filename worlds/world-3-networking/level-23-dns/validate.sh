#!/bin/bash

# Check if client pod can resolve service DNS
LOGS=$(kubectl logs app-client -n k8squest --tail=10 2>/dev/null)

# Check for pg_isready success message with correct service name
if echo "$LOGS" | grep -qE "(database-service|database):5432 - accepting connections"; then
  echo "✅ Level yakunlandi! DNS resolution working"
  echo "   Client muvaffaqiyatli connected to database-service"
  exit 0
else
  echo "❌ DNS resolution failing. Tekshiring: the service name in client pod"
  echo "Maslahat: Service is named 'database-service', not 'database'"
  echo ""
  echo "Oxirgi loglar:"
  echo "$LOGS"
  exit 1
fi
