#!/bin/bash

NAMESPACE="k8squest"
POD_NAME="regular-app"
# Node nomi QOTIRILMAYDI — u har muhitda boshqacha.
#
# Ilgari bu yerda `kind-control-plane` turardi. Bizning klasterlarda
# bunday node YO'Q (dev da `dev`, nested da `dojo-cluster-<id>`), ya'ni
# quyidagi `kubectl taint` JIMGINA yiqilardi va node hech qachon taint
# qilinmasdi. Natijada `regular-app` toleration siz ham DARHOL Running
# bo'lar va darsning butun sharti ("pod Pending, chunki node taint
# qilingan") umuman ko'rinmasdi — foydalanuvchi mavjud bo'lmagan
# muammoni "tuzatardi".
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$NODE_NAME" ]; then
    echo "❌ Node topilmadi — klasterga ulanib bo'lmadi"
    exit 1
fi

echo "🔍 TEKSHIRUV 1-BOSQICH: Tekshirilmoqda node taint qilinganligini..."
NODE_TAINTS=$(kubectl get node $NODE_NAME -o jsonpath='{.spec.taints[?(@.key=="dedicated")]}')
if [ -z "$NODE_TAINTS" ]; then
    echo "⚠️  Node hali taint qilinmagan. Taint qo'yilmoqda..."
    if ! kubectl taint nodes "$NODE_NAME" dedicated=gpu:NoSchedule --overwrite; then
        echo "❌ Node ni taint qilib bo'lmadi ($NODE_NAME)"
        exit 1
    fi
    echo "✅ Node taint qilindi: dedicated=gpu:NoSchedule"

    # Pod ni QAYTA rejalashtiramiz.
    #
    # `NoSchedule` faqat YANGI rejalashtirishga ta'sir qiladi — allaqachon
    # ishlab turgan pod ni u joyidan qo'zg'atmaydi. Setup esa broken.yaml ni
    # taint dan OLDIN qo'llaydi, ya'ni pod bemalol joylashib bo'lgan bo'ladi.
    #
    # Natijada darsning butun sharti ("pod Pending, chunki node taint
    # qilingan") umuman ko'rinmasdi va foydalanuvchi mavjud bo'lmagan
    # muammoni "tuzatardi".
    #
    # Bu shox FAQAT birinchi tekshiruvda ishlaydi (taint hali yo'q payt),
    # ya'ni foydalanuvchining ishi yo'qolmaydi: o'sha paytda pod hali
    # broken.yaml dan kelgan asl holatda.
    if kubectl get pod "$POD_NAME" -n "$NAMESPACE" &>/dev/null; then
        echo "   Pod qayta rejalashtirilmoqda (taint kuchga kirsin)..."
        # `spec.nodeName` OLIB TASHLANADI — bu yerda butun gap shunda.
        #
        # Rejalashtirilgan pod ning yaml ida `nodeName: <node>` yozib
        # qo'yilgan bo'ladi. Uni o'sha holicha `replace --force` qilsak,
        # pod SCHEDULER ni umuman chetlab o'tadi: kubelet uni to'g'ridan-
        # to'g'ri ishga tushiradi va NoSchedule taint hech qanday rol
        # o'ynamaydi. O'lchab ko'rdim — pod 3 soniya Pending ko'rinib,
        # keyin toleration SIZ o'zicha Running bo'lib ketardi, ya'ni
        # tekshiruv tasodifan "to'g'ri" javob berardi.
        #
        # `jq` ishlatilmaydi: u validate image ida yo'q.
        kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o yaml \
            | sed '/^  nodeName:/d' \
            | kubectl replace --force --grace-period=0 -f - &>/dev/null
        sleep 5
    fi
else
    echo "✅ Node has taint: dedicated=gpu"
fi

echo ""
echo "🔍 TEKSHIRUV 2-BOSQICH: Tekshirilmoqda pod mavjudligini..."
if ! kubectl get pod $POD_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ FAILED: Pod '$POD_NAME' topilmadi"
    exit 1
fi
echo "✅ Pod mavjud"

echo ""
echo "🔍 TEKSHIRUV 3-BOSQICH: Tekshirilmoqda pod Running holatida ekanligini (Pending emas)..."
POD_STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" = "Pending" ]; then
    echo "❌ FAILED: Pod is still Pending"
    echo "💡 Maslahat: Tekshiring: pod events: kubectl describe pod $POD_NAME -n $NAMESPACE"
    echo "💡 Maslahat: Pod needs toleration matching node taint"
    exit 1
fi
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ FAILED: Pod is in '$POD_STATUS' state"
    exit 1
fi
echo "✅ Pod Running holatida"

echo ""
echo "🔍 TEKSHIRUV 4-BOSQICH: Tekshirilmoqda pod da toleration lar sozlanganligini..."
TOLERATIONS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.tolerations}')
if [ -z "$TOLERATIONS" ] || [ "$TOLERATIONS" = "null" ]; then
    echo "❌ FAILED: No tolerations sozlangan on pod"
    echo "💡 Maslahat: Add tolerations to spec.tolerations"
    exit 1
fi
echo "✅ Toleration lar sozlangan"

echo ""
echo "🔍 TEKSHIRUV 5-BOSQICH: Tekshirilmoqda toleration taint ga mos kelishini..."
TOLERATION_KEY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.tolerations[?(@.key=="dedicated")].key}')
if [ "$TOLERATION_KEY" != "dedicated" ]; then
    echo "❌ FAILED: Toleration key doesn't match taint key 'dedicated'"
    echo "💡 Maslahat: Toleration key must match taint key exactly"
    exit 1
fi
echo "✅ Toleration kaliti taint ga mos keladi"

echo ""
echo "🔍 TEKSHIRUV 6-BOSQICH: Tekshirilmoqda pod scheduled on tainted node..."
SCHEDULED_NODE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.nodeName}')
echo "✅ Pod scheduled on node: $SCHEDULED_NODE"

echo ""
echo "🎉 SUCCESS! Pod tolerates node taint and is running!"
echo ""
echo "Taint tafsilotlari:"
kubectl get node $SCHEDULED_NODE -o jsonpath='{.spec.taints[?(@.key=="dedicated")]}' | jq '.'
echo ""
echo "Toleration tafsilotlari:"
kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.tolerations[?(@.key=="dedicated")]}' | jq '.'
