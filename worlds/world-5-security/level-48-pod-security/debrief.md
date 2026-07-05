# 🎓 Missiya Yakuni: Pod Security Standards

**Tabriklaymiz!** Siz o'zlashtirgansiz Pod Security Standards!

---

## Pod Security Standards

Xavfsizlikni ta'minlashning uch darajasi:

### 1. Privileged (Unrestricted)
No restrictions - use with caution!

### 2. Baseline (Minimal)
Ma'lum privilege escalation larning oldini oladi:
- No privileged containers
- No host path volumes
- No host networking

### 3. Restricted (Hardened)
Xavfsizlik eng yaxshi amaliyotlari (siz hozirgina amalga oshirgansiz):
- ✅ runAsNonRoot ni: true
- ✅ allowPrivilegeEscalation ni: false
- ✅ capabilities drop qilinganligini
- ✅ seccompProfile ni
- ✅ Non-root user

---

## Namespace Labels

```yaml
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

- **enforce**: Blocks non-compliant pods
- **audit**: Logs violations
- **warn**: Warns users

---

## 🎯 Asosiy Xulosalar

1. **Restricted = most secure** - use in production
2. **Requires complete SecurityContext** - all fields
3. **Enforced at admission** - pods rejected if non-compliant
4. **Eng yaxshi amaliyot** — doim non-root sifatida ishlating
5. **Defense in depth** - layer with NetworkPolicy ni, RBAC

---

## Keyingi Qadamlar

- **Level 49:** PriorityClass
- **Level 50:** CHAOS FINALE!

**Excellent work!** 🎉🔒
