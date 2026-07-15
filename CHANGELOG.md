# CHANGELOG

K8sQuest kontentidagi o'zgarishlar tarixi.

Format: [Keep a Changelog](https://keepachangelog.com/), sanalar ISO 8601.

**Har bir level o'zgarishi uchun yozing:** qaysi level, nima o'zgardi, **nega**,
va darsning mohiyati saqlanganini tasdiqlang. Sabab eng muhimi — keyingi odam
(yoki siz, olti oydan keyin) "bu nega shunday?" deb so'raganda javob shu yerda
bo'lsin.

---

## [Chiqarilmagan]

### Qo'shildi

- `docs/HOSTED-SANDBOX.md` — kontentni **ikki muhitda** (lokal `play.sh` o'yini
  va hosted k8s-dojo platformasi) ishlashi uchun qoidalar.

  **Nega:** K8sQuest dastlab bir kishilik lokal o'yin sifatida yozilgan — siz
  o'z k3s ingizda cluster-admin siz va fayllar diskingizda. k8s-dojo esa xuddi
  shu kontentni hosted, ko'p ijarachili muhitda ishlatadi: bitta namespace,
  namespace-scoped SA, fayl tizimi yo'q, TTY yo'q, node umumiy.

  2026-07-15 dagi avtomatik skan 50 leveldan ~20 tasi hosted muhitda
  ishlamasligini ko'rsatdi. Bu kontentning xatosi emas — u o'z muhiti uchun
  to'g'ri. Hujjat farqni va moslashtirish qoidalarini qayd etadi.

- `CHANGELOG.md` (shu fayl).

### Platformada hal qilindi — kontentga tegilmadi

k8s-dojo tomonida tuzatilgani uchun quyidagilar uchun **kontent o'zgarishi
kerak emas**. Dastlabki rejada bular 1, 2 va 3-ustuvorlik edi:

| Muammo | Level lar | Platforma yechimi |
|---|---|---|
| `-f broken.yaml` | 39 | sessiya ish katalogi |
| `-f solution.yaml` | 11 | `POST /solution` — hint kabi hisoblanadi |
| `-n k8squest` → 403 | 49 | validator placeholder ni kesadi |
| Tirnoqlar (`-p '{...}'`) | ~barchasi | tokenizer (BUG-027) |
| `&&` reset naqshi | — | server tomonida bo'linadi |
| verb noto'g'ri world da | 15 | world jadvali kontentga moslandi |

**Tamoyil:** har bir muammoni platformada hal qila olsak, kontentga tegmaymiz.
K8sQuest — lokal o'yin uchun to'g'ri yozilgan; uni hosted uchun buzish o'rniga
platforma moslashadi.

### Rejalashtirilgan (kontent o'zgarishi SHART bo'lganlar)

| Ustuvorlik | Ish | Level lar |
|---|---|---|
| 1 | `kubectl edit` → `patch` / `set` (TTY yo'q) | W2 L12, L13, L15, L16, L17; W3 L21, L22 |
| 2 | pipe → `jsonpath` | W2 L15 |
| 3 | Resurs limitlariga moslash yoki `sandbox:` override | W1 L4, W5 L43, W5 L49 |
| 4 | `hostPath` → `emptyDir` / dynamic PVC | W4 L31, L32, L33 |
| 5 | Cluster-scoped resurslarni olib tashlash | W3 L27, L30; W4 L31; W5 L41; W2 L14 |
| 6 | `environments: [local]` deb belgilash | W5 L45, L46; W2 L16; W1 L6; W3 L29 |

**6 — o'chirish emas:** node va port-forward level lari lokal o'yinda to'g'ri
va qimmatli, ular faqat hosted da ko'rsatilmaydi.

---

## Eslatma: nima O'ZGARMAYDI

Moslashtirish paytida quyidagilarga tegilmaydi:

- `mission.yaml` dagi `objective` va `concepts` — bu levelning **darsi**
- `validate.sh` — u ikkala muhitda bir xil ishlaydi
- `solution.yaml` — lokal o'yin uchun kerak
- `debrief.md`, `common-mistakes.md` — tushuntirish matni

Faqat **yechimga olib boradigan yo'l** o'zgaradi. Agar biror o'zgarish darsning
mohiyatini o'zgartirsa — u CHANGELOG da alohida asoslanishi kerak.
