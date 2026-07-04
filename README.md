# K8sQuest 🕹️⚙️

**Kubernetes ni o'rganish uchun interaktiv terminal o'yini**

50 ta level, 5 ta dunyo — buzilgan Kubernetes resurslarni tuzatib, amaliy tajriba orqali o'rganing.

> 🇺🇿 Bu versiya to'liq **o'zbek tilida** tarjima qilingan.

## 🎮 O'yin Haqida

K8sQuest — bu Kubernetes muammolarni hal qilish orqali o'rganishga mo'ljallangan terminal asosidagi o'yin. Har bir levelda buzilgan YAML konfiguratsiya beriladi va siz `kubectl` yordamida muammoni aniqlab, tuzatishingiz kerak.

### 🌍 Dunyo (World) lar

| Dunyo | Mavzu | Level lar | Qiyinlik |
|-------|-------|-----------|----------|
| 🟢 World 1 | Asoslar (Pod, Deployment, Label, Namespace) | 1-10 | Boshlang'ich |
| 🔵 World 2 | Deployment va Scaling (Rollback, Probe, HPA, Canary) | 11-20 | O'rta |
| 🟡 World 3 | Networking (Service, DNS, Ingress, NetworkPolicy) | 21-30 | O'rta |
| 🟠 World 4 | Storage (PVC, Volume, ConfigMap, Secret) | 31-40 | O'rta-Ilg'or |
| 🔴 World 5 | Xavfsizlik (RBAC, SecurityContext, PDB, Taint) | 41-50 | Ilg'or |

### 🎯 Har Bir Level Tarkibi

- **mission.yaml** — missiya tavsifi va maqsad
- **broken.yaml** — buzilgan konfiguratsiya (siz tuzatasiz)
- **hint-1/2/3.txt** — 3 bosqichli maslahatlar
- **validate.sh** — yechimingizni tekshirish
- **debrief.md** — chuqur tushuntirish, haqiqiy voqea misollari, intervyu savollari
- **solution.yaml** — to'g'ri yechim

## 🚀 O'rnatish

### Talablar
- Kubernetes klaster (k3s, kind, minikube yoki Docker Desktop)
- `kubectl` o'rnatilgan va sozlangan
- Python 3.8+
- `jq` (ba'zi levellar uchun)

### Tez Boshlash

```bash
# Repo ni clone qilish
git clone https://github.com/nosirbekdev/k8squest-uz.git
cd k8squest-uz

# Dependency larni o'rnatish
pip install -r requirements.txt

# O'yinni boshlash
./play.sh
```

### k3s Bilan Boshlash (tavsiya etiladi)

```bash
# k3s o'rnatish
curl -sfL https://get.k3s.io | sh -

# Kubeconfig sozlash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# O'yinni boshlash
./play.sh
```

## 🎮 O'ynash

### Asosiy Buyruqlar (o'yin ichida)

| Buyruq | Tavsif |
|--------|--------|
| `hints` | 💡 Maslahatlarni ko'rish (3 bosqich) |
| `guide` | 📖 Bosqichma-bosqich ko'rsatmalar |
| `validate` | ✅ Yechimni tekshirish |
| `skip` | ⏭️ Leverni o'tkazib yuborish |
| `quit` | 🚪 O'yindan chiqish |

### O'ynash Jarayoni

1. 🎯 Missiya tavsifini o'qing
2. 🔍 `kubectl` bilan muammoni aniqlang
3. 🔧 YAML ni tahrirlang yoki buyruqlar bilan tuzating
4. ✅ `validate` buyrug'i bilan tekshiring
5. 📚 `debrief` da chuqur tushuntirishni o'qing

## 📊 XP Tizimi

Har bir level XP (tajriba ballari) beradi:
- Boshlang'ich level lar: 100-150 XP
- O'rta level lar: 200-250 XP
- Ilg'or level lar: 250-300 XP
- **Jami: 10,200 XP** (50 level)

## 🏗️ Loyiha Tuzilishi

```
k8squest/
├── play.sh              # Asosiy o'yin skripti
├── install.sh           # O'rnatish skripti
├── engine/              # O'yin mexanizmi (Python)
│   ├── engine.py        # Asosiy o'yin logikasi
│   ├── retro_ui.py      # Terminal UI
│   └── ...
├── worlds/              # O'yin kontenti
│   ├── world-1-basics/
│   ├── world-2-deployments/
│   ├── world-3-networking/
│   ├── world-4-storage/
│   └── world-5-security/
└── README.md            # Shu fayl
```

## 🤝 Hissa Qo'shish

Xatolarni topsangiz yoki yaxshilash takliflaringiz bo'lsa, Issue yoki Pull Request oching.

## 📜 Litsenziya

MIT License — tafsilotlar uchun [License](License) faylini ko'ring.

## 🙏 Minnatdorchilik

- Original loyiha: [Manoj-engineer/k8squest](https://github.com/Manoj-engineer/k8squest)
- O'zbek tiliga tarjima: [@nosirbekdev](https://github.com/nosirbekdev)

---

**O'ynang, o'rganing, Kubernetes ustasi bo'ling!** 🏆
