#【Sing-box family bucket】

***

# Directory

- [1. Update information](#1-update-information)
- [2. Project Features](#2-project-features)
- [3. Sing-box for VPS run script](#3-sing-box-for-vps-run-script)
- [4. Speedy installation without interaction](#4-speedy-installation-without-interaction)
- [5. Json Argo Tunnel Get (Recommended)](#5-json-argo-tunnel-get-recommended)
- [6. Token Argo Tunnel scheme sets any port back to the origin to use CDN](#6-token-argo-tunnel-scheme-sets-any-port-back-to-the-origin-to-use-cdn)
- [7. Use Cloudflare API to automatically create Argo](#7-use-cloudflare-api-to-automatically-create-argo)
- [8. Vmess /Vless scheme sets any port back to origin to use CDN](#8-vmess-vless-scheme-sets-any-port-back-to-origin-to-use-cdn)
- [9. Docker and Docker compose installation](#9-docker-and-docker-compose-installation)
- [10. Nekobox set shadowTLS method](#10-nekobox-set-shadowtls-method)
- [11. Main directory file and description](#11-main-directory-file-and-description)
- [12. Comparison of the processing methods of self-signed certificates in different clients](#12-comparison-of-the-processing-methods-of-self-signed-certificates-in-different-clients)
- [13. Thanks to the following authors for their articles and projects](#13-thanks-to-the-following-authors-for-their-articles-and-projects)
- [14. Thanks to the sponsors](#14-thanks-to-the-sponsors)
- [15. Disclaimer](#15-disclaimer)
- [16. Open source certificate](#16-open-source-certificate)


* * *

## 1. Update information

2026.04.25 v1.3.10 Added native protocol, but client support is extremely limited, with Shadowrocket offering the best compatibility. For the sing-box core, you must use the -glibc or -musl version according to the requirements; refer to the official documentation for details: https://sing-box.sagernet.org/configuration/outbound/naive/

2026.04.11 v1.3.9 1. remove pre-install UFW blocking logic, fallback to iptables when inactive; 2. avoid unnecessary sing-box restart for CDN /bandwidth /port hopping changes; 3. reduce redundant single-use functions

<details>
    <summary>History update history (click to expand or collapse)</summary>
<br>

**[Previous versions - see full GitHub repo for complete history]**

</details>

## 2. Project Features

- Deploy multiple protocols with one click: ShadowTLS v3, XTLS Reality, Hysteria2, Tuic V5, ShadowSocks, Trojan, Vmess + ws, Vless + ws + tls, H2 Reality, gRPC Reality, AnyTLS, NaiveProxy
- All protocols do not require domain names
- Node information output to multiple clients (V2rayN, Clash Verge, Nekobox, Sing-box)
- Custom port support for limited open ports
- Built-in warp chain proxy to unlock chatGPT
- Support for multiple operating systems: Ubuntu, Debian, CentOS, Alpine, Arch Linux
- Support for AMD and ARM hardware, IPv4 and IPv6
- Non-interactive fast installation mode

## 3. Sing-box for VPS run script

### First run
```bash
bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh)
```

### Run again
```bash
sb
```

| Option | Description |
|--------|-------------|
| -c | Chinese |
| -e | English |
| -l | Quick deploy (Chinese version) |
| -k | Quick deploy (English version) |
| -u | Uninstall |
| -n | Export Nodes list |
| -d | Change config |
| -s | Stop / Start the Sing-box service |
| -a | Stop / Start the Argo Tunnel service |
| -v | Sync to newest version |
| -b | Upgrade kernel, turn on BBR, change Linux system |
| -r | Add and remove protocols |


## 4. Speedy installation without interaction

### Method 1: Fastest installation
```bash
# Chinese
bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh) -l

# English
bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh) -k
```

### Method 2: KV configuration file
```bash
bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh) -f config.conf
```

### Method 3: Parameter transfer examples

**See GitHub repository for complete parameter examples**


## 5. Json Argo Tunnel Get (Recommended)

Users can easily obtain it through: https://fscarmen.cloudflare.now.cc

![Cloudflare JSON Generator](./images/cloudflare-json-generator.png)

For manual setup, refer to: [CloudFlare Argo Tunnel trial](https://zhengweidong.com/try-cloudflare-argo-tunnel)


## 6. Token Argo Tunnel scheme sets any port back to the origin to use CDN

Detailed tutorial: [Cloudflare Tunnel intranet penetration Chinese tutorial](https://imnks.com/5984.html)

![Argo Tunnel Configuration](./images/argo-tunnel-config.png)


## 7. Use Cloudflare API to automatically create Argo

1. Visit https://dash.cloudflare.com/profile/api-tokens
2. API Token > Create Token > Create Custom Token
3. Add the following permissions:
   - Account > Cloudflare One Connector: Cloudflared > Edit
   - Zone > DNS > Edit
4. Account Resources > Includes > Required Accounts
5. Regional Resources > Includes > Specific Region > Required Domain Name


## 8. Vmess /Vless scheme sets any port back to origin to use CDN

Example IPv6: vmess [2a01:4f8:272:3ae6:100b:ee7a:ad2f:1]:10006


## 9. Docker and Docker compose installation

### Description
- Supports three Argo types of tunnels: temporary, Json, Token
- Requires 20 continuously available ports

### Docker deployment
```bash
docker run -dit \
    --pull always \
    --name sing-box \
    --network host \
    -e START_PORT=8800 \
    -e SERVER_IP=123.123.123.123 \
    -e XTLS_REALITY=true \
    -e HYSTERIA2=true \
    -e TUIC=true \
    -e SHADOWTLS=true \
    -e SHADOWSOCKS=true \
    -e TROJAN=true \
    -e VMESS_WS=true \
    -e VLESS_WS=true \
    -e H2_REALITY=true \
    -e GRPC_REALITY=true \
    -e ANYTLS=true \
    -e UUID=20f7fca4-86e5-4ddf-9eed-24142073d197 \
    -e CDN=www.csgo.com \
    -e NODE_NAME=sing-box \
    fscarmen/sb
```


## 10. Nekobox set shadowTLS method

1. Copy the Neko links output by the script
2. Set up chain proxy and enable it
3. Right click > Manually enter configuration > Select type as "Chained Proxy"
4. Select 1-tls-not-use and 2-ss-not-use (order matters!)


## 11. Main directory file and description

```
/etc/sing-box/
├── cert/                           # Certificate files
│   ├── cert.pem                    # SSL/TLS certificate
│   ├── cert_200.pem                # NaiveProxy certificate
│   └── private.key                 # Certificate private key
├── conf/                           # Configuration directory
│   ├── 00_log.json                 # Log configuration
│   ├── 01_outbounds.json           # Outbound configuration
│   ├── 02_endpoints.json           # Endpoints configuration
│   ├── 03_route.json               # Routing rules
│   ├── 04_experimental.json        # Cache configuration
│   ├── 05_dns.json                 # DNS rules
│   ├── 06_ntp.json                 # NTP configuration
│   ├── 11_xtls-reality_inbounds.json
│   ├── 12_hysteria2_inbounds.json
│   ├── 13_tuic_inbounds.json
│   ├── 14_ShadowTLS_inbounds.json
│   ├── 15_shadowsocks_inbounds.json
│   ├── 16_trojan_inbounds.json
│   ├── 17_vmess-ws_inbounds.json
│   ├── 18_vless-ws-tls_inbounds.json
│   ├── 19_h2-reality_inbounds.json
│   ├── 20_grpc-reality_inbounds.json
│   ├── 21_anytls_inbounds.json
│   └── 22_naive_inbounds.json
├── logs/
│   └── box.log                     # Runtime log
├── subscribe/                      # Subscription files
│   ├── qr/                         # QR codes
│   ├── shadowrocket/
│   ├── clash/
│   ├── sing-box-pc/
│   ├── sing-box-phone/
│   └── v2rayn/
├── cache.db                        # Cache file
├── nginx.conf                      # Nginx configuration
├── sing-box                        # Main program
├── cloudflared                     # Argo tunnel
├── tunnel.json                     # Argo tunnel info
├── tunnel.yml                      # Argo tunnel config
└── sb.sh                           # Shortcut script
```


## 12. Comparison of the processing methods of self-signed certificates in different clients

| Client | Verification Method | SNI = SAN | Certificate Chain | Hash Type |
|--------|---------------------|-----------|------------------|-----------|
| **V2RayN** | X.509 chain validation | **Yes** | Yes | None |
| **NekoBox** | X.509 chain validation | **Yes** | Yes | None |
| **ShadowRocket** | SHA-256(DER) | No | No | SHA-256(DER) |
| **Clash Verge /Meta** | SHA-256(DER) | No | No | SHA-256(DER) |
| **Sing-box** | SPKI fingerprint | No | No | SHA-256(SPKI) |

### Key Differences

**V2RayN and NekoBox** must have matching SAN and SNI, or you'll get "x509: cannot validate certificate" error.

**ShadowRocket, Clash, Sing-box** use fingerprint verification and don't require SAN matching.


## 13. Thanks to the following authors for their articles and projects

- [Chika sing-box template](https://github.com/chika0801/sing-box-examples)
- [zmlu's Cloudflare Tunnel management script](https://raw.githubusercontent.com/zmlu/sba/main/tunnel.sh)


## 14. Thanks to the sponsors

### 🚀 Sponsored by SharonNetworks

[SharonNetworks](https://sharon.io/) provides the infrastructure for this project.

- Asia-Pacific optimized routes with direct mainland China connection
- High bandwidth with low latency
- Anti-DDoS protection
- Multi-node coverage (Hong Kong, Singapore, Japan, Taiwan, South Korea)

[Visit Sharon's website](https://sharon.io) or [join the Telegram group](https://t.me/SharonNetwork)

### Thanks to vps.town

[VPS.Town](https://vps.town) - an all-in-one cloud computing solution for your business innovation.


## 15. Disclaimer

- This program is for learning and understanding only
- Non-profit use only
- Must be deleted within 24 hours after downloading
- Cannot be used for commercial purposes
- Text, data and images are copyrighted
- Use complies with local laws and regulations
- Author is not responsible for misuse


## 16. Open source certificate

This project strictly complies with the **GNU GPL v3 License** [LICENSE](LICENSE).

- Any copying, distribution, modification or derivative use must retain the original copyright and license text
- Must be open source and released under the same license
- Violation (closed source, commercial exclusivity, non-open modifications) is considered plagiarism
- Community contributions are welcomed via Pull Request
