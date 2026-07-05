# 🎓 Missiya Yakuni: NetworkPolicy Too Restrictive - Missiya Yakuni

## Missiya Umumiy Ko'rinishi

**Maqsad:** Haddan tashqari cheklangan NetworkPolicy ni tuzating — u frontend va backend pod lar orasidagi qonuniy trafikni to'sib qo'ygan.

**XP berildi:** 250 XP  
**Qiyinlik:** Intermediate  
**Konseptlar:** Kubernetes NetworkPolicy, Pod-to-pod Communication, Label Selectors, Ingress Rules

---

## Nima Bilan Duch Keldingiz

Siz backend API bilan aloqa qilishi kerak bo'lgan frontend ilovani deploy qildingiz. Ikkala pod ishlayotgan, service to'g'ri sozlangan va endpoint lar mavjud edi. Lekin frontend backend ga yeta olmadi — barcha ulanish urinishlari timeout bo'ldi.

Aybdor? Noto'g'ri label selector ga ega NetworkPolicy — u frontend dan barcha trafikni to'sib qo'ydi.

**The Broken Configuration:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-network-policy
spec:
  podSelector:
    matchLabels:
      app: backend        # Applies to backend pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: admin-tool  # ❌ WRONG! Only allows "admin-tool" pods
    ports:
    - protocol: TCP
      port: 8080
```

**Muammo:**
- Frontend pod has label: `app: frontend`
- NetworkPolicy allows traffic from: `app: admin-tool`
- Match? NO! → All frontend traffic DENIED
- Result: Connection timeouts

---

## The Root Cause: Label Selector Mismatch

### Tushunish NetworkPolicy

NetworkPolicy — bu Kubernetes ning pod-dan-pod trafikni boshqarish uchun firewall i. U qaysi pod lar bir-biri bilan aloqa qilishi mumkinligini label selector lar orqali nazorat qiladi.

**Three Key Components:**

1. **podSelector** - WHO the policy applies TO (target pods)
2. **policyTypes** - What types of traffic to control (Ingress, Egress, or both)
3. **ingress/egress qoidalar** — KIM trafik yuborishi mumkin va QAYSI port lar

```yaml
spec:
  podSelector:           # TARGET: Apply to these pods
    matchLabels:
      app: backend
  
  policyTypes:          # DIRECTION: Control incoming traffic
  - Ingress
  
  ingress:              # RULES: Allow traffic from these sources
  - from:
    - podSelector:
        matchLabels:
          app: frontend  # SOURCE: Pods that can send traffic
    ports:
    - protocol: TCP
      port: 8080        # PORT: Only this port allowed
```

**Qanday ishlaydi:**

```
┌─────────────────────┐
│ Frontend Pod        │
│ Labels:             │
│   app: frontend ────┼────┐
│   tier: web         │    │
└─────────────────────┘    │
                           │
                           ▼
                    ┌──────────────────────────┐
                    │ NetworkPolicy Check      │
                    │ Does label "app:         │
                    │ frontend" match ingress  │
                    │ podSelector?             │
                    └──────────────────────────┘
                           │
                ┌──────────┴──────────┐
                │                     │
               YES                   NO
                │                     │
                ▼                     ▼
         ┌──────────────┐      ┌──────────────┐
         │ ALLOW        │      │ DENY         │
         │ Traffic      │      │ Connection   │
         │ Passes ✅    │      │ Timeout ❌   │
         └──────────────┘      └──────────────┘
                │                     
                ▼                     
       ┌─────────────────────┐
       │ Backend Pod         │
       │ Labels:             │
       │   app: backend      │
       │   tier: api         │
       └─────────────────────┘
```

### Default Deny Behavior

**CRITICAL:** Pod uchun NetworkPolicy yaratganingizda, bu pod "himoyalangan" bo'ladi va BARCHA trafik rad etiladid standart holatda, faqat siz aniq ruxsat berganlari TASHQARIplicitly allow.

```yaml
# NO NetworkPolicy
# Result: All traffic allowed (open)

