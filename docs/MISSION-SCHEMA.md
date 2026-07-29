# mission.yaml sxemasi — `environments` overlay

Bu hujjat `mission.yaml` ning sxemasini va **muhitga xos overlay** mexanizmini
belgilaydi. Kontekst uchun [HOSTED-SANDBOX.md](HOSTED-SANDBOX.md) ni o'qing —
u nima uchun ikki muhit borligini tushuntiradi.

Bir jumlada: **K8sQuest lokal o'yin uchun yoziladi; hosted muhit — overlay.**
Base mission — lokal haqiqat. Overlay faqat hosted da farq qiladigan narsani
aytadi. Overlay yo'q bo'lsa, level ikkala muhitda bir xil.

---

## 1. Base sxema (o'zgarmadi)

Bu maydonlar hozir ham bor va **hech qanday level da o'zgarmaydi**:

```yaml
name: "Pending Pod Muammosi"
description: "Pod mavjud resurslardan ko'proq so'rayotgani uchun Pending holatida qotib qolgan"
objective: "Resource request larni moslang, shunda pod schedule qilinsin"
xp: 150
difficulty: boshlang'ich
expected_time: 12m
concepts:
  - Pod scheduling
  - Resource requests
```

30/50 level uchun `mission.yaml` **umuman o'zgarmaydi** — overlay ixtiyoriy.

---

## 2. `environments` overlay

```yaml
environments:
  hosted:
    available: false        # level hosted da o'ynalmaydi
    description: "..."      # hosted da boshqacha ta'rif
    concepts: [...]         # hosted da boshqacha tushunchalar
    expected_time: 15m
```

`environments` — muhit nomi bo'yicha map. Hozircha yagona ma'noli kalit —
`hosted`. `local` bloki **kerak emas**: base ning o'zi lokal haqiqat.

### 2.1 Nima override qilinadi — va nima QILINMAYDI

Bu ro'yxat ataylab qisqa. Sxema qoidani **majburlaydi**, intizomga
tayanmaydi:

| Maydon | Override | Nega |
|---|---|---|
| `available` | ✅ | Level muhitda prinsipial ishlamasligi mumkin |
| `description` | ✅ | Muammo qanday **ko'rinishi** muhitga bog'liq |
| `concepts` | ✅ | Mexanizm farq qiladi (masalan `Node sig'imi` → `LimitRange`) |
| `expected_time` | ✅ | Yo'l uzunligi farq qilishi mumkin |
| `setup` | ✅ | `broken.yaml` ni kim qo'llaydi — yo'l, dars emas |
| **`objective`** | ❌ | **Bu — darsning o'zi.** Muhitga qarab o'zgarsa, bu boshqa level |
| **`name`** | ❌ | Bir level — bir nom |
| **`xp`**, **`difficulty`** | ❌ | Bir xil dars = bir xil mukofot |

`objective` ni override qilib bo'lmasligi — sxemaning **asosiy xususiyati**.
HOSTED-SANDBOX §5 dagi "darsni o'zgartirmang" qoidasi shu tarzda kod bilan
qo'llanadi: overlay da `objective:` yozsangiz, u shunchaki e'tiborsiz qoladi
(va linter xato beradi).

### 2.2 `setup: auto | manual`

- **`auto`** (sukut) — platforma `broken.yaml` ni o'zi qo'llaydi. Foydalanuvchi
  tayyor buzilgan holatni ko'radi. 49/50 level shunday.
- **`manual`** — platforma `broken.yaml` ni faqat ish katalogiga yozadi;
  qo'llashni foydalanuvchi o'zi qiladi.

`manual` **buzilgan holat admission da tug'ilganda** kerak: manifest
namespace ning LimitRange/ResourceQuota siga urilib rad etiladi. Bunday
levelda `apply` ning **o'z xatosi** — darsning boshlanishi.

Bu jonli o'ynash paytida topilgan: `auto` da server `apply` ni o'zi bajaradi,
admission rad etadi va setup **500 bilan yiqiladi** — foydalanuvchi levelga
umuman kirolmaydi (bu BUG-022 ning ildizi).

`auto` da apply xatosi HAMON 500 bo'lib qoladi. Aks holda haqiqiy nosozlik
(klaster yiqilgan) "level holati" bo'lib ko'rinardi — bu BUG-024 dagi xato.

Noma'lum qiymat `auto` ga tushadi va log ga warning yoziladi.

### 2.3 `available: false` ning ma'nosi

Level ro'yxatda **"faqat lokal o'yinda" belgisi bilan ko'rinadi**, lekin:

- boshlab bo'lmaydi,
- XP hisoblanmaydi,
- **progressiya undan o'tishni talab qilmaydi** (world foizi faqat mavjud
  levellar bo'yicha hisoblanadi).

Butunlay yashirish emas — foydalanuvchi kontent borligini va uni lokal o'yinda
o'ynash mumkinligini bilsin. O'chirish esa umuman emas: bu levellar lokal
o'yinda to'g'ri va qimmatli.

---

## 3. Fayl overlay — konvensiya bo'yicha

Overlay fayllari level katalogi ichidagi **`hosted/`** katalogida yashaydi.
`mission.yaml` da fayl ro'yxati **yozilmaydi** — hal qilish konvensiya bilan:

```
level-4-pending/
├── mission.yaml          ← base + environments overlay
├── broken.yaml           ← lokal (haqiqiy Pending)
├── solution.yaml
├── hint-1.txt
├── hint-2.txt
├── hint-3.txt
├── validate.sh           ← IKKALA muhitda bir xil
├── debrief.md
└── hosted/
    ├── hint-1.txt        ← hosted da bu ustun turadi
    ├── hint-2.txt
    └── hint-3.txt
```

