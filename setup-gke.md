See :
- [https://github.com/likamrat/azure_arc/blob/master/azure_arc_k8s_jumpstart/docs/gke_terraform.md](https://github.com/likamrat/azure_arc/blob/master/azure_arc_k8s_jumpstart/docs/gke_terraform.md)

export KUBECONFIG=gke-config
gcloud container clusters create tns-demo-gke \
    --zone asia-south1-a \
    --disk-type=pd-ssd \
    --disk-size=50GB \
    --machine-type=n1-standard-1 \
    --num-nodes=3 \
    --image-type ubuntu

kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)