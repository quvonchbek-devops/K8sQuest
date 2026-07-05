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

# See what changed in each revision
kubectl rollout history deployment/payment-api --revision=2 -n k8squest
kubectl rollout history deployment/payment-api --revision=3 -n k8squest

# THEN: Rollback to known good revision
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

# WAIT for it to complete
kubectl rollout status deployment/payment-api -n k8squest

# Or watch pods change
kubectl get pods -n k8squest -w
# Press Ctrl+C when all pods are Running

# NOW validate
./validate.sh
```

**Asosiy saboq:**
`kubectl rollout status` bilan rollout tugashini kuting. Pod lar hali yangilanayotganda validatsiya qilmang!

---

## ❌ Mistake #3: Confusing ReplicaSets with Revisions

**O'yinchilar nima qiladi:**
```bash
kubectl get rs -n k8squest
# See multiple ReplicaSets
# Delete the old ones thinking it will help
kubectl delete rs payment-api-abc123 -n k8squest
```

**Nima uchun ishlamaydi:**
Har bir deployment revision ReplicaSet yaratadi. Eski ReplicaSet lar rollback tarixi uchun saqlanadi. Ularni o'chirish:
- Removes your rollback ability
- Doesn't fix the current deployment
- Can cause issues with rollout management

**To'g'ri yondashuv:**
```bash
# View ReplicaSets (but don't delete them)
kubectl get rs -n k8squest -l app=payment-api

# See which ReplicaSet is active (has pods)
kubectl describe deployment payment-api -n k8squest | grep -A 5 "NewReplicaSet"

# Let Deployment manage ReplicaSets - never delete manually
```

**Asosiy saboq:**
ReplicaSets = Deployment's internal mechanism for version control. Don't touch them directly!

---

## ❌ Mistake #4: Forgetting Why Rollback is Needed

**O'yinchilar nima qiladi:**
Faqat rollback buyrug'ini bajarishga e'tibor berish, deployment NIMA UCHUN muvaffaqiyatsiz bo'lganini tushunishni unutish.

**Nima uchun ishlamaydi:**
Siz muvaffaqiyatli rollback qilishingiz mumkin, lekin o'rganmasligingiz mumkin:
- Yangi versiyada nima noto'g'ri ketdi?
- Kelajakda buni qanday oldini olish?
- What to check before deploying?

**To'g'ri yondashuv:**
```bash
# BEFORE rollback: Understand the failure
kubectl describe deployment payment-api -n k8squest
kubectl get pods -n k8squest
kubectl logs deployment/payment-api -n k8squest

# THEN rollback
kubectl rollout undo deployment/payment-api --to-revision=2 -n k8squest

# AFTER rollback: Verify the difference
kubectl rollout history deployment/payment-api --revision=2 -n k8squest
kubectl rollout history deployment/payment-api --revision=3 -n k8squest
```

**Asosiy saboq:**
Rollback — tiklash mexanizmi, o'rganish yorlig'i emas. Takrorlanishni oldini olish uchun nosozlikni tushuning!

---

## ❌ Mistake #5: Not Checking Rollout History Limit

**O'yinchilar nima qiladi:**
Expect to roll back 10 revisions ago.

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

## ❌ Mistake #6: Using `kubectl edit` for Rollback

**O'yinchilar nima qiladi:**
```bash
kubectl edit deployment payment-api -n k8squest
# Manually change image tag back to old version
```

**Nima uchun ishlamaydi:**
Bu rollback emas, YANGI revision yaratadi. Siz:
- Lose the clean rollback history
- Qaysi revision qaysi ekanini aralashtirish
- May introduce typos

**To'g'ri yondashuv:**
```bash
# Use the proper rollback command
kubectl rollout undo deployment/payment-api --to-revision=2 -n k8squest

# NOT kubectl edit!
```

**Asosiy saboq:**
`kubectl edit` = new deployment. `kubectl rollout undo` = proper rollback with history intact.

---

## ❌ Mistake #7: Checking Wrong Resource

**O'yinchilar nima qiladi:**
```bash
# Check pods directly
kubectl get pods -n k8squest

# Don't check deployment status
```

**Nima uchun ishlamaydi:**
Rollout lar vaqtida pod lar keladi va ketadi. Deployment quyidagilar uchun haqiqat manbai:
- Desired state
- Rollout progress
- Available replicas

**To'g'ri yondashuv:**
```bash
# Check Deployment first
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

## ❌ Mistake #8: Not Understanding Rollout Status Output

**O'yinchilar nima qiladi:**
```bash
kubectl rollout status deployment/payment-api -n k8squest
# See "Waiting for deployment spec update to be observed..."
# Think it's broken
```

**Nima uchun ishlamaydi:**
Bu xabar normal! Bu Kubernetes rollback ingizni qayta ishlayotganini bildiradi. Boshqa normal xabarlar:
- "Waiting for deployment spec update..."
- "Waiting for rollout to finish: X out of Y new replicas..."
- "deployment successfully rolled out" ← Success!

**To'g'ri yondashuv:**
```bash
kubectl rollout status deployment/payment-api -n k8squest
# WAIT for: "deployment successfully rolled out"
# If it hangs, Ctrl+C and check:
kubectl describe deployment payment-api -n k8squest
kubectl get events -n k8squest --sort-by='.lastTimestamp'
```

**Asosiy saboq:**
`kubectl rollout status` shows real-time progress. Wait for "successfully rolled out" message.

---

## 💡 Debug Qilish Tartibi — To'g'ri Usul

Here's the systematic rollback approach:

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

# 5. Wait for completion
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
2. **Use `--to-revision=N`** - Don't rely on default "undo"
3. **Wait for rollout completion** - Use `kubectl rollout status`
4. **Don't delete ReplicaSets manually** - Deployment manages them
5. **Nosozlikni tushuning** — rollback qilishdan oldin nima noto'g'ri ketganini o'rganing
6. **Check Deployment status** - Not just individual pods
7. **Use proper rollback commands** - Not `kubectl edit`
8. **Revision history is limited** - Default 10, can't roll back forever

---

## 📊 Rollout History Explained

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

**Each revision is stored as a ReplicaSet:**
- Revision 1 → payment-api-abc123 (0 pods)
- Revision 2 → payment-api-def456 (0 pods)
- Revision 3 → payment-api-ghi789 (3 pods) ← Current

**After rollback to revision 2:**
- Revision 2 → payment-api-def456 (3 pods) ← Now current
- Revision 3 → payment-api-ghi789 (0 pods)
- Revision 4 created (same as revision 2)

---

## 📚 Bu Leveldan Keyin Bilishingiz Kerak

✅ How to view deployment rollout history  
✅ How to rollback to specific revision  
✅ How to wait for rollout completion  
✅ Understanding of ReplicaSet relationship to revisions  
✅ How to verify successful rollback  
✅ Difference between `undo` and `edit`  
✅ How to read deployment status output  

**Keyingi Level:** Level 12 da liveness probe lar — deployment muvaffaqiyatli lekin pod lar qayta ishga tusha berayotganda!
