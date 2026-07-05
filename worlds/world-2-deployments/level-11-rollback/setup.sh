#!/bin/bash
# Level 11 O'rnatish Skripti
# Bu rollback uchun oldingi revision borligini ta'minlaydi

echo "🔧 Level 11 o'rnatilmoqda: Rollback stsenariy..."
echo ""

# 1-qadam: Ishlaydigan versiyani deploy qilish
echo "📦 Boshlang'ich ishlaydigan versiya deploy qilinmoqda (revision 1)..."
kubectl apply -f setup.yaml

# Deployment tayyor bo'lishini kutish (kengaytirilgan timeout)
echo "⏳ Boshlang'ich deployment barqarorlashishi kutilmoqda..."
kubectl rollout status deployment/web-app -n k8squest --timeout=120s

if [ $? -ne 0 ]; then
    echo "⚠️  Boshlang'ich deployment kutilganidan uzoqroq, lekin davom etilmoqda..."
fi

echo "✅ Revision 1 deploy qilindi"
echo ""

# 2-qadam: Buzilgan versiyaga yangilash
echo "📦 Buzilgan versiyaga yangilanmoqda (revision 2)..."
kubectl apply -f broken.yaml

# Yangilash boshlanishi uchun bir lahza kutish
sleep 5

echo ""
echo "✅ Level 11 o'rnatish tugadi!"
echo ""
echo "📊 Rollback tarixi:"
kubectl rollout history deployment/web-app -n k8squest
echo ""
echo "🎯 Vazifangiz: Deployment noto'g'ri yangilanishda qotib qolgan."
echo "   Ishlaydigan versiyaga qaytish uchun 'kubectl rollout undo' ishlating!"
