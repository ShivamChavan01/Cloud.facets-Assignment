# Infrastructure Developer Assignment (Platform Engineer)

## Prerequisites

Before starting, ensure you have the following dependencies installed on your Windows system:

### Required Dependencies

1. **Minikube** - Kubernetes local cluster
2. **Kubectl** - Command-line tool for Kubernetes
3. **Helm** - Package manager for Kubernetes
4. **Terraform** - Infrastructure as Code tool
5. **Docker Desktop** (with Kubernetes enabled)
6. **Prometheus** - Monitoring system
7. **Grafana** - Data visualization tool

## Manual Deployment

### Step 1: Start Minikube

```sh
minikube start
```

### Step 2: Install Nginx Ingress Controller

```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install my-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
```

### Step 3: Deploy Applications

#### Blue Application

Create a file `blue-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blue-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: blue-app
  template:
    metadata:
      labels:
        app: blue-app
    spec:
      containers:
        - name: blue-app
          image: hashicorp/http-echo
          args:
            - "-listen=:8080"
            - "-text=I am blue"
          ports:
            - containerPort: 8080
```

Create a Service `blue-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: blue-service
spec:
  selector:
    app: blue-app
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  type: ClusterIP
```

Apply the configurations:

```sh
kubectl apply -f blue-deployment.yaml
kubectl apply -f blue-service.yaml
```

#### Green Application

Create a file `green-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: green-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: green-app
  template:
    metadata:
      labels:
        app: green-app
    spec:
      containers:
        - name: green-app
          image: hashicorp/http-echo
          args:
            - "-listen=:8081"
            - "-text=I am green"
          ports:
            - containerPort: 8081
```

Create a Service `green-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: green-service
spec:
  selector:
    app: green-app
  ports:
    - protocol: TCP
      port: 8081
      targetPort: 8081
  type: ClusterIP
```

Apply the configurations:

```sh
kubectl apply -f green-deployment.yaml
kubectl apply -f green-service.yaml
```

### Step 4: Create an Ingress

Create a file `ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: "/"
spec:
  rules:
    - http:
        paths:
          - path: "/blue"
            pathType: Prefix
            backend:
              service:
                name: blue-service
                port:
                  number: 8080
          - path: "/green"
            pathType: Prefix
            backend:
              service:
                name: green-service
                port:
                  number: 8081
```

Apply the ingress:

```sh
kubectl apply -f ingress.yaml
```

### Step 5: Forward Ports

```sh
kubectl get svc -n ingress-nginx
kubectl port-forward -n ingress-nginx svc/my-nginx-ingress-nginx-controller 8080:80
```

### Step 6: Test the Deployment

Use `curl` to test the services:

```sh
curl http://localhost:8080/blue
curl http://localhost:8080/green
```

## Monitoring with Prometheus and Grafana

### Step 1: Install Prometheus and Grafana

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
```

### Step 2: Access Grafana Dashboard

```sh
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Now, open [http://localhost:3000](http://localhost:3000) in your browser and log in with:
- **Username:** admin
- **Password:** prom-operator (or check the actual password using `kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode`)

### Step 3: Add Prometheus Data Source

1. In Grafana, navigate to **Configuration > Data Sources**.
2. Click **Add data source**.
3. Select **Prometheus** and enter the URL: `http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`
4. Click **Save & Test**.

### Step 4: Visualize Metrics

Import a Kubernetes dashboard:
1. Go to **Dashboards > Import**.
2. Use dashboard ID **3119** (Kubernetes Cluster Monitoring) or any preferred dashboard.
3. Select **Prometheus** as the data source and click **Import**.

## Terraform Deployment

(Same as before, Terraform steps remain unchanged)

## Conclusion

This guide walks you through both manual and Terraform-based deployment of a Blue-Green deployment using Kubernetes and Nginx Ingress, along with Prometheus and Grafana for monitoring. Let me know if you have any questions! 🚀

### For detailed Terraform explanation, see this [Notion Page](https://basalt-floss-edc.notion.site/Detailed-Explanation-of-Terraform-Deployment-and-Manual-Deployment-Process-1939055befce803b83c1c4f856253cc2)



## Conclusion

This guide walks you through both manual and Terraform-based deployment of a Blue-Green deployment using Kubernetes and Nginx Ingress. Let me know if you have any questions! 🚀


### For detailed Terraform explanation, see this [Notion Page](https://basalt-floss-edc.notion.site/Detailed-Explanation-of-Terraform-Deployment-and-Manual-Deployment-Process-1939055befce803b83c1c4f856253cc2)


## Screenshots

### Screenshot 1
![Screenshot 2025-02-07 170928](https://github.com/user-attachments/assets/f071b231-9c0c-4ee9-93a2-96c3f6d81839)


### Screenshot 2
![Screenshot 2025-02-06 194258](https://github.com/user-attachments/assets/b65441e5-f34a-4d56-8ab8-4bfcee0a7cb1)


### Screenshot 3
![Screenshot 2025-02-07 161306](https://github.com/user-attachments/assets/5ab0a98c-15d2-444c-b46c-44b041b79b4a)



