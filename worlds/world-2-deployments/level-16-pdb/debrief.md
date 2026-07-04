# 🎓 Missiya Yakuni: PDB Barcha Eviction larni Bloklayapti

## Nima Sodir Bo'ldi

PodDisruptionBudget (PDB) `minAvailable: 3` bilan sozlangan edi, lekin deployment da ham aynan 3 ta replika bor edi. Bu "har doim 3 pod ishlashi kerak, lekin jami 3 pod bor" degani — ya'ni **hech qanday pod ni evict qilib bo'lmaydi**.

Natija: `kubectl drain` ishlamaydi, klaster yangilanishlari to'xtaydi, node texnik xizmati mumkin emas.

## Kubernetes Qanday Ishladi

**PDB** — ixtiyoriy buzilishlar (voluntary disruptions) vaqtida minimal mavjudlikni kafolatlaydi:

```
PDB: minAvailable: 3
Replicas: 3
Mavjud pod lar: 3

kubectl drain node-1:
  → Pod evict qilishga urinish
  → PDB tekshirish: "3 - 1 = 2, lekin minAvailable = 3"
  → 2 < 3 → ❌ EVICTION RAD ETILDI
  → Drain qotib qoldi!
```

**Tuzatilgan holat** (minAvailable: 2):
```
PDB: minAvailable: 2
Replicas: 3
Mavjud pod lar: 3

kubectl drain node-1:
  → Pod evict qilishga urinish
  → PDB tekshirish: "3 - 1 = 2, minAvailable = 2"
  → 2 >= 2 → ✅ EVICTION RUXSAT BERILDI
  → Pod boshqa node da qayta yaratiladi
```

## To'g'ri Tushuncha Modeli

**Ikki yondashuv** — ikkalasi ham bir xil natija beradi:

```yaml
# Variant 1: minAvailable — kamida N pod ishlashi kerak
spec:
  minAvailable: 2    # 3 replikadan kamida 2 tasi doim ishlaydi

# Variant 2: maxUnavailable — maksimal N pod to'xtashi mumkin
spec:
  maxUnavailable: 1  # Bir vaqtda faqat 1 pod to'xtashi mumkin
```

**Ixtiyoriy vs Majburiy buzilishlar**:

| Tur | Misollar | PDB himoyalaydi? |
|-----|----------|-----------------|
| **Ixtiyoriy** | kubectl drain, klaster upgrade, autoscaler | ✅ Ha |
| **Majburiy** | Node crash, hardware nosozlik, OOM kill | ❌ Yo'q |

**⚠️ Keng tarqalgan xato**: `minAvailable = replicas` = eviction IMKONSIZ!

## Haqiqiy Voqea Misoli

**Kompaniya**: Fintech (kunlik $50M tranzaksiya)
**Ta'sir**: Klaster yangilanishi 3 hafta kechikdi
**Zarar**: Xavfsizlik yamoqlari qo'llanmadi, audit muvaffaqiyatsiz

**Nima sodir bo'ldi**: Barcha critical service larda `minAvailable = replicas` qo'yilgan edi. Klaster yangilanish vaqtida hech qanday node drain qilib bo'lmadi. 3 hafta davomida xavfsizlik yamoqlarini qo'llab bo'lmadi.

**Yechim**: Barcha PDB larda minAvailable ni replicas - 1 ga o'zgartirdi.

## O'zlashtirilgan Buyruqlar

```bash
# PDB holatini tekshirish
kubectl get pdb -n <namespace>
# ALLOWED ustuniga qarang — 0 bo'lsa muammo!

# PDB tafsilotlari
kubectl describe pdb <nom> -n <namespace>

# PDB ni tahrirlash
kubectl edit pdb <nom> -n <namespace>

# Node drain qilish (PDB ni hurmat qiladi)
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
```

## Keyingi Qadam

- ✅ PDB nima uchun va qachon ishlatish
- ✅ minAvailable va maxUnavailable farqi
- ✅ PDB ni replika soni bilan muvozanatlash

**Keyingi**: Blue-Green deployment lar!

---

💡 **Pro maslahat**: Formulasi oddiy: `minAvailable = replicas - 1` yoki `maxUnavailable = 1`. Bu doim kamida bitta eviction ga ruxsat beradi.
