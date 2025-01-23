podman build -t $REGISTRY_URL/$OCP_NAMESPACE/msr-base-jdbc:11.1.0.1 \
    --platform=linux/amd64 \
    --build-arg WPM_TOKEN=$WPM_TOKEN \
    --build-arg GIT_TOKEN=$GH_SAG_PAT .