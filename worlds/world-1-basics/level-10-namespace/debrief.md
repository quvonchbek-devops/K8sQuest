# 🎓 Missiya Yakuni: Namespace Chalkashligi

## Nima Sodir Bo'ldi

Resurslaringiz "k8squest" o'rniga "default" namespace ga deploy qilingan edi. Namespace lar izolyatsiya ta'minlaydi — turli namespace lardagi resurslar bir-birini oson topa olmaydi.

## Kubernetes Qanday Ishladi

**Namespace lar** — fizik klaster ichidagi virtual klasterlar:

- Nomlar uchun ko'lam beradi (bir nechta namespace da "web" pod bo'lishi mumkin)
- Har bir namespace uchun resource quota va limit lar imkonini beradi
- Kirish nazorati chegaralarini ta'minlaydi (har bir namespace uchun RBAC)
- Service lar namespace ichida oson aloqa qiladi
- Namespace lar arasi aloqa to'liq DNS talab qiladi

## To'g'ri Tushuncha Modeli

**Namespace izolyatsiyasi**:
```
Klaster
├── default namespace
│   ├── pod: app-1
│   └── service: api
├── k8squest namespace
│   ├── pod: client-app
│   └── service: backend-service
└── production namespace
    ├── pod: payment-processor
    └── service: payment-api
```

**DNS hal qilish**:
- Bir xil namespace: `service-nomi`
- Namespace lar arasi: `service-nomi.namespace-nomi.svc.cluster.local`

## O'zlashtirilgan Buyruqlar

```bash
# Barcha namespace larni ko'rish
kubectl get namespaces

# Aniq namespace dagi resurslarni ko'rish
kubectl get all -n <namespace>

# Barcha namespace lardagi resurslarni ko'rish
kubectl get pods --all-namespaces
kubectl get pods -A

# Namespace yaratish
kubectl create namespace <nom>

# Kontekst uchun standart namespace sozlash
kubectl config set-context --current --namespace=<namespace>

# Namespace o'chirish (ehtiyot bo'ling!)
kubectl delete namespace <namespace>
```

## Tabriklaymiz! 🎉

Siz **World 1: Asosiy Kubernetes** ni yakunladingiz!

O'zlashtirilganlar:
- ✅ CrashLoopBackOff debug qilish
- ✅ ImagePullBackOff hal qilish
- ✅ Resurs scheduling (Pending pod lar)
- ✅ Label lar va selector lar
- ✅ Port konfiguratsiyasi
- ✅ Ko'p konteynerli pod lar
- ✅ Log asosida debug qilish
- ✅ Init container lar
- ✅ Namespace izolyatsiyasi

**Yig'ilgan jami XP**: 1,450 XP

**Keyingi**: World 2 — Deployment lar va Scaling kutmoqda!
