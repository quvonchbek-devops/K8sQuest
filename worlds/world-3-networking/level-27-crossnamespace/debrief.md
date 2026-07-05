# 🎓 Missiya Yakuni: Cross-namespace Service Communication - Missiya Yakuni

## Missiya Umumiy Ko'rinishi

**Maqsad:** Boshqa namespace dagi backend service bilan aloqa qila olmagan frontend ilovani tuzatingce by using the proper DNS FQDN format.

**XP berildi:** 250 XP  
**Qiyinlik:** Intermediate  
**Konseptlar:** Cross-namespace Communication, Kubernetes DNS, FQDN, Service Discovery

---

## What You Encountered

Siz `k8squest` namespace da frontend ilovani deploy qildingiz, u `backend-ns` namespace dagi backend API ga murojaat qilishi kerak edi. Ikkala service mukammal ishlayotgan edi, endpoint lar mavjud edi. Tarmoq ulanishi ham yaxshi edi. Lekin frontend dan har bir API murojaat DNS hal qilish xatolari bilan muvaffaqiyatsiz bo'ldi.

Aybdor? Frontend faqat bir xil namespace ichida hal qilinadigan qisqa service nomi (`api-service`) ishlatayotgan edi.

**The Broken Configuration:**
```yaml
# Frontend pod in k8squest namespace
command: ['sh', '-c', 'wget -q -O- http://api-service']
```

**Muammo:**
- Frontend tries to resolve: `api-service`
- Kubernetes DNS searches: `api-service.k8squest.svc.cluster.local`
- But service is actually in: `backend-ns` namespace
- Result: DNS resolution failed - "could not resolve host"

---

## The Root Cause: DNS Namespace Scoping

### Tushunish Kubernetes DNS

Kubernetes ichki DNS server (CoreDNS) ishlatadi, u service discovery ta'minlaydi. Har bir Service DNS yozuvi oladi, lekin DNS nom formati bir xil namespace yoki boshqa namespace dagi service ga kirayotganingizga bog'liqmespace or a different namespace.

**DNS Architecture:**

```
┌─────────────────────────────────────────────────┐
│  CoreDNS (kube-system namespace)                │
│  DNS Server: 10.96.0.10                         │
│                                                  │
│  DNS Records:                                    │
│  • api-service.backend-ns.svc.cluster.local     │
│    → 10.96.15.23                                │
│  • frontend-service.k8squest.svc.cluster.local  │
│    → 10.96.20.45                                │
└─────────────────────────────────────────────────┘
                      ▲
                      │ DNS Query
                      │
┌─────────────────────┴─────────────────────┐
│  Pod (in k8squest namespace)              │
│  /etc/resolv.conf:                        │
│    nameserver 10.96.0.10                  │
│    search k8squest.svc.cluster.local      │
│           svc.cluster.local               │
│           cluster.local                   │
└───────────────────────────────────────────┘
```

### DNS Search Domains

When a pod tries to resolve a short name like `api-service`, Kubernetes uses **DNS search domains** to build FQDN candidates:

**Pod's /etc/resolv.conf:**
```
nameserver 10.96.0.10
search k8squest.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

**DNS Resolution Process for "api-service":**

1. **First attempt:** `api-service.k8squest.svc.cluster.local`
   - Looks for service in k8squest namespace
   - Service mavjud emas there → NXDOMAIN

2. **Second attempt:** `api-service.svc.cluster.local`
   - Ambiguous (which namespace?)
   - Not a valid query → NXDOMAIN

3. **Third attempt:** `api-service.cluster.local`
   - Not a service record
   - → NXDOMAIN

4. **Final attempt:** `api-service` (as-is)
   - Not a valid DNS name
   - → Resolution FAILED

**Natija:** "wget: bad address 'api-service'"

### Why Cross-namespace Needs FQDN

**Same Namespace (works with short name):**
```
Frontend in k8squest → api-service → Resolves to: api-service.k8squest.svc.cluster.local ✅
```

**Different Namespace (needs FQDN):**
```
Frontend in k8squest → api-service → Resolves to: api-service.k8squest.svc.cluster.local ❌
                                      (Service is actually in backend-ns!)

Frontend in k8squest → api-service.backend-ns → Resolves correctly ✅
```

---

## Tuzatish Explained

**What You Changed:**

```yaml
# BEFORE (broken)
command: ['sh', '-c', 'wget -q -O- http://api-service']

