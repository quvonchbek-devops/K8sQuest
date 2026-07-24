# 🎓 Missiya Yakuni: ImagePullBackOff Jumboqi

## Nima Sodir Bo'ldi

Pod `ImagePullBackOff` holatida qotib qoldi, chunki Kubernetes `nginx:nonexistent-tag-xyz-123` konteyner image ni Docker Hub dan torta olmadi. Bu tag mavjud emas, shuning uchun kubelet qayta-qayta urinib, urinishlar orasida kutdi (backoff).

## Kubernetes Qanday Ishladi

Pod yaratganingizda, Kubernetes bir necha bosqichdan o'tadi:

1. **Pending**: Pod qabul qilindi, schedule qilinishini kutmoqda
2. **ContainerCreating**: Schedule qilindi, image lar tortilmoqda
3. **Running**: Barcha konteynerlar muvaffaqiyatli ishga tushdi

Pod 2-bosqichda qotib qoldi. Node dagi kubelet image ni tortishga urindi, muvaffaqiyatsiz bo'ldi, biroz kutdi (backoff), va qayta urindi. Bu `ImagePullBackOff` holatini yaratadi.

## To'g'ri Tushuncha Modeli

**Konteyner image lari** — bu ilovangiz uchun chizmalar (blueprint) kabi. Ular quyidagilardan iborat:
- **Repository**: Image qayerda saqlanadi (masalan, `nginx`, `mysql`, `myapp`)
- **Tag**: Aniq versiya (masalan, `latest`, `1.21`, `v2.0.3`)
- **To'liq manzil**: `repository:tag` (masalan, `nginx:1.21`)

**Image tortish jarayoni**:
```
kubectl apply → Scheduler node ga tayinlaydi → Kubelet image tortadi → Konteyner yaratadi → Pod ishlaydi
                                                   ↑
                                              Shu yerda qotib qoldingiz!
```

Keng tarqalgan xatolar:
- Image nomlarida imlo xatolari
- Mavjud bo'lmagan tag lar
- Pull secret siz shaxsiy (private) image lar
- Noto'g'ri registry URL lari

## Haqiqiy Voqea Misoli

**Kompaniya**: Yirik elektron tijorat platformasi
**Ta'sir**: Mahsulot chiqarish vaqtida 2 soatlik uzilish
**Zarar**: $800K yo'qotilgan savdo

**Nima sodir bo'ldi**:
Dasturchi kodni `v2.3.1` image tag bilan push qildi, lekin CI/CD pipeline `v2.3.0` ni build qilgan edi. Deployment mavjud bo'lmagan `v2.3.1` tag ga murojaat qildi. Muhim mahsulot chiqarish vaqtida barcha pod lar ImagePullBackOff ga tushdi.

**Nega 2 soat davom etdi**:
- ImagePullBackOff uchun monitoring alert yo'q edi
- Jamoa deployment muvaffaqiyatli deb o'yladi (u muvaffaqiyatli edi — faqat pod lar ishga tusholmadi)
- Image mavjudligini tekshirish o'rniga ilova kodini debug qilishga vaqt sarflandi

**Yechim**: `kubectl describe pod` da muammoni sezishdi, tag ni to'g'riladilar, va pod lar 30 soniyada ishga tushdi.

**Saboq**: Deploy qilishdan oldin doim image mavjudligini tekshiring. Lokal da `docker pull <image>` ishlating yoki konteyner registry interfeysini tekshiring.

## O'zlashtirilgan Buyruqlar

```bash
# Pod holatini tekshirish
kubectl get pod <nom> -n <namespace>

# Batafsil event larni ko'rish (eng yaxshi do'stingiz!)
kubectl describe pod <nom> -n <namespace>

# Ishlatilayotgan aniq image ni tekshirish (image: qatorini toping)
kubectl get pod <nom> -n <namespace> -o yaml

# Image ni to'g'rilash — jonli podda, faylsiz (bu platformada shu ishlaydi)
kubectl set image pod/<nom> <konteyner>=<image> -n <namespace>

# Haqiqiy klasterda manifest fayl bilan ishlaganda esa:
#   kubectl apply -f <fayl>.yaml
```

## Oldini Olish Strategiyalari

1. Production da `latest` emas, **aniq tag lar ishlating**
2. Image lar mavjudligini tekshirish uchun CI/CD da **image scanning** joriy qiling
3. ImagePullBackOff event lari uchun **alert lar sozlang**
4. Deploy dan oldin image manzillarini tekshirish uchun **admission controller lar** ishlating
5. Muhim image lar uchun **lokal registry mirror** saqlang

## Keyingi Qadam

Endi siz ikkita pod nosozlik turini o'zlashtirgansiz:
- ✅ CrashLoopBackOff (noto'g'ri konteyner buyrug'i)
- ✅ ImagePullBackOff (noto'g'ri image manzili)

Keyingi — resurslar yetishmagan paytda pod scheduling muammolarini o'rganasiz!
