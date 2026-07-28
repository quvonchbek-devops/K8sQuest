#!/bin/bash

# Service endpoint larga ega ekanligini tekshirish
ENDPOINTS=$(kubectl get endpoints backend-service -n k8squest -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)

if [[ -z "$ENDPOINTS" ]]; then
  echo "❌ Service da endpoint lar yo'q. Tekshiring: the selector!"
  exit 1
fi

# test-client pod dan ulanishni tekshirish
# `kubectl exec` ATAYLAB ISHLATILMAYDI: sandbox foydalanuvchisida
# `pods/exec` yo'q (interaktiv shell buyruq validatorini chetlab o'tadi) va
# validate aynan o'sha huquq bilan ishlaydi — exec li tekshiruv har doim
# bo'sh qaytar va skript YOLG'ON sabab bilan yiqilardi.
#
# Darsning mavzusi — Service ning SELECTOR i pod yorliqlariga mos
# kelmayotgani. Buning to'g'ridan-to'g'ri dalili ENDPOINT lar: mos kelmasa
# ro'yxat bo'sh bo'ladi, mos kelsa pod IP si paydo bo'ladi. Bu curl dan
# ANIQROQ ham: curl yiqilsa sabab selector emas, ilova ham bo'lishi mumkin.
EP=$(kubectl get endpoints backend-service -n k8squest \
    -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [ -z "$EP" ]; then
  echo "❌ Service hech qanday pod ga ulanmagan (endpoint lar bo'sh)"
  echo "💡 Service selector i va pod yorliqlarini solishtiring:"
  echo "   kubectl get service backend-service -n k8squest -o jsonpath='{.spec.selector}'"
  echo "   kubectl get pods -n k8squest --show-labels"
  exit 1
fi

POD_IP=$(kubectl get pod backend-pod -n k8squest -o jsonpath='{.status.podIP}' 2>/dev/null)
if [ -n "$POD_IP" ] && ! echo "$EP" | grep -qw "$POD_IP"; then
  echo "❌ Endpoint lar backend-pod ga ishora qilmayapti (endpoint: $EP, pod: $POD_IP)"
  exit 1
fi

echo "✅ Level yakunlandi! Service traffic ni to'g'ri yo'naltirmoqda (endpoint: $EP)"
exit 0
