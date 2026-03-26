# hello-melange-apko 💫

[![go](https://github.com/chainguard-dev/hello-melange-apko/actions/workflows/go.yml/badge.svg)](https://github.com/chainguard-dev/hello-melange-apko/actions/workflows/go.yml)
[![js](https://github.com/chainguard-dev/hello-melange-apko/actions/workflows/js.yml/badge.svg)](https://github.com/chainguard-dev/hello-melange-apko/actions/workflows/js.yml)
[![py](https://github.com/chainguard-dev/hello-melange-apko/actions/workflows/py.yml/badge.svg)](https://github.com/chainguard-dev/hello-melange-apko/actions/workflows/py.yml)
[![ruby](https://github.com/chainguard-dev/hello-melange-apko/actions/workflows/ruby.yml/badge.svg)](https://github.com/chainguard-dev/hello-melange-apko/actions/workflows/ruby.yml)
[![rust](https://github.com/chainguard-dev/hello-melange-apko/actions/workflows/rust.yml/badge.svg)](https://github.com/chainguard-dev/hello-melange-apko/actions/workflows/rust.yml)

This repo contains an example app duplicated across 5 languages showing how to:

- Package source code into APKs using [`melange`](https://github.com/chainguard-dev/melange)
- Build and publish OCI images from APKs using [`apko`](https://github.com/chainguard-dev/apko)

The app itself is a basic HTTP server that returns "Hello World!"

```
$ curl -s http://localhost:8080
Hello World!
```

Wondering what "APKs" are? They're OS packages with a `.apk` extension (similar to `.rpm` / `.deb`) that are compatible with [`apk`](https://wiki.alpinelinux.org/wiki/Package_management).

## Variations

| Language   | Repo Path          | GitHub Action                                                  | Notes                                                     |
|------------|------------------- | -------------------------------------------------------------- | --------------------------------------------------------- |
| Go         | [`go/`](./go/)     | [`go.yml`](./.github/workflows/go.yml)       | uses gin                                                  |
| JavaScript | [`js/`](./js/)     | [`js.yml`](./.github/workflows/js.yml)       | uses express, vendors node_modules, depends on nodejs |
| Python     | [`py/`](./py/)     | [`py.yml`](./.github/workflows/py.yml)       | uses flask, vendors virtualenv, depends on python3    |
| Ruby       | [`ruby/`](./ruby/) | [`ruby.yml`](./.github/workflows/ruby.yml)   | uses sinatra, vendors bundle, depends on ruby         |
| Rust       | [`rust/`](./rust/) | [`rust.yml`](./.github/workflows/rust.yml)   | uses hyper, currently builds very slow cross-platform     |

Note: third-party server frameworks are used intentionally
to validate the use of dependencies.

---

## Container Security & Supply Chain Implementation (Go)

This project includes a comprehensive container security and supply chain implementation for the Go application, demonstrating best practices for secure containerization.

### Implementation Summary

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1 | Containerization (Single & Multi-stage Dockerfiles) | ✅ Complete |
| Phase 2 | Security Analysis (CVE scanning with Grype) | ✅ Complete |
| Phase 3 | Remediation (Dependency updates, base image optimization) | ✅ Complete |
| Phase 4 | Supply Chain Security (SBOM generation, image signing) | ✅ Complete |
| Phase 5 | Deployment (Kubernetes manifests, validation) | ✅ Complete |

### Key Results

#### Vulnerability Reduction

| Metric | Single-Stage | Multi-Stage | After Remediation |
|--------|--------------|-------------|-------------------|
| Total vulnerabilities | 717 | 56 | ~35 |
| Critical vulnerabilities | 41 | 4 | 1 |
| High vulnerabilities | 276 | 12 | 5 |
| Medium vulnerabilities | 354 | 38 | 27 |
| Low vulnerabilities | 46 | 2 | 2 |

- **92% reduction** in total vulnerabilities with multi-stage builds
- **37% additional reduction** after dependency remediation
- **75% reduction** in critical vulnerabilities
- **12x smaller** image size (19.3 MB vs 233 MB)

#### Image Comparison

| Aspect | Single-Stage | Multi-Stage |
|--------|--------------|-------------|
| Image Size | 233 MB | 19.3 MB |
| Go compiler | ✓ Present | ✗ Absent |
| Source code | ✓ Present | ✗ Absent |
| Build tools | ✓ Present | ✗ Absent |
| Non-root user | ✗ No | ✓ Yes |

### Security Features Implemented

#### Container Security
- Multi-stage Docker builds (minimal runtime image)
- Non-root user execution
- Read-only root filesystem
- No privilege escalation allowed

#### Supply Chain Security
- SBOM (Software Bill of Materials) generated with Syft
- Cryptographic image signing with Cosign (keyless/OIDC)
- Transparency log entry created (index: 1186476072)

#### Kubernetes Security
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
```

### Project Structure

```
.
├── go/
│   ├── Dockerfile.single      # Single-stage build (insecure)
│   ├── Dockerfile.multi       # Multi-stage build (secure)
│   ├── go.mod                 # Go dependencies (patched)
│   └── main.go                # Application source
├── k8s/
│   ├── go-deployment.yaml     # Kubernetes deployment
│   └── go-service.yaml        # Kubernetes service
├── docs/
│   ├── vulnerability-analysis.md    # CVE analysis report
│   ├── comparison-analysis.md       # Build comparison
│   ├── remediation-report.md        # Remediation results
│   └── deployment-validation.md     # Deployment validation
├── reports/
│   ├── go-single-cve-report.json    # Original scan
│   ├── go-multi-cve-report.json     # Multi-stage scan
│   └── go-multi-patched-cve-report.json  # Post-remediation
├── scripts/
│   └── verify-signatures.sh     # Signature verification
└── keys/
    ├── cosign.key               # Cosign private key
    └── cosign.pub               # Cosign public key
```

### Quick Start

#### Build and Run Locally

```bash
# Build multi-stage image
cd go/
docker build -f Dockerfile.multi -t go-multi-patched .

# Run container
docker run --rm -p 8080:8080 go-multi-patched

# Test
curl http://localhost:8080
# Output: Hello World!
```

#### Deploy to Kubernetes

```bash
# Load image into k3s
docker save go-multi-patched:latest | sudo k3s ctr images pull localhost:5000/go-multi-patched:latest

# Apply manifests
kubectl apply -f k8s/go-deployment.yaml -f k8s/go-service.yaml

# Verify
kubectl get pods -l app=go-hello-server
kubectl port-forward svc/go-hello-server 8080:8080
```

#### Verify Image Signature

```bash
# Run verification script
./scripts/verify-signatures.sh

# Or manually
cosign verify localhost:5000/go-multi-patched:latest --insecure-ignore-sct
```

### Documentation

| Document | Description |
|----------|-------------|
| [`docs/vulnerability-analysis.md`](./docs/vulnerability-analysis.md) | Detailed CVE analysis and severity breakdown |
| [`docs/comparison-analysis.md`](./docs/comparison-analysis.md) | Single-stage vs multi-stage build comparison |
| [`docs/remediation-report.md`](./docs/remediation-report.md) | Remediation steps and before/after results |
| [`docs/deployment-validation.md`](./docs/deployment-validation.md) | Kubernetes deployment validation report |

### Tools Used

| Tool | Purpose |
|------|---------|
| Docker | Container build and runtime |
| Grype | CVE vulnerability scanning |
| Syft | SBOM generation |
| Cosign | Image signing and verification |
| k3s/kubectl | Kubernetes deployment |

---

## "The hard way"

This section shows how to run through each of the build stages locally and
pushing an image to GHCR.

Requirements:

- [`docker`](https://docs.docker.com/get-docker/)
- [`cosign`](https://docs.sigstore.dev/cosign/installation/)

Note: these steps should also work without `docker` on an apk-based Linux distribution such as [Alpine](https://www.alpinelinux.org/).

### Change directory

All of the following steps in this section assume that
from the root of this repository, you have changed directory
to one of the variations:

```
cd go/   # for Go
cd js/   # for JavaScript
cd py/   # for Python
cd ruby/ # for Ruby
cd rust/ # for Rust
```

### Build apks with melange

Make sure the `packages/` directory is removed:
```
rm -rf ./packages/
```

Create a temporary melange keypair:
```
docker run --rm -v "${PWD}":/work --entrypoint=melange --workdir=/work ghcr.io/wolfi-dev/sdk keygen
```

Build an apk for all architectures using melange:
```
docker run --rm --privileged -v "${PWD}":/work  \
    --entrypoint=melange --workdir=/work \
    cgr.dev/chainguard/sdk build melange.yaml \
    --arch amd64,aarch64,armv7 \
    --signing-key melange.rsa
```

To debug the above:
```
docker run --rm --privileged -it -v "${PWD}":/work \
    --entrypoint sh \
    cgr.dev/chainguard/sdk

# Build apks (use just --arch amd64 to isolate issue)
melange build melange.yaml \
    --arch amd64,aarch64,armv7 \
    --signing-key melange.rsa

# Install an apk
apk add ./packages/x86_64/hello-server-*.apk --allow-untrusted --force-broken-world

# Delete an apk
apk del hello-server --force-broken-world
```

### Build image with apko

*Note: you could skip this step and go to "Push image with apko".*

Build an apk for all architectures using melange:
```
# Your GitHub username
GITHUB_USERNAME="myuser"
REF="ghcr.io/${GITHUB_USERNAME}/hello-melange-apko/$(basename "${PWD}")"

docker run --rm -v "${PWD}":/work \
    --entrypoint=apko --workdir=/work ghcr.io/wolfi-dev/sdk build --debug apko.yaml \
    "${REF}" output.tar -k melange.rsa.pub \
    --arch amd64,aarch64,armv7
```

If you do not wish to push the image, you could load it directly:
```
ARCH_REF="$(docker load < output.tar | grep "Loaded image" | sed 's/^Loaded image: //' | head -1)"
docker run --rm --rm -p 8080:8080  "${ARCH_REF}"
```

Note: The output of `docker load` will print all architectures. The command above just picks the first one.
You could also choose to run `docker load < output.tar` and manually copy the architecture that matches your system.

To debug the above:
```
docker run --rm -it -v "${PWD}":/work \
    -e REF="${REF}" \
    --entrypoint sh \
    --workdir=/work ghcr.io/wolfi-dev/sdk

# Build image (use just --arch amd64 to isolate issue)
apko build --debug apko.yaml "${REF}" output.tar -k melange.rsa.pub --arch amd64,aarch64,armv7
```

## Push image with apko

Build and push an image to, for example, GHCR:
```
# Your GitHub username
GITHUB_USERNAME="myuser"
REF="ghcr.io/${GITHUB_USERNAME}/hello-melange-apko/$(basename "${PWD}")"

# A personal access token with the "write:packages" scope
GITHUB_TOKEN="*****"

docker run --rm -v "${PWD}":/work \
    -e REF="${REF}" \
    -e GITHUB_USERNAME="${GITHUB_USERNAME}" \
    -e GITHUB_TOKEN="${GITHUB_TOKEN}" \
    --entrypoint sh \
    --workdir=/work ghcr.io/wolfi-dev/sdk -c \
        'echo "${GITHUB_TOKEN}" | \
            apko login ghcr.io -u "${GITHUB_USERNAME}" --password-stdin && \
            apko publish --debug apko.yaml \
                "${REF}" -k melange.rsa.pub \
                --arch amd64,aarch64,armv7'
```

## Sign image with cosign

After the image has been published, sign it recursively using cosign (2.0+):

```
# Your GitHub username
GITHUB_USERNAME="myuser"
REF="ghcr.io/${GITHUB_USERNAME}/hello-melange-apko/$(basename "${PWD}")"

cosign sign -r -y "${REF}"
```

This should use "keyless" mode and open a browser window for you to
authenticate.

Note: prior to running above, you may need to re-login to GHCR
on the host using docker (or other tool):

```
# Your GitHub username
GITHUB_USERNAME="myuser"

# A personal access token with the "write:packages" scope
GITHUB_TOKEN="*****"

echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_USERNAME}" --password-stdin
```

## Verify the signature

Verify that the image is signed using cosign:

```
# Your GitHub username
GITHUB_USERNAME="myuser"
REF="ghcr.io/${GITHUB_USERNAME}/hello-melange-apko/$(basename "${PWD}")"

cosign verify "${REF}" --certificate-identity-regexp=.* --certificate-oidc-issuer-regexp=.*
```

## Run the hello server image

Finally, run the image using docker:

```
# Your GitHub username
GITHUB_USERNAME="myuser"
REF="ghcr.io/${GITHUB_USERNAME}/hello-melange-apko/$(basename "${PWD}")"

docker run --rm --rm -p 8080:8080 "${REF}"
```

Then in another terminal, try hitting the server using curl:

```
curl -s http://localhost:8080
```

```
Hello World!