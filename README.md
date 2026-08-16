# ⛵ Cluster Template
At its core, this project leverages [makejinja](https://github.com/mirkolenz/makejinja), a powerful tool for rendering templates. By reading the [cluster.toml](./cluster.sample.toml) configuration file—validated and defaulted by [pydantic](https://docs.pydantic.dev/)—Makejinja generates the necessary configurations to deploy a Kubernetes cluster.
## Bootstrap
### Stage 1: Local Workstation
0. **Clone** Clone the project and cd into the repo directory.
1. **Install** the [Mise CLI](https://mise.jdx.dev/getting-started.html#installing-mise-cli) on your local workstation.

2. **Activate** Mise in your shell by following the [activation guide](https://mise.jdx.dev/getting-started.html#activate-mise).

3. Use `mise` to install the **required** CLI tools:

    ```sh
    mise trust
    mise install
    ```
5. Logout of the GitHub Container Registry as this may cause authorization problems in future steps when using the public registry:

    ```sh
    docker logout ghcr.io
    helm registry logout ghcr.io
    ```

### Stage 2: Machine Preparation

> [!IMPORTANT]
> If you have **3 or more nodes** it is recommended to make 3 of them controller nodes for a highly available control plane. This project configures **all nodes** to be able to run workloads. **Worker nodes** are therefore **optional**.
>
> **Minimum system requirements**
>
> | Role           | Cores | Memory | System Disk    |
> | -------------- | ----- | ------ | -------------- |
> | Control/Worker | 4     | 16GB   | 256GB SSD/NVMe |

1. Head over to the [Talos Linux Image Factory](https://factory.talos.dev) and follow the instructions. Be sure to only choose the **bare-minimum system extensions** as some might require additional configuration and prevent Talos from booting without it. Depending on your CPU start with the Intel/AMD system extensions (`i915`, `intel-ucode` & `mei` **or** `amdgpu` & `amd-ucode`), you can always add system extensions after Talos is installed and working.

2. This will eventually lead you to download a Talos Linux ISO (or for SBCs a RAW) image. Make sure to note the **schematic ID** you will need this later on.

3. Flash the Talos ISO or RAW image to a USB drive and boot from it on your nodes.

4. Verify with `nmap` that your nodes are available on the network. (Replace `192.168.1.0/24` with the network your nodes are on.)

    ```sh
    nmap -Pn -n -p 50000 192.168.1.0/24 -vv | grep 'Discovered'
    ```
    
### Stage 3: Cloudflare configuration

> [!TIP]
> **Internal-only cluster?** Set `provider = "none"` under `[dns]` in `cluster.toml` and skip this stage entirely: no Cloudflare account, API token, or `cloudflare-tunnel.json` is needed. Nothing is exposed to the internet, apps are reachable on your LAN via the internal gateway, and the wildcard certificate is issued by an in-cluster self-signed CA instead of Let's Encrypt.

> [!WARNING]
> If any of the commands fail with `command not found` or `unknown command` it means `mise` is either not installed, activated or it could be configured incorrectly.

1. Create a Cloudflare API token for use with cloudflared and external-dns by reviewing the official [documentation](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) and following the instructions below.

    - Click the blue `Use template` button for the `Edit zone DNS` template.
    - Name your token `kubernetes`
    - Under `Permissions`, click `+ Add More` and add permissions `Zone - DNS - Edit` and `Account - Cloudflare Tunnel - Read`
    - Limit the permissions to a specific account and/or zone resources and then click `Continue to Summary` and then `Create Token`.
    - **Save this token somewhere safe**, you will need it later on.

2. Create the Cloudflare Tunnel:

    ```sh
    cloudflared tunnel login
    cloudflared tunnel create --credentials-file cloudflare-tunnel.json kubernetes
    ```

    📍 _**Prefer port-forwarding over a tunnel?** Set `mode = "direct"` under `[ingress]` in `cluster.toml` and skip this step: no `cloudflare-tunnel.json` is needed. Instead, forward TCP 443 (and optionally 80) on your router to the `gateways.external` IP, and create an `external.<domain>` DNS record yourself pointing at your WAN address (an A record, or a CNAME to a DDNS hostname). Per-app records are still published automatically._

### Stage 4: Cluster configuration

1. Generate the config files from the sample files:

    ```sh
    just init
    ```

2. Fill out the `cluster.toml` configuration file using the comments in it as a guide.

3. Template out the kubernetes and talos configuration files, if any issues come up be sure to read the error and adjust your config files accordingly.

    ```sh
    just configure
    ```

4. Push your changes to git:

    📍 _**Verify** all the `./bootstrap/**/*.sops.*`, `./kubernetes/**/*.sops.*` and `./talos/secrets.sops.yaml` files are **encrypted** with SOPS_

    ```sh
    git add -A
    git commit -m "chore: initial commit :rocket:"
    git push
    ```

### Stage 5: Bootstrap Talos, Kubernetes, and Flux

1. Install Talos:

    ```sh
    just bootstrap talos
    ```

2. Install cilium, coredns, spegel, flux and sync the cluster to the repository state:

    ```sh
    just bootstrap apps
    ```

3. Watch the rollout of your cluster happen:

    ```sh
    kubectl get pods --all-namespaces --watch
    ```

### Stage 6 ✅ Verifications

1. Check the status of Cilium:

    ```sh
    kubectl -n kube-system exec ds/cilium --container cilium-agent -- cilium status
    ```

2. Check the status of Flux and if the Flux resources are up-to-date and in a ready state:

    📍 _Run `just kube reconcile` to force Flux to sync your Git repository state_

    ```sh
    flux check
    flux get sources git flux-system
    flux get ks -A
    flux get hr -A
    ```

3. Check TCP connectivity to both the internal and external gateways:

    📍 _The variables are only placeholders, replace them with your actual values_

    ```sh
    nmap -Pn -n -p 443 ${gateways_internal} ${gateways_external} -vv
    ```

4. Check you can resolve DNS for `echo`, this should resolve to `${gateways_external}`:

    📍 _The variables are only placeholders, replace them with your actual values_

    ```sh
    dig @${gateways_dns} echo.${cloudflare_domain}
    ```

5. Check the status of your wildcard `Certificate`:

    ```sh
    kubectl -n network describe certificates
    ```
## Changes i need to do:
### 🌐 Public DNS

> [!TIP]
> Use the `envoy-external` gateway on `HTTPRoutes` to make applications public to the internet. These are also accessible on your private network once you set up split DNS.

The `external-dns` application created in the `network` namespace will handle creating public DNS records. By default, `echo` and the `flux-webhook` are the only subdomains reachable from the public internet. In order to make additional applications public you must **set the correct gateway** like in the HelmRelease for `echo`.

### 🏠 Home DNS

> [!TIP]
> Use the `envoy-internal` gateway on `HTTPRoutes` to make applications private to your network. If you're having trouble with internal DNS resolution check out [this](https://github.com/onedr0p/cluster-template/discussions/719) GitHub discussion.

`k8s_gateway` will provide DNS resolution to external Kubernetes resources (i.e. points of entry to the cluster) from any device that uses your home DNS server. For this to work, your home DNS server must be configured to forward DNS queries for `${cloudflare_domain}` to `${gateways_dns}` instead of the upstream DNS server(s) it normally uses. This is a form of **split DNS** (aka split-horizon DNS / conditional forwarding).

_... Nothing working? That is expected, this is DNS after all!_

### 🪝 Git Webhook

By default Flux will periodically check your git repository for changes. In-order to have Flux reconcile on `git push` you must configure your Git provider to send `push` events to Flux.

📍 _Don't want a webhook, or your Git provider can't reach the cluster? Set `webhook_provider = "none"` in `cluster.toml` and skip this section; Flux will keep polling on an interval._

1. Obtain the webhook path:

    📍 _Hook id and path should look like `/hook/12ebd1e363c641dc3c2e430ecf3cee2b3c7a5ac9e1234506f6f5f3ce1230e123`_

    ```sh
    kubectl -n flux-system get receiver flux-webhook --output=jsonpath='{.status.webhookPath}'
    ```

2. Piece together the full URL with the webhook path appended:

    ```text
    https://flux-webhook.${cloudflare_domain}/hook/12ebd1e363c641dc3c2e430ecf3cee2b3c7a5ac9e1234506f6f5f3ce1230e123
    ```

3. Navigate to your repository settings and add a webhook with that URL and the secret token from `flux-webhook-token.txt`:

    - **GitHub**: under "Settings/Webhooks" press the "Add webhook" button. Fill in the webhook URL, paste the token as the secret, Content type: `application/json`, Events: Choose Just the push event, and save.
    - **GitLab**: under "Settings/Webhooks" fill in the webhook URL, paste the token as the secret token, check the push events trigger, and save. Also set `webhook_provider = "gitlab"` in `cluster.toml`.
    - **Gitea/Forgejo**: under "Settings/Webhooks" add a **Gitea/Forgejo** webhook with the webhook URL, method `POST`, content type `application/json`, paste the token as the secret, trigger on push events, and save. Keep the default `webhook_provider = "github"` since these providers emulate GitHub webhooks.

## 💥 Reset

There might be a situation where you want to destroy your Kubernetes cluster. The following command will reset your nodes back to maintenance mode.

```sh
just talos reset
```

## 🛠️ Talos and Kubernetes Maintenance

### ⚙️ Updating Talos node configuration

> [!TIP]
> Ensure you have updated `topf.yaml` and any patches with your updated configuration. In some cases you **not only need to apply the configuration but also upgrade talos** to apply new configuration.

```sh
# Preview the rendered machine configs (optional)
just talos render
# Apply the config to the node
just talos apply-node <node>
# e.g. just talos apply-node k8s-0
```

### ⬆️ Updating Talos and Kubernetes versions

> [!TIP]
> Ensure the `talosVersion` and `kubernetesVersion` in `topf.yaml` are up-to-date with the version you wish to upgrade to.

```sh
# Upgrade talos on a node
just talos upgrade-node <node>
# e.g. just talos upgrade-node k8s-0
```

```sh
# Upgrade cluster to a newer Kubernetes version
just talos upgrade-k8s
```

### ➕ Adding a node to your cluster

At some point you might want to expand your cluster to run more workloads and/or improve the reliability of your cluster. Keep in mind it is recommended to have an **odd number** of control plane nodes for quorum reasons.

You don't need to re-bootstrap the cluster to add new nodes. Follow these steps:

1. **Prepare the new node**: Review the [Stage 2: Machine Preparation](#stage-2-machine-preparation) section and boot your new node into maintenance mode.

2. **Get the node information**: While the node is in maintenance mode, retrieve the disk and MAC address information needed for configuration:

    ```sh
    talosctl get disks -n <ip> --insecure
    talosctl get links -n <ip> --insecure
    ```

3. **Update the configuration**: Read the documentation for [topf](https://postfinance.github.io/topf/) and extend `topf.yaml` (and any `node/<hostname>/` patches) manually with the new node information (including the disk and MAC address from step 2).

4. **Apply the configuration**:

    ```sh
    # Preview the rendered machine configs (optional)
    just talos render

    # Apply the configuration to the node
    just talos apply-node <node>
    # e.g. just talos apply-node k8s-3
    ```

The node should join the cluster automatically and workloads will be scheduled once they report as ready.

## 🤖 Renovate

[Renovate](https://www.mend.io/renovate) is a tool that automates dependency management. It is designed to scan your repository around the clock and open PRs for out-of-date dependencies it finds. Common dependencies it can discover are Helm charts, container images, GitHub Actions and more! In most cases merging a PR will cause Flux to apply the update to your cluster.

To enable Renovate on GitHub, click the 'Configure' button over at their [Github app page](https://github.com/apps/renovate) and select your repository. On other Git providers you can [self-host Renovate](https://docs.renovatebot.com/getting-started/running/#self-hosting-renovate); note that fetching the shared preset in `.renovaterc.json5` requires a `GITHUB_COM_TOKEN`. Renovate creates a "Dependency Dashboard" as an issue in your repository, giving an overview of the status of all updates. The dashboard has interactive checkboxes that let you do things like advance scheduling or reattempt update PRs you closed without merging.

The base Renovate configuration in your repository can be viewed at [.renovaterc.json5](.renovaterc.json5). By default it is scheduled to be active with PRs every weekend, but you can [change the schedule to anything you want](https://docs.renovatebot.com/presets-schedule), or remove it if you want Renovate to open PRs immediately.

## 🐛 Debugging

Below is a general guide on trying to debug an issue with an resource or application. For example, if a workload/resource is not showing up or a pod has started but in a `CrashLoopBackOff` or `Pending` state. These steps do not include a way to fix the problem as the problem could be one of many different things.

1. Check if the Flux resources are up-to-date and in a ready state:

    📍 _Run `just kube reconcile` to force Flux to sync your Git repository state_

    ```sh
    flux get sources git -A
    flux get ks -A
    flux get hr -A
    ```

2. Do you see the pod of the workload you are debugging:

    ```sh
    kubectl -n <namespace> get pods -o wide
    ```

3. Check the logs of the pod if it's there:

    ```sh
    kubectl -n <namespace> logs <pod-name> -f
    ```

4. If a resource exists, try to describe it to see what problems it might have:

    ```sh
    kubectl -n <namespace> describe <resource> <name>
    ```

5. Check the namespace events:

    ```sh
    kubectl -n <namespace> get events --sort-by='.metadata.creationTimestamp'
    ```

## 🧹 Tidy up

Once your cluster is fully configured and you no longer need to run `just configure`, it's a good idea to clean up the repository by removing the [template](./template) directory and any files related to the templating process. This will help eliminate unnecessary clutter from the upstream template repository and resolve any "duplicate registry" warnings from Renovate.

1. Tidy up your repository:

    ```sh
    just template tidy
    ```

2. Push your changes to git:

    ```sh
    git add -A
    git commit -m "chore: tidy up :broom:"
    git push
    ```

## ❔ What's next

There's a lot to absorb here, especially if you're new to these tools. Take some time to familiarize yourself with the tooling and understand how all the components interconnect. Dive into the documentation of the various tools included — they are a valuable resource. This shouldn't be a production environment yet, so embrace the freedom to experiment. Move fast, break things intentionally, and challenge yourself to fix them.

Below are some optional considerations you may want to explore.

### DNS

The template uses [k8s_gateway](https://github.com/k8s-gateway/k8s_gateway) to provide DNS for your applications, consider exploring [external-dns](https://github.com/kubernetes-sigs/external-dns) as an alternative.

External-DNS offers broad support for various DNS providers, including but not limited to:

- [Pi-hole](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/pihole.md)
- [UniFi](https://github.com/kashalls/external-dns-unifi-webhook)
- [Adguard Home](https://github.com/muhlba91/external-dns-provider-adguard)
- [Bind](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/rfc2136.md)

This flexibility allows you to integrate seamlessly with a range of DNS solutions to suit your environment and offload DNS from your cluster to your router, or external device.

### Secrets

SOPS is an excellent tool for managing secrets in a GitOps workflow. However, it can become cumbersome when rotating secrets or maintaining a single source of truth for secret items.

For a more streamlined approach to those issues, consider [External Secrets](https://external-secrets.io/latest/). This tool allows you to move away from SOPs and leverage an external provider for managing your secrets. External Secrets supports a wide range of providers, from cloud-based solutions to self-hosted options.

### Storage

If your workloads require persistent storage with features like replication or connectivity to NFS, SMB, or iSCSI servers, there are several projects worth exploring:

- [rook-ceph](https://github.com/rook/rook) / [longhorn](https://github.com/longhorn/longhorn) / [openebs](https://github.com/openebs/openebs)
- [democratic-csi](https://github.com/democratic-csi/democratic-csi)
- [csi-driver-nfs](https://github.com/kubernetes-csi/csi-driver-nfs) / [csi-driver-smb](https://github.com/kubernetes-csi/csi-driver-smb)
- [synology-csi](https://github.com/SynologyOpenSource/synology-csi)
- [truenas-csi](https://github.com/truenas/truenas-csi) / [tns-csi](https://github.com/fenio/tns-csi)

These tools offer a variety of solutions to meet your persistent storage needs, whether you’re using cloud-native or self-hosted infrastructures.

### Community Repositories

Community member [@whazor](https://github.com/whazor) created [Kubesearch](https://kubesearch.dev) to allow searching Flux HelmReleases across Github and Gitlab repositories with the `kubesearch` topic.

