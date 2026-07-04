# 🎓 Missiya Yakuni: Qayta Ishga Tushirish Sikli

## Nima Sodir Bo'ldi

Pod laringiz qayta ishga tushirish siklida qotib qoldi, chunki liveness probe 404 (Topilmadi) qaytaradigan `/nonexistent-healthz` endpoint ni tekshirayotgan edi. Kubernetes buni "pod sog'lomsiz" deb qabul qilib qayta-qayta ishga tushirdi, bu esa albatta health check dan yana o'tolmadi.

Bu produkciyada kaskadli nosozliklarga olib kelishi mumkin bo'lgan klassik konfiguratsiya xatosi.

## Kubernetes Qanday Ishladi

**Liveness Probe Oqimi**:

```
1. Pod ishga tushadi
2. initialDelaySeconds kutadi (5 soniya)
3. Liveness probe tekshiradi (HTTP GET /nonexistent-healthz:8080)
4. 404 javob oladi ❌
5. Muvaffaqiyatsizlik hisoblagichi oshadi (1/2)
6. periodSeconds kutadi (5 soniya)
7. Yana tekshiradi → 404 ❌
8. Muvaffaqiyatsizlik hisoblagichi (2/2)
9. failureThreshold ga yetdi! → Pod ni o'ldiradi
10. Pod ni qayta ishga tushiradi
11. 1-qadamdan takrorlash → Cheksiz sikl!
```

**Kubernetes nima uchun qayta ishga tushirdi**:
- Liveness probe lar konteyner **tirik va sog'lom** ekanini aniqlaydi
- Muvaffaqiyatsiz liveness probe = "Konteyner o'lgan yoki qotib qolgan, qayta ishga tushir"
- Kubernetes "tiklab" qayta ishga tushirishga urinadi
- Lekin probe konfiguratsiyasi noto'g'ri bo'lsa, restart lar yordam bermaydi!

## To'g'ri Tushuncha Modeli

**Liveness va Readiness Probe lari farqi**:

| Probe Turi | Maqsad | Muvaffaqiyatsizlikda | Foydalanish |
|------------|--------|---------------------|-------------|
| **Liveness** | Konteyner tirikmi? | Konteynerni qayta ishga tushiradi | Deadlock, cheksiz sikl aniqlash |
| **Readiness** | Konteyner trafikka tayyormi? | Service dan olib tashlaydi | Sekin ishga tushish, dependency kutish |

**Liveness Probe Turlari**:

```yaml
# HTTP probe (eng keng tarqalgan)
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30    # Birinchi tekshirishdan oldin kutish
  periodSeconds: 10          # Qanchalik tez-tez tekshirish
  timeoutSeconds: 5          # Javob kutish vaqti
  failureThreshold: 3        # Necha muvaffaqiyatsizlikdan keyin harakat

# TCP probe (faqat port ochiqligini tekshirish)
livenessProbe:
  tcpSocket:
    port: 8080

# Exec probe (konteyner ichida buyruq bajarish)
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
```

## Haqiqiy Voqea Misoli

**Kompaniya**: SaaS platforma (500K kunlik foydalanuvchi)
**Ta'sir**: 45 daqiqalik to'liq uzilish, 100% foydalanuvchilar ta'sirlandi
**Zarar**: $750K yo'qotilgan daromad + $1.2M SLA qaytarishlari = $1.95M

**Nima sodir bo'ldi**:
Dasturchi autentifikatsiya service ga liveness probe qo'shdi:

```yaml
livenessProbe:
  httpGet:
    path: /v2/health  # v2 branch dagi yangi endpoint
    port: 8080
  failureThreshold: 2
  periodSeconds: 5
```

Muammo: PR merge bo'ldi lekin `/v2/health` endpoint deploy qilingan kodda yo'q edi — boshqa branch da edi! Haqiqiy health endpoint `/health` (v1) edi.

