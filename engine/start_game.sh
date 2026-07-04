#!/bin/bash
set -e

WORLD_DIR="worlds/world-1-basics"

for LEVEL in "$WORLD_DIR"/*; do
  echo "=================================="
  echo "▶ Boshlanmoqda $(basename $LEVEL)"
  echo "=================================="

  kubectl delete namespace k8squest --ignore-not-found
  kubectl create namespace k8squest

  kubectl apply -n k8squest -f "$LEVEL/broken.yaml"

  echo "❌ Missiya deploy qilindi. Muammoni tuzating."
  echo "Tekshirishga tayyor bo'lganingizda ENTER bosing"
  read

  sh "$LEVEL/validate.sh"

done

echo "🎉 World 1 yakunlandi!"
