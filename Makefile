current_dir = $(shell pwd)
quick-start:
	make add-helm-repos
	make dependencies ip=$(ip) auto_tls=$(auto_tls) load_balancer=$(load_balancer)
add-helm-repos:
	helm repo add projectcalico https://docs.tigera.io/calico/charts
	helm repo add metallb https://metallb.github.io/metallb
	helm repo add istio https://istio-release.storage.googleapis.com/charts
	helm repo add jetstack https://charts.jetstack.io
dependencies:
	helm install calico projectcalico/tigera-operator --version v3.25.1 --namespace tigera-operator --create-namespace --wait
	@if [ "$(load_balancer)" = "true" ]; then helm install metallb metallb/metallb  --version v0.13.10 -n metallb-system --create-namespace --wait && sed -i 's/IPPLACEHOLDER/$(ip)/g' ./elonwallet/config/ip_pool.yaml &&  kubectl apply -f ./elonwallet/config/ip_pool.yaml; fi
	helm install istio-base istio/base --version 1.18.0 -n istio-system --create-namespace
	helm install istiod istio/istiod --version 1.18.0  -n istio-system --set meshConfig.ingressService=istio-ingress --set meshConfig.ingressSelector=ingress --wait
	helm install istio-ingress istio/gateway --version 1.18.0  -n istio-system --create-namespace --wait
	@if [ "$(auto_tls)" = "true" ]; then helm install cert-manager jetstack/cert-manager --version v1.12.2 --namespace cert-manager --create-namespace --version v1.12.0 --set installCRDs=true;fi