# NetworkPolicy with empty ingress
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress: []  # Empty = deny all ingress

# Result: ALL incoming traffic denied!
```

Shuning uchun label selector ni noto'g'ri qo'yish juda xavfli — tasodifan qonuniy trafikni rad etasiz!

---

## Tuzatish Explained

**What You Changed:**

```yaml
# BEFORE (broken)
ingress:
- from:
  - podSelector:
      matchLabels:
        app: admin-tool    # Noto'g'ri label

# AFTER (solution)
ingress:
- from:
  - podSelector:
      matchLabels:
        app: frontend      # To'g'ri label
```

**Why This Works:**

1. **Frontend pod** has label `app: frontend`
2. **NetworkPolicy** endi pod lardan trafikka ruxsat beradi: `app: frontend`
3. **Match:** YES ✅
4. **Natija:** Frontend can connect to backend

NetworkPolicy endi frontend ni vakolatli manba sifatida to'g'ri aniqlaydi va uning trafigining backend ga yetishiga ruxsat beradiend on port 8080.

---

## Haqiqiy Dunyo Incident: The Midnight Lockout

**Kompaniya:** Financial services platform (payment processing)  
**Date:** November 2021  
**Ta'sir:** 4 hours of downtime, 50,000 failed transactions, $2.3M in lost revenue  

### Nima Sodir Bo'ldi

Xavfsizlik jamoasi xavfsizlik holatini yaxshilash uchun barcha production namespace larda NetworkPolicy larni joriy qilishga qaror qildisture. They created policies to restrict database access to only authorized applications.

**The Broken NetworkPolicy:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-access-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend       # ❌ Used "tier" o'rniga of "app"
    ports:
    - protocol: TCP
      port: 5432
```

**The Application Labels:**
```yaml
# Payment service (needs database access)
metadata:
  labels:
    app: payment-service
    team: payments
    
# User service (needs database access)
metadata:
  labels:
    app: user-service
    team: identity
```

### Muammo

NetworkPolicy `tier: backend` label selector ishlatdi, lekin ilova pod larining HECH BIRIDA bu label yo'q edi! Ular `app: payment-service`, `app: user-service`, etc.

**Natija:**
- ALL application pods were denied database access
- Every query timed out
- Payment processing completely stopped
- User authentication failed
- Website became unusable

### Timeline

**11:00 PM:** Security team deployed NetworkPolicies to production  
**11:05 PM:** Payment API started returning 500 errors  
**11:10 PM:** All database-dependent services failed  
**11:15 PM:** On-call engineer paged (monitoring detected massive error spike)  
**11:30 PM:** Team identified database connection timeouts  
**11:45 PM:** Suspected network issue, checked firewall rules (nothing wrong)  
**12:15 AM:** Checked NetworkPolicies, found label mismatch  
**12:30 AM:** Hotfix deployed with correct labels  
**1:00 AM:** Services restored, transactions processing again  
**3:00 AM:** Full validation complete  

### The Hotfix

**Option 1: Fix the NetworkPolicy**
```yaml
ingress:
- from:
  - podSelector:
      matchLabels:
        app: payment-service
  - podSelector:
      matchLabels:
        app: user-service
  # ... list all authorized services
```

**Option 2: Use a common label** (better approach)
```yaml
# Add consistent labels to all backend services
metadata:
  labels:
    app: payment-service
    tier: backend          # ✅ Add this to all backend pods

# NetworkPolicy can now use it
ingress:
- from:
  - podSelector:
      matchLabels:
        tier: backend      # ✅ Now matches!
```

**Option 3: Use namespace selector** (if all services in same namespace)
```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        name: backend-services
```

### Lessons Learned

1. **Test NetworkPolicies in Staging:**
   - Hech qachon deploy qilmang NetworkPolicies directly to production
   - Test in staging with identical labels and traffic patterns
   - Tekshirish connectivity before promoting to production

