# Keng Tarqalgan Xatolar - Level 11: Deployment Rollback

## ❌ Xato #1: Tarixni Tekshirmasdan Rollback Qilish

**O'yinchilar nima qiladi:**
```bash
kubectl rollout undo deployment/payment-api -n k8squest
# Hammasini tuzatadi deb umid qilish!
```

**Nima uchun ishlamaydi:**
Standart holatda `undo` BITTA revision ga qaytadi. Lekin agar:
- Muammo 3 ta deployment oldin boshlangan bo'lsa?
- Siz allaqachon bir marta rollback qilgan bo'lsangiz ("undo" oldinga ketadi!)?
- Oldingi versiyada ham muammolar bo'lsa?

**To'g'ri yondashuv:**
```bash
# AVVAL: Tarixni tekshiring
kubectl rollout history deployment/payment-api -n k8squest

# Har bir revision da nimalar o'zgarganini ko'ring
kubectl rollout history deployment/payment-api --revision=2 -n k8squest
kubectl rollout history deployment/payment-api --revision=3 -n k8squest

# KEYIN: Ma'lum yaxshi revision ga rollback qiling
kubectl rollout undo deployment/payment-api --to-revision=2 -n k8squest
```

**Asosiy saboq:**
Ko'r-ko'rona `undo` ishlatishdan oldin doim rollout tarixini ko'rib chiqing. Qaysi revision yaxshi bo'lganini bilishingiz kerak!

---

## ❌ Xato #2: Rollout Tugashini Kutmaslik

**O'yinchilar nima qiladi:**
```bash
kubectl rollout undo deployment/payment-api -n k8squest
./validate.sh  # Immediate validation!
```

**Nima uchun ishlamaydi:**
Rollout lar **asinxron**. Undo buyrug'i darhol qaytadi, lekin haqiqiy rollout vaqt oladi (yangi pod lar yaratish, eskilarni to'xtatish).

**To'g'ri yondashuv:**
```bash
# Rollback ni boshlash
kubectl rollout undo deployment/payment-api --to-revision=2 -n k8squest

# Tugashini KUTING
kubectl rollout status deployment/payment-api -n k8squest

# Yoki pod o'zgarishlarini kuzating
kubectl get pods -n k8squest -w
# Press Ctrl+C when all pods are Running

# ENDI tekshiring
./validate.sh
```

**Asosiy saboq:**
`kubectl rollout status` bilan rollout tugashini kuting. Pod lar hali yangilanayotganda validatsiya qilmang!

---

## ❌ Xato #3: ReplicaSet larni Revision lar Bilan Aralashtirish

**O'yinchilar nima qiladi:**
```bash
kubectl get rs -n k8squest
# See multiple ReplicaSets
# Eskilarni o'chirish yordam beradi deb o'ylash
kubectl delete rs payment-api-abc123 -n k8squest
```

**Nima uchun ishlamaydi:**
Har bir deployment revision ReplicaSet yaratadi. Eski ReplicaSet lar rollback tarixi uchun saqlanadi. Ularni o'chirish:
- Rollback qilish imkoniyatingizni yo'qotadi
- Joriy deployment ni tuzatmaydi
- Rollout boshqaruvida muammolar keltirib chiqarishi mumkin

**To'g'ri yondashuv:**
```bash
# ReplicaSet larni ko'ring (lekin o'chirmang)
kubectl get rs -n k8squest -l app=payment-api

# Qaysi ReplicaSet faol ekanini ko'ring (pod larga ega)
kubectl describe deployment payment-api -n k8squest | grep -A 5 "NewReplicaSet"

# Deployment ReplicaSet larni boshqarsin — hech qachon qo'lda o'chirmang
```

**Asosiy saboq:**
ReplicaSets = Deployment's internal mechanism for version control. Ularni bevosita boshqarmang!

---

## ❌ Xato #4: Rollback Nima Uchun Kerakligini Unutish

**O'yinchilar nima qiladi:**
Faqat rollback buyrug'ini bajarishga e'tibor berish, deployment NIMA UCHUN muvaffaqiyatsiz bo'lganini tushunishni unutish.

