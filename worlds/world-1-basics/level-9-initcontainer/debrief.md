# 🎓 Missiya Yakuni: Init Container Tiqilinchi

## Nima Sodir Bo'ldi

Init container mavjud bo'lmagan service ni kutayotgan edi. Init container lar asosiy konteynerlar ishga tushishidan oldin tugashi kerak, shuning uchun pod "Init:0/1" holatida abadiy qotib qolgan edi.

## Kubernetes Qanday Ishladi

**Init container lar** ilova konteynerlardan oldin ishlaydi va muvaffaqiyatli tugashi kerak:

1. Init container lar ketma-ket ishlaydi (birin-ketin)
2. Har biri 0 (muvaffaqiyat) holati bilan chiqishi kerak
3. Faqat BARCHA init container lar tugagandan keyin ilova konteynerlari ishga tushadi
4. Agar init container muvaffaqiyatsiz bo'lsa, pod qayta ishga tushadi (restartPolicy ga bog'liq)

## To'g'ri Tushuncha Modeli

**Hayot sikli**:
```
Init Container 1 → Init Container 2 → Asosiy Konteyner 1 & Asosiy Konteyner 2
   (ketma-ket)        (ketma-ket)            (parallel)
```

**Keng tarqalgan foydalanish holatlari**:
- Dependency larni kutish (ma'lumotlar bazasi, service lar)
- Git repository larni klonlash
- Konfiguratsiya fayllari yaratish
- Ruxsatlar sozlash
- Ma'lumotlar bazasi schema migration lari

## O'zlashtirilgan Buyruqlar

```bash
# Init container holatini tekshirish
kubectl get pod <nom> -n <namespace>
# "Init:0/1" yoki "Init:Error" ni qidiring

# Init container loglarini ko'rish
kubectl logs <pod> -c <init-konteyner-nomi> -n <namespace>

# Init container tafsilotlarini ko'rish
kubectl describe pod <nom> -n <namespace>
# "Init Containers:" bo'limiga qarang
```

## Keyingi Qadam

Oxirgi level: Namespace izolyatsiya muammolari!
