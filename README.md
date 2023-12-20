# Running in kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: thunderbird
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: thunderbird
  template:
    metadata:
      labels:
        app: thunderbird
    spec:
      nodeSelector:
        kubernetes.io/arch: amd64
      initContainers:
        - name: fix-permissions
          image: debian
          command:
            - chown
            - -Rv
            - 1000:1000
            - /xauth
          volumeMounts:
            - mountPath: /xauth
              name: xauth
      containers:
        - name: thunderbird
          image: toelke158/docker-thunderbird:latest
          imagePullPolicy: Always
          volumeMounts:
            - name: home
              mountPath: /home/nonroot
            - mountPath: /home/nonroot/.Xauthority
              subPath: ".Xauthority"
              name: xauth
          env:
            - name: DISPLAY
              value: 127.0.0.1:1
        - name: x
          image: toelke158/docker-vnc:latest
          imagePullPolicy: Always
          volumeMounts:
            - mountPath: /home/vncuser/.Xauthority
              subPath: ".Xauthority"
              name: xauth
            - mountPath: /etc/ssl/certs/ssl-cert-snakeoil.pem
              name: tls
              subPath: tls.crt
            - mountPath: /etc/ssl/private/ssl-cert-snakeoil.key
              name: tls
              subPath: tls.key
          ports:
            - containerPort: 6080
      volumes:
        - name: home
          persistentVolumeClaim:
            claimName: thunderbird-data
        - name: xauth
          emptyDir: {}
        - name: tls
          secret:
            secretName: something-from-cert-manager
---
apiVersion: v1
kind: Service
metadata:
  name: thunderbird
  namespace: pr
  labels:
    app: thunderbird
spec:
  ports:
    - port: 443
      targetPort: 6080
      name: https
  selector:
    app: thunderbird
```
