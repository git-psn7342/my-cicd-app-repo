cat > deploy-bluegreen.sh << 'EOF'
#!/bin/bash
set -e

PROJECT_ID="able-folio-490803-g2"
IMAGE="us-central1-docker.pkg.dev/${PROJECT_ID}/my-app/app:${SHORT_SHA}"
NAMESPACE="production"

echo "Starting blue-green deployment..."

# Determine current slot
CURRENT=$(kubectl get service my-cicd-app-service -n $NAMESPACE \
  -o jsonpath='{.spec.selector.slot}')

if [ "$CURRENT" == "blue" ]; then
  NEW_SLOT="green"
  OLD_SLOT="blue"
else
  NEW_SLOT="blue"
  OLD_SLOT="green"
fi

echo "Current slot: $OLD_SLOT → Deploying to: $NEW_SLOT"

# Update new slot with new image
kubectl set image deployment/my-cicd-app-${NEW_SLOT} \
  my-cicd-app=${IMAGE} -n $NAMESPACE

# Wait for rollout
kubectl rollout status deployment/my-cicd-app-${NEW_SLOT} \
  -n $NAMESPACE --timeout=120s

# Switch traffic to new slot
kubectl patch service my-cicd-app-service -n $NAMESPACE \
  -p "{\"spec\":{\"selector\":{\"slot\":\"${NEW_SLOT}\"}}}"

echo "Traffic switched to $NEW_SLOT"

# Verify health
sleep 5
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  http://$(kubectl get service my-cicd-app-service \
  -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}'))

if [ "$RESPONSE" != "200" ]; then
  echo "Health check failed! Rolling back to $OLD_SLOT..."
  kubectl patch service my-cicd-app-service -n $NAMESPACE \
    -p "{\"spec\":{\"selector\":{\"slot\":\"${OLD_SLOT}\"}}}"
  exit 1
fi

echo "Deployment successful! Running on $NEW_SLOT"
EOF

chmod +x deploy-bluegreen.sh