# AFTER (solution)
command: ['sh', '-c', 'wget -q -O- http://api-service.backend-ns.svc.cluster.local']
```

**DNS FQDN Format:**

```
<service-name>.<namespace>.svc.<cluster-domain>
     |              |        |         |
     |              |        |         +-- Cluster DNS suffix (default: cluster.local)
     |              |        +------------ Service subdomain
     |              +--------------------- Namespace where service exists
     +------------------------------------ Service name
```

**Examples:**
```
api-service.backend-ns.svc.cluster.local    (Full FQDN - recommended)
api-service.backend-ns.svc                  (Short FQDN - works)
api-service.backend-ns                      (Minimal - works)
api-service                                 (Short name - only same namespace!)
```

**Why the Fix Works:**

1. Frontend requests: `http://api-service.backend-ns.svc.cluster.local`
2. DNS query goes to CoreDNS
3. CoreDNS looks up: Service "api-service" in namespace "backend-ns"
4. Returns ClusterIP: 10.96.15.23
5. Frontend connects to ClusterIP
6. kube-proxy routes to backend pod
7. Success! ✅

---

## Haqiqiy Dunyo Incident: The Microservices Migration Disaster

**Kompaniya:** SaaS platform (project management software)  
**Date:** March 2023  
**Ta'sir:** 8 hours of downtime, 15,000 users affected, $890K in SLA penalties  

### Nima Sodir Bo'ldi

Kompaniya monolit arxitekturadan microservice larga ko'chayotgan edi. Turli jamoalar uchun namespace izolyatsiyasini ishlatishga qaror qildiifferent service tiers:

- `frontend` namespace: Web UI, mobile API
- `backend` namespace: Business logic services
- `data` namespace: Database services, caching

Ko'chirish rejasi — service larni birma-bir monolitdan microservice larga ko'chirish edi.

**Phase 1: Backend Migration (Week 1)**

Jamoa birinchi microservice ni deploy qildi: `backend` namespace da `user-service`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: backend    # New microservice in backend namespace
spec:
  selector:
    app: user-service
  ports:
  - port: 8080
```

**Phase 2: Frontend Update (Week 2)**

Frontend jamoasi yangi microservice ga murojaat qilish uchun kodini yangiladi:

```javascript
// Frontend code (running in 'frontend' namespace)
const API_URL = 'http://user-service:8080/api/users';

fetch(API_URL)
  .then(response => response.json())
  .then(users => displayUsers(users))
  .catch(err => console.error('Failed to load users:', err));
```

**Deployment:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: frontend
data:
  API_URL: "http://user-service:8080"    # ❌ SHORT NAME!
```

### Muammo

The frontend and backend teams tested independently:

**Backend Team Testing:**
```bash
# Created test pod in 'backend' namespace
kubectl run test -n backend --image=curlimages/curl -- curl http://user-service:8080/health

# Worked perfectly! ✅
```

**Frontend Team Testing:**
```bash
# Tested frontend service endpoints in 'frontend' namespace
kubectl port-forward -n frontend service/web-frontend 3000:80

# Frontend loaded fine ✅
# But they didn't test actual API calls!
```

**Production Deployment (Saturday 2 AM):**

- 2:00 AM: Deployed updated frontend with user-service integration
- 2:05 AM: All user-related pages started showing errors
- 2:10 AM: Login page broken (calls user-service)
- 2:15 AM: Profile pages failing
- 2:20 AM: User management admin panel down

**User Experience:**
```
User tries to login → Frontend calls http://user-service:8080/auth
                   → DNS: "could not resolve host: user-service"
                   → Error: "Service temporarily unavailable"
```

### Timeline

**2:00 AM:** Frontend v2.0 deployed to production  
**2:05 AM:** User login failures start (5 failed logins/minute)  
**2:10 AM:** Failure rate spikes (500+ failed logins/minute)  
**2:15 AM:** On-call engineer paged (automated alert: 95% login failure rate)  
**2:30 AM:** Team checking authentication service (appears healthy)  
**3:00 AM:** Network team checks connectivity (all green)  
**3:30 AM:** Someone checks frontend pod logs:  
```
Error: getaddrinfo ENOTFOUND user-service
Error: getaddrinfo ENOTFOUND user-service
Error: getaddrinfo ENOTFOUND user-service
```
**3:45 AM:** DNS issue suspected  
**4:00 AM:** Checked DNS resolution from frontend pod:  
```bash
kubectl exec web-frontend-xxx -n frontend -- nslookup user-service
# Returns: NXDOMAIN (not found)
```
**4:15 AM:** Realized user-service is in different namespace!  
**4:30 AM:** Hotfix deployed with FQDN  
**5:00 AM:** Services restored  
**10:00 AM:** Full post-mortem completed  

