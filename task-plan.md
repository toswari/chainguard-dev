# Task Plan: Go Container Security & Supply Chain Implementation

## Overview

This plan outlines the step-by-step approach to complete the containerization, security analysis, remediation, supply chain security, and deployment tasks for the **Go implementation** of hello-melange-apko.

**Go Application Details:**
- Location: `go/`
- Main file: `go/main.go`
- Framework: Gin v1.8.1
- Build config: `go/melange.yaml`
- Image config: `go/apko.yaml`
- Dependencies: `go/go.mod`, `go/go.sum`

---

## Phase 1: Containerization

### Task 1.1: Create Single-Stage Dockerfile

**Goal:** Create a basic single-stage Dockerfile that builds and runs the Go application in one layer.

**File:** `go/Dockerfile.single`

**Approach:**
```dockerfile
FROM golang:1.22-alpine
WORKDIR /app
COPY . .
RUN go build -o hello-server .
EXPOSE 8080
CMD ["./hello-server"]
```

**Steps:**
1. Create `go/Dockerfile.single` with the above content
2. Build image: `docker build -f go/Dockerfile.single -t go-single .`
3. Test: `docker run --rm -p 8080:8080 go-single`
4. Verify: `curl http://localhost:8080`

### Task 1.2: Create Multi-Stage Dockerfile

**Goal:** Create an optimized multi-stage Dockerfile that separates build and runtime environments.

**File:** `go/Dockerfile.multi`

**Approach:**
```dockerfile
# Build stage
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o hello-server .

# Runtime stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
RUN adduser -D -g '' nonroot
USER nonroot
WORKDIR /home/nonroot
COPY --from=builder /app/hello-server .
EXPOSE 8080
CMD ["./hello-server"]
```

**Steps:**
1. Create `go/Dockerfile.multi` with the above content
2. Build image: `docker build -f go/Dockerfile.multi -t go-multi .`
3. Test: `docker run --rm -p 8080:8080 go-multi`
4. Verify: `curl http://localhost:8080`

### Task 1.3: Build and Compare Images

**Steps:**
1. Build both images
2. Compare sizes: `docker images | grep go-`
3. Document size difference
4. Test both respond correctly on port 8080

---

## Phase 2: Security Analysis

### Task 2.1: Scan Containers with CVE Scanner

**Goal:** Identify vulnerabilities in both container images using Grype.

**Steps:**
1. Create reports directory: `mkdir -p reports`
2. Scan single-stage image:
   ```bash
   ./CVE-check.sh go-single > reports/go-single-cve-report.txt 2>&1
   ```
3. Scan multi-stage image:
   ```bash
   ./CVE-check.sh go-multi > reports/go-multi-cve-report.txt 2>&1
   ```
4. Generate JSON reports for detailed analysis:
   ```bash
   grype go-single -o json > reports/go-single-cve-report.json
   grype go-multi -o json > reports/go-multi-cve-report.json
   ```

### Task 2.2: Document All Vulnerabilities

**Goal:** Create comprehensive vulnerability documentation.

**Steps:**
1. Parse JSON reports with jq:
   ```bash
   jq '.matches[] | {vulnerability: .vulnerability.id, severity: .vulnerability.severity, package: .artifact.name}' reports/go-single-cve-report.json
   ```
2. Count vulnerabilities by severity for each image
3. Create summary table in `docs/vulnerability-analysis.md`

**Output format:**
| Severity | Single-Stage | Multi-Stage |
|----------|--------------|-------------|
| Critical | X | Y |
| High | X | Y |
| Medium | X | Y |
| Low | X | Y |
| Total | X | Y |

### Task 2.3: Compare Results Between Approaches

**Goal:** Analyze security differences between single and multi-stage builds.

**Steps:**
1. Identify vulnerabilities unique to single-stage (build tools, dev deps)
2. Identify vulnerabilities common to both (Go stdlib, Gin framework)
3. Document attack surface reduction
4. Note which packages contribute most vulnerabilities

**Output:** `docs/comparison-analysis.md`

---

## Phase 3: Remediation

### Task 3.1: Patch Go Application and Dependencies

**Goal:** Update Go application to use secure dependency versions.

**Current State:**
- Go version: 1.18 (in go.mod)
- Gin version: v1.8.1
- Multiple indirect dependencies with older versions

**Steps:**
1. Update Go version in `go/go.mod`:
   ```
   go 1.22
   ```
2. Update Gin to latest:
   ```bash
   cd go && go get -u github.com/gin-gonic/gin@latest
   ```
3. Update all dependencies:
   ```bash
   cd go && go get -u ./...
   ```
