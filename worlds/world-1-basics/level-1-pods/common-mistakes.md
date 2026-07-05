# Keng Tarqalgan Xatolar — Level 1: CrashLoopBackOff

## ❌ Xato #1: Oldingi Loglarni Tekshirmaslik

**O'yinchilar nima qiladi:**
```bash
kubectl logs nginx-broken -n k8squest
```

**Nima uchun ishlamaydi:**
Konteyner shunchalik tez crash bo'ladiki, bu buyruqni ishlatganingizda yangi konteynerda hali log yo'q (yoki juda kam). OLDINGI crash bo'lgan konteyner loglarini ko'rishingiz kerak.

**To'g'ri yondashuv:**
```bash
kubectl logs nginx-broken --previous -n k8squest
```

**Asosiy saboq:**
`--previous` bayrog'i oxirgi to'xtatilgan konteyner loglarini ko'rsatadi — crash larni debug qilayotganda aynan shu kerak.

---

## ❌ Xato #2: Ishlayotgan Pod ni Tahrirlashga Urinish

**O'yinchilar nima qiladi:**
```bash
kubectl edit pod nginx-broken -n k8squest
# command maydonini o'zgartirishga urinish
```

**Nima uchun ishlamaydi:**
Ko'p pod spec maydonlari (`command` ni o'z ichiga olgan holda) yaratilgandan keyin **o'zgartirib bo'lmaydi** (immutable). Kubernetes o'zgarishlaringizni rad etadi yoki ular ta'sir qilmaydi.

**To'g'ri yondashuv:**
```bash
# Buzilgan pod ni o'chirish
kubectl delete pod nginx-broken -n k8squest

# Tuzatilgan YAML ni apply qilish
kubectl apply -f solution.yaml -n k8squest
```

**Asosiy saboq:**
Pod spec o'zgarishi kerak bo'lganda, pod ni qayta yaratishingiz shart. Deployment lar aynan shuning uchun mavjud — ular buni siz uchun boshqaradi!

---

## ❌ Xato #3: Noto'g'ri Konteynerni Tuzatish

**O'yinchilar nima qiladi:**
Ko'p konteynerli pod larda, o'yinchilar ko'pincha qaysi biri haqiqatan crash bo'layotganini tekshirmasdan YAML dagi birinchi konteynerni tuzatadi.

**Nima uchun ishlamaydi:**
Event lar va status ko'rsatadi "Container 'app' is crashing" lekin siz konteynerni tuzatdingiz 'nginx'. Doim qaysi aniq konteyner muvaffaqiyatsiz ekanini tekshiring.

**To'g'ri yondashuv:**
```bash
# Qaysi konteyner muvaffaqiyatsiz ekanini tekshirish
kubectl describe pod nginx-broken -n k8squest | grep -A 5 "State:"

# Yoki konteyner holatini ko'rish
kubectl get pod nginx-broken -n k8squest -o jsonpath='{.status.containerStatuses[*].name}'
```

**Asosiy saboq:**
O'zgarish kiritishdan oldin doim muvaffaqiyatsiz bo'lgan aniq konteynerni aniqlang.

---

## ❌ Xato #4: Chiqish Kodlarini Tushunmaslik

**O'yinchilar nima qiladi:**
"Exit Code: 127" ni describe natijasida ko'rasiz lekin nimani bildirshini tushunmaysiz.

**Nima uchun ishlamaydi:**
Chiqish kodlari konteyner NIMA UCHUN crash bo'lganini aytadi:
- **Exit 0**: Normal chiqish (muvaffaqiyat)
- **Exit 1**: Umumiy xato
- **Exit 127**: Buyruq topilmadi
- **Exit 137**: OOM tomonidan o'ldirildi (xotira yetishmovchiligi)
- **Exit 143**: To'xtatildi (SIGTERM)

**To'g'ri yondashuv:**
```bash
kubectl describe pod nginx-broken -n k8squest | grep "Exit Code"
```

Agar **Exit Code: 127** ko'rsangiz, buyruq mavjud emas yoki PATH da yo'q.

**Asosiy saboq:**
- **127 → Buyruq topilmadi** (buyruqda imlo xatosi yoki binary topilmadi)
- **137 → OOMKilled** (xotira limiti juda past)
- **1 → Application error** (tafsilotlar uchun loglarni tekshiring)

---

## ❌ Xato #5: broken.yaml ni Qayta Apply Qilish

**O'yinchilar nima qiladi:**
```bash
kubectl apply -f broken.yaml -n k8squest
# Bu safar ishlaydi deb umid qilish?
```

**Nima uchun ishlamaydi:**
Bir xil buzilgan konfiguratsiyani apply qilish muammoni tuzatmaydi! YAML ni o'zgartirish yoki tuzatilgan versiya yaratish kerak.

**To'g'ri yondashuv:**
1. broken.yaml ni yangi faylga nusxalang
2. Yangi faylni tuzatishlar bilan tahrirlang
3. Tuzatilgan faylni apply qiling

```bash
cp broken.yaml my-fix.yaml
# my-fix.yaml ni tahrirlash
kubectl apply -f my-fix.yaml -n k8squest
```

**Asosiy saboq:**
`kubectl apply` "qayta urinmaydi" — u siz bergan konfiguratsiyani majbur qiladi. Avval konfiguratsiyani tuzating!

---

## ❌ Xato #6: Event larni E'tiborsiz Qoldirish

