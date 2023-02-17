## Install Nginx

Run:ai requires an ingress controller as a prerequisite. The Run:ai cluster installation configures one or more ingress objects on top of the controller.

There are many ways to install and configure an ingress controller and configuration is environment-dependent. A simple solution is to install & configure NGINX:

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade -i nginx-ingress ingress-nginx/ingress-nginx   \
    --namespace nginx-ingress --create-namespace \
    --set controller.kind=DaemonSet \
    --set controller.daemonset.useHostPort=true
```

## Configure External IP

To configure an external IP for a control plane node in Kubernetes, you first need to determine whether the IP address you want to use is internal or external. You can check the IP address of the control plane node by running the following command:

```
kubectl get nodes -o wide
```

The output of this command will display the internal and external IP addresses of each node, along with other information such as the operating system and container runtime.

Once you have identified the IP address to use, you can configure it for the nginx service in Kubernetes. To get the correct namespace for nginx, you can run the following command:

```
kubectl get pods -A | grep nginx
```

To get the name of the ingress controller for the ingress-nginx namespace, you can run the following command:

```
kubectl get svc -n ingress-nginx
```

This command will display a list of services in the ingress-nginx namespace, including the ingress controller service. The name of the ingress controller service usually includes the word controller. You can use this name to edit the service and add the external IP address, as described in the previous answer.

To edit the ingress controller service and add an external IP address, you can run the following command:

```
kubectl edit svc <ingress-controller-service-name> -n ingress-nginx
```

Replace <ingress-controller-service-name> with the name of the ingress controller service that you found in the previous step. This command will open the service definition in a text editor, allowing you to modify the configuration. To add an external IP address, you can add the following line under the clusterIPs section:

```
externalIPs:
  - <add your IP address here>
```
  
Replace <add your IP address here> with the external IP address you want to use. Once you have made this change, save the file and exit the text editor.

After configuring the external IP for the service, you can verify that it has been successfully added by running the following command:

```
kubectl get svc -n ingress-nginx
```
  
The output of this command will show the updated configuration for the nginx service, including the external IP address that you added.
