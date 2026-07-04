# 🎯 World 1: Asoslar — Tezkor Ma'lumotnoma

> **Bu sahifani chop etib, klaviaturangiz yonida saqlang!**

## 🔧 Asosiy kubectl Buyruqlari

### Tekshirish va Debug Qilish
```bash
# Pod holatini tekshirish
kubectl get pods -n k8squest

# Pod haqida batafsil ma'lumot
kubectl describe pod <pod-nomi> -n k8squest

# Konteyner loglarini ko'rish
kubectl logs <pod-nomi> -n k8squest

# Ko'p konteynerli pod da aniq konteyner loglarini ko'rish
kubectl logs <pod-nomi> -c <konteyner-nomi> -n k8squest

# Loglarni real-time kuzatish
kubectl logs -f <pod-nomi> -n k8squest

# Crash dan keyingi oldingi konteyner loglarini olish
kubectl logs <pod-nomi> --previous -n k8squest

# Event larni tekshirish (debug qilish uchun muhim!)
kubectl get events -n k8squest --sort-by='.lastTimestamp'

# Ishlayotgan konteynerga interaktiv shell
kubectl exec -it <pod-nomi> -n k8squest -- /bin/sh
```

### Resurslarni Boshqarish
```bash
# Namespace dagi barcha resurslarni ko'rish
kubectl get all -n k8squest

# Pod ni o'chirib qayta yaratish
kubectl delete pod <pod-nomi> -n k8squest
kubectl apply -f <fayl.yaml> -n k8squest

# Qotib qolgan pod ni majburan o'chirish
kubectl delete pod <pod-nomi> -n k8squest --grace-period=0 --force

# Resource quota larni tekshirish
kubectl get resourcequota -n k8squest
kubectl describe resourcequota -n k8squest
```

### YAML Tahrirlash
```bash
# Fayldan o'zgarishlarni apply qilish
kubectl apply -f broken.yaml -n k8squest

# Jonli resursni tahrirlash (xavfli!)
kubectl edit pod <pod-nomi> -n k8squest

# Joriy YAML ni ko'rish
kubectl get pod <pod-nomi> -n k8squest -o yaml

# O'zgarishlarni test qilish uchun dry-run
kubectl apply -f solution.yaml -n k8squest --dry-run=client
```

---

## 🚨 Debug Qilish Oqimi (Flowchart)

```
Pod ishlamayaptimi?
    │
    ├─→ Holat: Pending
    │   ├─→ Tekshiring: kubectl describe pod
    │   ├─→ Qidiring: Yetishmayotgan resurslar, PVC muammolari, node selector
    │   └─→ Tuzating: Request/limit larni sozlang, storage tekshiring, scheduling tuzating
    │
    ├─→ Holat: CrashLoopBackOff
    │   ├─→ Tekshiring: kubectl logs <pod> --previous
    │   ├─→ Qidiring: Ilova xatolari, yetishmayotgan config, noto'g'ri buyruq
    │   └─→ Tuzating: Buyruqni to'g'rilang, config qo'shing, ilova kodini tuzating
    │
    ├─→ Holat: ImagePullBackOff
    │   ├─→ Tekshiring: kubectl describe pod (Events ga qarang)
    │   ├─→ Qidiring: Noto'g'ri image nomi, yo'q tag, shaxsiy registry
    │   └─→ Tuzating: Image nomini to'g'rilang, imagePullSecrets qo'shing
    │
    ├─→ Holat: Running lekin ishlamayapti
    │   ├─→ Tekshiring: kubectl logs <pod>
    │   ├─→ Tekshiring: kubectl get svc (service endpoint lari)
    │   ├─→ Qidiring: Port nomuvofiqlik, label selector xatosi, ilova xatolari
    │   └─→ Tuzating: Port larni moslang, label larni tuzating, ilovani debug qiling
    │
    └─→ Holat: Error/Unknown
        ├─→ Tekshiring: kubectl get events
        ├─→ Tekshiring: kubectl describe pod
        └─→ Qidiring: Node muammolari, API server muammolari, RBAC
```

---

## 💡 Keng Tarqalgan Pattern lar va Yechimlar

### Pattern 1: Crash Loop
**Belgilari:** Pod qayta-qayta ishga tushadi, "Back-off restarting failed container"
**Birinchi Tekshirish:** `kubectl logs <pod> --previous`
**Keng Tarqalgan Sabablar:**
- Noto'g'ri buyruq yoki argumentlar
- Yetishmayotgan environment variable lar
- Ilova kodi xatolari
- Yetishmayotgan dependency lar