### The Damage

- **8 hours of downtime** (2 AM - 10 AM full recovery)
- **15,000 users** kira olmadi their accounts
- **$890K in SLA penalties** (99.9% uptime guarantee violated)
- **Brand damage** (negative social media, support tickets)
- **Lost productivity** (entire engineering team worked emergency overnight)

### The Hotfix

**Option 1: Update ConfigMap (chosen)**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: frontend
data:
  API_URL: "http://user-service.backend.svc.cluster.local:8080"  # ✅ FQDN
```

Then restart frontend pods to pick up new config.

**Option 2: Move service to same namespace**
Not chosen because:
- Would break namespace isolation strategy
- Defeats purpose of service tier separation
- Harder to implement under pressure

**Option 3: Use ExternalName Service**
Create a "proxy" service in frontend namespace:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: frontend
spec:
  type: ExternalName
  externalName: user-service.backend.svc.cluster.local
```

Not chosen because:
- Adds complexity
- Harder to understand service topology
- Could cause naming conflicts

### The Long-Term Fix

The team implemented several changes:

**1. Service Naming Convention**
```yaml
# Document all cross-namespace dependencies
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-directory
  namespace: kube-public
data:
  # Format: SERVICE_NAME: FQDN
  user-service: "user-service.backend.svc.cluster.local"
  auth-service: "auth-service.backend.svc.cluster.local"
  database: "postgres-service.data.svc.cluster.local"
```

**2. Environment Variable Standard**
```yaml
# Doim ishlating FQDN in environment variables
env:
- name: USER_SERVICE_URL
  value: "http://user-service.backend.svc.cluster.local:8080"
- name: AUTH_SERVICE_URL
  value: "http://auth-service.backend.svc.cluster.local:8080"
```

**3. Integration Testing**
```bash
# Test cross-namespace connectivity BEFORE production
kubectl run test-frontend -n frontend --image=curlimages/curl -- \
  curl http://user-service.backend.svc.cluster.local:8080/health
```

**4. DNS Validation in CI/CD**
```yaml
# Helm chart validation
{{- if not (contains "." .Values.userServiceUrl) }}
  {{- fail "userServiceUrl must be FQDN (include namespace)" }}
{{- end }}
```

**5. Documentation**
```markdown
# Cross-Namespace Communication Guide

## Namespace Structure
- `frontend`: Web UI, mobile API gateway
- `backend`: Business logic microservices
- `data`: Databases, caches, message queues

## Service Discovery Rules
1. Same namespace: Use short name (`service-name`)
2. Different namespace: Use FQDN (`service-name.namespace.svc.cluster.local`)

## Examples
✅ Frontend → Backend:
   http://user-service.backend.svc.cluster.local:8080

✅ Backend → Data:
   postgres://postgres-service.data.svc.cluster.local:5432/mydb

❌ Frontend → Backend (WRONG):
   http://user-service:8080
```

### Lessons Learned

1. **Test Cross-Namespace Communication:**
   - Don't just test within each namespace
   - Test actual communication paths
   - Include integration tests in CI/CD

2. **Boshqa Namespace lar Uchun Doim FQDN Ishlating:**
   - Qisqa nomlar faqat bir xil namespace ichida ishlaydi
   - FQDN is explicit and to'sib qo'yadi errors
   - Document service locations

3. **Validate Configuration:**
   - Check for FQDN in config files
   - Validate DNS resolution before deployment
   - Use tools to detect short names in cross-namespace calls

4. **Monitor DNS Errors:**
   - Alert on NXDOMAIN responses
   - Track DNS resolution failures
   - Log service discovery issues

5. **Document Namespace Topology:**
   - Which services are in which namespaces
   - Which services need to communicate
   - Service dependency map

---

## Kubernetes DNS Deep Dive

### DNS Record Types

Kubernetes creates several types of DNS records:

#### 1. Service DNS Records (A Records)

```bash
# Service: api-service in namespace backend-ns
# Gets A record:
api-service.backend-ns.svc.cluster.local → 10.96.15.23 (ClusterIP)
```

