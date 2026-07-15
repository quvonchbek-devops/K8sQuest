# K8sQuest — Hosted Sandbox uchun qoidalar

> Bu hujjat K8sQuest kontentini **ikki xil muhitda** ishlashi uchun yozilgan.
> Level yozayotgan yoki tahrirlayotgan bo'lsangiz, avval shuni o'qing.

---

## 1. Nega bu hujjat kerak

K8sQuest dastlab **bir kishilik lokal o'yin** sifatida yaratilgan: `play.sh`
sizning mashinangizga k3s o'rnatadi, siz o'z clusteringizda **cluster-admin**
bo'lasiz, level fayllari esa diskingizda yotadi.

Endi xuddi shu kontent **k8s-dojo** platformasida ham ishlatiladi — bu
brauzerdan kiriladigan, **ko'p ijarachili** (multi-tenant) hosted xizmat. U
yerda har foydalanuvchi:

- umumiy clusterdagi **bitta namespace** ga ega (`sandbox-001`, `sandbox-002`…)
- **cluster-admin emas** — namespace-scoped ServiceAccount nomidan ishlaydi
- **fayl tizimiga ega emas** (`broken.yaml`, so'ralganda `solution.yaml`)
- **muharrir va TTY siz** ishlaydi
- **node ga tega olmaydi** — node barcha foydalanuvchilar uchun umumiy

Ikki muhit o'rtasidagi farq:

| | Lokal o'yin (`play.sh`) | Hosted (k8s-dojo) |
|---|---|---|
| Cluster | sizniki | umumiy, ko'p foydalanuvchi |
| Huquq | cluster-admin | namespace-scoped SA |
| Fayl tizimi | to'liq disk | `broken.yaml` + `solution.yaml` |
| Muharrir / TTY | bor | **yo'q** |
| Node | sizniki | umumiy — tegib bo'lmaydi |
| Namespace | `k8squest` | `sandbox-NNN` (avtomatik almashtiriladi) |

**Kontent noto'g'ri emas — u lokal o'yin uchun to'g'ri yozilgan.** Muammo
shundaki, ba'zi level lar hosted muhitda **prinsipial** ishlay olmaydi.

Bu hujjatning maqsadi: level lar **ikkala muhitda ham** ishlashi uchun qoidalar
berish. Ya'ni lokal o'yin buzilmasin, hosted da ham ishlasin.

---

## 2. Oltin qoida

> **Level ning darsi (mohiyati) o'zgarmasin — faqat unga olib boradigan yo'l
> ikkala muhitda ham bosib o'tiladigan bo'lsin.**

Masalan "Deployment da `replicas: 0`" darsini o'zgartirish shart emas. Faqat
hint `kubectl edit` o'rniga `kubectl scale` ni aytsin — chunki `edit` hosted da
muharrir talab qiladi va u yerda muharrir yo'q. Dars bir xil, yo'l boshqa.

---

## 3. Qoidalar

### 3.1 Namespace — `k8squest` deb yozing

Platforma uni avtomatik almashtiradi (`broken.yaml` da YAML parse bilan,
`validate.sh` da matn almashtirish bilan). Hint larda ham `-n k8squest` deb
yozaverish mumkin — platforma buni buyruqdan olib tashlaydi.

✅ `kubectl get pods -n k8squest`
❌ `kubectl get pods -n default` — hosted da 403

### 3.2 Fayllar — `broken.yaml` va `solution.yaml`

Hosted da foydalanuvchining sessiya katalogiga `broken.yaml` yoziladi (namespace
almashtirilgan holda). Ya'ni bular ishlaydi:

```bash
kubectl apply -f broken.yaml
kubectl delete -f broken.yaml && kubectl apply -f broken.yaml   # reset naqshi
```

**`solution.yaml` — so'ralganda beriladi ✅**

Lokal o'yinda solution.yaml level katalogida shunchaki yotadi: "javob mavjud,
unga qarash sizning ixtiyoringizda". Hosted da u ham beriladi, lekin
foydalanuvchi uni ochiq so'raydi ("Yechimni ko'rsatish") va u **hint kabi
hisoblanadi**. Shundan keyin:

```bash
kubectl apply -f solution.yaml    # ✅
```

Ya'ni hint larda `apply -f solution.yaml` deb yozaverish mumkin — o'zgartirish
shart emas.

Yo'l va URL ham ishlamaydi (`-f` faqat oddiy fayl nomini qabul qiladi):

❌ `kubectl apply -f https://.../components.yaml`
❌ `kubectl apply -f ../../etc/passwd`

### 3.3 `kubectl edit` ishlatmang — TTY yo'q

Hosted terminal bir martalik buyruq bajaradi, interaktiv muharrir ochib
bo'lmaydi:

```
$ kubectl edit deploy web
vi: can't read user input
error: there was a problem with the editor "vi"
```

❌ `kubectl edit deploy web`
✅ `kubectl patch deploy web -p '{"spec":{"replicas":1}}'`
✅ `kubectl set image deploy/web nginx=nginx:1.25`
✅ `kubectl scale deploy web --replicas=3`

Xuddi shu sabab: `kubectl exec -it` ham ishlamaydi. Interaktiv bo'lmagan
`kubectl exec pod -- <buyruq>` esa ishlaydi.

### 3.4 Cluster-scoped resurs yaratmang

Hosted da namespace — chegara. Cluster-scoped resurs barcha foydalanuvchilarga
tegishli va **nomi qat'iy bo'lsa ikki foydalanuvchi to'qnashadi**.

❌ `PersistentVolume`, `StorageClass`, `ClusterRole`, `ClusterRoleBinding`
❌ `Namespace` yaratish (ikkinchi namespace talab qiladigan level lar)
❌ qat'iy `clusterIP: 10.96.100.50` — allocate qilib bo'lmaydi / to'qnashadi

✅ `PersistentVolumeClaim` + dynamic provisioner (k3s da `local-path`)
✅ `emptyDir`

### 3.5 `hostPath` ishlatmang

`hostPath` node ning haqiqiy diskiga yozadi. Hosted da node umumiy, ya'ni bu
ijarachilar orasidagi chegarani buzadi.

Alohida ogohlantirish: Pod Security Admission pod spec idagi `hostPath` ni
bloklaydi, lekin **PVC orqali bog'langan hostPath ni ko'rmaydi** (u pod spec
ida `persistentVolumeClaim` bo'lib ko'rinadi). Ya'ni hostPath li PV yaratish
PSA ni chetlab o'tadi — bu tasodifiy emas, K8s ning ma'lum xususiyati.

❌ `hostPath: /tmp/k8squest-data`
✅ `emptyDir: {}` yoki dynamic PVC

### 3.6 Node ga tegmang

Node barcha foydalanuvchilar uchun umumiy. Node ga label qo'yish yoki taint
berish **boshqalarning scheduling iga ta'sir qiladi**.

❌ `kubectl label nodes <node> disk-type=ssd`
❌ `kubectl taint nodes ...`, `kubectl drain ...`
❌ `kubectl get nodes`

Bu level lar hosted da **prinsipial** ishlay olmaydi. Ular yo lokal-only deb
belgilanadi, yo namespace darajasidagi ekvivalent bilan qayta loyihalanadi.

### 3.7 Resurs limitlari

Hosted sandbox da har namespace uchun:

| | Qiymat |
|---|---|
| ResourceQuota | CPU `500m`, RAM `256Mi`, pods `10` |
| LimitRange default | CPU `200m`, RAM `128Mi` |
| LimitRange max | CPU `500m`, RAM `256Mi` |

`requests` container ning `limits` idan katta bo'lsa, pod **yaratilmaydi** —
foydalanuvchi muammoni emas, bo'sh namespace ni ko'radi.

❌ `requests: {cpu: "999", memory: "999Gi"}`
✅ limitlar ichida qoling

Agar level uchun boshqa limit **shart** bo'lsa, `mission.yaml` da e'lon qiling
(platforma buni level setup ida qo'llaydi):

```yaml
sandbox:
  cpu: "2"
  memory: "1Gi"
  limitrange: false
```

### 3.8 Bloklangan buyruqlar

Hosted validator quyidagilarni rad etadi:

| Buyruq/flag | Sabab |
|---|---|
| `exec -it`, `attach` | TTY yo'q |
| `port-forward`, `proxy` | uzoq muddatli oqim — bir martalik exec modeliga mos emas |
| `-w`, `--watch`, `logs -f` | cheksiz kutadi, buyruq 15s dan oshmasligi kerak |
| `drain`, `taint`, `cordon` | node amallari |
| `--kubeconfig`, `--token`, `--as`, `-s` | identity almashtirish |
| `\|`, `;`, `\|\|`, `$()` | shell metabelgilari (`&&` — ISHLAYDI) |

Hint larda **shell metabelgilarini ishlatmang**:

❌ `kubectl get deploy web -o yaml | grep -A5 strategy`
✅ `kubectl get deploy web -o jsonpath='{.spec.strategy}'`

Diqqat: `&&` **ishlaydi** ✅ — server uni bo'lib, har qismni alohida
validatsiyadan o'tkazadi (ko'pi bilan 5 ta buyruq):

```bash
kubectl delete -f broken.yaml && kubectl apply -f broken.yaml   # ✅ reset naqshi
```

`;`, `||` va `|` hamon bloklangan — `|` haqiqiy shell talab qiladi.

### 3.9 Tirnoqlar — ishlaydi ✅

Hosted terminal tirnoqlarni shell kabi parse qiladi, ya'ni rasmiy Kubernetes
hujjatlaridagi buyruqlarni **o'zgarishsiz** yozish mumkin:

```bash
kubectl patch deploy web -p '{"spec":{"replicas":2}}'      # ✅
kubectl get pod x -o jsonpath='{.status.phase}'            # ✅
kubectl create cm x --from-literal=msg='salom dunyo'       # ✅
```

Lekin bu **shell emas** — expansion yo'q. Bular oddiy matn sifatida ketadi:

❌ `$HOME`, `$(date)`, `*.yaml`, `~/config`

(2026-07-15 gacha tirnoqlar buzilgan edi — k8s-dojo BUG-027. Tuzatildi.)

---

## 4. Hozirgi holat — moslashtirish kerak bo'lgan level lar

2026-07-15 dagi skan (hint matni + `broken.yaml` ni hosted sandbox ga
`--dry-run=server` bilan yuborish).

### ✅ Platformada hal qilindi — kontentga tegilmadi

Bular dastlab "kontent muammosi" deb belgilangan edi, lekin platformada
tuzatilgani uchun **kontent o'zgarishsiz ishlaydi**:

| Muammo | Level lar | Yechim |
|---|---|---|
| `-f broken.yaml` ishlamasdi | 39 | sessiya ish katalogi |
| `-f solution.yaml` ishlamasdi | 11 | `POST /solution` (hint kabi hisoblanadi) |
| `-n k8squest` → 403 | 49 | validator placeholder ni olib tashlaydi |
| Tirnoqlar buzilardi | ~barchasi | tokenizer (BUG-027) |
| `&&` bloklangan edi | reset naqshi | server tomonida bo'linadi |
| `scale`/`patch`/`edit`/`set`/`label` noto'g'ri world da | 15 → 0 | world jadvali kontentga moslandi |

### ⚠️ Kontent o'zgarishi kerak

| Level | Muammo | Yechim |
|---|---|---|
| W2 L12, L13, L15, L16, L17; W3 L21, L22 | hint faqat `kubectl edit` ni aytadi, TTY yo'q | `patch` / `set` ga o'tkazish |
| W2 L15 | hint da pipe: `-o yaml \| grep -A5 strategy` | `-o jsonpath=...` |
| W1 L4 | `999` CPU > default limit `200m` — pod umuman yaratilmaydi | `sandbox:` override yoki `nodeSelector` bilan qayta loyihalash |
| W5 L43 | limit `2Gi` > max `256Mi` | `sandbox:` override |
| W5 L49 | `512Mi` > `128Mi` | `sandbox:` override |
| W4 L31, L32, L33 | `hostPath` + cluster-scoped PV | `emptyDir` / dynamic PVC |
| W3 L27 | ikkinchi namespace (`backend-ns`) | qayta loyihalash |
| W3 L30 | qat'iy `clusterIP: 10.96.100.50` | clusterIP ni olib tashlash |
| W5 L41 | SA + Role + RoleBinding yaratish | qayta loyihalash |
| W2 L14 | `apply -f https://.../metrics-server` — cluster-wide o'rnatish | qayta loyihalash |

### 🔴 Hosted da prinsipial mumkin emas

| Level | Sabab |
|---|---|
| W5 L45 | `kubectl label nodes` — node umumiy |
| W5 L46 | `kubectl taint nodes` — node umumiy |
| W2 L16 | `kubectl drain` — node amali |
| W1 L6, W3 L29 | `port-forward` — uzoq muddatli oqim |

Bular `environments: [local]` deb belgilanadi. **O'chirilmaydi** — lokal
o'yinda ular to'g'ri va qimmatli.

W5 L44 (`exec`) — interaktiv bo'lmagan `exec` ochilsa ishlaydi (rejada).

## 5. O'zgartirish protokoli

Har bir level ni moslashtirganda:

1. **Darsni aniqlang.** `mission.yaml` dagi `objective` va `concepts` —
   o'zgarmasligi kerak.
2. **Faqat yo'lni o'zgartiring.** Hint lardagi buyruqlarni yuqoridagi
   qoidalarga moslang.
3. **Lokal o'yinda ham ishlashini tekshiring.** `patch` va `scale` ikkala
   muhitda ishlaydi; `edit` faqat lokalda. Shuning uchun `patch` ga o'tish
   xavfsiz — lokal o'yin buzilmaydi.
4. **`validate.sh` ga tegmang**, agar dars o'zgarmasa. U ikkala muhitda bir xil.
5. **CHANGELOG.md ga yozing** — nima, nega, qaysi level.

Agar level hosted da prinsipial ishlamasa (node, cluster-scoped), uni
`mission.yaml` da belgilang:

```yaml
environments:
  - local        # faqat lokal o'yinda
```

Platforma bunday level larni ro'yxatda ko'rsatmaydi yoki "faqat lokal" deb
belgilaydi. Bu level ni o'chirishdan afzal — lokal o'yin uchun u to'g'ri va
qimmatli.

---

## 6. Tekshirish

Level ni o'zgartirgach, hosted muhitda ishlashini tekshirish:

```bash
# broken.yaml ni sandbox namespace ga admission tekshiruvidan o'tkazish
curl -s http://localhost:8181/api/v1/content/worlds/<world>/levels/<level>/broken \
  | sed 's/k8squest/sandbox-003/g' \
  | kubectl apply --dry-run=server -n sandbox-003 -f -
```

Xato bo'lmasa — `broken.yaml` sandbox limitlariga sig'adi.

Hint larni tekshirish: ularda `edit`, `solution.yaml`, `nodes`, `hostPath`,
`&&`, `|`, `-w`, `port-forward`, `exec -it` bo'lmasligi kerak.

---

## 7. Bog'liq hujjatlar

- `CHANGELOG.md` — moslashtirish o'zgarishlari tarixi
- k8s-dojo repo: `docs/KNOWN-BUGS.md` — platforma tomonidagi bug lar
- k8s-dojo repo: `docs/AUDIT-2026-07-15.md` — to'liq audit
