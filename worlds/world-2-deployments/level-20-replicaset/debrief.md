# 🎓 Missiya Yakuni: Deployment siz ReplicaSet

## Nima Sodir Bo'ldi

Mustaqil ReplicaSet yaratilgan edi — Deployment siz. ReplicaSet pod lar sonini saqlaydi, lekin **rolling update, rollback va versiya boshqaruvini ta'minlamaydi**.

Image yangilaganda mavjud pod lar o'zgarmadi — ularni qo'lda o'chirish kerak edi!

## Kubernetes Qanday Ishladi

### Abstraksiya Qatlamlari

```
Deployment (yuqori daraja — SIZ ishlatasiz)
    │
    ├── Yangi image → Yangi ReplicaSet yaratadi
    ├── Rolling update → Eski RS kamaytirish, yangi RS ko'paytirish
    ├── Rollback → Eski RS ga qaytish
    └── Tarix → Barcha versiyalarni eslab qoladi
        │
        ▼
ReplicaSet (past daraja — Deployment BOSHQARADI)
    │
    ├── Kerakli pod soni = 3 → 3 pod yaratadi
    ├── Pod o'lsa → yangi pod yaratadi
    └── Image o'zgarsa → HECH NARSA QILMAYDI (mavjud pod larga tegmaydi)
        │
        ▼
Pod lar (eng past daraja)
```

### Nima Uchun To'g'ridan-to'g'ri ReplicaSet Ishlatmaslik Kerak

```
MUAMMO: Image yangilash

ReplicaSet bilan:
  1. kubectl set image rs/web app=nginx:v2
  2. ReplicaSet spec yangilandi ✅
  3. Lekin MAVJUD pod lar hali ham nginx:v1 ❌
  4. Qo'lda pod larni o'chirish kerak
  5. Yangi pod lar nginx:v2 bilan yaratiladi
  6. ROLLBACK IMKONSIZ — eski spec yo'qoldi

Deployment bilan:
  1. kubectl set image deploy/web app=nginx:v2
  2. Deployment YANGI ReplicaSet yaratadi (nginx:v2)
  3. Yangi RS ko'payadi, eski RS kamayadi (rolling update)
  4. Barcha pod lar yangi versiyada ✅
  5. Rollback: kubectl rollout undo — DARHOL eski versiyaga qaytadi
```

## To'g'ri Tushuncha Modeli

**DOIM Deployment ishlating, ReplicaSet ni qo'lda yaratmang.**

ReplicaSet mustaqil ishlatish holatlari deyarli yo'q. Agar ko'rsangiz — bu odatda xato yoki legacy konfiguratsiya.

```
✅ TO'G'RI                    ❌ NOTO'G'RI
kubectl create deploy web     kubectl create rs web-rs
  --image=nginx                 (to'g'ridan-to'g'ri)
```

## O'zlashtirilgan Buyruqlar

```bash
# ReplicaSet va Deployment larni ko'rish
kubectl get deployments,replicasets -n <namespace>

# Deployment yaratish (to'g'ri usul)
kubectl create deployment web --image=nginx --replicas=3

# ReplicaSet egasini tekshirish (ownerReferences)
kubectl get rs <nom> -o yaml | grep -A 5 ownerReferences
# Agar bo'sh — mustaqil RS, Deployment ga aylantiring!
```

## Keyingi Qadam

- ✅ Deployment va ReplicaSet farqi
- ✅ Abstraksiya qatlamlari
- ✅ Nima uchun to'g'ridan-to'g'ri RS ishlatmaslik kerak

🎉 **Tabriklaymiz! World 2 yakunlandi!** Keyingi: World 3 — Networking!

---

💡 **Pro maslahat**: `kubectl get rs` buyrug'i bilan ReplicaSet larni ko'ring. Agar OWNER ustunida Deployment nomi ko'rinsa — to'g'ri. Agar bo'sh bo'lsa — xato, Deployment ga aylantiring.
