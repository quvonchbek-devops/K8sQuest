#!/bin/bash

# PDB konfiguratsiyasini tekshirish
MIN_AVAILABLE=$(kubectl get pdb db-proxy-pdb -n k8squest -o jsonpath='{.spec.minAvailable}' 2>/dev/null)
REPLICAS=$(kubectl get deployment database-proxy -n k8squest -o jsonpath='{.spec.replicas}' 2>/dev/null)

# PDB eviction larga ruxsat berishini tekshirish
ALLOWED=$(kubectl get pdb db-proxy-pdb -n k8squest -o jsonpath='{.status.disruptionsAllowed}' 2>/dev/null)

if [ "$MIN_AVAILABLE" -ge "$REPLICAS" ]; then
    echo "❌ PDB is too restrictive!"
    echo "   minAvailable: $MIN_AVAILABLE >= replicas: $REPLICAS"
    echo "   This blocks ALL evictions - node drains will fail!"
    exit 1
fi

if [ "$ALLOWED" -gt 0 ]; then
    echo "✅ PDB allows evictions"
    echo "   minAvailable: $MIN_AVAILABLE (keeps $MIN_AVAILABLE pods running)"
    echo "   Replicas: $REPLICAS"
    echo "   Ruxsat etilgan uzilishlar: $ALLOWED"
    exit 0
else
    echo "❌ PDB currently blocks all disruptions"
    echo "   Ruxsat etilgan uzilishlar: $ALLOWED"
    exit 1
fi