**Nima uchun ishlamaydi:**
Siz muvaffaqiyatli rollback qilishingiz mumkin, lekin o'rganmasligingiz mumkin:
- Yangi versiyada nima noto'g'ri ketdi?
- Kelajakda buni qanday oldini olish?
- Deploy qilishdan oldin nimani tekshirish kerak?

**To'g'ri yondashuv:**
```bash
# ROLLBACK DAN OLDIN: Nosozlikni tushuning
kubectl describe deployment payment-api -n k8squest
kubectl get pods -n k8squest
kubectl logs deployment/payment-api -n k8squest

# KEYIN rollback qiling
kubectl rollout undo deployment/payment-api --to-revision=2 -n k8squest

# ROLLBACK DAN KEYIN: Farqni tekshiring
kubectl rollout history deployment/payment-api --revision=2 -n k8squest
kubectl rollout history deployment/payment-api --revision=3 -n k8squest
```

**Asosiy saboq:**
Rollback — tiklash mexanizmi, o'rganish yorlig'i emas. Takrorlanishni oldini olish uchun nosozlikni tushuning!

---

## ❌ Xato #5: Rollout Tarix Limitini Tekshirmaslik

**O'yinchilar nima qiladi:**
10 ta revision oldingi holatga qaytishni kutish.

**Nima uchun ishlamaydi:**
Deployment larda `revisionHistoryLimit` bor (standart: 10). 10 ta deployment dan keyin eski ReplicaSet lar avtomatik tozalanadi.

**To'g'ri yondashuv:**
```yaml
# In deployment spec
spec:
  revisionHistoryLimit: 10  # Adjust if needed
  # ...
```

```bash
# Check how many revisions are kept
kubectl get deployment payment-api -n k8squest -o jsonpath='{.spec.revisionHistoryLimit}'

# See available history
kubectl rollout history deployment/payment-api -n k8squest
```

**Asosiy saboq:**
Faqat `revisionHistoryLimit` ruxsat bergancha orqaga qaytishingiz mumkin. Standart — 10 ta revision.

---

## ❌ Xato #6: Rollback Uchun `kubectl edit` Ishlatish

**O'yinchilar nima qiladi:**
```bash
kubectl edit deployment payment-api -n k8squest
# Manually change image tag back to old version
```

**Nima uchun ishlamaydi:**
Bu rollback emas, YANGI revision yaratadi. Siz:
- Toza rollback tarixini yo'qotasiz
- Qaysi revision qaysi ekanini aralashtirish
- Imlo xatolari kiritishingiz mumkin

**To'g'ri yondashuv:**
```bash
# To'g'ri rollback buyrug'ini ishlating
kubectl rollout undo deployment/payment-api --to-revision=2 -n k8squest

# kubectl edit EMAS!
```

**Asosiy saboq:**
`kubectl edit` = yangi deployment. `kubectl rollout undo` = tarix saqlanib qoladigan to'g'ri rollback.

---

## ❌ Xato #7: Noto'g'ri Resursni Tekshirish

**O'yinchilar nima qiladi:**
```bash
# Check pods directly
kubectl get pods -n k8squest

# Don't check deployment status
```

**Nima uchun ishlamaydi:**
Rollout lar vaqtida pod lar keladi va ketadi. Deployment quyidagilar uchun haqiqat manbai:
- Kerakli holat
- Rollout jarayoni
- Mavjud replica lar

**To'g'ri yondashuv:**
```bash
# Avval Deployment ni tekshiring
kubectl get deployment payment-api -n k8squest

# Output shows:
# NAME          READY   UP-TO-DATE   AVAILABLE
# payment-api   3/3     3            3

# READY = current/desired
# UP-TO-DATE = pods with latest template
# AVAILABLE = pods passing readiness checks
```

**Asosiy saboq:**
Deployment lar pod larni boshqaradi. Faqat alohida pod larni emas, Deployment holatini tekshiring.

---

## ❌ Xato #8: Rollout Status Natijasini Tushunmaslik

**O'yinchilar nima qiladi:**
```bash
kubectl rollout status deployment/payment-api -n k8squest
# See "Waiting for deployment spec update to be observed..."
# Think it's broken
```

