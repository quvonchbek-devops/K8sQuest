# 🎓 Missiya Yakuni: Deployment Yangilanishi Qotib Qoldi

## Nima Sodir Bo'ldi

Deployment Docker Hub da mavjud bo'lmagan `nginx:nonexistent-v2.0-xyz` image bilan yangi versiyani chiqarishga urindi. Deployment qotib qoldi — ba'zi pod lar eski ishlaydigan versiyada, ba'zilari esa yangi buzilgan versiya bilan ishga tusholmayapti.

Kubernetes ning RollingUpdate strategiyasi eski pod larni ishlashda qoldirish orqali to'liq to'xtashdan himoya qildi.

## Kubernetes Qanday Ishladi

**RollingUpdate Strategiyasi** (Deployment lar uchun standart):

```
1. Yangi pod template bilan yangi ReplicaSet yaratish
2. Yangi ReplicaSet ni ko'paytirish (yangi pod lar yaratish)
3. Yangi pod lar Ready bo'lishini kutish
4. Eski ReplicaSet ni kamaytirish (eski pod larni to'xtatish)
5. Barcha replikalar yangilanguncha takrorlash
```

Deployment **3-qadamda** qotib qoldi — yangi pod lar hech qachon Ready bo'lmadi chunki image mavjud emas. Kubernetes qayta urinishda davom etdi lekin eski pod larni ham ishlashda qoldirdi, xizmatning to'liq to'xtashini oldini oldi!

**Deployment holatlari**:
- **Progressing**: Yangilanish davom etmoqda
- **Complete**: Barcha replikalar yangilangan va sog'lom
- **Failed**: Yangilanish tugata olmadi (shu yerda qotib qoldi!)

## To'g'ri Tushuncha Modeli

**Deployment lar ReplicaSet larni qanday boshqaradi**:

```
Deployment: web-app
├── ReplicaSet (v1 - nginx:1.21) ← 3 pod ishlayapti (eski)
└── ReplicaSet (v2 - nginx:nonexistent) ← 0 pod tayyor (yangi, buzilgan)
```

**Rollback** — bu shunchaki eski ReplicaSet ga qaytarish:
```bash
kubectl rollout undo deployment/web-app -n k8squest
```

Bu quyidagini qiladi:
1. v1 ReplicaSet ni ko'paytirish
2. v2 ReplicaSet ni nolga kamaytirish
3. Natija: barcha pod lar yana ishlaydigan v1 da

**Tarix ko'rish va aniq versiyaga qaytarish**:
```bash
# Rollout tarixini ko'rish
kubectl rollout history deployment/web-app -n k8squest

# Aniq versiyaga qaytarish
kubectl rollout undo deployment/web-app --to-revision=2 -n k8squest
```

## Haqiqiy Voqea Misoli

**Kompaniya**: Onlayn bank (2M kunlik tranzaksiya)
**Ta'sir**: 45 daqiqalik qisman xizmat buzilishi
**Zarar**: $180K yo'qotilgan tranzaksiyalar

**Nima sodir bo'ldi**:
CI/CD pipeline yangi image ni build qildi lekin push qilishda xato bo'ldi.
Deployment mavjud bo'lmagan image tag ga murojaat qildi.
RollingUpdate tufayli eski pod lar ishlashda davom etdi, lekin sig'im 60% ga tushdi.

**Yechim**:
```bash
# 1. Muammoni aniqlash
kubectl rollout status deployment/payment-api
# "Waiting for rollout to finish: 1 out of 3 new replicas have been updated..."

# 2. Rollback
kubectl rollout undo deployment/payment-api

# 3. Tekshirish
kubectl get pods  # Barcha pod lar Running
```

**Saboq**:
- CI/CD da image mavjudligini tekshirish qadami qo'shing
- Rollback jarayonini hujjatlang va mashq qiling
- `kubectl rollout status` ni deploy dan keyin monitoring qiling

## O'zlashtirilgan Buyruqlar

```bash
# Rollout holatini kuzatish
kubectl rollout status deployment/<nom> -n <namespace>

# Rollout tarixini ko'rish
kubectl rollout history deployment/<nom> -n <namespace>

# Oxirgi versiyaga rollback
kubectl rollout undo deployment/<nom> -n <namespace>

# Aniq versiyaga rollback
kubectl rollout undo deployment/<nom> --to-revision=N -n <namespace>

# Rollout ni to'xtatish
kubectl rollout pause deployment/<nom> -n <namespace>

# Rollout ni davom ettirish
kubectl rollout resume deployment/<nom> -n <namespace>

# Deployment ning ReplicaSet larini ko'rish
kubectl get rs -n <namespace>

# Image ni yangilash (yangi rollout boshlash)
kubectl set image deployment/<nom> <konteyner>=<image>:<tag> -n <namespace>
```

## Keyingi Qadam

Endi siz tushunasiz:
- ✅ Rolling update lar qanday ishlashi
- ✅ Deployment qotib qolganda nima qilish
- ✅ Rollback buyruqlari va rollout tarixi
- ✅ ReplicaSet lar va deployment versiyalari

**Keyingi topshiriq**: Liveness probe lar — pod lar sog'ligini tekshirish!

---

💡 **Pro maslahat**: Production da `kubectl rollout undo` eng tezkor tuzatish. Lekin doimiy yechim — CI/CD pipeline ni tuzatish va image mavjudligini oldindan tekshirish.
