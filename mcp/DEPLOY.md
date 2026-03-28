# MCP Server - Deployment Guide

Complete deployment instructions for production environments.

---

## Quick Deploy (Development)

### Local Machine

```bash
cd /home/art/.openclaw/workspace/mcp
npm install
npm run build
npm start
```

Server runs on `localhost:3000`.

### Systemd Service (Linux)

1. **Copy service file:**
   ```bash
   sudo cp /home/art/.openclaw/workspace/mcp/mcp-server.service /etc/systemd/system/
   ```

2. **Enable and start:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable mcp-server
   sudo systemctl start mcp-server
   ```

3. **Check status:**
   ```bash
   sudo systemctl status mcp-server
   ```

4. **View logs:**
   ```bash
   sudo journalctl -u mcp-server -f
   ```

---

## Docker Deployment

### Build Image

```bash
cd /home/art/.openclaw/workspace/mcp
docker build -t openclaw/mcp-server:latest .
```

### Run Container

```bash
docker run -d \
  --name mcp-server \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e LOG_LEVEL=info \
  -v /home/art/.openclaw/workspace/data:/app/data:ro \
  --restart unless-stopped \
  openclaw/mcp-server:latest
```

### Using Docker Compose

```bash
cd /home/art/.openclaw/workspace/mcp
docker-compose up -d
```

Check status:
```bash
docker-compose ps
docker-compose logs -f mcp-server
```

Stop:
```bash
docker-compose down
```

---

## Kubernetes Deployment

### Prerequisites

- Kubernetes 1.20+
- kubectl configured
- Docker image pushed to registry (optional: use local if using minikube)

### Deploy to Kubernetes

```bash
cd /home/art/.openclaw/workspace/mcp
kubectl apply -f kubernetes-deployment.yaml
```

This creates:
- Namespace: `openclaw`
- Service: `mcp-server`
- Deployment: `mcp-server` (2 replicas)
- HorizontalPodAutoscaler: scales to 10 replicas
- PodDisruptionBudget: maintains 1 available pod

### Check Deployment

```bash
# Check pods
kubectl get pods -n openclaw

# Check service
kubectl get svc -n openclaw

# Check deployment
kubectl get deployment -n openclaw

# Check HPA
kubectl get hpa -n openclaw
```

### View Logs

```bash
# Real-time logs from all pods
kubectl logs -n openclaw -l app=mcp-server -f

# Logs from specific pod
kubectl logs -n openclaw mcp-server-<pod-id>
```

### Port Forward (local testing)

```bash
kubectl port-forward -n openclaw svc/mcp-server 3000:3000
```

Then access on `localhost:3000`.

### Scale Deployment

```bash
# Manual scaling
kubectl scale deployment mcp-server -n openclaw --replicas=5

# Check HPA auto-scaling
kubectl get hpa -n openclaw -w
```

### Update Deployment

```bash
# Trigger rolling update with new image
kubectl set image deployment/mcp-server \
  mcp=openclaw/mcp-server:v1.1.0 \
  -n openclaw

# Watch rolling update
kubectl rollout status deployment/mcp-server -n openclaw
```

### Delete Deployment

```bash
kubectl delete -f kubernetes-deployment.yaml
```

---

## Production Configuration

### Environment Variables

```bash
NODE_ENV=production        # Production mode
LOG_LEVEL=info            # info|debug|warn|error
PORT=3000                 # Server port
HOST=0.0.0.0             # Listen on all interfaces
```

### Resource Limits (Docker)

```bash
docker run \
  --memory 512m \
  --cpus 0.5 \
  --memory-reservation 256m \
  openclaw/mcp-server:latest
```

### Performance Tuning

```bash
NODE_OPTIONS="--max-old-space-size=512"
```

---

## Monitoring & Health Checks

### Health Check Endpoint

```bash
# Check server health
curl http://localhost:3000/health || echo "Server down"
```

### Metrics

Server exposes metrics via:
- Event logs (on stdout)
- Application logs

### Systemd Health Check

```bash
systemctl is-active mcp-server
systemctl show -p ActiveState mcp-server
```

### Docker Health Check

```bash
docker ps --filter "name=mcp-server"
```

### Kubernetes Health Check

```bash
kubectl get deployment mcp-server -n openclaw -o wide
```

---

## Logging

### Local Logs

```bash
tail -f /tmp/mcp-server.log
```

### Docker Logs

```bash
docker logs -f mcp-server
```

### Kubernetes Logs

```bash
kubectl logs -f deployment/mcp-server -n openclaw
```

### Log Levels

- **debug** — Verbose logging (development only)
- **info** — Normal operation (recommended)
- **warn** — Warnings only
- **error** — Errors only

Change log level:

**Local:**
```bash
# Edit src/main.ts, change logLevel: 'info' to desired level
npm run build && npm start
```

**Docker:**
```bash
docker run -e LOG_LEVEL=debug openclaw/mcp-server:latest
```

**Kubernetes:**
```bash
kubectl set env deployment/mcp-server LOG_LEVEL=debug -n openclaw
```

---

## Troubleshooting

### Server Won't Start

**Local:**
```bash
npm run clean
npm install
npm run build
npm start
```

**Docker:**
```bash
docker logs mcp-server
```

**Kubernetes:**
```bash
kubectl describe pod <pod-name> -n openclaw
kubectl logs <pod-name> -n openclaw
```

### Port Already in Use

**Local:**
```bash
lsof -i :3000
kill -9 <PID>
```

**Docker:**
```bash
docker ps
docker stop mcp-server
docker run -p 3001:3000 ...  # Use different port
```

### High Memory Usage

**Local:**
```bash
NODE_OPTIONS="--max-old-space-size=256" npm start
```

**Docker:**
```bash
docker run --memory 256m openclaw/mcp-server:latest
```

**Kubernetes:**
```bash
kubectl set resources deployment mcp-server \
  --limits=memory=256Mi \
  -n openclaw
