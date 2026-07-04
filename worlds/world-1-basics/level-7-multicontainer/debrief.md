# 🎓 Missiya Yakuni: Sidecar Sabotaji

## Nima Sodir Bo'ldi

Pod ingizda ikkita konteyner bor edi: asosiy ilova va log-sidecar. Sidecar mavjud bo'lmagan faylni `tail -f` qilishga urindi va darhol crash bo'ldi. Kubernetes da **pod dagi biron konteyner crash bo'lsa, butun pod sog'lomsiz (unhealthy) hisoblanadi**.

## Kubernetes Qanday Ishladi

Ko'p konteynerli pod lar barcha konteynerlarni **bir xil node da bir vaqtda** ishga tushiradi va **ayrim resurslarni ulashadi**:

- **Tarmoq**: Bir xil IP manzil, localhost orqali aloqa qilish mumkin
- **Volume lar**: volumeMount lar orqali storage ulashish mumkin
- **Hayot sikli**: Pod faqat BARCHA konteynerlar Ready bo'lganda Ready

Pod hayot sikli:
1. Ikkala konteyner ishga tushdi
2. main-app: Muvaffaqiyatli ishga tushdi ✅
3. log-sidecar: Crash bo'ldi (fayl topilmadi) ❌
4. Kubernetes log-sidecar ni qayta ishga tushirdi
5. Yana crash → CrashLoopBackOff
6. Pod "1/2" ready ko'rsatadi (bitta konteyner ishlayapti, bitta muvaffaqiyatsiz)

## To'g'ri Tushuncha Modeli

**Nima uchun ko'p konteynerli pod lar?**

Keng tarqalgan pattern lar:

| Pattern | Asosiy Konteyner | Sidecar Konteyner | Foydalanish |
|---------|-----------------|-------------------|-------------|
| **Sidecar** | Veb ilova | Log yo'naltiruvchi | Loglarni Elasticsearch ga yuborish |
| **Ambassador** | Ilova | Proxy | Tashqi service larga ulanish |
| **Adapter** | Eski ilova | Format konvertor | Loglarni standart formatga o'girish |

**Pod atom birlik sifatida**:
```
┌─────────────────── Pod ───────────────────┐
│  ┌──────────┐        ┌──────────┐        │
│  │  asosiy  │◄─────► │  sidecar │        │
│  │  ilova   │ volume │  logging │        │
│  └──────────┘ ulash  └──────────┘        │
│       ↓                    ↓              │
│  Bir xil tarmoq namespace                 │
│  Bir xil IP: 10.244.0.5                  │
└───────────────────────────────────────────┘
```

**Pod dagi konteyner holatlari**:
- Hammasi Running bo'lishi kerak → Pod Running
- Birortasi crash → Pod kamaytirilgan ready son ko'rsatadi (masalan, 1/2)
- Hammasi crash → Pod CrashLoopBackOff ga tushadi

## Haqiqiy Voqea Misoli

**Kompaniya**: Media streaming platformasi (50M foydalanuvchi)
**Ta'sir**: 12 soat davomida pasaygan xizmat sifati, 2M foydalanuvchi ta'sirlandi
**Zarar**: $3.5M qaytarish (refund) + brend obro'siga zarar

**Nima sodir bo'ldi**:
Platforma sidecar pattern ishlatardi: asosiy konteyner video xizmat qilardi, sidecar metrikalar to'plardi. Oddiy yangilash vaqtida kimdir metrika sidecar ning konfiguratsiya fayl yo'lini `/config/metrics.yaml` dan `/etc/metrics.yaml` ga o'zgartirdi.

Fayl yangi yo'lda yo'q edi. Sidecar crash bo'ldi. Pod "1/2" ready ko'rsatdi. Kubernetes deployment strategiyasi "RollingUpdate" edi, `maxUnavailable: 0` bilan, ya'ni yangi pod lar Ready bo'lmaguncha eski pod larni almashtirolmaydi.

**Natija**: Deployment tiqilib qoldi — yangi pod lar hech qachon to'liq Ready (2/2) bo'lmadi, shuning uchun eski pod lar ishlashda davom etdi. Lekin deployment "jarayonda" deb belgilandi va hech kim tuzatish deploy qilolmadi!

**Nega 12 soat davom etdi**:
- Jamoa deployment muvaffaqiyatli deb o'yladi (replikalarning 75% "ishlayotgan" edi)
- Monitoring faqat pod mavjudligini tekshirardi, readiness ni emas
- Nihoyat `kubectl get pods` orqali barcha yangi pod larda "1/2" ko'rindi
- Loglar tekshirildi: `kubectl logs <pod> -c metrics-sidecar` "file not found" ko'rsatdi

**Yechim**: Konfiguratsiya yo'li to'g'irlandi. Barcha pod lar darhol 2/2 Ready bo'ldi.

**Saboq**:
1. Faqat pod mavjudligini emas, konteyner readiness ni monitoring qiling
2. Sidecar konteynerlarni mustaqil test qiling
3. Tezda muvaffaqiyatsiz bo'lish uchun deployment timeout qo'ying
4. Qisman ready holatdagi pod lar uchun alert sozlang

## O'zlashtirilgan Buyruqlar

```bash
# Pod dagi barcha konteynerlarni ko'rish
kubectl get pod <nom> -n <namespace> -o jsonpath='{.spec.containers[*].name}'

# Ready holatini tekshirish (X/Y konteyner tayyor)
kubectl get pod <nom> -n <namespace>

# Har bir konteyner holatini ko'rish
kubectl describe pod <nom> -n <namespace>

# Aniq konteyner loglarini ko'rish
kubectl logs <pod-nomi> -c <konteyner-nomi> -n <namespace>

# Oldingi konteyner instance loglarini ko'rish (crash bo'lgan bo'lsa)
kubectl logs <pod-nomi> -c <konteyner-nomi> --previous -n <namespace>

# Loglarni real-time kuzatish
kubectl logs <pod-nomi> -c <konteyner-nomi> -f -n <namespace>

# Aniq konteynerda buyruq bajarish
kubectl exec <pod-nomi> -c <konteyner-nomi> -it -n <namespace> -- sh

# Barcha konteynerlardan loglarni oqimda ko'rish
kubectl logs <pod-nomi> --all-containers=true -f -n <namespace>
```

## Ko'p Konteynerli Pod Debug Qilish

Bosqichma-bosqich jarayon:

```bash
# 1. Umumiy pod holatini tekshirish
kubectl get pod <nom> -n <namespace>
# READY ustunida X/Y ga qarang (masalan, 1/2 bitta konteyner muvaffaqiyatsiz)

# 2. Qaysi konteyner muvaffaqiyatsiz ekanini aniqlash
kubectl describe pod <nom> -n <namespace>
# "Container Statuses" bo'limiga qarang

# 3. Muvaffaqiyatsiz konteyner loglarini tekshirish
kubectl logs <pod> -c <muvaffaqiyatsiz-konteyner> -n <namespace>

# 4. Konteyner crash loop da bo'lsa oldingi loglarni tekshirish
kubectl logs <pod> -c <muvaffaqiyatsiz-konteyner> --previous -n <namespace>

# 5. Imkon bo'lsa interaktiv test qilish
kubectl exec <pod> -c <konteyner> -it -n <namespace> -- sh
# Keyin buyruqni qo'lda ishlatib nima muvaffaqiyatsiz bo'lishini ko'ring
```

## Keyingi Qadam

Ko'p konteynerli debug qilishni o'zlashtirgansiz! Keyingi topshiriq: faqat loglarda ko'rinadigan sirli ilova xatosi — log detektivi bo'lish vaqti! 🕵️