#### 2. Pod DNS Records (A Records)

```bash
# Pod with IP 10.244.1.5 in namespace backend-ns
# Gets A record:
10-244-1-5.backend-ns.pod.cluster.local → 10.244.1.5
```

#### 3. Headless Service Records (A Records per Pod)

```bash
# Headless service (clusterIP: None)
api-service.backend-ns.svc.cluster.local → 10.244.1.5
                                         → 10.244.1.6
                                         → 10.244.1.7
```

#### 4. SRV Records (for named ports)

```bash
# Service with named port "http"
_http._tcp.api-service.backend-ns.svc.cluster.local
  → 10 100 8080 api-service.backend-ns.svc.cluster.local
```

### FQDN Components

```
api-service.backend-ns.svc.cluster.local
    |          |        |       |
    |          |        |       +-- Cluster domain (configurable)
    |          |        +---------- Service/Pod subdomain
    |          +------------------- Namespace
    +------------------------------- Resource name (service/pod)
```

**Cluster Domain:**
- Default: `cluster.local`
- Configurable in kubelet: `--cluster-domain=example.com`
- Must match across all nodes

**Service Subdomain:**
- `svc` for Services
- `pod` for Pods

### DNS Resolution Examples

**Within Same Namespace (k8squest):**

```bash
# All of these work:
curl http://api-service
curl http://api-service.k8squest
curl http://api-service.k8squest.svc
curl http://api-service.k8squest.svc.cluster.local

# DNS resolution:
api-service → api-service.k8squest.svc.cluster.local (search domain appended)
```

**Cross-Namespace (k8squest → backend-ns):**

```bash
# These work:
curl http://api-service.backend-ns
curl http://api-service.backend-ns.svc
curl http://api-service.backend-ns.svc.cluster.local

# This FAILS:
curl http://api-service
# DNS tries: api-service.k8squest.svc.cluster.local (wrong namespace!)
```

**To External Service:**

```bash
# External DNS (outside Kubernetes)
curl http://api.example.com    # Uses external DNS, not CoreDNS
```

### Pod DNS Configuration

Every pod gets DNS configured via `/etc/resolv.conf`:

```bash
kubectl exec frontend-app -n k8squest -- cat /etc/resolv.conf
```

Output:
```
nameserver 10.96.0.10
search k8squest.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

**Explanation:**
- `nameserver`: CoreDNS service IP
- `search`: DNS search domains (appended to short names)
- `ndots:5`: If name has < 5 dots, try search domains first

**ndots Behavior:**

```bash
# "api-service" has 0 dots (< 5)
# Try search domains:
#   1. api-service.k8squest.svc.cluster.local
#   2. api-service.svc.cluster.local
#   3. api-service.cluster.local
# Then try as-is: api-service

# "api-service.backend-ns.svc.cluster.local" has 5 dots (>= 5)
# Try as-is first: api-service.backend-ns.svc.cluster.local ✅
```

---

## Cross-Namespace Communication Patterns

### Pattern 1: Frontend → Backend Architecture

```
┌─────────────────────┐
│  frontend namespace │
│                     │
│  ┌───────────────┐  │
│  │  Web UI       │  │
│  └───────┬───────┘  │
└──────────┼──────────┘
           │
           │ http://api-service.backend.svc.cluster.local
           │
┌──────────▼──────────┐
│  backend namespace  │
│                     │
│  ┌───────────────┐  │
│  │  API Service  │  │
│  └───────┬───────┘  │
└──────────┼──────────┘
           │
           │ postgres://db-service.data.svc.cluster.local
           │
┌──────────▼──────────┐
│  data namespace     │
│                     │
│  ┌───────────────┐  │
│  │  Database     │  │
│  └───────────────┘  │
└─────────────────────┘
```

**Configuration:**
```yaml
# Frontend deployment
env:
- name: API_URL
  value: "http://api-service.backend.svc.cluster.local:8080"

# Backend deployment
env:
- name: DATABASE_URL
  value: "postgres://db-service.data.svc.cluster.local:5432/mydb"
