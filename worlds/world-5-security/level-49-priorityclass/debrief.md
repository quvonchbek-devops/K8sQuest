# 🎓 Missiya Yakuni: PriorityClass

**Tabriklaymiz!** PriorityClass mastered!

---

## Priority & Preemption

**PriorityClass** assigns importance to pods.

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000  # Higher value = higher priority
preemptionPolicy: PreemptLowerPriority
```

**Preemption**: Scheduler evicts lower priority pods to make room for higher priority.

---

## Priority Values

- **System-critical**: 2000000000+ (reserved)
- **Production-critical**: 1000-10000
- **Production**: 500-999
- **Development**: 100-499
- **Batch/test**: 0-99

---

## 🎯 Asosiy Xulosalar

1. **Higher value = higher priority**
2. **Preemption evicts lower priority** pods
3. Faqat **muhim ish yuklari uchun** ishlating
4. **Assign via priorityClassName**
5. **Balance**: Don't make everything high priority!

---

## Final Level

🎉 **LEVEL 50: CHAOS FINALE** - Coming next!

Combines ALL World 5 concepts in one epic challenge!

**Great work!** 🚀⭐