2. **Use Consistent Labeling:**
   - Establish label conventions across organization
   - Document required labels for NetworkPolicy access
   - Automate label validation in CI/CD

3. **Monitor Denied Connections:**
   - Log NetworkPolicy denials
   - Alert on unexpected connection failures
   - Track denied connections by source/destination

4. **Gradual Rollout:**
   - Deploy NetworkPolicies namespace-by-namespace
   - Start with logging-only mode (if controller supports)
   - Have instant rollback plan

5. **Documentation:**
   - Document which services need to communicate
   - Maintain service dependency maps
   - Include NetworkPolicy requirements in service documentation

---

## NetworkPolicy Deep Dive

### 1. Ingress vs Egress

**Ingress:** INCOMING traffic TO the protected pod
```yaml
policyTypes:
- Ingress        # Controls traffic coming IN

ingress:
- from:          # WHO can send traffic TO me
  - podSelector:
      matchLabels:
        app: frontend
```

**Egress:** OUTGOING traffic FROM the protected pod
```yaml
policyTypes:
- Egress         # Controls traffic going OUT

egress:
- to:            # WHERE can I send traffic TO
  - podSelector:
      matchLabels:
        app: database
```

**Both:**
```yaml
policyTypes:
- Ingress
- Egress

ingress:
- from:
  - podSelector:
      matchLabels:
        app: frontend

egress:
- to:
  - podSelector:
      matchLabels:
        app: database
```

### 2. Multiple Selectors (OR Logic)

```yaml
ingress:
- from:
  - podSelector:
      matchLabels:
        app: frontend
  - podSelector:
      matchLabels:
        app: admin
```

**Meaning:** Allow traffic from pods with `app: frontend` OR `app: admin`

### 3. Combined Selectors (AND Logic)

```yaml
ingress:
- from:
  - podSelector:
      matchLabels:
        app: frontend
    namespaceSelector:
      matchLabels:
        env: production
```

**Ma'nosi:** `app: frontend` label li pod lardan VA `env: production` label li namespace dan trafikka ruxsat berish

### 4. Namespace Selectors

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        team: backend
```

**Meaning:** Allow traffic from ANY pod in namespaces labeled `team: backend`

### 5. IP Block Selectors

```yaml
ingress:
- from:
  - ipBlock:
      cidr: 10.0.0.0/24
      except:
      - 10.0.0.1/32  # Except this specific IP
```

**Meaning:** Allow traffic from IP range 10.0.0.0/24 except 10.0.0.1

### 6. Port Restrictions

```yaml
ingress:
- from:
  - podSelector:
      matchLabels:
        app: frontend
  ports:
  - protocol: TCP
    port: 8080    # Only allow port 8080
  - protocol: TCP
    port: 9090    # Also allow port 9090
```

### 7. Default Deny All

```yaml
# Deny all ingress traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}    # Applies to ALL pods
  policyTypes:
  - Ingress
  # No ingress rules = deny all
```

```yaml
# Deny all egress traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
spec:
  podSelector: {}    # Applies to ALL pods
  policyTypes:
  - Egress
  # No egress rules = deny all
```

### 8. Allow All

```yaml
# Allow all ingress traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - {}              # Empty rule = allow all
```

---

## Keng Tarqalgan NetworkPolicy Patterns

### Pattern 1: Frontend → Backend → Database

```yaml
# Allow frontend to access backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
---
# Allow backend to access database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
```

### Pattern 2: Allow Ingress Controller

```yaml
# Allow ingress controller to access all services
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-controller
spec:
  podSelector:
    matchLabels:
      exposed: "true"    # Only pods with this label
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
      podSelector:
        matchLabels:
          app: ingress-nginx
```

### Pattern 3: Allow Monitoring/Metrics

```yaml
# Allow Prometheus to scrape metrics
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-prometheus
spec:
  podSelector: {}        # All pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
      podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: 9090       # Metrics port
```

### Pattern 4: Allow DNS

```yaml
# Allow all pods to query DNS
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