```

### Pattern 2: Multi-Tenant Isolation

```
┌───────────────────┐    ┌───────────────────┐
│  tenant-a         │    │  tenant-b         │
│  ┌─────────────┐  │    │  ┌─────────────┐  │
│  │ App Instance│  │    │  │ App Instance│  │
│  └──────┬──────┘  │    │  └──────┬──────┘  │
└─────────┼─────────┘    └─────────┼─────────┘
          │                        │
          │ Both access shared services
          │                        │
          └────────────┬───────────┘
                       │
          ┌────────────▼──────────────┐
          │  shared-services          │
          │  ┌──────────────────────┐ │
          │  │ Authentication      │ │
          │  │ Logging             │ │
          │  │ Monitoring          │ │
          │  └──────────────────────┘ │
          └───────────────────────────┘
```

**Configuration:**
```yaml
# Tenant A app
env:
- name: AUTH_SERVICE
  value: "http://auth-service.shared-services.svc.cluster.local"

# Tenant B app (same)
env:
- name: AUTH_SERVICE
  value: "http://auth-service.shared-services.svc.cluster.local"
```

### Pattern 3: Environment Isolation

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  dev         │  │  staging     │  │  production  │
│              │  │              │  │              │
│  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │
│  │  App   │  │  │  │  App   │  │  │  │  App   │  │
│  └────┬───┘  │  │  └────┬───┘  │  │  └────┬───┘  │
└───────┼──────┘  └───────┼──────┘  └───────┼──────┘
        │                 │                 │
        └─────────────────┴─────────────────┘
                          │
                ┌─────────▼──────────┐
                │  databases         │
                │  ┌──────────────┐  │
                │  │ dev-db       │  │
                │  │ staging-db   │  │
                │  │ prod-db      │  │
                │  └──────────────┘  │
                └────────────────────┘
```

**Configuration:**
```yaml
# Dev app
env:
- name: DATABASE_URL
  value: "postgres://dev-db.databases.svc.cluster.local:5432"

# Staging app
env:
- name: DATABASE_URL
  value: "postgres://staging-db.databases.svc.cluster.local:5432"

# Prod app
env:
- name: DATABASE_URL
  value: "postgres://prod-db.databases.svc.cluster.local:5432"
```

---

## Security Considerations

### NetworkPolicy for Cross-Namespace Access

By default, pods can access services in any namespace. Use NetworkPolicy to restrict:

```yaml
# Allow only frontend namespace to access backend services
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-access-policy
  namespace: backend
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend    # Only frontend namespace
    ports:
    - protocol: TCP
      port: 8080
```

**Namespace Labels:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: frontend
  labels:
    name: frontend
```

### RBAC for Namespace Access

Control which service accounts can access resources in other namespaces:

```yaml
# Role in backend namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: service-reader
  namespace: backend
rules:
- apiGroups: [""]
  resources: ["services", "endpoints"]
  verbs: ["get", "list"]
---
# RoleBinding ruxsat berish frontend service account
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: frontend-can-read-backend-services
  namespace: backend
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: service-reader
subjects:
- kind: ServiceAccount
  name: frontend-app
  namespace: frontend
```

---

## Debug qilish Qilish Cross-Namespace DNS Issues

### 1. Test DNS Resolution

```bash
# From frontend pod
kubectl exec frontend-app -n k8squest -- nslookup api-service
# Should fail: NXDOMAIN

kubectl exec frontend-app -n k8squest -- nslookup api-service.backend-ns.svc.cluster.local
# Should succeed: Returns ClusterIP
```

### 2. Check DNS Configuration

```bash
# View pod's DNS config
kubectl exec frontend-app -n k8squest -- cat /etc/resolv.conf

# Check CoreDNS ishlayapti
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

### 3. Tekshirish Service Exists

```bash
# Service ni tekshirish in target namespace
kubectl get service api-service -n backend-ns

# Service ni tekshirish has endpoints
kubectl get endpoints api-service -n backend-ns
```

### 4. Test Connectivity

```bash
# Get service ClusterIP
SERVICE_IP=$(kubectl get service api-service -n backend-ns -o jsonpath='{.spec.clusterIP}')

# Test direct IP connection
kubectl exec frontend-app -n k8squest -- wget -q -O- http://$SERVICE_IP
```

### 5. Check CoreDNS Logs

```bash
# View CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Qidiring NXDOMAIN responses
kubectl logs -n kube-system -l k8s-app=kube-dns | grep NXDOMAIN
```

### 6. Query CoreDNS Directly

```bash
# Get CoreDNS service IP
kubectl get service kube-dns -n kube-system

# Query from pod
kubectl exec frontend-app -n k8squest -- nslookup api-service.backend-ns.svc.cluster.local 10.96.0.10
```

---

## Eng Yaxshi Amaliyotlar

