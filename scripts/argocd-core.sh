#!/usr/bin/env sh
# Run Argo in Kubernetes core mode without changing the user's Argo or kube contexts.
set -eu
umask 077

case "${1:-}" in
  --tailnet)
    [ "$#" -ge 3 ] || { echo 'usage: argocd-core.sh --tailnet HTTPS_KUBE_SERVER ARGO_ARGS... or --in-cluster ARGO_ARGS...' >&2; exit 2; }
    server=$2
    shift 2
    case "$server" in https://*) ;; *) echo 'expected an HTTPS Kubernetes endpoint' >&2; exit 2 ;; esac
    mode=tailnet
    context=homelab-core
    ;;
  --in-cluster)
    [ "$#" -ge 2 ] && [ -n "${KUBECONFIG:-}" ] || { echo 'in-cluster mode requires KUBECONFIG and Argo arguments' >&2; exit 2; }
    shift
    mode=in-cluster
    context=$(kubectl --kubeconfig "$KUBECONFIG" config current-context)
    ;;
  *) echo 'usage: argocd-core.sh --tailnet HTTPS_KUBE_SERVER ARGO_ARGS... or --in-cluster ARGO_ARGS...' >&2; exit 2 ;;
esac

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
trap 'exit 1' HUP INT TERM

if [ "$mode" = tailnet ]; then
  # This is a nonsecret proxy prompt suppressor, NOT Kubernetes authorization.
  jq -n --arg server "$server" --arg context "$context" '{apiVersion:"v1",kind:"Config",clusters:[{name:$context,cluster:{server:$server}}],users:[{name:$context,user:{token:"nonsecret-tailnet-proxy-placeholder"}}],contexts:[{name:$context,context:{cluster:$context,user:$context,namespace:"argocd"}}],"current-context":$context}' > "$tmp/kubeconfig"
  export KUBECONFIG="$tmp/kubeconfig"
else
  # Reject embedded bearer/cert credentials: Rex must use its live projected SA.
  kubectl --kubeconfig "$KUBECONFIG" config view --raw --minify --context "$context" -o json |
    jq -e '.contexts[0].context.namespace == "argocd" and (.users[0].user.tokenFile | type == "string" and startswith("/var/run/")) and (.users[0].user."certificate-authority-data" == null) and (.users[0].user."client-certificate-data" == null) and (.users[0].user.token == null)' >/dev/null || {
      echo 'expected an argocd-namespaced kube context with a projected tokenFile (no embedded credentials)' >&2
      exit 1
    }
fi

# The Argo client requires a resolvable current-context even in --core mode.
jq -n --arg context "$context" '{"current-context":$context,contexts:[{name:$context,server:$context,user:$context}],servers:[{server:$context,core:true}],users:[{name:$context}]}' > "$tmp/argocd-config"
argocd --core --config "$tmp/argocd-config" --kube-context "$context" "$@"
