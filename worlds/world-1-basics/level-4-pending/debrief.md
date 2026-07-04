# 🎓 Missiya Yakuni: Pending Pod Muammosi

## Nima Sodir Bo'ldi

Pod `Pending` holatida qotib qoldi, chunki 999 ta CPU va 999Gi xotira so'radi — bu klasteringizdagi biron-bir node taqdim eta oladigan miqdordan ancha ko'p. Kubernetes scheduler yetarli resursli node topa olmadi, shuning uchun pod hech qachon ishga tushmadi.

## Kubernetes Qanday Ishladi

**Kubernetes scheduler** pod larni node larga joylashtirish uchun javobgar. Jarayon quyidagicha:

1. **Pod yaratildi**: API server pod manifestingizni qabul qildi
2. **Scheduler kuzatadi**: Yangi schedule qilinmagan pod ni ko'rdi
3. **Filtrlash**: Talablarga mos kelmaydigan node larni chiqarib tashlaydi (resurslar, taint lar, affinity)
4. **Baholash**: Qolgan node larni eng yaxshi mos kelish bo'yicha tartiblaydi
5. **Bog'lash**: Pod ni g'olib node ga tayinlaydi

Pod 3-qadamda muvaffaqiyatsiz bo'ldi — **hech qanday node filtrdan o'tmadi** chunki hech birida 999 ta CPU mavjud emas.

## To'g'ri Tushuncha Modeli

**Resource Requests va Limits**:

- **Requests**: Kafolatlangan minimal resurslar (scheduling uchun ishlatiladi)
- **Limits**: Ruxsat etilgan maksimal resurslar (ishlash vaqtida cheklanadi)

```yaml
resources:
  requests:      # "Menga kamida shuncha kerak"
    memory: "64Mi"
    cpu: "100m"
  limits:        # "Bundan ko'p ishlatishga ruxsat berma"
    memory: "128Mi"
    cpu: "200m"
```

**CPU birliklari**:
- `1` = 1 ta to'liq CPU yadrosi
- `100m` = 0.1 CPU (100 millicore)
- `1000m` = 1 CPU

**Xotira birliklari**:
- `Mi` = Mebibayt (1024²)
- `Gi` = Gibibayt (1024³)
- `M` = Megabayt (1000²)
- `G` = Gigabayt (1000³)

**Node to'lganda nima bo'ladi**:
```
Node sig'imi: 4 CPU, 8Gi xotira
Allaqachon ajratilgan: 3 CPU, 6Gi xotira
Mavjud: 1 CPU, 2Gi xotira

Pod 2 CPU so'raydi → ❌ Schedule qilib bo'lmaydi (CPU yetishmaydi)
Pod 500m CPU, 1Gi xotira so'raydi → ✅ Schedule qilish mumkin
```

## Haqiqiy Voqea Misoli

**Kompaniya**: SaaS startup (100K foydalanuvchi)
**Ta'sir**: 6 soatlik deployment to'xtashi, o'tkazib yuborilgan mahsulot muddati
**Zarar**: $500K ARR qiymatidagi korporativ mijoz yo'qotildi

**Nima sodir bo'ldi**:
Dasturchi "production-grade" blog postidan pod konfiguratsiyasini copy-paste qildi, u har bir microservice uchun `cpu: 2` va `memory: 4Gi` o'rnatgan edi. Ularning dev klasteri kichik node larga ega edi (har biri 2 CPU).

10 ta microservice deploy qilganda, faqat birinchi 1-2 ta pod schedule qilindi. Qolganlari Pending da qoldi.

**Nega 6 soat davom etdi**:
- Dasturchilar klaster muammosi deb o'ylab, ops jamoaga murojaat qildi
- Ops node lar sog'lom emas deb o'ylab, infrastrukturani debug qildi
- 5 soat davomida hech kim `kubectl describe pod` event larini tekshirmadi
- Nihoyat `kubectl get events --sort-by='.lastTimestamp'` orqali aniqlashdi

**Yechim**: Request larni haqiqiy foydalanishga asoslanib `cpu: 100m, memory: 128Mi` ga o'zgartirdi. Barcha pod lar darhol schedule qilindi.

**Saboq**:
1. Kichik resource request lardan boshlang (50-100m CPU, 64-128Mi xotira)
2. `kubectl top pod` bilan haqiqiy foydalanishni monitoring qiling
3. Taxmin emas, haqiqiy ma'lumotlarga asoslanib sozlang

## O'zlashtirilgan Buyruqlar

```bash
# Pod holatini tekshirish
kubectl get pod <nom> -n <namespace>

# Pod nima uchun schedule qilinmayotganini ko'rish (Events muhim!)
kubectl describe pod <nom> -n <namespace>

# Resource request/limit larni tekshirish
kubectl get pod <nom> -n <namespace> -o yaml | grep -A 6 resources:

# Node sig'imi va ajratiladigan resurslarni ko'rish
kubectl describe nodes

# Haqiqiy resurs foydalanishini tekshirish (metrics-server kerak)
kubectl top pod <nom> -n <namespace>
kubectl top nodes

# Barcha klaster event larini vaqt bo'yicha tartiblash
kubectl get events --sort-by='.lastTimestamp' -n <namespace>
```

## Oldini Olish Strategiyalari

1. **Oqilona standart qiymatlar**: Haqiqiy bo'lmagan request larni oldini olish uchun LimitRange lar ishlating
2. **Foydalanishni monitoring qilish**: metrics-server deploy qilib, haqiqiy foydalanishni kuzating
3. **VPA ishlating** (Vertical Pod Autoscaler): Foydalanishga qarab request larni avtomatik sozlaydi
4. **Klaster autoscaling**: Pod lar pending bo'lganda avtomatik node qo'shadi
5. **Admission webhook lar**: Pod larni qabul qilishdan oldin resource request larni tekshiradi
6. **Resource quota lar**: Bitta jamoaning butun klasterni egallashini oldini oladi

## Scheduling Nosozliklarini Tushunish

Pod lar Pending da qolishining keng tarqalgan sabablari:

| Sabab | Event Xabari | Yechim |
|-------|--------------|--------|
| CPU yetishmayapti | `Insufficient cpu` | CPU request ni kamaytiring yoki node qo'shing |
| Xotira yetishmayapti | `Insufficient memory` | Xotira request ni kamaytiring yoki node qo'shing |
| Selector ga mos node yo'q | `node(s) didn't match node selector` | nodeSelector label larini to'g'rilang |
| Taint lar to'sqinlik qilmoqda | `node(s) had taint that pod didn't tolerate` | Toleration qo'shing yoki taint larni olib tashlang |
| Volume mavjud emas | `persistentvolumeclaim not found` | Avval PVC yarating |

## Keyingi Qadam

Siz uchta pod holatini o'zlashtirgansiz:
- ✅ CrashLoopBackOff (noto'g'ri konteyner buyrug'i)
- ✅ ImagePullBackOff (noto'g'ri image manzili)
- ✅ Pending (resurs cheklovlari)

Keyingi: Label lar va selector lar service larni pod larga qanday ulashini o'rganasiz!
