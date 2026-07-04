# 🎓 Missiya Yakuni: Stateful Ilova Ma'lumot Yo'qotishi

## Nima Sodir Bo'ldi

Ma'lumotlar bazasi uchun Deployment ishlatilayotgan edi. Deployment — stateless ilovalar uchun mo'ljallangan. Pod qayta ishga tushganda yangi nom oldi, storage yo'qoldi, va barcha ma'lumotlar o'chib ketdi.

Yechim: Deployment o'rniga **StatefulSet** ishlatish.

## Kubernetes Qanday Ishladi

### Deployment va StatefulSet Farqi

| Jihat | Deployment | StatefulSet |
|-------|-----------|-------------|
| **Pod nomlari** | Tasodifiy (web-7d8f9-abc) | Barqaror (web-0, web-1, web-2) |
| **Ishga tushish** | Parallel (bir vaqtda) | Tartibli (0→1→2) |
| **To'xtash** | Istalgan tartibda | Teskari tartibda (2→1→0) |
| **Storage** | Ulashilgan yoki yo'q | Har pod ga alohida PVC |
| **DNS** | Tasodifiy | Barqaror (pod-0.service) |
| **Mo'ljal** | Web server, API | DB, Kafka, etcd |

### StatefulSet Kafolatlari

```
StatefulSet: database (replicas: 3)
  ├── database-0  ← DOIM birinchi ishga tushadi, oxirgi to'xtaydi (Primary)
  │   └── PVC: data-database-0 (o'zining alohida storage)
  ├── database-1  ← database-0 tayyor bo'lgandan keyin ishga tushadi
  │   └── PVC: data-database-1 (o'zining alohida storage)
  └── database-2  ← database-1 tayyor bo'lgandan keyin ishga tushadi
      └── PVC: data-database-2 (o'zining alohida storage)
```

**Barqaror DNS** (headless service kerak):
```
database-0.database-service.namespace.svc.cluster.local
database-1.database-service.namespace.svc.cluster.local
database-2.database-service.namespace.svc.cluster.local
```

### Qachon StatefulSet Ishlatish

✅ **StatefulSet kerak**:
- Ma'lumotlar bazalari (PostgreSQL, MySQL, MongoDB)
- Xabar navbatlari (Kafka, RabbitMQ)
- Taqsimlangan tizimlar (etcd, ZooKeeper, Consul)
- Har qanday ilova — barqaror identifikatsiya va doimiy storage talab qiladigan

❌ **Deployment yetarli**:
- Web serverlar (nginx, Apache)
- API lar (REST, GraphQL)
- Worker lar (background job lar)
- Har qanday stateless ilova

## Haqiqiy Voqea Misoli

**Kompaniya**: SaaS platforma
**Ta'sir**: 4 soatlik ma'lumot yo'qotish
**Sabab**: PostgreSQL Deployment sifatida ishlagan, pod crash bo'lganda barcha tranzaksiyalar yo'qoldi

**Yechim**: StatefulSet + volumeClaimTemplates ga o'tish:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-headless
  replicas: 3
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

## O'zlashtirilgan Buyruqlar

```bash
# StatefulSet holatini tekshirish
kubectl get statefulset -n <namespace>

# Pod lar tartibli nomlarini ko'rish
kubectl get pods -l app=<label> -n <namespace>

# Alohida PVC larni ko'rish
kubectl get pvc -n <namespace>

# Headless service tekshirish
kubectl get svc -n <namespace>
# CLUSTER-IP: None bo'lishi kerak
```

## Keyingi Qadam

- ✅ Deployment va StatefulSet farqi
- ✅ Barqaror pod identifikatsiyasi va storage
- ✅ Headless service va DNS

**Keyingi**: ReplicaSet — Deployment ning ichki mexanizmi!
