#!/usr/bin/env bash
# ============================================================
# kube-prometheus-stack 81.6.1 — Descarga de imágenes Docker
# ============================================================
# Ejecutar en una máquina CON acceso a internet.
# Por defecto solo descarga las imágenes.
# Con --save también empaqueta en tarballs dentro de tar_monitoring/.
#
# USO:
#   ./monitoring-images-pull.sh            # solo descargar
#   ./monitoring-images-pull.sh --save     # descargar + empaquetar
# ============================================================
set -euo pipefail

MODE="${1:-pull}"
OUTDIR="tar_monitoring"

IMAGES=(
  # --- Prometheus Operator (v0.88.1) ---
  quay.io/prometheus-operator/prometheus-operator:v0.88.1
  quay.io/prometheus-operator/prometheus-config-reloader:v0.88.1
  quay.io/prometheus-operator/admission-webhook:v0.88.1

  # --- Prometheus / Alertmanager / Thanos ---
  quay.io/prometheus/prometheus:v3.9.1
  quay.io/prometheus/alertmanager:v0.31.0
  quay.io/thanos/thanos:v0.40.1

  # --- RBAC Proxy ---
  quay.io/brancz/kube-rbac-proxy:v0.20.2

  # --- Webhook certgen ---
  ghcr.io/jkroepke/kube-webhook-certgen:1.7.6

  # --- Grafana (sub-chart 11.1.0, app 12.3.2) ---
  docker.io/grafana/grafana:12.3.2
  docker.io/grafana/grafana-image-renderer:latest

  # --- Sidecar ---
  quay.io/kiwigrid/k8s-sidecar:2.5.0

  # --- Utilidades (init containers, tests) ---
  docker.io/curlimages/curl:8.18.0
  docker.io/bats/bats:1.13.0
  docker.io/library/busybox:1.37.0
  docker.io/busybox:latest

  # --- kube-state-metrics (sub-chart 7.1.0, app 2.18.0) ---
  registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.18.0

  # --- node-exporter (sub-chart 4.51.1, app 1.10.2) ---
  quay.io/prometheus/node-exporter:v1.10.2

  # --- windows-exporter (sub-chart 0.12.3, app 0.31.3) ---
  ghcr.io/prometheus-community/windows-exporter:v0.31.3
)

echo "📦 Descargando ${#IMAGES[@]} imágenes para kube-prometheus-stack 81.6.1..."
echo ""

for img in "${IMAGES[@]}"; do
  echo "  🔽 Pulling: $img"
  docker pull "$img" 2>&1 | tail -1
done

echo ""
echo "✅ Todas las imágenes descargadas."

if [ "$MODE" = "--save" ]; then
  echo ""
  echo "📁 Empaquetando en $OUTDIR/ ..."
  mkdir -p "$OUTDIR"
  for img in "${IMAGES[@]}"; do
    name=$(echo "$img" | tr "/:" "_")
    tar_path="${OUTDIR}/${name}.tar"
    if [ -f "$tar_path" ]; then
      echo "  ⏭️  Ya existe: $tar_path"
    else
      echo "  💾 Salvando: $img -> $tar_path"
      docker save "$img" -o "$tar_path"
    fi
  done
  echo ""
  echo "✅ Tarballs generados en $OUTDIR/"
  echo "   Total: $(ls -1 "$OUTDIR"/*.tar 2>/dev/null | wc -l) archivos"
  echo "   Peso:  $(du -sh "$OUTDIR" | cut -f1)"
fi
