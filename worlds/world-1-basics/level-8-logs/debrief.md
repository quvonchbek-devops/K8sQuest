# 🎓 Missiya Yakuni: Pod Loglar Jumboqi

## Nima Sodir Bo'ldi

PostgreSQL konteyner initsializatsiya uchun `POSTGRES_PASSWORD` environment variable ni talab qilardi, lekin u berilmagan edi. Konteyner ishga tushdi, darhol muvaffaqiyatsiz bo'ldi, qayta ishga tushdi va takrorlandi — CrashLoopBackOff ga kirdi. Buni aniqlashning yagona yo'li loglarni tekshirish edi.

## To'g'ri Tushuncha Modeli

**Loglar — debug qilish super kuchingiz**. Barcha nosozliklar `kubectl describe` da ko'rinmaydi. Ba'zi ilovalar:
- Muvaffaqiyatli ishga tushadi (shuning uchun pod "Running" ko'rsatadi)
- Konfiguratsiya xatolari tufayli muvaffaqiyatsiz bo'ladi
- Darhol chiqib ketadi
- Qayta ishga tushadi va takrorlanadi

**Kubernetes da log joylashuvi**:
- Konteyner loglar: stdout/stderr dan olinadi
- Kirish: `kubectl logs` orqali
- Node da vaqtincha saqlanadi
- Hajmi katta bo'lganda aylantiradi (rotate)

## O'zlashtirilgan Buyruqlar

```bash
# Joriy loglarni ko'rish
kubectl logs <pod> -n <namespace>

# Oldingi konteyner loglarini ko'rish (crash dan keyin)
kubectl logs <pod> --previous -n <namespace>

# Loglarni real-time kuzatish
kubectl logs <pod> -f -n <namespace>

# Ko'p konteynerli pod da aniq konteyner
kubectl logs <pod> -c <konteyner> -n <namespace>

# Oxirgi N qator
kubectl logs <pod> --tail=50 -n <namespace>

# Ma'lum vaqtdan beri
kubectl logs <pod> --since=1h -n <namespace>
```

## Keyingi Qadam

Keyingi: Pod ishga tushishini to'suvchi Init container lar!
