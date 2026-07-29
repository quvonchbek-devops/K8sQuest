#!/bin/bash
#
# ⚠️  BU SKRIPT PLATFORMA TOMONIDAN ISHGA TUSHIRILMAYDI.
#
# `setup.sh` importer ning ruxsat ro'yxatida YO'Q (k8s-dojo:
# `services/content/importer.go`), ya'ni u bazaga umuman import
# qilinmaydi. Kontent mualliflari mavjud deb o'ylagan "setup bosqichi"
# hech qachon mavjud bo'lmagan — level lar esa unga tayangan va shu
# sababdan buzuq edi (BUG.md CNT-004).
#
# Bu skript o'rniga endi hint-3 foydalanuvchining O'ZIGA node ni
# yorliqlashni o'rgatadi — dars aynan shu. BUG.md CNT-001.
#
# Fayl SAQLANDI: u mualliflarning niyatini ko'rsatadi va platformaga
# setup bosqichi qo'shilsa (sandbox ichida Job da, host da EMAS — P0.2
# host-exec zaifligiga qarang) shu yerdan boshlanadi.
#
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
