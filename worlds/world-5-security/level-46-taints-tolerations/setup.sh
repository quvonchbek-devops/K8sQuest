#!/bin/bash
# O'rnatish skripti
# Node ga taint qo'yadi

set -e

NAMESPACE=${1:-k8squest}
echo "🔧 Taint lar va Toleration lar level o'rnatilmoqda..."

# Birinchi node ni olish
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

if [ -z "$NODE_NAME" ]; then
    echo "❌ Cluster da hech qanday node topilmadi"
    exit 1
fi

echo "📍 Node topildi: $NODE_NAME"

# Node ga taint qo'yish
echo "🚧 Node ga dedicated=gpu:NoSchedule..."
kubectl taint nodes "$NODE_NAME" dedicated=gpu:NoSchedule --overwrite

# Taint ni tekshirish
echo "✅ Node taint lari:"
kubectl get node "$NODE_NAME" -o jsonpath='{.spec.taints}'
echo ""

echo ""
echo "✅ Setup complete! Node is tainted - pods need tolerations to schedule."