### 1. Always Use FQDN for Cross-Namespace

```yaml
# ❌ BAD: Relies on same namespace
env:
- name: API_URL
  value: "http://api-service:8080"

# ✅ GOOD: Explicit namespace
env:
- name: API_URL
  value: "http://api-service.backend.svc.cluster.local:8080"
```

### 2. Document Service Locations

```yaml
# ConfigMap documenting service topology
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-directory
  namespace: kube-public
data:
  services.yaml: |
    frontend:
      - web-ui
      - mobile-api
    backend:
      - user-service
      - auth-service
      - notification-service
    data:
      - postgres-service
      - redis-service
```

### 3. Use Environment Variables

```yaml
# Don't hardcode URLs in application code
# Use environment variables o'rniga
env:
- name: USER_SERVICE_URL
  value: "http://user-service.backend.svc.cluster.local:8080"
- name: AUTH_SERVICE_URL
  value: "http://auth-service.backend.svc.cluster.local:8080"
```

### 4. Validate in CI/CD

```bash
#!/bin/bash
# Validate all service URLs use FQDN for cross-namespace

# Extract all service URLs from config
SERVICE_URLS=$(grep -r "http://" k8s/ | grep -o "http://[^:]*")

for url in $SERVICE_URLS; do
  service=$(echo $url | sed 's|http://||')
  
  # Tekshiring it contains a dot (namespace qualifier)
  if [[ ! "$service" =~ \. ]]; then
    echo "ERROR: $service uses short name (add namespace!)"
    exit 1
  fi
done

echo "✅ All service URLs use FQDN"
```

### 5. Use Service Mesh for Advanced Routing

For complex multi-namespace architectures, consider a service mesh:

```yaml
# Istio VirtualService for cross-namespace routing
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: user-service
  namespace: frontend
spec:
  hosts:
  - user-service.backend.svc.cluster.local
  http:
  - route:
    - destination:
        host: user-service.backend.svc.cluster.local
        port:
          number: 8080
```

### 6. Monitor DNS Performance

```yaml
# Prometheus metrics for DNS
sum(rate(coredns_dns_request_duration_seconds_count[5m])) by (type)

# Alert on high DNS failure rate
sum(rate(coredns_dns_response_rcode_count_total{rcode="NXDOMAIN"}[5m])) > 10
```

---

## Key Takeaways

1. **DNS Naming Rules:**
   - Same namespace: `service-name` (short name works)
   - Different namespace: `service-name.namespace.svc.cluster.local` (FQDN required)
   - Full format: `<service>.<namespace>.svc.<cluster-domain>`

2. **DNS Search Domains:**
   - Pods get search domains: `namespace.svc.cluster.local`, `svc.cluster.local`, `cluster.local`
   - Short names are expanded using search domains
   - Only searches current namespace standart holatda

3. **Why FQDN Matters:**
   - Explicit namespace to'sib qo'yadi resolution errors
   - Works regardless of pod's namespace
   - Clear and self-documenting
   - Prevents ambiguity

4. **Common Mistakes:**
   - Using short names for cross-namespace (DNS fails)
   - Wrong namespace in FQDN (service not found)
   - Typos in service names (DNS fails)
   - Testing in same namespace, deploying cross-namespace

5. **Real-World Lessons:**
   - Doim test qiling cross-namespace communication before production
   - Use FQDN in all configuration files
   - Document namespace topology
   - Validate DNS resolution in CI/CD
   - Monitor DNS errors

---

## Keyingi Qadam?

Siz o'zlashtirgansiz cross-namespace service communication! Endi siz tushunasiz:
- ✅ Kubernetes DNS naming conventions
- ✅ When to use short names vs FQDN
- ✅ How DNS search domains work
- ✅ Debug qilishging DNS resolution issues across namespaces

Keyingi level larda siz readiness probe lar bilan service endpoint boshqaruvi, LoadBalancer va NodePort service lari, and headless services for StatefulSets.

**Continue your K8sQuest journey to unlock the next challenge!** 🚀

---

## Qo'shimcha Resources

- [Kubernetes DNS Documentation](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [CoreDNS](https://coredns.io/)
- [DNS Debug qilishging Guide](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)
- [Service Discovery](https://kubernetes.io/docs/concepts/services-networking/service/#discovering-services)

---

**Mission Complete!** 🎉  
You've earned 250 XP and mastered cross-namespace service discovery!
