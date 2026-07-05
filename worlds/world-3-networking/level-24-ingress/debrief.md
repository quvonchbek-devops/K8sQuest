# 🎓 Missiya Yakuni: Ingress Path Mismatch - Missiya Yakuni

## Missiya Umumiy Ko'rinishi

**Maqsad:** Path yo'naltirish noto'g'ri sozlangani uchun 404 xatolarga sabab bo'lgan Ingress konfiguratsiyasini tuzating for all requests to the application.

**XP berildi:** 250 XP  
**Qiyinlik:** Intermediate  
**Konseptlar:** Kubernetes Ingress, Path-based Routing, HTTP Routing, PathType

---

## What You Encountered

Siz oddiy web ilovani (nginx) `http://myapp.local` da deploy qildingiz. Hamma narsa to'g'ri sozlangandek ko'rindi— Pod ishlayotgan edi, Service da endpoint lar mavjud edi, va Ingress resursi ham bor edi — lekin URL ga kirganda 404 xato oldingiz. Ingress path `/api` ga sozlangan edi, aslida `/` bo'lishi kerak edi.

Aybdor? Ingress path dagi nozik lekin jiddiy noto'g'ri konfiguratsiya.

**The Broken Configuration:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
spec:
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /api        # ❌ WRONG!
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

**Muammo:**
- The application serves content at the **root path** (`/`)
- The Ingress sozlangan edi to route traffic for **`/api`**
- When users accessed `http://myapp.local/`, the request mos kelmadi any Ingress rule
- Result: 404 Not Found

---

## The Root Cause: Path Mismatch

### Tushunish Ingress Path Matching

Kubernetes Ingress **path-asoslangan yo'naltirish** ishlatib HTTP/HTTPS trafikni turli backend service larga yo'naltiradi. `path` maydonield in the Ingress spec determines which requests get routed to which service.

**How Path Matching Works:**

1. **Client makes request:** `http://myapp.local/index.html`
2. **Ingress controller extracts path:** `/index.html`
3. **Ingress controller checks rules:**
   - Does `/index.html` match the configured path?
   - Matching logic depends on `pathType`
4. **Routes to backend or returns 404**

### PathType Options

Kubernetes supports three `pathType` values:

#### 1. **Prefix** (Most Common)
Path prefiksi asosida moslik tekshiradi. Path sozlangan qiymat bilan BOSHLANISHI kerak.

```yaml
path: /api
pathType: Prefix
```

**Matches:**
- `/api` ✅
- `/api/` ✅
- `/api/users` ✅
- `/api/v1/posts` ✅

**Does NOT Match:**
- `/` ❌
- `/app` ❌
- `/application/api` ❌

#### 2. **Exact**
Faqat aniq path ga mos keladi, harf-ma-harf.

```yaml
path: /api
pathType: Exact
```

**Matches:**
- `/api` ✅

**Does NOT Match:**
- `/api/` ❌ (trailing slash!)
- `/api/users` ❌
- `/API` ❌ (case-sensitive)

#### 3. **ImplementationSpecific**
Ingress controller implementatsiyasiga bog'liq. Aniq ehtiyoj va Ingress controller ingizni tushunmasangiz, buni ishlatmang's behavior.

### Keng Tarqalgan Path Patterns

```yaml
# Match root and everything
path: /
pathType: Prefix
# Matches: /, /index.html, /css/app.css, /api/users, etc.

# Match only API endpoints
path: /api
pathType: Prefix
# Matches: /api, /api/users, /api/v1/posts
# Does NOT match: /, /app, /home

# Match exact login page
path: /login
pathType: Exact
# Matches: /login only
# Does NOT match: /login/, /login?redirect=home

# Match specific version of API
path: /api/v2
pathType: Prefix
# Matches: /api/v2, /api/v2/users, /api/v2/posts
# Does NOT match: /api/v1, /api/v3
```

---

## Tuzatish Explained

**What You Changed:**

```yaml
# BEFORE (broken.yaml)
paths:
- path: /api        # Noto'g'ri path
  pathType: Prefix
  
# AFTER (solution.yaml)
paths:
- path: /           # To'g'ri path
  pathType: Prefix
```

**Why This Works:**

1. **Requests to `http://myapp.local/`:**
   - Extracted path: `/`
   - Ingress rule: `path: /`, `pathType: Prefix`
   - Match: `/` starts with `/` ✅
   - Routes to: `web-service:80`