4. Tidy dependencies:
   ```bash
   cd go && go mod tidy
   ```
5. Verify build still works:
   ```bash
   cd go && go build -o hello-server .
   ./hello-server &
   curl http://localhost:8080
   kill %1
   ```

**Files to modify:**
- `go/go.mod`
- `go/go.sum`

### Task 3.2: Update and Optimize Base Images

**Goal:** Use secure, minimal base images for containers.

**Options:**
1. **Chainguard images** (recommended for security):
   - `cgr.dev/chainguard/go:latest-dev` for build
   - `cgr.dev/chainguard/static` for runtime

2. **Alpine images** (alternative):
   - `golang:1.22-alpine` for build
   - `alpine:latest` for runtime

**Steps:**
1. Update `go/Dockerfile.multi` with chosen base images
2. Update `go/melange.yaml` if needed
3. Rebuild image: `docker build -f go/Dockerfile.multi -t go-multi-patched .`
4. Verify application runs correctly

### Task 3.3: Rescan and Document Improvements

**Goal:** Verify remediation effectiveness.

**Steps:**
1. Rebuild both images with updated dependencies:
   ```bash
   docker build -f go/Dockerfile.single -t go-single-patched .
   docker build -f go/Dockerfile.multi -t go-multi-patched .
   ```
2. Re-scan patched images:
   ```bash
   ./CVE-check.sh go-single-patched > reports/go-single-patched-cve-report.txt
   ./CVE-check.sh go-multi-patched > reports/go-multi-patched-cve-report.txt
   ```
3. Compare before/after results
4. Document vulnerability reduction in `docs/remediation-report.md`

**Output:** Before/after comparison table showing vulnerability reduction

---

## Phase 4: Supply Chain Security

### Task 4.1: Generate SBOM for Each Container

**Goal:** Create Software Bill of Materials for all Go container images.

**Steps:**
1. Create sbom directory: `mkdir -p sbom`
2. Generate SBOM for single-stage:
   ```bash
   ./SBOM-create.sh go-single sbom/go-single.json
   ```
3. Generate SBOM for multi-stage:
   ```bash
   ./SBOM-create.sh go-multi sbom/go-multi.json
   ```
4. Generate SPDX format for compatibility:
   ```bash
   syft go-single -o spdx-json=sbom/go-single.spdx.json
   syft go-multi -o spdx-json=sbom/go-multi.spdx.json
   ```
5. Generate SBOM for patched images:
   ```bash
   syft go-single-patched -o json=sbom/go-single-patched.json
   syft go-multi-patched -o json=sbom/go-multi-patched.json
   ```

### Task 4.2: Sign All Container Images

**Goal:** Cryptographically sign all Go container images using Cosign.

**Steps:**
1. Ensure local registry is running:
   ```bash
   docker run -d -p 5000:5000 --name registry registry:2 2>/dev/null || true
   ```
2. Tag images for local registry:
   ```bash
   docker tag go-single localhost:5000/go-single:latest
   docker tag go-multi localhost:5000/go-multi:latest
   docker tag go-single-patched localhost:5000/go-single-patched:latest
   docker tag go-multi-patched localhost:5000/go-multi-patched:latest
   ```
3. Push images to registry:
   ```bash
   docker push localhost:5000/go-single:latest
   docker push localhost:5000/go-multi:latest
   docker push localhost:5000/go-single-patched:latest
   docker push localhost:5000/go-multi-patched:latest
   ```
4. Generate Cosign key pair:
   ```bash
   mkdir -p keys
   cosign generate-key-pair -output-file keys/cosign
   ```
5. Sign each image:
   ```bash
   cosign sign --key keys/cosign.key localhost:5000/go-single:latest -y
   cosign sign --key keys/cosign.key localhost:5000/go-multi:latest -y
   cosign sign --key keys/cosign.key localhost:5000/go-single-patched:latest -y
   cosign sign --key keys/cosign.key localhost:5000/go-multi-patched:latest -y
   ```

### Task 4.3: Verify Signatures

**Goal:** Create and run verification script.

**Steps:**
1. Create `scripts/verify-signatures.sh`:
   ```bash
   #!/bin/bash
   for image in go-single go-multi go-single-patched go-multi-patched; do
     echo "Verifying $image..."
     cosign verify --key keys/cosign.pub localhost:5000/$image:latest
   done
   ```
2. Run verification:
   ```bash
   chmod +x scripts/verify-signatures.sh
   ./scripts/verify-signatures.sh
   ```

---

## Phase 5: Deployment

### Task 5.1: Create Kubernetes Manifests

