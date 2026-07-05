# 🎓 Missiya Yakuni: Uzilgan Aloqa — Labels & Selectors

## Nima Sodir Bo'ldi

Service da `app: frontend` selector bor edi, lekin Pod da `app: backend` label bor edi. Label lar mos kelmagani uchun Service Pod ni topa olmadi va endpoint lari bo'lmadi. Endpoint larsiz, Service ga yuborilgan trafikka boradigan joy yo'q edi.

## Kubernetes Qanday Ishladi

**Service** lar Pod larni to'g'ridan-to'g'ri boshqarmaydi. Buning o'rniga, qaysi Pod lar trafik qabul qilishi kerakligini dinamik ravishda aniqlash uchun **label selector** lar ishlatiladi.

Jarayon:
1. Service `app: frontend, tier: api` selector bilan yaratildi
2. Service controller barcha Pod larni kuzatadi
3. BARCHA selector label lariga mos Pod larni topadi
4. Mos Pod IP lari bilan **Endpoints** obyekti yaratadi
5. Trafikni shu endpoint larga yo'naltiradi

Service `app=frontend` ni qidirayotgan edi, lekin Pod `app=backend` deb belgilangan edi, shuning uchun 3-qadam muvaffaqiyatsiz bo'ldi — **hech qanday moslik topilmadi**.

## To'g'ri Tushuncha Modeli

**Label lar** — Kubernetes obyektlariga biriktirilgan kalit-qiymat juftliklari:

```yaml
metadata:
  labels:
    app: backend
    tier: api
    environment: prod
    version: v2
```

**Selector lar** — obyektlarni label lar bo'yicha filtrlaydigan so'rovlar:

```yaml
selector:
  app: backend    # app=backend bo'lgan pod larni topadi
  tier: api       # VA tier=api (ikkalasi ham mos kelishi shart)
```

**Service lar Selector larni Qanday Ishlatadi**:

```
Service selector: {app: backend, tier: api}
                        ↓
Mos label li pod larni qidiradi
                        ↓
Pod 1: {app: backend, tier: api} ✅ Mos!
Pod 2: {app: frontend, tier: api} ❌ app mos emas
Pod 3: {app: backend, tier: db} ❌ tier mos emas
Pod 4: {app: backend, tier: api, env: prod} ✅ Mos! (qo'shimcha label lar OK)
                        ↓
Pod 1 va Pod 4 IP lari bilan Endpoints yaratadi
```

**Muhim**: Selector dagi barcha label lar mos kelishi shart, lekin pod larda qo'shimcha label lar bo'lishi mumkin.

## Haqiqiy Voqea Misoli

**Kompaniya**: Kuniga $10M to'lov ishlaydigan fintech startup
**Ta'sir**: 3 soatlik to'lov tizimi uzilishi
**Zarar**: $125K SLA buzilishi + 400 ta mijoz qo'llab-quvvatlash so'rovi

**Nima sodir bo'ldi**:
Oddiy deployment jarayonida DevOps muhandis to'lov service deployment ini yangilab, tasodifan pod label ni `app: payment-processor` dan `app: payment-service` ga o'zgartirdi.

Service hali ham `app: payment-processor` selector ga ega edi. Natija: **darhol uzilish**. Barcha to'lov pod lariga yetib bo'lmay qoldi. Load balancer Service ni tirik ushlab turdi, lekin 0 ta endpoint bilan.

**Nega 3 soat davom etdi**:
- Service "ishlayotgan" edi (alert lar ishlamadi)
- Health check lar Service ni tekshirardi, u mavjud edi (lekin backend larsiz)
- Loglar "connection refused" ko'rsatdi, lekin jamoa tarmoq muammosi deb o'yladi
- Nihoyat `kubectl get endpoints payment-service` orqali aniqlashdi — bo'sh
- Tekshirish: `kubectl get pods --selector=app=payment-processor` — 0 ta pod

**Yechim**: Service selector ni yangi label ga mos qilib o'zgartirdi. Endpoint lar darhol paydo bo'ldi.

**Saboq**:
1. Mos service larni yangilamasdan pod label larni hech qachon o'zgartirmang
2. Endpoint sonini monitoring qiling (endpoint = 0 bo'lsa alert)
3. Barqarorlik uchun izchil nomlash qoidalari (naming convention) ishlating

## O'zlashtirilgan Buyruqlar

```bash
# Service va uning selector ini tekshirish
kubectl get service <nom> -n <namespace>
kubectl describe service <nom> -n <namespace>
kubectl get service <nom> -n <namespace> -o yaml | grep -A 5 selector

# Endpoint larni tekshirish (service yo'naltiradigan IP lar)
kubectl get endpoints <nom> -n <namespace>
kubectl describe endpoints <nom> -n <namespace>

# Pod label larini ko'rish
kubectl get pods --show-labels -n <namespace>
kubectl get pod <nom> -n <namespace> --show-labels

# Selector ga mos pod larni topish
kubectl get pods --selector=app=backend -n <namespace>
kubectl get pods -l app=backend,tier=api -n <namespace>

# Ishlayotgan pod larga label qo'shish/o'zgartirish
kubectl label pod <nom> app=frontend -n <namespace>
kubectl label pod <nom> app=backend --overwrite -n <namespace>
```

## Label Eng Yaxshi Amaliyotlari

1. **Kubernetes tavsiya etgan label larni ishlating**:
   ```yaml
   app.kubernetes.io/name: myapp
   app.kubernetes.io/instance: myapp-prod
   app.kubernetes.io/version: 1.2.3
   app.kubernetes.io/component: backend
   app.kubernetes.io/part-of: payment-system
   ```

2. **Selector larni oddiy saqlang**: maksimal 1-3 ta label
3. **Label larni o'zgartirmang** agar service lar ularga bog'liq bo'lsa
4. **Izchil qiymatlar ishlating**: `backend` — `Backend` yoki `back-end` emas
5. **Label laringizni hujjatlang**: tashkilotingiz uchun label lug'ati tuzing

## Endpoint larni Tushunish

Endpoint lar Service va Pod lar o'rtasidagi ko'prik:

```
kubectl get endpoints <service-nomi>

NAME              ENDPOINTS
backend-service   10.244.0.5:5678,10.244.0.6:5678

                  ↑ Bular selector ga mos Pod IP lari
```

Agar `ENDPOINTS` bo'sh bo'lsa = service da backend yo'q = trafik muvaffaqiyatsiz.

Bo'sh endpoint larning keng tarqalgan sabablari:
- ❌ Label nomuvofiqlik (hozirgina tuzatgansiz!)
- ❌ Pod lar mavjud emas
- ❌ Pod lar mavjud lekin Ready emas
- ❌ Service da port nomuvofiqlik
- ❌ Pod lar boshqa namespace da

## Keyingi Qadam

Label lar Kubernetes ning har joyida ishlatiladi:
- Service lar Pod larni tanlash (hozirgina o'rgandingiz!)
- Deployment lar ReplicaSet larni boshqarish
- NetworkPolicy ni lar trafikni filtrlash
- Node selector lar scheduling uchun
- Volume claim lar storage tanlash uchun

Keyingi topshiriq: Konteyner port nomuvofiqligini debug qilasiz!