```

### Connection Refused

Check if server is running:

**Local:**
```bash
ps aux | grep "node dist/server"
```

**Docker:**
```bash
docker ps | grep mcp-server
```

**Kubernetes:**
```bash
kubectl get pods -n openclaw
kubectl logs <pod-name> -n openclaw
```

---

## Backup & Recovery

### Backup Configuration

```bash
# Backup MCP directory
tar -czf mcp-server-backup.tar.gz \
  /home/art/.openclaw/workspace/mcp

# Store safely
mv mcp-server-backup.tar.gz /backup/location/
```

### Restore Configuration

```bash
# Restore from backup
tar -xzf mcp-server-backup.tar.gz -C /

# Rebuild
cd /home/art/.openclaw/workspace/mcp
npm install
npm run build
```

### Database Recovery (if using persistence)

```bash
# Check data volume
docker inspect mcp-server | grep Mounts

# Backup data volume
docker run --rm -v mcp-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/mcp-data-backup.tar.gz -C / data
```

---

## Zero-Downtime Deployment

### Kubernetes Rolling Update

Configured automatically in `kubernetes-deployment.yaml`:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

This ensures:
- New pods start before old ones stop
- At least 1 pod always available
- Smooth transition for clients

### Docker Compose Update

```bash
# Update image
docker-compose pull mcp-server

# Restart with new image (brief downtime)
docker-compose up -d mcp-server
```

### Manual Blue-Green Deployment

1. Deploy new version as separate service
2. Test on new service
3. Switch load balancer to new service
4. Remove old service

---

## Security Considerations

### Network Security

**Kubernetes:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mcp-server-policy
  namespace: openclaw
spec:
  podSelector:
    matchLabels:
      app: mcp-server
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: openclaw
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53  # DNS
    - protocol: UDP
      port: 53
```

### RBAC (Kubernetes)

```bash
# Create service account
kubectl create serviceaccount mcp-server -n openclaw

# Bind role (if needed)
kubectl create rolebinding mcp-server \
  --clusterrole=view \
  --serviceaccount=openclaw:mcp-server \
  -n openclaw
```

### Secrets Management

For API keys, tokens, etc.:

**Docker:**
```bash
docker run --env-file .env.production openclaw/mcp-server:latest
```

**Kubernetes:**
```bash
kubectl create secret generic mcp-secrets \
  --from-env-file=.env.production \
  -n openclaw
```

Then reference in deployment:
```yaml
envFrom:
- secretRef:
    name: mcp-secrets
```

---

## Performance Optimization

### Resource Allocation

**Docker:**
```bash
docker run \
  --cpus="0.5" \
  --memory="512m" \
  --memory-reservation="256m" \
  openclaw/mcp-server:latest
```

**Kubernetes:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Auto-scaling

Already configured in `kubernetes-deployment.yaml`:

- Min replicas: 2
- Max replicas: 10
- CPU target: 70%
- Memory target: 80%

---

## Maintenance

### Regular Tasks

**Daily:**
- Check logs for errors
- Verify server responsiveness

**Weekly:**
- Review performance metrics
- Check resource usage
- Test backup/restore

**Monthly:**
- Update dependencies
- Security patches
- Performance tuning

### Update Procedure

1. Build new image:
   ```bash
   npm run clean && npm install && npm run build
   docker build -t openclaw/mcp-server:v1.1.0 .
   ```

2. Test locally:
   ```bash
   docker run openclaw/mcp-server:v1.1.0
   ```

3. Deploy:
   - Kubernetes: `kubectl set image ...`
   - Docker Compose: `docker-compose up -d`
   - Systemd: `systemctl restart mcp-server`

---

## Deployment Checklist

- [ ] Install dependencies (`npm install`)
- [ ] Build TypeScript (`npm run build`)
- [ ] Test locally (`npm start`)
- [ ] Configure environment variables
- [ ] Set up logging
- [ ] Configure resource limits
- [ ] Set up health checks
- [ ] Configure backups
- [ ] Test failover/recovery
- [ ] Set up monitoring
- [ ] Document configuration
- [ ] Create runbooks
- [ ] Test zero-downtime updates

---

## Support

For issues during deployment:

1. Check `QUICK_START.md` for setup help
2. Review logs for error messages
3. Verify prerequisites (Node 20+, npm 10+)
4. Check disk space and memory
5. Review firewall/network settings

---

_Deployment guide created: 2026-03-28_  
_Supports: Local, Docker, Docker Compose, Kubernetes_  
_Status: Production-ready_
