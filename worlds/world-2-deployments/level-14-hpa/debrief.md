# 🎓 Missiya Yakuni: HPA Scale Qila Olmayapti

## Nima Sodir Bo'ldi

HorizontalPodAutoscaler (HPA) to'g'ri sozlangan edi, lekin **metrics-server o'rnatilmagani** uchun scale qila olmadi.

metrics-server siz, Kubernetes pod larning CPU/xotira foydalanishini bilolmaydi, shuning uchun HPA scaling qarorlarini qabul qilolmaydi.

Bu yangi klasterlarda eng keng tarqalgan HPA muammolardan biri!

## Kubernetes Qanday Ishladi

**HPA dependency zanjiri**:

```
HPA scale qilmoqchi
    ↓
Joriy CPU/xotira metrikalari kerak
    ↓
Metrics API ga so'rov yuboradi
    ↓
Metrics API ni metrics-server xizmat qiladi
    ↓
❌ metrics-server o'rnatilmagan
    ↓
HPA "<unknown>/50%" ko'rsatadi
    ↓
Scaling qarorlarini qabul qilolmaydi
```

**metrics-server nima qiladi**:

```
metrics-server kube-system namespace da deployment sifatida ishlaydi
    ↓
Har bir node dagi kubelet dan resurs metrikalarini yig'adi
    ↓
Metrikalarni jamlaydi (CPU, xotira foydalanishi)
    ↓
Kubernetes Metrics API orqali ochib beradi
    ↓
HPA, kubectl top va boshqa vositalar bu metrikalarni iste'mol qiladi
```

## To'g'ri Tushuncha Modeli

### Kubernetes Metrikalar Arxitekturasi

```
┌─────────────────────────────────────────────────┐
│                  kubectl top                     │
│                      HPA                         │
│            Dashboard / Monitoring                │
└────────────────────┬────────────────────────────┘
                     │ Metrikalarni so'raydi
                     ↓
         ┌───────────────────────┐
         │    Metrics API        │
         │ (metrics.k8s.io/v1)   │
         └──────────┬────────────┘
                    │ Bajaradigan
                    ↓
         ┌───────────────────────┐
         │   metrics-server      │
         │  (kube-system ns)     │
         └──────────┬────────────┘
                    │ Metrikalarni yig'adi
                    ↓
    ┌───────────────────────────────────┐
    │  har bir node dagi kubelet        │
    │  (cAdvisor konteyner CPU/xotira   │
    │   statistikasini beradi)           │
    └───────────────────────────────────┘
```

### HPA Scaling Mantiqi

```yaml
# HPA konfiguratsiyasi
spec:
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50  # Maqsad: 50% CPU
```

**HPA qanday scale qilish qarorini qabul qiladi**:

```
Joriy holat:
- Deployment da 2 pod bor
- Pod 1: 80% CPU
- Pod 2: 70% CPU
- O'rtacha: 75% CPU

Maqsad: 50% CPU

HPA hisoblash:
  kerakliReplikalar = ceil(joriyReplikalar × (joriyMetrika / maqsadMetrika))
  kerakliReplikalar = ceil(2 × (75 / 50))
  kerakliReplikalar = ceil(2 × 1.5)
  kerakliReplikalar = 3

Harakat: 2 dan 3 replikaga ko'paytirish
```

