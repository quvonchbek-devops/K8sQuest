#!/bin/bash
# O'rnatish skripti
# Node ga accelerator=gpu label qo'yadi

set -e

NAMESPACE=${1:-k8squest}
echo "🔧 Node Affinity level o'rnatilmoqda..."

# Birinchi node ni olish
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

if [ -z "$NODE_NAME" ]; then
    echo "❌ Cluster da hech qanday node topilmadi"
    exit 1
fi

echo "📍 Node topildi: $NODE_NAME"

# Node ni label lash
echo "🏷️  Node ga accelerator=gpu..."
kubectl label node "$NODE_NAME" accelerator=gpu --overwrite

# Label ni tekshirish
echo "✅ Node label lari:"
kubectl get node "$NODE_NAME" --show-labels

echo ""
echo "✅ Setup complete! Node is ready for GPU workload scheduling."