**O'yinchilar nima qiladi:**
Faqat pod holatini va loglarga e'tibor berish, event larni o'tkazib yuborish.

**Nima uchun ishlamaydi:**
Event larda muhim debug ma'lumotlari bor:
- Nima uchun scheduling muvaffaqiyatsiz bo'ldi
- Probe lar qachon muvaffaqiyatsiz bo'ldi
- Image pull xatolari
- Resource quota buzilishlari

**To'g'ri yondashuv:**
```bash
# Debug qilishda doim event larni tekshiring
kubectl get events -n k8squest --sort-by='.lastTimestamp'

# Yoki aniq pod uchun event larni tekshiring
kubectl describe pod nginx-broken -n k8squest | grep -A 20 Events
```

**Asosiy saboq:**
Event lar — Kubernetes ning nima noto'g'ri ketganini aytish usuli. Ular vaqt bo'yicha tartiblangan va nosozliklar ketma-ketligini ko'rsatadi.

---

## ❌ Xato #7: Tuzatishni Test Qilmaslik

**O'yinchilar nima qiladi:**
YAML ni o'zgartirib darhol validate qilish.

**Nima uchun ishlamaydi:**
O'zgarishlarni haqiqatan apply qilish va validatsiyadan oldin pod ishlayotganini tekshirish kerak.

**To'g'ri yondashuv:**
```bash
# 1. Eski pod ni o'chirish
kubectl delete pod nginx-broken -n k8squest

# 2. Tuzatishni apply qilish
kubectl apply -f solution.yaml -n k8squest

# 3. Ishlayotganini tekshirish
kubectl get pod nginx-broken -n k8squest

# 4. Running holatini kutish
kubectl wait --for=condition=ready pod/nginx-broken -n k8squest --timeout=60s

# 5. ENDI tekshirish
./validate.sh
```

**Asosiy saboq:**
Validatsiyani ishga tushirishdan oldin doim tuzatishingizni qo'lda tekshiring. kubectl get/describe/logs — eng yaxshi do'stlaringiz!

---

## ❌ Xato #8: Namespace ni Unutish

**O'yinchilar nima qiladi:**
```bash
kubectl get pods
# No pods found!
```

**Nima uchun ishlamaydi:**
Standart holatda kubectl `default` namespace ga qaraydi. K8sQuest `k8squest` namespace ni ishlatadi.

**To'g'ri yondashuv:**
```bash
# Doim namespace ko'rsating
kubectl get pods -n k8squest

# Yoki sessiya uchun standart namespace o'rnating
kubectl config set-context --current --namespace=k8squest
```

**Asosiy saboq:**
Namespace lar resurslarni izolyatsiya qiladi. Doim ishlating `-n k8squest` yoki uni standart qilib o'rnating.

---

## 💡 Debug Qilish Tartibi — To'g'ri Usul

Mana ishlaydigan tizimli yondashuv:

```bash
# 1. Joriy holatni tekshiring
kubectl get pods -n k8squest

# 2. Batafsil ma'lumot oling
kubectl describe pod nginx-broken -n k8squest

# 3. OLDINGI loglarni tekshiring (crash lar uchun)
kubectl logs nginx-broken --previous -n k8squest

# 4. Event larni tekshiring
kubectl get events -n k8squest --sort-by='.lastTimestamp' | tail -20

# 5. Yuqoridagi ma'lumotlardan muammoni aniqlang

# 6. YAML ni tuzating

# 7. O'chirib qayta yarating
kubectl delete pod nginx-broken -n k8squest
kubectl apply -f solution.yaml -n k8squest

# 8. Tuzatishni tekshiring
kubectl get pod nginx-broken -n k8squest -w
# Running holatini kuting (Ctrl+C bilan to'xtatish)

# 9. Validatsiya
./validate.sh
```

---

## 🎯 Asosiy Xulosalar

1. **Crash larni debug qilayotganda doim oldingi loglarni tekshiring** (`--previous` bayrog'i)
2. **Pod spec lar asosan o'zgartirib bo'lmaydi** — o'zgartirish uchun o'chirib qayta yarating
3. **Event lar — do'stingiz** — ular nima noto'g'ri ketganining vaqt jadvalini ko'rsatadi
4. **Chiqish kodlari muhim** — 127 = buyruq topilmadi, 137 = OOMKilled
5. **Namespace ko'rsating** — `-n k8squest` ishlating yoki standart kontekst o'rnating
6. **Validatsiyadan oldin test qiling** — validatsiya ishga tushirishdan oldin kubectl bilan tekshiring
7. **Faqat simptomni emas, konfiguratsiyani tuzating** — NIMA UCHUN crash bo'lganini tushuning

---

## 📚 Bu Leveldan Keyin Bilishingiz Kerak

✅ Oldingi konteyner loglarini qanday o'qish  
✅ CrashLoopBackOff holatini qanday talqin qilish  
✅ Qaysi konteyner muvaffaqiyatsiz ekanini qanday aniqlash  
✅ Pod spec lardagi buyruq xatolarini qanday tuzatish  
✅ Pod larni qanday o'chirib qayta yaratish  
✅ Debug qilish uchun event larni qanday ishlatish  
✅ Chiqish kodlarini tushunish  

**Keyingi Level:** Level 2 da ImagePullBackOff debug qilishni o'rganasiz — boshqa simptomlar, lekin shunga o'xshash tizimli yondashuv!
