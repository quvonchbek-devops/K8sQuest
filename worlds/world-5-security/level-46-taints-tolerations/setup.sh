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
# Bu skript o'rniga endi validate.sh ning o'zi node ni taint qiladi va
# podni qayta rejalashtiradi. BUG.md CNT-002.
#
# Fayl SAQLANDI: u mualliflarning niyatini ko'rsatadi va platformaga
# setup bosqichi qo'shilsa (sandbox ichida Job da, host da EMAS — P0.2
# host-exec zaifligiga qarang) shu yerdan boshlanadi.
#
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