**Goal:** Create K8s deployment configurations for Go application.

**File:** `k8s/go-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: go-hello-server
  labels:
    app: go-hello-server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: go-hello-server
  template:
    metadata:
      labels:
        app: go-hello-server
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 65532
      containers:
      - name: hello-server
        image: localhost:5000/go-multi-patched:latest
        ports:
        - containerPort: 8080
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
          requests:
            memory: "64Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
```

**File:** `k8s/go-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: go-hello-server
spec:
  selector:
    app: go-hello-server
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
```

### Task 5.2: Deploy to Kubernetes Cluster

**Goal:** Deploy Go application to k3s cluster.

**Steps:**
1. Ensure k3s is running:
   ```bash
   sudo systemctl status k3s
   ```
2. Create k8s directory: `mkdir -p k8s`
3. Create deployment and service YAML files
4. Load image into k3s:
   ```bash
   docker save localhost:5000/go-multi-patched:latest | sudo k3s ctr images load -
   ```
5. Apply manifests:
   ```bash
   kubectl apply -f k8s/
   ```
6. Verify pods:
   ```bash
   kubectl get pods
   kubectl get deployments
   ```

### Task 5.3: Validate Deployment

**Goal:** Confirm Go application is functional in Kubernetes.

**Steps:**
1. Check pod status:
   ```bash
   kubectl get pods -l app=go-hello-server
   ```
2. Check service:
   ```bash
   kubectl get svc go-hello-server
   ```
3. Port forward and test:
   ```bash
   kubectl port-forward svc/go-hello-server 8080:8080 &
   curl http://localhost:8080
   kill %1
   ```
4. Expected output: `Hello World!`
5. Document results in `docs/deployment-validation.md`

---

## Deliverables Checklist

| # | Deliverable | Location | Status |
|---|-------------|----------|--------|
| 1 | Single-stage Dockerfile | `go/Dockerfile.single` | ☐ |
| 2 | Multi-stage Dockerfile | `go/Dockerfile.multi` | ☐ |
| 3 | CVE scan report (before) | `reports/go-single-cve-report.txt` | ☐ |
| 4 | CVE scan report (after) | `reports/go-multi-patched-cve-report.txt` | ☐ |
| 5 | SBOM files (JSON) | `sbom/go-*.json` | ☐ |
| 6 | SBOM files (SPDX) | `sbom/go-*.spdx.json` | ☐ |
| 7 | Kubernetes manifests | `k8s/go-*.yaml` | ☐ |
| 8 | Vulnerability analysis | `docs/vulnerability-analysis.md` | ☐ |
| 9 | Comparison analysis | `docs/comparison-analysis.md` | ☐ |
| 10 | Remediation report | `docs/remediation-report.md` | ☐ |
| 11 | Deployment validation | `docs/deployment-validation.md` | ☐ |
| 12 | Signature verification script | `scripts/verify-signatures.sh` | ☐ |
| 13 | Cosign keys | `keys/cosign.*` | ☐ |

---

## Execution Order

1. **Phase 1** → Create Dockerfiles (single-stage first, then multi-stage)
2. **Phase 2** → Scan and document vulnerabilities
3. **Phase 3** → Update Go dependencies, remediate, and rescan
4. **Phase 4** → Generate SBOMs and sign images
5. **Phase 5** → Deploy to k3s and validate

---

## Tools Required

| Tool | Purpose | Installed via |
|------|---------|---------------|
| Docker | Build/run containers | install-tools.sh |
| Grype | CVE scanning | install-tools.sh |
| Syft | SBOM generation | install-tools.sh |
| Cosign | Image signing | install-tools.sh |
| k3s | Local Kubernetes | install-tools.sh |
| kubectl | K8s management | install-tools.sh |
| curl | HTTP testing | System |
| jq | JSON parsing | install-tools.sh |
| Go | Build application | install-tools.sh |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Dependency breakage | Test after each `go get` |
| Base image incompatibility | Keep original Dockerfiles as backup |
| k3s cluster issues | Use Docker for local testing first |
| Signature key loss | Backup keys: `cp keys/cosign.* ~/secure-backup/` |
| Registry conflicts | Use unique image tags with timestamps |

---

## Estimated Timeline

| Phase | Estimated Time |
|-------|----------------|
| Phase 1: Containerization | 30-45 minutes |
| Phase 2: Security Analysis | 30-45 minutes |
| Phase 3: Remediation | 30-45 minutes |
| Phase 4: Supply Chain Security | 30-45 minutes |
| Phase 5: Deployment | 30-45 minutes |
| **Total** | **2.5-4 hours** |