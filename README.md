# Elonwallet Helm Deployment
## Requirements
- A domain and public ip address (The domain should map to that ip)
- [Helm v3](https://helm.sh/docs/intro/install/)
- [Kubernetes (Kubelet, Kubectl, Kubeadm) ](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- At least one node 
- a container runtime
- An Email Server
- A moralis api key
- A Mumbai Matic wallet, with some balance. (Used to transfer 0.01 matics to registered users for test purposes) 

## Set-Up
**1.1** Initialize a kubernetes cluster and install a networking plugin of your liking. Here is an example using Calico (Skip to 2, if you wish to install another networking plug-in):

**1.2** 
 ```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock
``` 
(here, cri-dockerd is used as a container-runtime, but it also works with other runtimes)
If you only have one node in your cluster, so you need to use the control plane node to schedule pods on, you will need to untaint it (!!not recommended in production!!):
 ```bash
kubectl taint nodes --all  node-role.kubernetes.io/control-plane-
``` 
**1.3** 
Install Calico using helm
 ```bash
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm install calico projectcalico/tigera-operator --version v3.25.1 --namespace tigera-operator --create-namespace
``` 
**2.1** Set up a load balancer. This step differs depending on whether you are deploying on bare metal or in a cloud. Here,
we want to get a public ip address for a kubernetes load balancer service. This load balancer service needs to obtain the public IP address associated with your domain, which you want to use. 
If you are in a cloud, refer to your cloud provider's documentation and skip to 3 afterwards.
**2.2** 

For a bare metall set up, install the metallb load balancer:
 ```bash
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -n metallb-system --create-namespace --wait
``` 
**2.3**

Configure metallb to provide the public ip associated with your domain.
Use the following command, but replace {{ Enter your ip here }} with the ip beforehand.

 ```bash
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
  annotations:
    "helm.sh/hook": "post-install"
    "helm.sh/hook-weight": "0"
spec:
  addresses:
  - {{ Enter your ip here}} - {{ Enter your ip here }}
EOF
``` 
**3.1** Install with Helm the missing required dependencies (Istio and Cert-Manager)

**3.2** 
Cert-Manager is used for automatic tls certificate provisioning and renewal. For the verification of HTTP-01 challenges, cert-manager is deploying an Istio-Ingress and for this to work,   
istiod has to be configured with meshConfig.ingressService=istio-ingress --set meshConfig.ingressSelector=ingress, to use that ingress for incoming traffic. 
```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm install istio-base istio/base -n istio-system --create-namespace
helm install istiod istio/istiod -n istio-system --set meshConfig.ingressService=istio-ingress --set meshConfig.ingressSelector=ingress --wait
helm install istio-ingress istio/gateway -n istio-system --create-namespace --wait
``` 
**3.3**
Now install cert-manager
```bash
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.12.0 --set installCRDs=true
``` 
**4.1** Finally, configure a values.yaml to suit your environment.
For this create a values.yaml file, insert the following and replace the values:
```bash
sgx_activate: false # specify if you want sgx to be activated | possible values true and false
domain: example.com # specify your domain here. Should be equivalent to the frontend host
postgres:
  user: test   # specify a db user
  db: test   # specify a name for the db
  password: test   # specify a password for the postgres db
backend:
  moralis_api_key: test   # insert your moralis api key here
  email_user: test@example.com   # insert the email user here
  email_password: test   # insert the password of the email usere here 
  email_auth_host: test   # insert the email auth host here 
  email_smtp_host: test   # insert the smtp host here
  wallet_private_key_hex: 43ab301   # insert the mumbai matic wallet private key in hex here
  wallet_address: test   # insert the corresponding wallet address here
 ```

**4.2** 
Install elonmask and you are ready to go!
```bash
helm repo add elonmask https://elonwallet-io.github.io/helm-deployment/
helm install elonmask elonmask/elonmask-pre --values values.yaml
``` 
Note that, it takes several seconds for the certificates to fetch.


