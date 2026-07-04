# 🎓 Missiya Yakuni: Buzilgan Pod ni Tuzatish

## Nima Sodir Bo'ldi

Pod `nginxzz` degan buyruqni ishga tushirishga urinib ishdan chiqdi — lekin bu buyruq nginx konteyner image da mavjud emas.

Pod ni `kubectl describe` bilan tekshirganingizda quyidagini ko'rgansiz:
```
Error: failed to create containerd task: exec: "nginxzz": executable file not found in $PATH
```

Kubernetes sizga shuni aytmoqda: "Image ni topdim, tortdim, konteyner yaratdim... lekin siz aytgan buyruq mavjud emas."

## Kubernetes Qanday Ishladi

Ichki jarayonda nima sodir bo'ldi:

1. **Scheduler** pod ni node ga tayinladi ✅
2. **Kubelet** nginx image ni tortdi ✅
3. **Container runtime** konteynerni `["nginxzz"]` buyrug'i bilan ishga tushirishga urindi ❌
4. **Konteyner darhol ishdan chiqdi**
5. **Kubelet** qayta urindi (CrashLoopBackOff)
6. **Exponential backoff** boshlandi — har safar urinishlar orasida ko'proq kutadi

Bu **Kubernetes aynan siz aytganingizni bajarayotgan holat**. U `nginxzz` imlo xatosi ekanini bilishga aqli yetmaydi.

## To'g'ri Tushuncha Modeli

### Asosiy Konseptlar:

1. **Pod lar vaqtincha (ephemeral)**
   - Ishlayotgan pod ning ko'p maydonlarini o'zgartirib bo'lmaydi
   - O'zgartirish kerak bo'lsa, o'chirib qayta yarating
   - Shuning uchun Deployment lar mavjud (ular buni siz uchun boshqaradi)

2. **Konteyner image lari nima ishlashi MUMKIN ligini belgilaydi**
   - nginx image da: nginx, bash, sh va boshqalar bor
   - nginx image da: nginxzz YO'Q
   - `command` maydoni image ning standart buyrug'ini bekor qiladi (override)

3. **CrashLoopBackOff — bu qayta aloqa (feedback)**
   - Bu qo'rqinchli xato emas — bu ma'lumot
   - Sizga: "Qayta-qayta urinmoqdaman lekin har safar ishlamayapti" deyapti
   - `kubectl describe` dagi Events NIMA UCHUN ishlamaganini aytadi

### Eslab Qolish Kerak:

- **Har doim `kubectl describe pod <nom>` tekshiring** — Events voqealar tarixini ko'rsatadi
- **Pod lar yaratilgandan keyin tahrirlanmaydi** — o'chirib qayta yarating
- **CrashLoopBackOff = konteyner qayta-qayta ishdan chiqmoqda** — bu tarmoq/scheduling muammosi emas
- **command maydoni xavfli** — faqat standart buyruqni bekor qilish kerak bo'lganda ishlating

## Haqiqiy Voqea Misoli

### Stsenariy: Produkciyada tungi soat 3 da uzilish

**Nima sodir bo'ldi:**
Dasturchi API service ning yangi versiyasini deploy qildi. Ishga tushirish skriptini bajarish uchun `command` maydoni qo'shdi:

```yaml
command: ["/app/startup.sh"]
```

Lekin skriptni bajariladigan qilishni unutdi (`chmod +x`).

**Ta'siri:**
- Barcha pod lar darhol ishdan chiqdi
- Butun deployment bo'ylab CrashLoopBackOff
- API 12 daqiqa ishlamadi
- $50,000 daromad yo'qotildi

**Asosiy sabab:**
`command` maydoni bajarish ruxsati bo'lmagan faylni ishga tushirishga urindi.

**Qanday tuzatildi:**
```bash
# Tezkor yechim: command override ni olib tashlash
kubectl edit deployment api-service
# (command maydonini o'chirdi — image ning standart buyrug'ini ishlatdi)

# To'g'ri yechim: Dockerfile da skriptni bajariladigan qilish
RUN chmod +x /app/startup.sh
```

**Saboq:**
- Konteyner buyruqlarini avval lokal da test qiling: `docker run --rm -it <image> <buyruq>`
- Imkon qadar image ning standart buyrug'ini ishlating
- Agar bekor qilsangiz, nima qilayotganingizni aniq biling

## Bu Sizning Karyerangizga Qanday Aloqador

### Intervyuda javob bera oladigan savollar:

**S: "Pod CrashLoopBackOff holatida. Qanday debug qilasiz?"**

**J:**
1. Pod event larini tekshiraman: `kubectl describe pod <nom>`
2. Loglarni tekshiraman: `kubectl logs <nom>` (yoki oxirgi crash uchun `--previous`)
3. Qidiraman: buyruq topilmadi, yetishmayotgan dependency lar, konfiguratsiya xatolari
4. Muammoni tuzatib, pod ni qayta yarataman yoki deployment ni yangilayman

**S: "Ishlayotgan pod ni tahrirlash mumkinmi?"**

**J:**
Faqat ayrim maydonlar:
- `spec.containers[*].image`
- `spec.activeDeadlineSeconds`
- `spec.tolerations` (faqat qo'shish)

Ko'p o'zgartirishlar uchun o'chirib qayta yaratish kerak. Shuning uchun produkciyada Deployment lar ishlatamiz.

## O'zlashtirilgan Buyruqlar

```bash
# Pod holatini tekshirish
kubectl get pod <nom> -n <namespace>

# Batafsil event va holat ko'rish
kubectl describe pod <nom> -n <namespace>

# Loglarni ko'rish (hatto ishdan chiqqan konteynerlardan)
kubectl logs <nom> -n <namespace>
kubectl logs <nom> -n <namespace> --previous

# O'chirib qayta yaratish
kubectl delete pod <nom> -n <namespace>
kubectl apply -f <fayl>.yaml

# Tezda tahrirlash (cheklangan maydonlar)
kubectl edit pod <nom> -n <namespace>
```

## Keyingi Qadamlar

Endi siz tushunasiz:
- ✅ Buzilgan pod larni qanday debug qilish
- ✅ CrashLoopBackOff nima uchun sodir bo'lishi
- ✅ Pod immutabilligi (o'zgarmaslik) va uning oqibatlari
- ✅ `command` maydonining kuchi (va xavfi)

**Keyingi topshiriq:** Deployment lar — produkciyada pod larni boshqarishning to'g'ri usuli bilan tanishamiz.

---

💡 **Pro maslahat:** Produkciyada mustaqil pod larni deyarli hech qachon ishlatmaysiz. Deployment lar qayta ishga tushirish, rollback va scaling ni boshqaradi. Lekin pod larni tushunish juda muhim, chunki Deployment lar ichki jarayonda pod lar yaratadi.
