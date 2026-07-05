# 🎓 Missiya Yakuni: ConfigMap Key Management

**Tabriklaymiz!** Siz o'zlashtirgansiz ConfigMap key references - essential for application configuration Kubernetes da!

---

## 📊 Nimani Tuzatdingiz

**Muammo:**
```yaml
data:
  app_name: "MyApp"
  app_version: "1.0.0"
  # ❌ Missing: database_host
  
env:
- name: DATABASE_HOST
  valueFrom:
    configMapKeyRef:
      key: database_host  # ❌ Key mavjud emas!
```

**Yechim:**
```yaml
data:
  app_name: "MyApp"
  app_version: "1.0.0"
  database_host: "postgres.k8squest.svc.cluster.local"  # ✅ Added!
```

---

## 🔍 ConfigMap Fundamentals

ConfigMaps store non-sensitive configuration data as key-value pairs.

### Three Ways to Use ConfigMaps

**1. Environment Variables:**
```yaml
env:
- name: APP_NAME
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: app_name
```

**2. All Keys as Environment Variables:**
```yaml
envFrom:
- configMapRef:
    name: app-config
# Creates env vars for ALL keys
```

**3. As Files (Volume Mount):**
```yaml
volumes:
- name: config
  configMap:
    name: app-config
volumeMounts:
- name: config
  mountPath: /etc/config
# Each key becomes a file
```

---

## 💥 Common Mistakes

### Mistake 1: Key Typo
```yaml
data:
  database_host: "..."  # Defined as database_host

env:
- valueFrom:
    configMapKeyRef:
      key: databaseHost  # ❌ Wrong case!
```

### Mistake 2: Missing Required Key
```yaml
# ConfigMap has: app_name, app_version
# Pod needs: app_name, app_version, database_host
# Result: Pod fails to start
```

### Mistake 3: Using configMapKeyRef siz Optional Flag
```yaml
env:
- name: OPTIONAL_CONFIG
  valueFrom:
    configMapKeyRef:
      name: config
      key: optional_key  # ❌ If missing, pod fails
      # Should add: optional: true
```

---

## 🛡️ Best Practices

1. **Validate all required keys exist:**
   ```bash
   kubectl get configmap app-config -o jsonpath='{.data}'
   ```

2. **Use optional for non-critical configs:**
   ```yaml
   configMapKeyRef:
     key: feature_flag
     optional: true
   ```

3. **Document expected keys:**
   ```yaml
   metadata:
     annotations:
       required-keys: "app_name,database_host,api_key"
   ```

4. **Use envFrom for all keys:**
   ```yaml
   envFrom:
   - configMapRef:
       name: app-config
   ```

---

## 🎯 Key Takeaways

1. **All referenced keys must exist** - Or pod fails to start
2. **Keys are case-sensitive** - database_host ≠ databaseHost
3. **Three usage patterns** - Env vars, envFrom, volume mounts
4. **Muhim bo'lmagan uchun optional: true ishlating** — Pod ni ishga tushishga ruxsat beradi
5. **Deploy dan oldin tekshiring** — ConfigMap da barcha kerakli kalit lar borligini tekshiring

---

**Yaxshi ish!** You understand ConfigMap key management! 🎉