### Pattern 5: Cross-namespace Communication

```yaml
# Allow frontend in "app" namespace to access backend in "services" namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-cross-namespace
  namespace: services
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: app
      podSelector:
        matchLabels:
          app: frontend
```

---

## Debug qilish Qilish NetworkPolicy Issues

### 1. Tekshiring NetworkPolicy Exists

```bash
# List all NetworkPolicies in namespace
kubectl get networkpolicy -n k8squest

# Describe specific NetworkPolicy
kubectl describe networkpolicy backend-network-policy -n k8squest
```

Qidiring:
- **podSelector:** Which pods does it apply to?
- **Allowing ingress traffic:** What's allowed?
- **Allowing egress traffic:** Where can traffic go?

### 2. Check Pod Labels

```bash
# View pod labels
kubectl get pod frontend -n k8squest --show-labels

# Tekshiring labels match NetworkPolicy selector
kubectl get pod -n k8squest -l app=frontend
```

If no pods match the NetworkPolicy selector, it's not being applied!

### 3. Test Connectivity

```bash
# Urinib ko'ring connect from frontend to backend
kubectl exec frontend -n k8squest -- wget -q -O- http://backend-service:8080 --timeout=5

# Success: Prints response
# Failure: Timeout or connection refused
```

### 4. Check NetworkPolicy Controller Logs

```bash
# Find NetworkPolicy controller pods (depends on CNI)
# For Calico:
kubectl logs -n kube-system -l k8s-app=calico-node

# For Cilium:
kubectl logs -n kube-system -l k8s-app=cilium

# For Weave:
kubectl logs -n kube-system -l name=weave-net
```

Qidiring denied connection logs.

### 5. Tekshirish CNI Plugin Supports NetworkPolicy

Not all CNI plugins support NetworkPolicy!

**Support NetworkPolicy:**
- Calico ✅
- Cilium ✅
- Weave Net ✅
- Kube-router ✅

**DO NOT Support:**
- Flannel ❌ (sizdditional setup)
- Basic kubenet ❌

Check your CNI:
```bash
kubectl get pods -n kube-system
```

### 6. Test with curl Pod

Create a test pod to diagnose connectivity:

```bash
# Create test pod
kubectl run test -n k8squest --image=nicolaka/netshoot -- sleep 3600

# Test connection
kubectl exec test -n k8squest -- curl http://backend-service:8080

# Tekshiring NetworkPolicy affects test pod
kubectl label pod test -n k8squest app=frontend

# Try again (ishlashi kerak if NetworkPolicy allows app=frontend)
kubectl exec test -n k8squest -- curl http://backend-service:8080
```

### 7. Temporarily Remove NetworkPolicy

```bash
# Delete NetworkPolicy to test if it's the issue
kubectl delete networkpolicy backend-network-policy -n k8squest

# Test connection (ishlashi kerak now)
kubectl exec frontend -n k8squest -- wget -q -O- http://backend-service:8080

# If it works now, NetworkPolicy was the problem
# Reapply with correct configuration
```

---

## Eng Yaxshi Amaliyotlar

### 1. Start Permissive, Then Tighten

```bash
# Phase 1: No NetworkPolicy (allow all)
# Deploy application, verify it works

# Phase 2: Default deny with broad allow
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
spec:
  podSelector:
    matchLabels:
      tier: backend
  ingress:
  - from:
    - podSelector: {}  # Allow from all pods in namespace

# Phase 3: Restrict to specific sources
ingress:
- from:
  - podSelector:
      matchLabels:
        tier: frontend  # Only frontend tier
```

### 2. Use Consistent Labels

```yaml
# Establish labeling conventions
metadata:
  labels:
    app: payment-service      # Application name
    tier: backend             # Architectural tier
    team: payments            # Owning team
    env: production           # Environment
```

Use these labels consistently in NetworkPolicies.

### 3. Document Service Dependencies