### Pattern 2: Image Pull Muvaffaqiyatsizligi
**Belgilari:** ImagePullBackOff, ErrImagePull
**Birinchi Tekshirish:** `kubectl describe pod <pod>` (Events bo'limi)
**Keng Tarqalgan Sabablar:**
- Image nomida imlo xatosi
- Tag yetishmayapti (:latest default bo'lishi mumkin, u mavjud bo'lmasligi mumkin)
- Credential larsiz shaxsiy registry

### Pattern 3: Abadiy Pending
**Belgilari:** Pod Pending da qoladi, hech qachon schedule qilinmaydi
**Birinchi Tekshirish:** `kubectl describe pod <pod>` ("FailedScheduling" qidiring)
**Keng Tarqalgan Sabablar:**
- CPU/xotira yetishmayapti
- PersistentVolumeClaim bog'lanmagan
- Node selector hech qanday node ga mos kelmayapti
- ResourceQuota oshib ketgan

### Pattern 4: Label Selector Nomuvofiqlik
**Belgilari:** Service da endpoint lar yo'q, pod lar tanlanmagan
**Birinchi Tekshirish:**
```bash
kubectl get pods --show-labels -n k8squest
kubectl describe svc <service> -n k8squest
```
**Keng Tarqalgan Sabablar:**
- Label kalit yoki qiymatda imlo xatosi
- Katta-kichik harf sezgirligi (app va App)
- Pod larda label lar yetishmayapti

---

## 🎓 Pro Maslahatlar

### 1-Maslahat: Event lar — Do'stingiz
**Qotib qolganingizda doim event larni tekshiring:**
```bash
kubectl get events -n k8squest --sort-by='.lastTimestamp' | tail -20
```

### 2-Maslahat: Crash dan Keyingi Oldingi Loglar
**Konteyner crash bo'ldimi? O'lishdan oldingi loglarni oling:**
```bash
kubectl logs <pod> --previous -n k8squest
```

### 3-Maslahat: Qisqa Nomlar
```bash
kubectl get po    # pods
kubectl get svc   # services
kubectl get deploy # deployments
kubectl get rs    # replicasets
kubectl get ns    # namespaces
```

### 4-Maslahat: Watch Rejimi
**O'zgarishlarni real-time ko'ring:**
```bash
kubectl get pods -n k8squest -w
# To'xtatish uchun Ctrl+C bosing
```

---

## 📊 Holat Kodlari Ma'lumotnomasei

| Holat | Ma'nosi | Birinchi Tekshirish |
|-------|---------|---------------------|
| `Pending` | Pod qabul qilindi lekin schedule qilinmadi | `kubectl describe pod` → Events |
| `Running` | Pod schedule qilindi, kamida 1 konteyner ishlayapti | `kubectl logs` |
| `Succeeded` | Barcha konteynerlar muvaffaqiyatli tugadi | Hech narsa (bu yaxshi!) |
| `Failed` | Barcha konteynerlar tugadi, kamida 1 muvaffaqiyatsiz | `kubectl logs --previous` |
| `Unknown` | Pod holati noma'lum (node muammosi) | `kubectl get nodes` |
| `CrashLoopBackOff` | Konteyner qayta-qayta crash bo'lmoqda | `kubectl logs --previous` |
| `ImagePullBackOff` | Konteyner image tortib bo'lmayapti | `kubectl describe pod` → Events |

---

## 🚀 Tezkor G'alaba Cheklisti

Level da qotib qolganingizda, bularni tartib bilan sinang:

- [ ] `kubectl get pods -n k8squest` — Holat nima?
- [ ] `kubectl describe pod <pod> -n k8squest` — Events bo'limini tekshiring
- [ ] `kubectl logs <pod> -n k8squest` — Ilova xatolari bormi?
- [ ] `kubectl logs <pod> --previous -n k8squest` — Crash bo'lsa, oldingi loglarni tekshiring
- [ ] `kubectl get events -n k8squest --sort-by='.lastTimestamp'` — Yaqindagi event lar
- [ ] `broken.yaml` ni kutilgan xatti-harakat bilan solishtiring — Nima farq bor?
- [ ] O'yinda `hints` buyrug'ini ishlating — To'g'ri yo'nalish uchun ishora
- [ ] O'yinda `guide` buyrug'ini ishlating — Haqiqatan qotib qolsangiz bosqichma-bosqich yechim

**Eslab qoling:** Maqsad — o'rganish, tezlik emas. Har bir tuzatish NIMA UCHUN ishlashini tushunishga vaqt ajrating!

---

💡 **Pro Maslahat:** Bu ma'lumotnomani o'ynayotganda brauzer tabida ochiq saqlang. Buyruqlarni tez topish uchun Ctrl+F ishlating!

🎮 **O'ynashga tayyormisiz?** `./play.sh` ni ishlating va o'rganishni boshlang!
