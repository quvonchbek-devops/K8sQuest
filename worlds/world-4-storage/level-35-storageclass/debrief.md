# 🎓 Missiya Yakuni: StorageClass Configuration

**Tabriklaymiz!** Siz o'zlashtirgansiz StorageClass troubleshooting - the foundation of dynamic storage provisioning Kubernetes da!

---

## 📊 Nimani Tuzatdingiz

**Muammo:**
```yaml
spec:
  storageClassName: premium-ssd  # ❌ Doesn't exist!
```
Result: PVC stuck in Pending forever

**Yechim:**
```yaml
spec:
  storageClassName: standard  # ✅ Use existing StorageClass
```
Result: PVC automatically provisioned and bound

---

## 🔍 Tushunish StorageClass

### What is a StorageClass?

StorageClass is a Kubernetes resource that describes different "classes" of storage:
- **Provisioner:** What creates the storage (AWS EBS, GCE PD, NFS, etc.)
- **Parameters:** Configuration (disk type, IOPS, encryption, etc.)
- **Reclaim Policy:** What happens when PVC is deleted
- **Volume Binding Mode:** When to provision (Immediate or WaitForFirstConsumer)

### Static vs Dynamic Provisioning

**Static Provisioning (Manual):**
1. Admin creates PersistentVolume manually
2. User creates PVC
3. Kubernetes binds PVC to matching PV

**Dynamic Provisioning (Automatic):**
1. User creates PVC with storageClassName
2. StorageClass provisioner automatically creates PV
3. Kubernetes binds PVC to new PV

---

## 🎯 StorageClass Examples

### AWS EBS (Block Storage)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ebs
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iopsPerGB: "10"
  encrypted: "true"
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

### Google Cloud Persistent Disk

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-gce
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  replication-type: regional-pd
```

### Azure Disk

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-azure
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
```

### NFS (Network File System)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
provisioner: example.com/nfs
parameters:
  server: nfs-server.example.com
  path: /exported/path
  readOnly: "false"
```

---

## 💥 Common Mistakes

### Mistake 1: Non-Existent StorageClass

```yaml
# PVC
spec:
  storageClassName: super-fast  # ❌ Doesn't exist!
```
Fix: Use `kubectl get sc` to find available classes

### Mistake 2: Wrong Provisioner for Cloud

```yaml
# On AWS, but using GCE provisioner
kind: StorageClass
provisioner: kubernetes.io/gce-pd  # ❌ Wrong cloud!
```
Fix: Match provisioner to your infrastructure

### Mistake 3: Missing Default StorageClass

```yaml
# No default marked, PVCs with empty storageClassName fail
```
Fix: Mark one as default:
```yaml
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
```

---

## 🚨 REAL-WORLD INCIDENT: The Missing StorageClass

**Kompaniya:** E-commerce platform  
**Ta'sir:** 2 hours downtime, $400K revenue loss  

**What Happened:**
- New developer created PVC with `storageClassName: fast-storage`
- StorageClass mavjud emas edi
- Deployment stuck, pods ishga tusha olmadi
- Black Friday traffic lost

**Root Cause:** No validation of StorageClass existence

**Fix:**
- Document available StorageClasses
- Add admission webhook to validate
- Create standard storage classes in all environments

---

## 🛡️ Best Practices

1. **List available classes:**
   ```bash
   kubectl get storageclass
   ```

2. **Set a default:**
   ```yaml
   annotations:
     storageclass.kubernetes.io/is-default-class: "true"
   ```

3. **Use WaitForFirstConsumer for multi-zone:**
   ```yaml
   volumeBindingMode: WaitForFirstConsumer
   # Ensures PV created in same zone as pod
   ```

4. **Document your classes:**
   ```yaml
   metadata:
     annotations:
       description: "Fast SSD storage for databases"
       cost: "high"
       performance: "high-iops"
   ```

---

## 🎯 Key Takeaways

1. **StorageClass enables dynamic provisioning** - No manual PV creation
2. **Must exist before PVC creation** - Or PVC stays Pending
3. **Turli ehtiyojlar uchun turli class lar** — tez/sekin, arzon/qimmat
4. **Cloud-specific provisioners** - AWS EBS, GCE PD, Azure Disk
5. **Check availability first** - `kubectl get sc`

---

**Yaxshi ish!** You understand StorageClass fundamentals! 🎉