```yaml
# backend-deployment.yaml
metadata:
  annotations:
    dependencies: "database-service, cache-service"
    networkpolicy: "Allows ingress from tier=frontend on port 8080"
```

### 4. Test in Staging First

- Deploy NetworkPolicies to staging environment
- Run full integration tests
- Monitor for connection failures
- Only promote to production after validation

### 5. Monitor Denied Connections

Set up monitoring for NetworkPolicy denials:

```bash
# Calico example: View denied connections
kubectl logs -n kube-system -l k8s-app=calico-node | grep "DENY"
```

Alert on unexpected denials.

### 6. Use Namespace Isolation

```yaml
# Deny all cross-namespace traffic standart holatda
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}  # Only same namespace
  egress:
  - to:
    - podSelector: {}  # Only same namespace
```

Then explicitly allow cross-namespace where needed.

### 7. Keep It Simple

```yaml
# ❌ TOO COMPLEX - hard to understand and maintain
ingress:
- from:
  - podSelector:
      matchLabels:
        app: frontend
    namespaceSelector:
      matchLabels:
        env: production
  - ipBlock:
      cidr: 10.0.0.0/16
      except:
      - 10.0.1.0/24
  ports:
  - protocol: TCP
    port: 8080
  - protocol: TCP
    port: 9090
  - protocol: UDP
    port: 8080
```

```yaml
# ✅ SIMPLE - clear and maintainable
ingress:
- from:
  - podSelector:
      matchLabels:
        tier: frontend
  ports:
  - protocol: TCP
    port: 8080
```

---

## Key Takeaways

1. **NetworkPolicy Uses Labels:**
   - `podSelector` determines which pods the policy applies TO
   - `ingress.from.podSelector` determines which pods can send traffic (source)
   - Labels must match EXACTLY for traffic to be allowed

2. **Default Deny Behavior:**
   - Once a NetworkPolicy is applied, ALL traffic is denied except what's explicitly allowed
   - Empty ingress/egress rules mean DENY ALL

3. **Multiple NetworkPolicies Are Additive:**
   - If multiple NetworkPolicies match a pod, their rules are combined (OR logic)
   - Siz frontend kirishi uchun bitta policy, monitoring uchun boshqasini qo'yasiz

4. **Testing is Critical:**
   - Doim test qiling NetworkPolicies in staging first
   - Tekshirish connectivity after applying
   - Have rollback plan ready

5. **Common Mistakes:**
   - Label mismatch (eng keng tarqalgan!)
   - Forgetting to allow DNS (egress to kube-dns)
   - Applying policy to wrong pods (podSelector mistake)
   - OR kerak bo'lganda AND logikasi ishlatish
   - Not ruxsat berish ingress controller or monitoring

6. **Real-World Lessons:**
   - NetworkPolicy mistakes can cause complete outages
   - Test with same labels and traffic patterns as production
   - Monitor denied connections
   - Document service dependencies
   - Use consistent labeling conventions

---

## Keyingi Qadam?

Siz o'zlashtirgansiz NetworkPolicy fundamentals! Endi siz tushunasiz:
- ✅ How NetworkPolicy controls pod-to-pod traffic
- ✅ Label selector matching for ingress/egress rules
- ✅ Default deny behavior
- ✅ Debug qilishging connectivity issues sabab bo'ldi by NetworkPolicies

Keyingi level larda siz stateful ilovalar uchun session affinity, namespace lar arasi service aloqasi va d more advanced networking patterns.

**Continue your K8sQuest journey to unlock the next challenge!** 🚀

---

## Qo'shimcha Resources

- [Kubernetes NetworkPolicy Documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [NetworkPolicy Recipes](https://github.com/ahmetb/kubernetes-network-policy-recipes)
- [Calico NetworkPolicy](https://docs.projectcalico.org/security/kubernetes-network-policy)
- [Cilium NetworkPolicy](https://docs.cilium.io/en/stable/policy/)

---

**Mission Complete!** 🎉  
You've earned 250 XP and mastered Kubernetes NetworkPolicy!
