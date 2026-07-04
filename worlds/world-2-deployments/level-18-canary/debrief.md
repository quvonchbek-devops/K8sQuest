# 🎓 Missiya Yakuni: Canary Og'irlik Nomutanosibligi

## Nima Sodir Bo'ldi

Canary deployment da replika nisbatlari noto'g'ri edi: stable 5, canary 5 — bu 50/50 trafik taqsimoti berdi. Canary test uchun bu juda ko'p! Odatda 90/10 yoki 95/5 kerak.

## Kubernetes Qanday Ishladi

Canary deployment — yangi versiyani **kichik foiz foydalanuvchilarga** ko'rsatish:

```
MAQSAD: 90% stable, 10% canary

NOTO'G'RI (50/50):
  app-stable: 5 replika  → 5/10 = 50% trafik
  app-canary:  5 replika  → 5/10 = 50% trafik  ❌ Juda ko'p!

TO'G'RI (90/10):
  app-stable: 9 replika  → 9/10 = 90% trafik  ✅
  app-canary:  1 replika  → 1/10 = 10% trafik  ✅
```

**Trafik taqsimoti** — Service **barcha** mos pod larga teng yo'naltiradi:
```
Service selector: app=myapp
  → stable pod lar (app=myapp, version=stable) ← 9 ta
  → canary pod lar (app=myapp, version=canary) ← 1 ta
  Jami: 10 pod, har biri ~10% trafik oladi
```

## To'g'ri Tushuncha Modeli

### Canary Jarayoni

```
1. Yangi versiyani 1 replika bilan deploy qiling (canary)
   → kubectl scale deployment app-canary --replicas=1

2. Monitoring qiling:
   - Xato darajasi (error rate)
   - Javob vaqti (latency)
   - Foydalanuvchi shikoyatlari

3. Yaxshi bo'lsa — canary ni asta-sekin ko'paytiring:
   10% → 25% → 50% → 100%

4. Muammo bo'lsa — canary ni 0 ga tushiring (rollback):
   kubectl scale deployment app-canary --replicas=0
```

### Replika nisbatlari

| Maqsad | Stable | Canary | Jami |
|--------|--------|--------|------|
| 99/1 | 99 | 1 | 100 |
| 95/5 | 19 | 1 | 20 |
| 90/10 | 9 | 1 | 10 |
| 75/25 | 3 | 1 | 4 |
| 50/50 | 1 | 1 | 2 |

⚠️ Kubernetes native canary faqat pod soni orqali ishlaydi. Aniq foiz kerak bo'lsa Istio yoki Nginx Ingress controller ishlating.

## Haqiqiy Voqea Misoli

**Kompaniya**: Ijtimoiy tarmoq (20M foydalanuvchi)
**Ta'sir**: Yangi algoritm 50% foydalanuvchilarga ko'rsatildi, engagement 30% tushdi
**Sabab**: Canary 50/50 qo'yilgan edi, 5% bo'lishi kerak edi

**Saboq**: Canary DOIM kichik foizda boshlang (1-5%), asta-sekin ko'paytiring.

## O'zlashtirilgan Buyruqlar

```bash
# Canary nisbatini sozlash
kubectl scale deployment app-stable --replicas=9
kubectl scale deployment app-canary --replicas=1

# Nisbatni tekshirish
kubectl get deployments -n <namespace>

# Canary ni rollback qilish
kubectl scale deployment app-canary --replicas=0

# Canary muvaffaqiyatli — to'liq rollout
kubectl scale deployment app-canary --replicas=0
kubectl set image deployment/app-stable app=myapp:v2.0
```

## Keyingi Qadam

- ✅ Canary deployment strategiyasi
- ✅ Replika nisbatlari orqali trafik boshqarish
- ✅ Canary monitoring va rollback

**Keyingi**: StatefulSet — stateful ilovalar uchun!

---

💡 **Pro maslahat**: Canary deploy qilganda DOIM monitoring dashboardini ochib qo'ying. Xato darajasi yoki latency oshsa — darhol `--replicas=0` qiling.
