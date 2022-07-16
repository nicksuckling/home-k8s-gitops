#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel)

die() {
  echo "$*" 1>&2
  exit 1
}

need() {
  which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "kubectl"
need "helm"

message() {
  echo -e "\n######################################################################"
  echo "# $1"
  echo "######################################################################"
}

installArgoCd() {
  message "installing argoCD Helm Chart"

  kubectl create namespace argocd

  helm repo add argo-cd https://argoproj.github.io/argo-helm
  cd $REPO_ROOT/
  helm dep update charts/argo-cd


  helm install -n argocd argo-cd charts/argo-cd

  checkDeployment argo-cd-argocd-applicationset-controller argocd
  checkDeployment argo-cd-argocd-repo-server argocd
  checkDeployment argo-cd-argocd-server argocd
  checkDeployment argo-cd-argocd-redis argocd

  message "argoCD Helm Chart is Ready"

}

checkDeployment() {
  READY=1
  while [ $READY != 0 ]; do
    echo "waiting for $1 to be fully ready..."
    kubectl -n $2 wait --for condition=Available deployment/$1 >/dev/null 2>&1
    READY="$?"
    sleep 5
  done
}

initArgo() {
  message "Setting up argoCD"

  cd $REPO_ROOT || exit

  helm template argocd/ | kubectl apply -f -

  #kubectl delete secret -l owner=helm,name=argocd -n argocd

}


installArgoCd
initArgo

#"$REPO_ROOT"/setup/bootstrap-objects.sh
#"$REPO_ROOT"/setup/bootstrap-vault.sh

message "all done!"
kubectl get nodes -o=wide