**Nima uchun ishlamaydi:**
Bu xabar normal! Bu Kubernetes rollback ingizni qayta ishlayotganini bildiradi. Boshqa normal xabarlar:
- "Waiting for deployment spec update..." (Deployment spec yangilanishini kutish)
- "Waiting for rollout to finish: X out of Y new replicas..." (Rollout tugashini kutish)
- "deployment successfully rolled out" ← Muvaffaqiyat!

**To'g'ri yondashuv:**
```bash
kubectl rollout status deployment/payment-api -n k8squest
# KUTING: "deployment successfully rolled out" xabari chiqguncha
# If it hangs, Ctrl+C and check:
kubectl describe deployment payment-api -n k8squest
kubectl get events -n k8squest --sort-by='.lastTimestamp'
```

**Asosiy saboq:**
`kubectl rollout status` real-time jarayonni ko'rsatadi. "successfully rolled out" xabarini kuting.

---

## 💡 Debug Qilish Tartibi — To'g'ri Usul

Mana tizimli rollback yondashuvi:

```bash
# 1. Identify the problem
kubectl get deployment payment-api -n k8squest
kubectl get pods -n k8squest
kubectl logs deployment/payment-api -n k8squest

# 2. Check rollout history
kubectl rollout history deployment/payment-api -n k8squest

# 3. Identify last known good revision
kubectl rollout history deployment/payment-api --revision=2 -n k8squest

# 4. Initiate rollback to specific revision
kubectl rollout undo deployment/payment-api --to-revision=2 -n k8squest

# 5. Tugashini kuting
kubectl rollout status deployment/payment-api -n k8squest

# 6. Verify success
kubectl get deployment payment-api -n k8squest
kubectl get pods -n k8squest

# 7. Test functionality (if applicable)
kubectl logs deployment/payment-api -n k8squest

# 8. Validate
./validate.sh
```

---

## 🎯 Asosiy Xulosalar

1. **Rollback dan oldin tarixni tekshiring** — maqsadli revision ni biling
2. **`--to-revision=N` ishlating** — standart "undo" ga tayanmang
3. **Wait for rollout completion** - Use `kubectl rollout status`
4. **ReplicaSet larni qo'lda o'chirmang** — Deployment ularni boshqaradi
5. **Nosozlikni tushuning** — rollback qilishdan oldin nima noto'g'ri ketganini o'rganing
6. **Deployment holatini tekshiring** — faqat alohida pod larni emas
7. **To'g'ri rollback buyruqlarini ishlating** — `kubectl edit` emas
8. **Revision tarixi cheklangan** — standart 10, abadiy orqaga qaytib bo'lmaydi

---

## 📊 Rollout Tarixi Tushuntirish

```bash
$ kubectl rollout history deployment/payment-api -n k8squest
REVISION  CHANGE-CAUSE
1         Initial deployment
2         Updated to v1.2.0
3         Updated to v1.3.0 (BROKEN)

# Current = Revision 3
# kubectl rollout undo → Goes to Revision 2
# kubectl rollout undo --to-revision=1 → Goes to Revision 1
```

**Har bir revision ReplicaSet sifatida saqlanadi:**
- Revision 1 → payment-api-abc123 (0 pods)
- Revision 2 → payment-api-def456 (0 pods)
- Revision 3 → payment-api-ghi789 (3 pods) ← Current

**Revision 2 ga rollback qilingandan keyin:**
- Revision 2 → payment-api-def456 (3 pods) ← Now current
- Revision 3 → payment-api-ghi789 (0 pods)
- Revision 4 created (same as revision 2)

---

## 📚 Bu Leveldan Keyin Bilishingiz Kerak

✅ Deployment rollout tarixini qanday ko'rish  
✅ Aniq revision ga qanday rollback qilish  
✅ Rollout tugashini qanday kutish  
✅ ReplicaSet va revision lar o'rtasidagi aloqani tushunish  
✅ Muvaffaqiyatli rollback ni qanday tekshirish  
✅ `undo` va `edit` o'rtasidagi farq  
✅ Deployment status natijasini qanday o'qish  

**Keyingi Level:** Level 12 da liveness probe lar — deployment muvaffaqiyatli lekin pod lar qayta ishga tusha berayotganda!