2. **Requests to `http://myapp.local/index.html`:**
   - Extracted path: `/index.html`
   - Ingress rule: `path: /`, `pathType: Prefix`
   - Match: `/index.html` starts with `/` ✅
   - Routes to: `web-service:80`

3. **With the broken config (`path: /api`):**
   - Request: `http://myapp.local/`
   - Extracted path: `/`
   - Ingress rule: `path: /api`, `pathType: Prefix`
   - Moslik: `/` `/api` bilan BOSHLANMAYDI ❌
   - Result: 404 Not Found (no matching rule)

---

## Haqiqiy Dunyo Incident: The API Gateway Nightmare

**Kompaniya:** E-commerce platform with 2M monthly users  
**Date:** March 2022  
**Ta'sir:** 6 hours of downtime, $180,000 in lost revenue  

### Nima Sodir Bo'ldi

Platforma monolit ilovadan microservice larga ko'chayotgan edi. Infrastruktura jamoasi Ingress sozladi to route traffic:

```yaml
# INTENDED ROUTING:
# / → frontend-service (main website)
# /api → backend-service (API)
```

**The Broken Configuration:**
```yaml
spec:
  rules:
  - host: shop.example.com
    http:
      paths:
      - path: /api/v1           # ❌ TOO SPECIFIC!
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

### Muammo

The API had two versions:
- `/api/v1/*` (old, being deprecated)
- `/api/v2/*` (new, actively used)

**What Went Wrong:**

1. **Day 1:** Deployed new Ingress configuration
   - `/api/v1/products` → Routed to `backend-service` ✅
   - `/api/v2/products` → Routed to `frontend-service` ❌

2. **Frontend service received API requests:**
   - Frontend (React app) doesn't handle API paths
   - Returned: 404 Not Found for all v2 API requests

3. **Mobile app broke completely:**
   - Mobile app ONLY used `/api/v2/*` endpoints
   - All API calls failed: authentication, product listings, checkout
   - 500,000 active users couldn't browse or purchase

4. **Monitoring didn't catch it:**
   - Health checks only tested `/api/v1/health`
   - Those succeeded, so alerts didn't fire
   - Load balancer hamma narsa yaxshi deb o'yladi

### Timeline

**10:00 AM:** Deployed new Ingress configuration during scheduled maintenance  
**10:15 AM:** Mobile users started reporting "can't load products"  
**10:30 AM:** Customer support flooded with tickets (500+ in 15 minutes)  
**10:45 AM:** Engineering team identified 95% of API calls failing  
**11:00 AM:** Root cause identified: Ingress path mismatch  
**11:15 AM:** Hotfix deployed: Changed `path: /api/v1` to `path: /api`  
**11:30 AM:** Validation complete, traffic restored  
**4:00 PM:** Full post-mortem completed

### The Hotfix

```yaml
# FIXED:
paths:
- path: /api              # ✅ Matches ALL API versions
  pathType: Prefix
  backend:
    service:
      name: backend-service
      port:
        number: 8080
- path: /
  pathType: Prefix
  backend:
    service:
      name: frontend-service
      port:
        number: 80
```

Now:
- `/api/v1/products` → `backend-service` ✅
- `/api/v2/products` → `backend-service` ✅
- `/` → `frontend-service` ✅

### Lessons Learned

1. **Test All Paths:**
   - Don't just test one version of the API
   - Test deprecated AND current endpoints
   - Automate path coverage testing

2. **Order Matters:**
   - Ingress rules are evaluated in order
   - Eng aniq path lar BIRINCHI kelishi kerak
   - Umumiyroq path lar OXIRIDA kelishi kerak

3. **Monitor Path Coverage:**
   - Track which paths are getting 404s
   - Alert on unexpected 404 spikes
   - "Resurs topilmadi" va "yo'nalish topilmadi" ni farqlang

4. **Use Integration Tests:**
   - Test qiling full request path: DNS → Ingress → Service → Pod
   - Don't rely solely on unit tests or health checks
   - Test from outside the cluster (like real users)

5. **Gradual Rollouts:**
   - Deploy Ingress changes to staging first
   - Muhim routing o'zgarishlar uchun canary deployment lar ishlating
   - Darhol rollback jarayonlari tayyor bo'lsin

---

## Advanced Ingress Concepts

### 1. **Path Rewriting**

Ba'zida Ingress path ni backend path dan farqli qilishni xohlaysiz.

**Example:** Eski API `/api/v1` da, yangi API `/v2` da, lekin foydalanuvchilar ikkisiga ham `/api` orqali kirishini xohlaysiz

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: api-service
            port:
              number: 8080
```

**Qanday ishlaydi:**
- Request: `http://api.example.com/api/users`
- Regex captures: `$2 = "users"`
- Rewritten to: `http://api-service:8080/users`
- Backend receives: `/users` (not `/api/users`)

### 2. **Multiple Paths to Same Service**

```yaml
paths:
- path: /app
  pathType: Prefix
  backend:
    service:
      name: web-service
      port:
        number: 80
- path: /application
  pathType: Prefix
  backend:
    service:
      name: web-service
      port:
        number: 80
```

Ham `/app/*` ham `/application/*` bitta service ga yo'naltiriladi.

### 3. **Multiple Services on Same Host**

```yaml
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8080
      - path: /images
        pathType: Prefix
        backend:
          service:
            name: cdn-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

**Path Evaluation Order (Most Specific First):**
1. `/api/*` → `backend-service`
2. `/images/*` → `cdn-service`
3. `/*` (everything else) → `frontend-service`

### 4. **Wildcard Hosts**

```yaml
spec:
  rules:
  - host: "*.example.com"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wildcard-service
            port:
              number: 80
```

Matches:
- `app.example.com` ✅
- `api.example.com` ✅
- `staging.example.com` ✅

Does NOT match:
- `example.com` ❌ (no subdomain)
- `app.staging.example.com` ❌ (too many levels)

---

## Debug qilish Qilish Ingress Path Issues

### 1. **Check Ingress Configuration**

```bash
# View Ingress details
kubectl describe ingress web-ingress -n k8squest

# Check path configuration
kubectl get ingress web-ingress -n k8squest -o yaml
```

Qidiring:
- `spec.rules[].http.paths[].path` - Is it correct?
- `spec.rules[].http.paths[].pathType` - Prefix, Exact, or ImplementationSpecific?
- `spec.rules[].http.paths[].backend` - Does it point to the right service?

### 2. **Test Path Matching Locally**

```bash
# Add host to /etc/hosts
echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts

# Test different paths
curl -v http://myapp.local/
curl -v http://myapp.local/api
curl -v http://myapp.local/api/users
```

Qidiring:
- **200 OK** - Path matches, request succeeded
- **404 Not Found** - Path mos kelmaydi OR resource mavjud emas
- **503 Service Unavailable** - Path matches but backend is down

### 3. **Check Ingress Controller Logs**

```bash
# Find Ingress controller pod (varies by installation)
kubectl get pods -n ingress-nginx

# View logs
kubectl logs -n ingress-nginx ingress-nginx-controller-xxxxx

# Follow logs in real-time
kubectl logs -n ingress-nginx ingress-nginx-controller-xxxxx -f
```

Qidiring:
```
# Path matched successfully
"GET / HTTP/1.1" 200

# Path mos kelmadi any rule
"GET /api HTTP/1.1" 404

# Backend service unavailable
"GET / HTTP/1.1" 503
```

### 4. **Tekshirish Backend Service**

```bash
# Service ni tekshirish exists
kubectl get service web-service -n k8squest

# Service ni tekshirish has endpoints
kubectl get endpoints web-service -n k8squest

# Describe service
kubectl describe service web-service -n k8squest
```

Agar endpoint lar bo'sh bo'lsa, service selector hech qanday pod ga mos kelmayotgan bo'lishi mumkin.

### 5. **Test Service Directly**

```bash
# Port-forward to service
kubectl port-forward -n k8squest service/web-service 8080:80

# Test in another terminal
curl http://localhost:8080/
```

This bypasses the Ingress to test if the backend service works.

---

## Eng Yaxshi Amaliyotlar for Ingress Paths

### 1. **Use Specific Paths First, General Paths Last**

```yaml
# ✅ GOOD: Most specific first
paths:
- path: /api/v2
  pathType: Prefix
  backend:
    service:
      name: api-v2-service
- path: /api
  pathType: Prefix
  backend:
    service:
      name: api-v1-service
- path: /
  pathType: Prefix
  backend:
    service:
      name: frontend-service
```

```yaml
# ❌ BAD: General path catches everything
paths:
- path: /
  pathType: Prefix
  backend:
    service:
      name: frontend-service
- path: /api        # Never reached! "/" already matched
  pathType: Prefix
  backend:
    service:
      name: api-service
```

### 2. **Be Careful with Trailing Slashes**

```yaml
# With Exact pathType
path: /login
pathType: Exact

# Matches: /login
# Does NOT match: /login/ (has trailing slash!)
```

`Exact` path larda `/login` va `/login/` FARQLI.

**Recommendation:** `Exact` ishlatish uchun aniq sabab bo'lmasa `Prefix` ishlating.

### 3. **Document Your Routing Logic**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    description: "Routes traffic for example.com application"
spec:
  rules:
  - host: example.com
    http:
      paths:
      # API v2 (current)
      - path: /api/v2
        pathType: Prefix
        backend:
          service:
            name: api-v2-service
            port:
              number: 8080
      
      # API v1 (deprecated, remove after Q2 2024)
      - path: /api/v1
        pathType: Prefix
        backend:
          service:
            name: api-v1-service
            port:
              number: 8080
      
      # Static assets (CDN)
      - path: /static
        pathType: Prefix
        backend:
          service:
            name: cdn-service
            port:
              number: 80
      
      # Frontend (catch-all)
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

### 4. **Test Path Changes Before Production**

```bash
# Create test Ingress with different host
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: k8squest
spec:
  rules:
  - host: test.myapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
EOF

# Test with curl
curl http://test.myapp.local/

# If it works, apply to production Ingress
```

### 5. **Monitor 404 Rates**

Set up monitoring/alerting for 404 errors:

```yaml
# Prometheus alert example
groups:
- name: ingress_alerts
  rules:
  - alert: HighIngress404Rate
    expr: |
      sum(rate(nginx_ingress_controller_requests{status="404"}[5m])) 
      / 
      sum(rate(nginx_ingress_controller_requests[5m])) > 0.05
    for: 5m
    annotations:
      summary: "High 404 rate on Ingress (>5% of requests)"
      description: "Check for path misconfigurations or broken links"
```

### 6. **Use Path Aliases for Backward Compatibility**

```yaml
# Support both /api and /v1/api during migration
paths:
- path: /v1/api
  pathType: Prefix
  backend:
    service:
      name: api-service
      port:
        number: 8080
- path: /api
  pathType: Prefix
  backend:
    service:
      name: api-service
      port:
        number: 8080
```

---

## Key Takeaways

1. **Path Matching is Literal:**
   - `/api` does NOT match `/`
   - `/` DOES match everything (with Prefix pathType)
   - Order matters when using multiple paths

2. **Choose the Right PathType:**
   - **Prefix:** Most common, matches path prefixes (e.g., `/api` matches `/api/users`)
   - **Exact:** Matches only exact path (e.g., `/login` matches `/login` only)
   - **ImplementationSpecific:** Depends on Ingress controller, avoid unless necessary

3. **Test Your Paths:**
   - Use `curl` to test different paths
   - Check Ingress controller logs
   - Tekshirish service endpoints exist

4. **Path Order Matters:**
   - Most specific paths first
   - General catch-all paths last
   - `/` should almost always be last

5. **Common Mistakes:**
   - Using `/api` when app serves at `/`
   - `Prefix` kerak bo'lganda `Exact` ishlatish
   - Putting catch-all `/` path first (it catches everything!)
   - Forgetting trailing slashes with `Exact` pathType

6. **Real-World Lessons:**
   - Path misconfigurations can cause complete outages
   - Test ALL API versions, not just one
   - Monitor 404 rates to catch routing issues
   - Have rollback procedures for Ingress changes

---

## Keyingi Qadam?

Siz o'zlashtirgansiz Ingress path-based routing! Endi siz tushunasiz:
- ✅ How Kubernetes Ingress routes HTTP traffic
- ✅ The difference between Prefix, Exact, and ImplementationSpecific pathTypes
- ✅ How to debug path mismatch issues
- ✅ Best practices for configuring Ingress paths

Keyingi level larda siz yanada ilg'or networking konseptlarini o'rganasiz: pod lar orasidagi trafikni boshqarish uchun NetworkPolicy pods, session affinity for stateful applications, and cross-namespace service communication.

**Keyingi topshiriqni ochish uchun K8sQuest sayohatingizni davom eting!** 🚀

---

## Qo'shimcha Resources

- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Ingress Path Matching](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Ingress Path Rewriting](https://kubernetes.github.io/ingress-nginx/examples/rewrite/)

---

**Mission Complete!** 🎉  
You've earned 250 XP and leveled up your Kubernetes networking skills!
