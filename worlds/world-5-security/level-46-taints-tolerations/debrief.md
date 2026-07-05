# 🎓 Missiya Yakuni: Taints & Tolerations

**Tabriklaymiz!** Siz o'zlashtirgansiz taints and tolerations - the gatekeepers of node scheduling!

---

## 📊 Nimani Tuzatdingiz

**Problem:** Node taint qilindi, pod has no toleration
```yaml
# Node: dedicated=gpu:NoSchedule
# Pod: No tolerations → Can't schedule
```

**Solution:** Added matching toleration
```yaml
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "gpu"
  effect: "NoSchedule"
```

**Natija:** Pod schedules successfully

---

## 🎯 Understanding Taints & Tolerations

### Taints (Node-level)

**Purpose:** Repel pods from nodes

```bash
kubectl taint nodes node1 key=value:Effect
```

**Effects:**
- **NoSchedule**: New pods schedule qila olmaydi
- **PreferNoSchedule**: Avoid scheduling (soft)
- **NoExecute**: Evict existing + block new

### Tolerations (Pod-level)

**Purpose:** Allow scheduling on tainted nodes

```yaml
tolerations:
- key: "gpu"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
```

---

## 🔧 Common Patterns

### Dedicated Nodes
```bash
# Taint GPU nodes
kubectl taint nodes gpu-node dedicated=gpu:NoSchedule

# Only GPU workloads tolerate
tolerations:
- key: "dedicated"
  value: "gpu"
  effect: "NoSchedule"
```

### Maintenance Mode
```bash
# Drain node (NoExecute)
kubectl taint nodes node1 maintenance=true:NoExecute

# Evicts all pods siz toleration
```

### Spot Instances
```bash
# Mark as spot
kubectl taint nodes spot-1 node.kubernetes.io/instance-type=spot:PreferNoSchedule

# Dev workloads tolerate
tolerations:
- key: "node.kubernetes.io/instance-type"
  operator: "Exists"
```

---

## 💥 Keng Tarqalgan Xatolar

1. **Missing effect**: Must match taint effect
2. **Typo in key/value**: Case-sensitive!
3. **Wrong operator**: "Equal" needs value, "Exists" doesn't
4. **Forgetting NoExecute**: Evicts running pods

---

## 🎯 Asosiy Xulosalar

1. **Taints repel**, **tolerations allow**
2. **All parts must match**: key, value, effect
3. **NoExecute evicts** existing pods
4. **operator: Exists** tolerates any value
5. **Use for**: dedicated nodes, maintenance, special hardware

---

## 🚀 Keyingi Qadamlar

- **Level 47:** PodDisruptionBudget
- **Level 48:** Admission Webhooks  
- **Level 49:** PriorityClass
- **Level 50:** CHAOS FINALE!

**Excellent work!** 🎉⚡