**Kaskad**:
```
14:00 - Deployment boshlanadi
14:01 - Birinchi pod ishga tushadi, liveness probe muvaffaqiyatsiz (404)
14:01 - Pod qayta ishga tushirildi (10 soniyada o'ldiradi)
14:02 - Barcha 50 pod restart siklida
14:03 - Service da 0 ta sog'lom endpoint
14:03 - 100% foydalanuvchilar "Service Unavailable" ko'radi
14:20 - Jamoa liveness probe muammosini aniqladi
14:25 - Tezkor tuzatish: kubectl edit deployment, /v2/health → /health
14:45 - Service to'liq tiklandi
```

**Olingan saboqlar**:
1. Deploy dan oldin health endpoint larni doim test qiling
2. Sekin ishga tushadigan ilovalar uchun uzunroq initial delay ishlating
3. Vaqtincha xatolarga chidash uchun yuqoriroq failure threshold qo'ying (3-5)
4. Bosqichma-bosqich rollout ishlating (hammasini birdan emas)
5. Restart sonini monitoring qiling — pod lar qayta-qayta ishga tushsa alert

## O'zlashtirilgan Buyruqlar

```bash
# Restart sonini tekshirish
kubectl get pods -n <namespace>
# RESTARTS ustuniga qarang

# Liveness probe muvaffaqiyatsizliklarini ko'rish
kubectl describe pod <nom> -n <namespace>
# Events: "Liveness probe failed" qidiring

# Deployment probe konfiguratsiyasini tekshirish
kubectl get deployment <nom> -n <namespace> -o yaml | grep -A 20 livenessProbe

# Deployment ni tahrirlash (probe konfiguratsiyasini tuzatish)
kubectl edit deployment <nom> -n <namespace>

# Health endpoint ni qo'lda test qilish
kubectl port-forward pod/<nom> 8080:8080 -n <namespace>
curl http://localhost:8080/healthz  # 200 qaytarishi kerak
```

## Liveness Probe Eng Yaxshi Amaliyotlari

### ✅ TO'G'RI:

1. **Mos initialDelaySeconds ishlating** — ilovaga ishga tushish vaqti bering
2. **Oqilona failureThreshold qo'ying** (3) — vaqtincha xatolarga chidash
3. **Health check larni yengil saqlang** — faqat 200 OK qaytarsin
4. **Alohida liveness va readiness probe lar ishlating**:
   - Liveness: `/healthz` — jarayon tirikmi?
   - Readiness: `/ready` — trafik qabul qilishga tayyormi?

### ❌ NOTO'G'RI:

1. Liveness va readiness uchun **bir xil probe ishlatmang**
2. Health check larni **og'ir qilmang** (DB so'rov, tozalash, migration)
3. **Juda qisqa period ishlating** (`periodSeconds: 1` — ortiqcha yuk yaratadi)
4. **initialDelaySeconds ni unutmang** — ilova 20s da ishga tushsa, 5s delay = restart sikl!

## Debug Qilish — Restart Sikllari

```bash
# 1. Pod lar qayta ishga tushyaptimi?
kubectl get pods -n <namespace>    # RESTARTS ustuniga qarang

# 2. Agar RESTARTS oshayotgan bo'lsa, pod ni describe qiling
kubectl describe pod <nom> -n <namespace>
# Events: "Liveness probe failed" qidiring

# 3. Probe konfiguratsiyasini tekshiring
kubectl get deployment <nom> -o yaml | grep -A 20 livenessProbe

# 4. Health endpoint ni qo'lda test qiling
kubectl port-forward pod/<nom> 8080:8080
curl http://localhost:8080/healthz    # 200 qaytarishi kerak

# 5. Agar endpoint noto'g'ri bo'lsa — tuzating
kubectl edit deployment <nom> -n <namespace>
```

## Keyingi Qadam

Liveness probe larni to'g'ri sozlashni o'rgandingiz.

Keyingi level: Readiness probe lar! Pod lar so'rovlarni qabul qilishga tayyor bo'lmasdan trafik yuborishni qanday oldini olishni o'rganasiz.

---

💡 **Pro maslahat**: Liveness probe lar oddiy va ishonchli bo'lishi kerak. Ishonchsiz bo'lganingizda TCP socket probe yoki faqat 200 qaytaradigan juda oddiy HTTP endpoint ishlating.