**Scaling xatti-harakati**:
- **Ko'paytirish**: Darhol (CPU > maqsad bo'lganda)
- **Kamaytirish**: 5 daqiqalik barqarorlashtirish oynasi (tez-tez o'zgarishni oldini olish)

### metrics-server O'rnatish

**Standart o'rnatish**:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

**Lokal ishlab chiqish uchun (kind, Docker Desktop, minikube)**:
```bash
# --kubelet-insecure-tls bayrog'ini qo'shish
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

⚠️ `--kubelet-insecure-tls` faqat ishlab chiqishda ishlating, production da HECH QACHON!

## Haqiqiy Voqea Misoli

**Kompaniya**: Mobil o'yin kompaniyasi (10M kunlik faol foydalanuvchi)
**Ta'sir**: Mahsulot chiqarish vaqtida 2 soatlik uzilish, 100% trafik yo'qotildi
**Zarar**: $3.5M yo'qotilgan daromad + $2M qaytarishlar

**Nima sodir bo'ldi**:
Jamoa katta o'yin chiqarishi uchun 10x kutilgan trafik bilan tayyorlandi. HPA ni yukni boshqarish uchun sozladi:

```yaml
spec:
  minReplicas: 10
  maxReplicas: 500
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        averageUtilization: 70
```

Staging da test qilishdi (metrics-server o'rnatilgan edi). Hamma narsa mukammal ishladi!

**Muvaffaqiyatsizlik** (Chiqarish kuni):
```
10:00 - O'yin chiqdi
10:00 - Trafik ko'tarila boshladi (50K → 100K → 200K foydalanuvchi/daqiqa)
10:05 - 10 pod da CPU 90% ga yetdi
10:05 - HPA 13 pod ga scale qilishi kerak edi... lekin qilmadi
10:08 - CPU 100%, pod lar crash bo'la boshladi
10:10 - Barcha 10 pod restart siklida
10:10 - O'yin to'liq ishdan chiqdi
10:15 - HPA tekshirish: "unable to get metrics for resource cpu"
10:20 - metrics-server tekshirish: TOPILMADI
10:20 - Anglash: Production dagi klasterda metrics-server yo'q!
10:25 - metrics-server o'rnatish boshlandi
10:30 - metrics-server ishlayapti
10:35 - HPA ishlay boshladi
10:40 - 180 pod ga scale qilindi
10:50 - Xizmat barqarorlashdi
12:00 - To'liq tiklandi (2 soat to'xtash)
```

**Asosiy sabab**:
- IaC (Infrastructure as Code) majbur qilinmagan — staging da metrics-server bor edi, prodda yo'q
- Deploy oldi tekshiruv ro'yxati yo'q — hech kim metrics-server mavjudligini tekshirmadi
- Noto'g'ri muhitda test — staging ≠ produktsiya
- Monitoring yo'q — "HPA scale qilolmayapti" uchun alert yo'q

**Joriy qilingan tuzatishlar**:

1. **Klaster sozlash avtomatlashtirildi** (Terraform):
```hcl
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
}
```

2. **Deploy oldi tekshiruv**:
```bash
if ! kubectl top nodes &>/dev/null; then
    echo "XATO: metrics-server ishlamayapti"
    exit 1
fi
```

3. **HPA monitoring**:
```yaml
- alert: HPAMetricsUnavailable
  expr: kube_horizontalpodautoscaler_status_condition{condition="ScalingActive",status="false"} == 1
  for: 2m
```

**Olingan saboqlar**:
1. Feature deploy qilishdan oldin dependency lar mavjudligini tekshiring
2. Staging production dagi infrastrukturaga mos bo'lishi kerak
3. HPA sog'ligini monitoring qiling — scaling muvaffaqiyatsizliklarida alert
4. Haqiqiy scaling bilan yuk testi qiling — faqat belgilangan pod soni bilan emas

## O'zlashtirilgan Buyruqlar

```bash
# HPA holatini tekshirish
kubectl get hpa -n <namespace>
# TARGETS ga qarang — "X%/50%" bo'lishi kerak, "<unknown>/50%" emas

# HPA tafsilotlarini ko'rish
kubectl describe hpa <nom> -n <namespace>

# metrics-server o'rnatilganini tekshirish
kubectl get deployment metrics-server -n kube-system

# metrics-server o'rnatish
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Lokal klasterlar uchun xavfsiz TLS bayrog'i
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# metrics-server tayyor bo'lishini kutish
kubectl wait --for=condition=available --timeout=60s deployment/metrics-server -n kube-system

# Metrikalar ishlashini test qilish
kubectl top nodes           # Node CPU/xotira
kubectl top pods -n <ns>    # Pod CPU/xotira

# HPA scale qilishini real-time kuzatish
kubectl get hpa -n <namespace> -w

# Scaling ni ishga tushirish uchun yuk yaratish (test)
kubectl run -it --rm load-generator --image=busybox --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://service-nomi; done"
```

## HPA Eng Yaxshi Amaliyotlari

### ✅ TO'G'RI:
1. **Doim metrics-server o'rnating** — klaster sozlash avtomatizatsiyasiga kiritib qo'ying
2. **Resource request lar qo'ying** (HPA ularsiz ishlamaydi):
   ```yaml
   resources:
     requests:
       cpu: 200m      # HPA buni bazaviy qiymat sifatida ishlatadi
   ```
3. **Oqilona maqsad foiz ishlating** (60-70%) — yuklama uchuvchanligi uchun joy qoldiring
4. **minReplicas ni 2+ qo'ying** — muhim xizmatlar uchun doim zaxira

### ❌ NOTO'G'RI:
1. Resource request siz HPA ishlatmang — foizni hisoblay olmaydi
2. Muhim xizmatlar uchun minReplicas: 1 qo'ymang — yagona nosozlik nuqtasi
3. Juda agressiv scaling qilmang (averageUtilization: 30) — ortiqcha pod lar

## Keyingi Qadam

HPA ni sozlash va metrics-server dependency sini o'rganib oldingiz.

**Keyingi level**: Rollout strategiyalari! Noto'g'ri sozlangan rolling update parametrlari qanday to'xtashga olib kelishini o'rganasiz.

---

💡 **Pro maslahat**: HPA metrics-server ni talab qiladi. Production ga HPA deploy qilishdan oldin doim metrics-server o'rnatilgan va ishlayotganini tekshiring!
