# 🎓 Missiya Yakuni: Blue-Green Noto'g'ri Ketdi

## Nima Sodir Bo'ldi

Ilovaning yangi versiyasini (GREEN) blue-green deployment strategiyasi bilan deploy qildingiz, lekin foydalanuvchilar hali ham eski versiyani (BLUE) ko'rishmoqda.

Asosiy sabab: **Service selector yangi deployment ga yo'naltirilmagan**.

## Kubernetes Qanday Ishladi

Blue-green deployment — **ikkita to'liq deployment** bir vaqtda ishlaydi:

```
┌──────────────────────────────────────────────┐
│ BLUE Deployment (eski)    GREEN Deployment (yangi)  │
│ ┌──────┐ ┌──────┐        ┌──────┐ ┌──────┐        │
│ │Pod-1 │ │Pod-2 │        │Pod-1 │ │Pod-2 │        │
│ │v1.0  │ │v1.0  │        │v2.0  │ │v2.0  │        │
│ └──────┘ └──────┘        └──────┘ └──────┘        │
│     ▲                                              │
│     │ Service selector: version=blue               │
│     │ (MUAMMO: hali eski versiyaga yo'naltirilgan) │
└──────────────────────────────────────────────┘
```

**Tuzatilgan holat** — service selector ni blue → green ga o'zgartirish:

```
Service selector: version=green  ← O'ZGARTIRILDI
                      │
                      ▼
              GREEN Deployment
              ┌──────┐ ┌──────┐
              │Pod-1 │ │Pod-2 │
              │v2.0  │ │v2.0  │
              └──────┘ └──────┘
```

## To'g'ri Tushuncha Modeli

### Blue-Green vs Rolling Update

| Jihat | Blue-Green | Rolling Update |
|-------|-----------|----------------|
| **Almashish** | Bir lahzalik | Bosqichma-bosqich |
| **Rollback** | Service selector qaytarish (soniya) | Rollout undo (daqiqa) |
| **Resurs** | 2x resurs kerak (ikkala versiya) | 1x + maxSurge |
| **Test** | GREEN ni alohida test qilish mumkin | Faqat produkciyada |
| **To'xtash** | Nol | Nol |

### Almashish jarayoni

```bash
# 1. GREEN tayyor ekanini tekshiring
kubectl get pods -l version=green -n k8squest

# 2. Trafikni GREEN ga yo'naltiring
kubectl patch service app-service -n k8squest \
  -p '{"spec":{"selector":{"version":"green"}}}'

# 3. GREEN ishlayotganini tekshiring
kubectl get endpoints app-service -n k8squest

# 4. Muammo bo'lsa — darhol BLUE ga qaytaring (rollback)
kubectl patch service app-service -n k8squest \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

## Haqiqiy Voqea Misoli

**Kompaniya**: Streaming xizmati (5M obunachi)
**Ta'sir**: Yangi versiyaga o'tish 2 soat kechikdi
**Sabab**: Jamoa service selector ni yangilashni UNUTDI

**Saboq**: Blue-green deploy jarayonini avtomatlashtirib, selector almashishni skriptga kiritish kerak.

## O'zlashtirilgan Buyruqlar

```bash
# Deployment larni ko'rish
kubectl get deployments -n <namespace>

# Service selector ni tekshirish
kubectl get svc <nom> -o yaml | grep -A 5 selector

# Endpoint larni tekshirish
kubectl get endpoints <service-nom>

# Selector ni tez o'zgartirish
kubectl patch svc <nom> -p '{"spec":{"selector":{"version":"green"}}}'

# BLUE deployment ni tozalash (GREEN barqaror bo'lgandan keyin)
kubectl delete deployment app-blue -n <namespace>
```

## Keyingi Qadam

- ✅ Blue-green deployment strategiyasi
- ✅ Service selector orqali trafik almashtirish
- ✅ Bir lahzalik rollback imkoniyati

**Keyingi**: Canary deployment lar — faqat kichik foiz foydalanuvchilarga yangi versiyani ko'rsatish!

---

💡 **Pro maslahat**: Blue-green — eng xavfsiz deploy strategiyasi. Rollback = bitta buyruq. Kamchiligi: 2x resurs. Agar resurs cheklangan bo'lsa, canary yoki rolling update ishlating.
