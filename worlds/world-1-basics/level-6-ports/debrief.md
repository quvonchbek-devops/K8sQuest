# 🎓 Missiya Yakuni: Port Nomuvofiqlik Muammosi

## Nima Sodir Bo'ldi

Service trafikni konteynerdagi 8080-portga yo'naltirayotgan edi, lekin NGINX konteyner aslida 80-portda tinglaydi. Natija: har bir so'rov yopiq portga tushdi va "connection refused" bilan muvaffaqiyatsiz bo'ldi.

## Kubernetes Qanday Ishladi

So'rov Service ga kelganida:
1. Klient Service IP:port ga ulanadi (masalan, 10.96.0.1:80)
2. Service endpoint laridan biriga yo'naltiradi
3. Trafik Pod IP:targetPort ga yuboriladi (masalan, 10.244.0.5:8080)
4. Konteyner shu portda tinglayotgan bo'lishi kerak

Service trafikni 8080-portga yo'naltirayotgan edi, lekin NGINX 80-portda tinglaydi. 4-qadam muvaffaqiyatsiz bo'ldi — **8080-portda hech qanday jarayon (process) yo'q**.

## To'g'ri Tushuncha Modeli

**Uchta port tushunchasi**:

```yaml
apiVersion: v1
kind: Service
spec:
  ports:
  - port: 80          # Tashqi: klientlar ulanadigan port
    targetPort: 8080  # Ichki: Pod dagi qaysi port
    nodePort: 30080   # (Ixtiyoriy) NodePort service lari uchun node portlari
```

**Port larni moslashtirish**:
```yaml
# Konteyner 8080-portda tinglaydi
containerPort: 8080

# Service ham o'sha portga yo'naltirishi kerak
targetPort: 8080
```

**Keng tarqalgan pattern lar**:

| Pattern | Konteyner | Service Port | Service TargetPort |
|---------|-----------|--------------|-------------------|
| Oddiy moslik | 80 | 80 | 80 |
| Port mapping | 8080 | 80 | 8080 |
| Nomli port | 8080 ("http" nomi) | 80 | "http" |

## Haqiqiy Voqea Misoli

**Kompaniya**: Qora Juma vaqtida elektron tijorat sayti
**Ta'sir**: 30 daqiqa checkout muvaffaqiyatsizligi
**Zarar**: $2.1M yo'qotilgan savdo

**Nima sodir bo'ldi**:
Dasturchi lokal muhitda ziddiyatlarni (conflict) oldini olish uchun ilovani 8080-portdan 9000-portga o'zgartirdi. Dockerfile va containerPort ni yangiladi lekin **Service ning targetPort ini yangilashni unutdi**.

Deploy vaqtida pod lar yaxshi ishga tushdi. Service mavjud edi. Endpoint lar sog'lom ko'rinardi. Lekin har bir checkout so'rovi "connection refused" oldi.

**Nima uchun debug qilish qiyin bo'ldi**:
- Service "sog'lom" ko'rindi (u endpoint lar bilan mavjud edi)
- Pod lar "Ready" ko'rindi (readiness probe boshqa endpoint da edi)
- Load balancer health check lari o'tdi (ular to'g'ri portdagi health endpoint ni tekshirardi)
- Faqat haqiqiy checkout trafik muvaffaqiyatsiz bo'ldi

**Topilishi**:
```bash
# To'g'ridan-to'g'ri test qilish
kubectl port-forward pod/checkout-xyz 8080:9000 -n production
# Ishladi! ← Bu port nomuvofiqligini ochdi

kubectl describe service checkout -n production
# targetPort: 8080 (eski qiymat) ko'rsatdi

kubectl get pod checkout-xyz -n production -o yaml | grep containerPort
# containerPort: 9000 (yangi qiymat) ko'rsatdi
```

**Yechim**: Service targetPort ni 9000 ga yangiladi. Darhol tiklandi.

**Saboq**: Ilova port larini o'zgartirganingizda, HAMMA JOYDA yangilang:
- Dockerfile
- Pod spec dagi containerPort
- Service spec dagi targetPort
- Health check konfiguratsiyalari
- Monitoring konfiguratsiyalari

## O'zlashtirilgan Buyruqlar

```bash
# Konteyner port larini tekshirish
kubectl get pod <nom> -n <namespace> -o yaml | grep -A 2 ports:
kubectl describe pod <nom> -n <namespace> | grep Port

# Service port larini tekshirish
kubectl get service <nom> -n <namespace>
kubectl describe service <nom> -n <namespace>
kubectl get service <nom> -n <namespace> -o yaml | grep -A 3 ports:

# Ulanishni to'g'ridan-to'g'ri test qilish
kubectl port-forward pod/<nom> 8080:80 -n <namespace>
kubectl port-forward service/<nom> 8080:80 -n <namespace>

# Konteyner ichida buyruq bajarish
kubectl exec -it <pod-nomi> -n <namespace> -- curl localhost:80
kubectl exec -it <pod-nomi> -n <namespace> -- netstat -tlnp
```

## Port Turlarini Tushunish

**containerPort**: Faqat hujjat maqsadida! Aslida portni ochmaydi.
```yaml
# Bu faqat konteyner qaysi portni ishlatishini hujjatlaydi
ports:
- containerPort: 8080
```

**Service port**: Klientlar service ga kirish uchun ishlatadilar
```yaml
# Klientlar service-ip:80 ga ulanadi
ports:
- port: 80
```

**targetPort**: Service trafik yo'naltiradigan joy
```yaml
# Service pod-ip:8080 ga yo'naltiradi
ports:
- targetPort: 8080
```

**Nomli port lar** (best practice):
```yaml
# Pod da
ports:
- name: http
  containerPort: 8080

# Service da  
ports:
- port: 80
  targetPort: http  # Raqam emas, nomga murojaat!
```

Foydalari: Port raqamini bir joyda (pod da) o'zgartiring, service avtomatik yangi qiymatni ishlatadi.

## Port Muammolarini Debug Qilish

Bosqichma-bosqich debug qilish:

```bash
# 1. Pod ishlayaptimi?
kubectl get pod <nom> -n <namespace>

# 2. Konteyner qaysi portda tinglayapti?
kubectl exec <pod> -n <namespace> -- netstat -tlnp

# 3. Service da endpoint lar bormi?
kubectl get endpoints <service> -n <namespace>

# 4. Service qaysi portga yo'naltiryapti?
kubectl get service <service> -n <namespace> -o yaml | grep targetPort

# 5. To'g'ridan-to'g'ri pod ulanishini test qilish
kubectl port-forward pod/<nom> 9999:<containerPort> -n <namespace>
curl localhost:9999

# 6. Service ulanishini test qilish
kubectl port-forward service/<nom> 9999:<port> -n <namespace>
curl localhost:9999
```

## Keyingi Qadam

Bitta konteynerli pod asoslarini o'rgandingiz. Keyingi topshiriq — sidecar konteyner crash bo'lib butun pod ga ta'sir qiladigan ko'p konteynerli pod lar!