**Hal qilish qoidasi:** hosted muhitda `X` fayli so'ralganda —
`hosted/X` bor bo'lsa o'sha, aks holda `X`. Lokal o'yin `hosted/` ga
**hech qachon qaramaydi**.

### 3.1 Overlay qilsa bo'ladigan fayllar

`broken.yaml`, `solution.yaml`, `hint-*.txt`, `debrief.md`,
`common-mistakes.md`.

### 3.2 `validate.sh`

Overlay **texnik jihatdan mumkin, lekin sukut bo'yicha qilinmaydi.**
`validate.sh` ikkala muhitda bir xil bo'lishi — darsning bir xilligining
isboti. Agar u farq qilsa, demak levellar **turli narsani tekshiryapti** →
dars ikkiga bo'lingan.

Override qilish kerak bo'lsa, `CHANGELOG.md` da alohida asoslang: nega
tekshiruv farq qiladi va dars baribir bir xil ekani.

### 3.3 `mission.yaml` overlay qilinmaydi

Bitta manba — base fayl. Overlay uning **ichida** yashaydi (§2). `hosted/mission.yaml`
e'tiborsiz qoldiriladi (linter xato beradi).

---

## 4. Nima uchun aynan shunday

**Nega `environments: [local]` (ro'yxat) emas?**
HOSTED-SANDBOX ning dastlabki taklifi shunday edi. Lekin bizga ikki xil narsa
kerak: *mavjudlik* va *override lar*. Bitta kalitni ba'zan ro'yxat, ba'zan map
qilish — tip noaniqligi. Map bilan ikkalasi ham bir joyda va bir xil shaklda.

**Nega fayllar `mission.yaml` da ro'yxatlanmaydi?**
Har bir fayl uchun yozuv qo'shilsa, `mission.yaml` shishadi va ro'yxat kod
bilan sinxrondan chiqadi. Konvensiya (`hosted/` katalogi) o'zini o'zi
hujjatlaydi: katalogga qarab nima override qilinganini ko'rasiz.

**Nega `hosted/` katalogi xavfsiz?**
Tekshirilgan:
- Hosted loader (`content/github.go`) level ni yo'lning 3-qismi `level-` bilan
  boshlanishiga qarab aniqlaydi → `hosted/` fantom level yaratmaydi.
- `yaml.Unmarshal` `KnownFields` siz ishlaydi → eski binar `environments` ni
  e'tiborsiz qoldiradi.
- Lokal engine `yaml.safe_load` bilan faqat o'zi biladigan kalitlarni o'qiydi.
- `utils/audit_levels.sh` `worlds/*/level-*` bo'yicha yuradi, ichkariga kirmaydi.

---

## 5. ⚠️ Joriy qilish tartibi — MUHIM

Eski hosted binar `environments` ni **e'tiborsiz qoldiradi**. Ya'ni sxema
**fail-open**: W5 L45 ni `available: false` deb belgilasangiz, sxemani
bilmaydigan platforma uni baribir ko'rsatadi va foydalanuvchi buzilgan levelga
tushadi.

Shuning uchun tartib qat'iy:

1. **Avval platforma** — k8s-dojo `environments` va `hosted/` ni qo'llab-quvvatlasin, deploy qilinsin.
2. **Keyin kontent** — mission.yaml larga overlay qo'shilsin.

Teskari tartib — regressiya. (Kontent alohida repoda va API uni 10 daqiqada
avtomatik oladi, ya'ni kontent o'zgarishi deploysiz yetib boradi — bu qulaylik
aynan shu yerda tuzoq.)

---

## 6. Linter

`utils/lint_schema.sh` (yozilishi kerak) quyidagilarni tekshiradi:

- overlay da faqat ruxsat etilgan kalitlar (`available`, `description`,
  `concepts`, `expected_time`, `setup`);
- `setup` qiymati faqat `auto` yoki `manual`;
- `objective`/`name`/`xp`/`difficulty` overlay da **yo'q**;
- `hosted/` da faqat ruxsat etilgan fayllar; `hosted/mission.yaml` yo'q;
- `hosted/validate.sh` bo'lsa — CHANGELOG da shu level haqida yozuv bor.

---

## 7. Misol: W1 L4

Dars: "resource request lar juda katta → tuzating". Fix ikkala muhitda **bir
xil**: `999` → `64Mi`/`100m`. Farq — xatoni kim qaytaradi:

- **Lokal:** scheduler → pod `Pending`, `describe` Events da `Insufficient cpu`.
- **Hosted:** LimitRange admission → `apply` ning o'zi rad etadi:
  `Invalid value: "999": must be less than or equal to cpu limit of 200m`.

Ikkalasi ham haqiqiy dars. `objective`, `solution.yaml`, `validate.sh`
o'zgarmaydi.

```yaml
# worlds/world-1-basics/level-4-pending/mission.yaml
name: "Pending Pod Muammosi"
description: "Pod mavjud resurslardan ko'proq so'rayotgani uchun Pending holatida qotib qolgan"
objective: "Resource request larni moslang, shunda pod schedule qilinsin"
xp: 150
difficulty: boshlang'ich
expected_time: 12m
concepts:
  - Pod scheduling
  - Resource requests
  - Resource limits
  - kubectl describe
  - Pending holati
  - Node sig'imi (capacity)

environments:
  hosted:
    setup: manual
    description: "Pod ning resource request lari namespace limitidan oshib ketgan — admission uni rad etmoqda"
    concepts:
      - Pod scheduling
      - Resource requests
      - Resource limits
      - LimitRange
      - Admission nazorati
      - Xato xabarini o'qish
```

Va `hosted/hint-1.txt` … `hosted/hint-3.txt` — `describe` → Events yo'li
o'rniga `apply` xatosini o'qish yo'lini aytadi.
