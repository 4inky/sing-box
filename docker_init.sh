#!/usr/bin/env bash
# Script update date 2026.04.23
set -e

WORK_DIR=/sing-box
PORT=$START_PORT
SUBSCRIBE_TEMPLATE="https://raw.githubusercontent.com/fscarmen/client_template/main"

# Custom font color, read function
warning() { echo -e "\033[31m\033[01m$*\033[0m"; }  # red
info() { echo -e "\033[32m\033[01m$*\033[0m"; } # Green
hint() { echo -e "\033[33m\033[01m$*\033[0m"; } # Yellow

# Determine the system architecture to download the corresponding application
case "$ARCH" in
  arm64 )
    SING_BOX_ARCH=arm64-musl; JQ_ARCH=arm64; QRENCODE_ARCH=arm64; ARGO_ARCH=arm64
    ;;
  amd64 )
    SING_BOX_ARCH=amd64-musl; JQ_ARCH=amd64; QRENCODE_ARCH=amd64; ARGO_ARCH=amd64
    ;;
  armv7 )
    SING_BOX_ARCH=armv7-musl; JQ_ARCH=armhf; QRENCODE_ARCH=arm; ARGO_ARCH=arm
    ;;
esac

# Check the latest version of sing-box
check_latest_sing-box() {
  # Check whether the specified version is mandatory
  local FORCE_VERSION=$(wget --no-check-certificate --tries=2 --timeout=3 -qO-https://raw.githubusercontent.com/fscarmen/sing-box/refs/heads/main/force_version | sed 's/^[vV]//g')

  # When there is no forced version specification, get the latest version
grep -q '.' <<< "$FORCE_VERSION" || local FORCE_VERSION=$(wget --no-check-certificate --tries=2 --timeout=3 -qO-https://api.github.com/repos/SagerNet/sing-box/releases | awk -F '["v-]' '/tag_name/{print $5}' | sort -Vr | sed -n '1p')

  # Get the final version number
  local VERSION=$(wget --no-check-certificate --tries=2 --timeout=3 -qO-https://api.github.com/repos/SagerNet/sing-box/releases | awk -F '["v]' -v var="tag_name.*$FORCE_VERSION" '$0 ~ var {print $5; exit}')
  VERSION=${VERSION:-'1.13.0-rc.4'}

  echo "$VERSION"
}

# Install sing-box container
install() {
  # Download sing-box
  echo "Downloading sing-box..."
  local ONLINE=$(check_latest_sing-box)
  wget https://github.com/SagerNet/sing-box/releases/download/v$ONLINE/sing-box-$ONLINE-linux-$SING_BOX_ARCH.tar.gz -O-| tar xz -C ${WORK_DIR} sing-box-$ONLINE-linux-$SING_BOX_ARCH/sing-box && mv ${WORK_DIR}/sing-box-$ONLINE-linux-$SING_BOX_ARCH/sing-box ${WORK_DIR}/sing-box && rm -rf ${WORK_DIR}/sing-box-$ONLINE-linux-$SING_BOX_ARCH

  # download jq
  echo "Downloading jq..."
wget -O ${WORK_DIR}/jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-$JQ_ARCH && chmod +x ${WORK_DIR}/jq

  # Download qrencode
  echo "Downloading qrencode..."
  wget -O ${WORK_DIR}/qrencode https://github.com/fscarmen/client_template/raw/main/qrencode-go/qrencode-go-linux-$QRENCODE_ARCH && chmod +x ${WORK_DIR}/qrencode

  # download cloudflared
  echo "Downloading cloudflared..."
wget -O ${WORK_DIR}/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$ARGO_ARCH && chmod +x ${WORK_DIR}/cloudflared

  # Generate a 100-year self-signed certificate, using IPv4 /IPv6 /domain name separately
  echo "Generate self-signed certificate..."
  openssl ecparam -genkey -name prime256v1 -out ${WORK_DIR}/cert/private.key
  openssl req -new -x509 -days 36500 -key ${WORK_DIR}/cert/private.key -out ${WORK_DIR}/cert/cert.pem -subj "/CN=mozilla.org" -addext "subjectAltName = DNS:addons.mozilla.org"

 # Check whether the system has installed tcp-brutal
  IS_BRUTAL=false && [ -x "$(type -p lsmod)" ] && lsmod 2>/dev/null | grep -q 'brutal' && IS_BRUTAL=true
  [ "$IS_BRUTAL" = 'false' ] && [ -x "$(type -p modprobe)" ] && modprobe brutal 2>/dev/null && IS_BRUTAL=true

  # Generate sing-box configuration file
  for i in {1..3}; do
    ping -c 1 -W 1 "151.101.1.91" &>/dev/null && local IS_IPV4=is_ipv4 && break
  done

  for i in {1..3}; do
    ping -c 1 -W 1 "2a04:4e42:200::347" &>/dev/null && local IS_IPV6=is_ipv6 && break
  done

  case "${IS_IPV4}@${IS_IPV6}" in
    is_ipv4@is_ipv6)
      local STRATEGY=prefer_ipv4
      ;;
    @is_ipv6)
      local STRATEGY=ipv6_only
      ;;
    *)
      local STRATEGY=ipv4_only
      ;;
  esac

  if [[ "$REALITY_PRIVATE" =~ ^[A-Za-z0-9_-]{43}$ ]]; then
    # convert base64url -> base64 (standard), add padding
    local B64=$(printf '%s' "$REALITY_PRIVATE" | tr '_-' '/+')
    local MOD=$(( ${#B64} % 4 ))
    if [ $MOD -eq 2 ]; then
      B64="${B64}=="
    elif [ $MOD -eq 3 ]; then
      B64="${B64}="
    elif [ $MOD -eq 1 ]; then
      echo "Invalid base64url length" >&2
      exit 1
    fi

    # decode to raw 32 bytes
    echo "$B64" | base64 -d > /tmp/_x25519_priv_raw

    local PRIV_LEN=$(stat -c%s /tmp/_x25519_priv_raw 2>/dev/null || stat -f%z /tmp/_x25519_priv_raw)
    [ "$PRIV_LEN" -ne 32 ] && echo "Decoded private key is ${PRIV_LEN} bytes (expected 32)." >&2 && echo "Make sure you passed a 32-byte X25519 private scalar (base64url, no padding)." >&2 && rm -f /tmp/_x25519_* && exit 1

    # DER prefix for PKCS#8 private key with OID 1.3.101.110 (X25519)
    # Hex: 30 2e 02 01 00 30 05 06 03 2b 65 6e 04 22 04 20
    local PREFIX_HEX="302e020100300506032b656e04220420"

    # append raw private key hex and create DER
    local PRIV_HEX=$(xxd -p -c 256 /tmp/_x25519_priv_raw | tr -d '\n')
    printf "%s%s" "$PREFIX_HEX" "$PRIV_HEX" | xxd -r -p > /tmp/_x25519_priv_der

    # convert DER PKCS8 -> PEM private key
    openssl pkcs8 -inform DER -in /tmp/_x25519_priv_der -nocrypt -out /tmp/_x25519_priv_pem 2>/dev/null

    # extract public key in DER
    openssl pkey -in /tmp/_x25519_priv_pem -pubout -outform DER > /tmp/_x25519_pub_der 2>/dev/null

    # last 32 bytes are the raw public key
    tail -c 32 /tmp/_x25519_pub_der > /tmp/_x25519_pub_raw

    # encode to base64url (no padding)
    local REALITY_PUBLIC=$(base64 -w0 /tmp/_x25519_pub_raw | tr '+/' '-_' | sed -E 's/=+$//')

    rm -f /tmp/_x25519_*
  else
    local REALITY_KEYPAIR=$(${WORK_DIR}/sing-box generate reality-keypair) && REALITY_PRIVATE=$(awk '/PrivateKey/{print $NF}' <<< "$REALITY_KEYPAIR") && REALITY_PUBLIC=$(awk '/PublicKey/{print $NF}' <<< "$REALITY_KEYPAIR")
  fi

  local SIP022_PASSWORD=$(${WORK_DIR}/sing-box generate rand --base64 16)
  local SIP022_METHOD="2022-blake3-aes-128-gcm"
  local UUID=${UUID:-"$(${WORK_DIR}/sing-box generate uuid)"}
  local NODE_NAME=${NODE_NAME:-"sing-box"}
  local CDN=${CDN:-"skk.moe"}

  # Check whether chatGPT is unlocked, first check API access
local CHECK_RESULT1=$(wget --timeout=2 --tries=2 --retry-connrefused --waitretry=5 -qO---content-on-error --header='authority: api.openai.com' --header='accept: */*' --header='accept-language: en-US,en;q=0.9' --header='authorization: Bearer null' --header='content-type: application/json' --header='origin: https://platform.openai.com' --header='referer: https://platform.openai.com/' --header='sec-ch-ua: "Google Chrome";v="125", "Chromium";v="125", "Not.A/Brand";v="24"' --header='sec-ch-ua-mobile: ?0' --header='sec-ch-ua-platform: "Windows"' --header='sec-fetch-dest: empty' --header='sec-fetch-mode: cors' --header='sec-fetch-site: same-site' --user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36' 'https://api.openai.com/compliance/cookie_requirements')
# If the API detection fails or unsupported_country is detected, return ban directly.
  if [ -z "$CHECK_RESULT1" ] || grep -qi 'unsupported_country' <<< "$CHECK_RESULT1"; then
    CHATGPT_OUT=warp-ep
  fi

  # After the API detection passes, continue to check web page access
local CHECK_RESULT2=$(wget --timeout=2 --tries=2 --retry-connrefused --waitretry=5 -qO---content-on-error --header='authority: ios.chat.openai.com' --header='accept: */*;q=0.8,application/signed-exchange;v=b3;q=0.7' --header='accept-language: en-US,en;q=0.9' --header='sec-ch-ua: "Google Chrome";v="125", "Chromium";v="125", "Not.A/Brand";v="24"' --header='sec-ch-ua-mobile: ?0' --header='sec-ch-ua-platform: "Windows"' --header='sec-fetch-dest: document' --header='sec-fetch-mode: navigate' --header='sec-fetch-site: none' --header='sec-fetch-user: ?1' --header='upgrade-insecure-requests: 1' --user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36' https://ios.chat.openai.com/)
# Check the second result
  if [ -z "$CHECK_RESULT2" ] || grep -qi 'VPN' <<< "$CHECK_RESULT2"; then
    CHATGPT_OUT=warp-ep
  else
    CHATGPT_OUT=direct
  fi

  # Generate log configuration
  cat > ${WORK_DIR}/conf/00_log.json << EOF
{
    "log":{
        "disabled":false,
        "level":"error",
        "output":"${WORK_DIR}/logs/box.log",
        "timestamp":true
    }
}
EOF

# Generate outbound configuration
  cat > ${WORK_DIR}/conf/01_outbounds.json << EOF
{
    "outbounds":[
        {
            "type":"direct",
            "tag":"direct"
        }
    ]
}
EOF

  # Generate endpoint configuration
  cat > ${WORK_DIR}/conf/02_endpoints.json << EOF
{
    "endpoints":[
        {
            "type":"wireguard",
            "tag":"warp-ep",
            "mtu":1280,
            "address":[
                "172.16.0.2/32",
                "2606:4700:110:8a36:df92:102a:9602:fa18/128"
            ],
            "private_key":"YFYOAdbw1bKTHlNNi+aEjBM3BO7unuFC5rOkMRAz9XY=",
            "peers": [
              {
                "address": "engage.cloudflareclient.com",
                "port":2408,
                "public_key":"bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
                "allowed_ips": [
                  "0.0.0.0/0",
                  "::/0"
                ],
                "reserved":[
                    78,
                    135,
                    76
                ]
              }
            ]
        }
    ]
}
EOF

  # Generate route configuration
  cat > ${WORK_DIR}/conf/03_route.json << EOF
{
    "route":{
        "rule_set":[
            {
                "tag":"geosite-openai",
                "type":"remote",
                "format":"binary",
                "url":"https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-openai.srs"
            }
        ],
        "rules":[
            {
                "action": "sniff"
            },
            {
                "action": "resolve",
                "domain":[
                    "api.openai.com"
                ],
                "strategy": "prefer_ipv4"
            },
            {
                "action": "resolve",
                "rule_set":[
                    "geosite-openai"
                ],
                "strategy": "prefer_ipv6"
            },
            {
                "domain":[
                    "api.openai.com"
                ],
                "rule_set":[
                    "geosite-openai"
                ],
                "outbound":"${CHATGPT_OUT}"
            }
        ]
    }
}
EOF

# Generate cache file
  cat > ${WORK_DIR}/conf/04_experimental.json << EOF
{
    "experimental": {
        "cache_file": {
            "enabled": true,
            "path": "${WORK_DIR}/cache.db"
        }
    }
}
EOF

  # Generate dns configuration file
  cat > ${WORK_DIR}/conf/05_dns.json << EOF
{
    "dns":{
        "servers":[
            {
                "type":"local"
            }
        ],
        "strategy": "${STRATEGY}"
    }
}
EOF

  # Built-in NTP client service configuration file, which is useful for environments where time synchronization is not possible
  cat > ${WORK_DIR}/conf/06_ntp.json << EOF
{
    "ntp": {
        "enabled": true,
        "server": "time.apple.com",
        "server_port": 123,
        "interval": "60m"
    }
}
EOF

  # Generate XTLS + Reality configuration
  [ "${XTLS_REALITY}" = 'true' ] && ((PORT++)) && PORT_XTLS_REALITY=$PORT && cat > ${WORK_DIR}/conf/11_xtls-reality_inbounds.json << EOF
//  "public_key":"${REALITY_PUBLIC}"
{
    "inbounds":[
        {
            "type":"vless",
            "tag":"${NODE_NAME} xtls-reality",
            "listen":"::",
            "listen_port":${PORT_XTLS_REALITY},
            "users":[
                {
                    "uuid":"${UUID}",
                    "flow":"xtls-rprx-vision"
                }
            ],
            "tls":{
                "enabled":true,
                "server_name":"addons.mozilla.org",
                "reality":{
                    "enabled":true,
                    "handshake":{
                        "server":"addons.mozilla.org",
                        "server_port":443
                    },
                    "private_key":"${REALITY_PRIVATE}",
                    "short_id":[
                        ""
                    ]
                }
            },
            "multiplex":{
                "enabled":false,
                "padding":false,
                "brutal":{
                    "enabled":${IS_BRUTAL},
                    "up_mbps":1000,
                    "down_mbps":1000
                }
            }
        }
    ]
}
EOF

 # Generate Hysteria2 configuration
  [ "${HYSTERIA2}" = 'true' ] && ((PORT++)) && PORT_HYSTERIA2=$PORT && cat > ${WORK_DIR}/conf/12_hysteria2_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"hysteria2",
            "tag":"${NODE_NAME} hysteria2",
            "listen":"::",
            "listen_port":${PORT_HYSTERIA2},
            "users":[
                {
                    "password":"${UUID}"
                }
            ],
            "ignore_client_bandwidth":false,
"tls":{
                "enabled":true,
                "alpn":[
                    "h3"
                ],
                "min_version":"1.3",
                "max_version":"1.3",
                "certificate_path":"${WORK_DIR}/cert/cert.pem",
                "key_path":"${WORK_DIR}/cert/private.key"
            }
        }
    ]
}
EOF

  #Generate Tuic V5 configuration
  [ "${TUIC}" = 'true' ] && ((PORT++)) && PORT_TUIC=$PORT && cat > ${WORK_DIR}/conf/13_tuic_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"tuic",
            "tag":"${NODE_NAME} tuic",
            "listen":"::",
            "listen_port":${PORT_TUIC},
            "users":[
                {
                    "uuid":"${UUID}",
                    "password":"${UUID}"
                }
            ],
            "congestion_control": "bbr",
            "zero_rtt_handshake": false,
            "tls":{
                "enabled":true,
                "alpn":[
                    "h3"
                ],
                "certificate_path":"${WORK_DIR}/cert/cert.pem",
                "key_path":"${WORK_DIR}/cert/private.key"
            }
        }
    ]
}
EOF

  # Generate ShadowTLS V5 configuration
  [ "${SHADOWTLS}" = 'true' ] && ((PORT++)) && PORT_SHADOWTLS=$PORT && cat > ${WORK_DIR}/conf/14_ShadowTLS_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"shadowtls",
            "tag":"${NODE_NAME} ShadowTLS",
            "listen":"::",
            "listen_port":${PORT_SHADOWTLS},
            "detour":"shadowtls-in",
            "version":3,
            "users":[
                {
                    "password":"${UUID}"
                }
            ],
            "handshake":{
                "server":"addons.mozilla.org",
                "server_port":443
            },
            "strict_mode":true
        },
        {
            "type":"shadowsocks",
            "tag":"shadowtls-in",
            "listen":"127.0.0.1",
            "network":"tcp",
            "method":"${SIP022_METHOD}",
            "password":"${SIP022_PASSWORD}",
            "multiplex":{
                "enabled":true,
                "padding":true,
                "brutal":{
                    "enabled":${IS_BRUTAL},
                    "up_mbps":1000,
                    "down_mbps":1000
                }
            }
        }
    ]
}
EOF

  # Generate Shadowsocks configuration
  [ "${SHADOWSOCKS}" = 'true' ] && ((PORT++)) && PORT_SHADOWSOCKS=$PORT && cat > ${WORK_DIR}/conf/15_shadowsocks_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"shadowsocks",
            "tag":"${NODE_NAME} shadowsocks",
            "listen":"::",
            "listen_port":${PORT_SHADOWSOCKS},
            "method":"${SIP022_METHOD}",
            "password":"${SIP022_PASSWORD}",
            "multiplex":{
                "enabled":true,
                "padding":true,
                "brutal":{
                    "enabled":${IS_BRUTAL},
                    "up_mbps":1000,
                    "down_mbps":1000
                }
            }
        }
    ]
}
EOF

  # Generate Trojan configuration
  [ "${TROJAN}" = 'true' ] && ((PORT++)) && PORT_TROJAN=$PORT && cat > ${WORK_DIR}/conf/16_trojan_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"trojan",
            "tag":"${NODE_NAME} trojan",
            "listen":"::",
            "listen_port":${PORT_TROJAN},
            "users":[
                {
                    "password":"${UUID}"
                }
            ],
            "tls":{
                "enabled":true,
                "certificate_path":"${WORK_DIR}/cert/cert.pem",
                "key_path":"${WORK_DIR}/cert/private.key"
            },
            "multiplex":{
                "enabled":true,
                "padding":true,
                "brutal":{
                    "enabled":${IS_BRUTAL},
                    "up_mbps":1000,
                    "down_mbps":1000
                }
            }
        }
    ]
}
EOF

  # Generate vmess + ws configuration
  [ "${VMESS_WS}" = 'true' ] && ((PORT++)) && PORT_VMESS_WS=$PORT && cat > ${WORK_DIR}/conf/17_vmess-ws_inbounds.json << EOF
//  "CDN": "${CDN}"
{
    "inbounds":[
        {
            "type":"vmess",
            "tag":"${NODE_NAME} vmess-ws",
            "listen":"127.0.0.1",
            "listen_port":${PORT_VMESS_WS},
            "tcp_fast_open":false,
            "proxy_protocol":false,
            "users":[
                {
                    "uuid":"${UUID}",
                    "alterId":0
                }
            ],
            "transport":{
                "type":"ws",
                "path":"/${UUID}-vmess",
                "max_early_data":2560,
                "early_data_header_name":"Sec-WebSocket-Protocol"
            },
            "multiplex":{
                "enabled":true,
                "padding":true,
                "brutal":{
                    "enabled":${IS_BRUTAL},
                    "up_mbps":1000,
                    "down_mbps":1000
                }
            }
        }
    ]
}
EOF

  # Generate vless + ws + tls configuration
  [ "${VLESS_WS}" = 'true' ] && ((PORT++)) && PORT_VLESS_WS=$PORT && cat > ${WORK_DIR}/conf/18_vless-ws-tls_inbounds.json << EOF
//  "CDN": "${CDN}"
{
    "inbounds":[
        {
            "type":"vless",
            "tag":"${NODE_NAME} vless-ws-tls",
            "listen":"127.0.0.1",
            "listen_port":${PORT_VLESS_WS},
            "tcp_fast_open":false,
            "proxy_protocol":false,
            "users":[
                {
                    "name":"sing-box",
                    "uuid":"${UUID}"
                }
            ],
            "transport":{
                "type":"ws",
                "path":"/${UUID}-vless",
                "max_early_data":2560,
                "early_data_header_name":"Sec-WebSocket-Protocol"
            },
            "multiplex":{
                "enabled":true,
                "padding":true,
                "brutal":{
                    "enabled":${IS_BRUTAL},
                    "up_mbps":1000,
                    "down_mbps":1000
                }
            }
        }
    ]
}
EOF
#Generate H2 + Reality configuration
  [ "${H2_REALITY}" = 'true' ] && ((PORT++)) && PORT_H2_REALITY=$PORT && cat > ${WORK_DIR}/conf/19_h2-reality_inbounds.json << EOF
//  "public_key":"${REALITY_PUBLIC}"
{
    "inbounds":[
        {
            "type":"vless",
            "tag":"${NODE_NAME} h2-reality",
            "listen":"::",
            "listen_port":${PORT_H2_REALITY},
            "users":[
                {
                    "uuid":"${UUID}"
                }
            ],
            "tls":{
                "enabled":true,
                "server_name":"addons.mozilla.org",
                "reality":{
                    "enabled":true,
                    "handshake":{
                        "server":"addons.mozilla.org",
                        "server_port":443
                    },
                    "private_key":"${REALITY_PRIVATE}",
                    "short_id":[
                        ""
                    ]
                }
            },
            "transport": {
                "type": "http"
            },
            "multiplex":{
                "enabled":true,
                "padding":true,
                "brutal":{
                    "enabled":${IS_BRUTAL},
                    "up_mbps":1000,
                    "down_mbps":1000
                }
            }
        }
    ]
}
EOF

  # Generate gRPC + Reality configuration
  [ "${GRPC_REALITY}" = 'true' ] && ((PORT++)) && PORT_GRPC_REALITY=$PORT && cat > ${WORK_DIR}/conf/20_grpc-reality_inbounds.json << EOF
//  "public_key":"${REALITY_PUBLIC}"
{
    "inbounds":[
        {
            "type":"vless",
            "tag":"${NODE_NAME} grpc-reality",
            "listen":"::",
            "listen_port":${PORT_GRPC_REALITY},
            "users":[
                {
                    "uuid":"${UUID}"
                }
            ],
            "tls":{
                "enabled":true,
                "server_name":"addons.mozilla.org",
                "reality":{
                    "enabled":true,
                    "handshake":{
                        "server":"addons.mozilla.org",
                        "server_port":443
                    },
                    "private_key":"${REALITY_PRIVATE}",
                    "short_id":[
                        ""
                    ]
                }
            },
            "transport": {
                "type": "grpc",
                "service_name": "grpc"
            },
            "multiplex":{
                "enabled":true,
                "padding":true,
                "brutal":{
                    "enabled":${IS_BRUTAL},
                    "up_mbps":1000,
                    "down_mbps":1000
                }
            }
        }
    ]
}
EOF

  # Generate AnyTLS configuration
  [ "${ANYTLS}" = 'true' ] && ((PORT++)) && PORT_ANYTLS=$PORT && cat > ${WORK_DIR}/conf/21_anytls_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"anytls",
            "tag":"${NODE_NAME} anytls",
            "listen":"::",
            "listen_port":$PORT_ANYTLS,
            "users":[
                {
                    "password":"${UUID}"
                }
            ],
            "padding_scheme":[],
            "tls":{
                "enabled":true,
                "certificate_path":"${WORK_DIR}/cert/cert.pem",
                "key_path":"${WORK_DIR}/cert/private.key"
            }
        }
    ]
}
EOF

# Determine the argo tunnel type
  if [[ -n "$ARGO_DOMAIN" && -n "$ARGO_AUTH" ]]; then
    # Based on the content of ARGO_AUTH, determine whether it is Json, Token or API application.
    if [[ "$ARGO_AUTH" =~ TunnelSecret ]]; then
      # JSON type
      local ARGO_JSON=${ARGO_AUTH//[ ]/}
    elif [[ "${ARGO_AUTH}" =~ [A-Z0-9a-z=]{150,250}$ ]]; then
      # Token type
      local ARGO_TOKEN=$(awk '{print $NF}' <<< "$ARGO_AUTH")
    elif [[ "${#ARGO_AUTH}" == 40 ]]; then
      # API type (Cloudflare API Token)
echo -e "\nCreate a tunnel using the Cloudflare API..."

   # Get the tunnel name and root domain name
      local TUNNEL_NAME=${ARGO_DOMAIN%%.*}
      local ROOT_DOMAIN=${ARGO_DOMAIN#*.}

      # Get Zone ID and Account ID
      local ZONE_RESPONSE=$(wget --no-check-certificate -qO---content-on-error \
        --header="Authorization: Bearer ${ARGO_AUTH}" \
        --header="Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/zones?name=${ROOT_DOMAIN}")
local ZONE_ID=$(sed 's/.*"result":[ ]*[{"id:[ ]*"\([^"]*\)",.*/\1/' <<< $ZONE_RESPONSE)
      local ACCOUNT_ID=$(sed 's/.*account":[ ]*{"id":"\([^"]*\)",.*/\1/' <<< $ZONE_RESPONSE)

# Query and process existing tunnels
      local TUNNEL_LIST=$(wget --no-check-certificate -qO---content-on-error \
        --header="Authorization: Bearer ${ARGO_AUTH}" \
        --header="Content-Type: application/json" \
"https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/cfd_tunnel?is_deleted=false" \
| awk 'BEGIN{RS="";FS=""}{s=substr($0,index($0,"\"result\":[")+10);d=0;b="";for(i=1;i<=length(s);i++){c=substr(s,i,1);if(c=="{")d++;if(d>0)b=b c;if(c=="}"){d--;if(d==0){print b;b=""}}}}')

      if [[ "$TUNNEL_LIST" =~ \"id\":\"([^\"]+).*\"name\":\"$TUNNEL_NAME\" ]]; then
       # If there is a Tunnel with the same name, get its ID and TOKEN
        local EXISTING_TUNNEL_ID="${BASH_REMATCH[1]}"
        local EXISTING_TUNNEL_TOKEN=$(wget -qO- --content-on-error \
          --header="Authorization: Bearer ${ARGO_AUTH}" \
          --header="Content-Type: application/json" \
          "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/cfd_tunnel/${EXISTING_TUNNEL_ID}/token")

        local TUNNEL_ID=$EXISTING_TUNNEL_ID
        local ARGO_TOKEN=$(sed -n 's/.*"result":"\([^"]\+\)".*/\1/p' <<< "$EXISTING_TUNNEL_TOKEN")
      else
      # Generate Tunnel Secret (at least 32 bytes base64 encoded)
        local TUNNEL_SECRET=$(openssl rand -base64 32)

        #Create new Tunnel
        local CREATE_RESPONSE=$(wget --no-check-certificate -qO---content-on-error \
          --header="Authorization: Bearer ${ARGO_AUTH}" \
          --header="Content-Type: application/json" \
          --post-data="{
            \"name\": \"$TUNNEL_NAME\",
            \"config_src\": \"cloudflare\",
            \"tunnel_secret\": \"$TUNNEL_SECRET\"
}"\
          "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/cfd_tunnel")

        local TUNNEL_ID=$(sed -n 's/.*"id":"\([^"]\+\)".*/\1/p' <<< "$CREATE_RESPONSE")
        local ARGO_TOKEN=$(sed -n 's/.*"token":"\([^"]\+\)".*/\1/p' <<< "$CREATE_RESPONSE")
      fi

      # Configure tunnel ingress rules
      local CONFIG_RESPONSE=$(wget --no-check-certificate -qO- --content-on-error \
        --method=PUT \
        --header="Authorization: Bearer ${ARGO_AUTH}" \
        --header="Content-Type: application/json" \
        --body-data="{
          \"config\": {
            \"ingress\": [
              {
                \"service\": \"http://localhost:${START_PORT}\",
                \"hostname\": \"${ARGO_DOMAIN}\"
              },
              {
                \"service\": \"http_status:404\"
              }
            ],
            \"warp-routing\": {
              \"enabled\": false
            }
          }
        }" \
        "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations")

      # Manage DNS records
      local DNS_PAYLOAD="{
        \"name\": \"${ARGO_DOMAIN}\",
        \"type\": \"CNAME\",
        \"content\": \"${TUNNEL_ID}.cfargotunnel.com\",
        \"proxied\": true,
        \"settings\": {
          \"flatten_cname\": false
        }
      }"

      local DNS_LIST=$(wget --no-check-certificate -qO- --content-on-error \
        --header="Authorization: Bearer ${ARGO_AUTH}" \
        --header="Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=CNAME&name=${ARGO_DOMAIN}")

 # If the required DNS record already exists, skip it
      if [[ "$DNS_LIST" =~ \"id\":\"([^\"]+)\".*\"$ARGO_DOMAIN\".*\"content\":\"([^\"]+)\" ]]; then
        local EXISTING_DNS_ID="${BASH_REMATCH[1]}" EXISTED_DNS_CONTENT="${BASH_REMATCH[2]}"

        # If the DNS record does not match the tunnel ID, overwrite the original CNAME record
        if ! grep -qw "$EXISTING_TUNNEL_ID" <<< "${EXISTED_DNS_CONTENT%%.*}"; then
          local DNS_RESPONSE=$(wget --no-check-certificate -qO- --content-on-error \
            --method=PATCH \
            --header="Authorization: Bearer ${ARGO_AUTH}" \
            --header="Content-Type: application/json" \
            --body-data="$DNS_PAYLOAD" \
            "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${EXISTING_DNS_ID}")
        fi
      else
# Existing DNS record not found, created using POST
        local DNS_RESPONSE=$(wget --no-check-certificate -qO---content-on-error \
          --method=POST \
          --header="Authorization: Bearer ${ARGO_AUTH}" \
          --header="Content-Type: application/json" \
          --body-data="$DNS_PAYLOAD" \
          "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records")
      fi

      # Construct ARGO_JSON
local ARGO_JSON="{\"AccountTag\":\"$ACCOUNT_ID\",\"TunnelSecret\":\"$TUNNEL_SECRET\",\"TunnelID\":\"$TUNNEL_ID\",\"Endpoint\":\"\"}"
    fi

    # Set ARGO_RUNS based on ARGO_JSON or ARGO_TOKEN
    if [[ -n "$ARGO_JSON" ]]; then
      local ARGO_RUNS="cloudflared tunnel --edge-ip-version auto --config ${WORK_DIR}/tunnel.yml run"
      echo $ARGO_JSON > ${WORK_DIR}/tunnel.json
      cat > ${WORK_DIR}/tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< $ARGO_JSON)
credentials-file: ${WORK_DIR}/tunnel.json

ingress:
  - hostname: ${ARGO_DOMAIN}
    service: http://localhost:${START_PORT}
  - service: http_status:404
EOF
    elif [[ -n "$ARGO_TOKEN" ]]; then
      local ARGO_RUNS="cloudflared tunnel --edge-ip-version auto run --token ${ARGO_TOKEN}"
    fi
  else
    ((PORT++))
    METRICS_PORT=$PORT
    local ARGO_RUNS="cloudflared tunnel --edge-ip-version auto --no-autoupdate --no-tls-verify --metrics 0.0.0.0:$METRICS_PORT --url http://localhost:$START_PORT"
  fi

# Generate s6-overlay service script (replacing supervisord)
  mkdir -p /etc/services.d/nginx /etc/services.d/sing-box
  cat > /etc/services.d/nginx/run << 'EOF'
#!/usr/bin/env sh
exec /usr/sbin/nginx -g 'daemon off;'
EOF
  cat > /etc/services.d/sing-box/run << EOF
#!/usr/bin/env sh
exec ${WORK_DIR}/sing-box run -C ${WORK_DIR}/conf/
EOF
  chmod +x /etc/services.d/nginx/run /etc/services.d/sing-box/run

  # When naming tunnel mode, argo serves as s6 service; Quick Tunnel mode maintains the original front-end and background pull-up logic
  if [ -z "$METRICS_PORT" ]; then
    mkdir -p /etc/services.d/argo
    cat > /etc/services.d/argo/run << EOF
#!/usr/bin/env sh
exec ${WORK_DIR}/${ARGO_RUNS} 2>/dev/null
EOF
    chmod +x /etc/services.d/argo/run

  else
# If using a temporary tunnel, run cloudflared first to obtain the temporary tunnel domain name
    nohup ${WORK_DIR}/${ARGO_RUNS} >/dev/null 2>&1 &
    until grep -q 'trycloudflare\.com' <<< "$ARGO_DOMAIN" ; do
      sleep 1
      local ARGO_DOMAIN=$(wget -qO-http://localhost:$METRICS_PORT/quicktunnel | awk -F '"' '{print $4}')
    done
  fi

  # Get the fingerprint of the self-signed certificate. The origin returned by argo is a trusted certificate (not self-signed) issued by Google Trust Services as an intermediate CA (CN=WE1)
local SELF_SIGNED_FINGERPRINT_SHA256=$(openssl x509 -fingerprint -noout -sha256 -in ${WORK_DIR}/cert/cert.pem | awk -F '=' '{print $NF}')
  local SELF_SIGNED_FINGERPRINT_BASE64=$(openssl x509 -in ${WORK_DIR}/cert/cert.pem -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)

 # Generate nginx configuration file
  local NGINX_CONF="user root;

  worker_processes auto;

  error_log  /dev/null;
  pid        /var/run/nginx.pid;

  events {
      worker_connections  1024;
  }

  http {
 map \$http_user_agent \$path {
      default /; #Default path
      ~*v2rayN|Neko|Throne /base64; # Match V2rayN /NekoBox /Throne client
      ~*clash /clash; # Match Clash client
      ~*ShadowRocket /shadowrocket; # Match ShadowRocket client
      ~*SFM|SFI|SFA /sing-box; # Match Sing-box official client
   # ~*Chrome|Firefox|Mozilla /; # Add more diversion rules
    }

      include       /etc/nginx/mime.types;
      default_type  application/octet-stream;

      log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                        '\$status \$body_bytes_sent "\$http_referer" '
                        '"\$http_user_agent" "\$http_x_forwarded_for"';


      access_log  /dev/null;

      sendfile        on;
      #tcp_nopush     on;

      keepalive_timeout  65;

      #gzip  on;

      #include /etc/nginx/conf.d/*.conf;

    server {
      listen 127.0.0.1:$START_PORT; # sing-box backend
"

  [ "${VLESS_WS}" = 'true' ] && NGINX_CONF+="
      # Anti-generational sing-box vless websocket
      location /${UUID}-vless {
        if (\$http_upgrade != "websocket") {
           return 404;
        }
        proxy_pass                          http://127.0.0.1:${PORT_VLESS_WS};
        proxy_http_version                  1.1;
        proxy_set_header Upgrade            \$http_upgrade;
        proxy_set_header Connection         "upgrade";
        proxy_set_header X-Real-IP          \$remote_addr;
        proxy_set_header X-Forwarded-For    \$proxy_add_x_forwarded_for;
        proxy_set_header Host               \$host;
        proxy_redirect                      off;
      }"

  [ "${VMESS_WS}" = 'true' ] && NGINX_CONF+="
      # anti-dai sing-box websocket
      location /${UUID}-vmess {
        if (\$http_upgrade != "websocket") {
           return 404;
        }
        proxy_pass                          http://127.0.0.1:${PORT_VMESS_WS};
        proxy_http_version                  1.1;
        proxy_set_header Upgrade            \$http_upgrade;
        proxy_set_header Connection         "upgrade";
        proxy_set_header X-Real-IP          \$remote_addr;
        proxy_set_header X-Forwarded-For    \$proxy_add_x_forwarded_for;
        proxy_set_header Host               \$host;
        proxy_redirect                      off;
      }"

  NGINX_CONF+="
      # Diversion from /auto
      location ~ ^/${UUID}/auto {
        default_type 'text/plain; charset=utf-8';
        alias ${WORK_DIR}/subscribe/\$path;
      }

      location ~ ^/${UUID}/(.*) {
        autoindex on;
        proxy_set_header X-Real-IP \$proxy_protocol_addr;
        default_type 'text/plain; charset=utf-8';
        alias ${WORK_DIR}/subscribe/\$1;
      }
    }
  }"

  echo "$NGINX_CONF" > /etc/nginx/nginx.conf

# IP handling for IPv6
  if [[ "$SERVER_IP" =~ : ]]; then
    SERVER_IP_1="[$SERVER_IP]"
    SERVER_IP_2="[[$SERVER_IP]]"
  else
    SERVER_IP_1="$SERVER_IP"
    SERVER_IP_2="$SERVER_IP"
  fi

  # Generate each subscription file
  # Generate Clash proxy providers subscription file
  local CLASH_SUBSCRIBE='proxies:'

  [ "${XTLS_REALITY}" = 'true' ] && local CLASH_XTLS_REALITY="- {name: \"${NODE_NAME} xtls-reality\", type: vless, server: ${SERVER_IP}, port: ${PORT_XTLS_REALITY}, uuid: ${UUID}, network: tcp, udp: true, tls: true, flow: xtls-rprx-vision, servername: addons.mozilla.org, client-fingerprint: firefox, reality-opts: {public-key: ${REALITY_PUBLIC}, short-id: \"\"}, smux: { enabled: false, protocol: 'h2mux', padding: false, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: false } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_XTLS_REALITY
"
  [ "${HYSTERIA2}" = 'true' ] && local CLASH_HYSTERIA2="- {name: \"${NODE_NAME} hysteria2\", type: hysteria2, server: ${SERVER_IP}, port: ${PORT_HYSTERIA2}, up: \"200 Mbps\", down: \"1000 Mbps\", password: ${UUID}, sni: addons.mozilla.org, skip-cert-verify: false, fingerprint: ${SELF_SIGNED_FINGERPRINT_SHA256}}" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_HYSTERIA2
"
  [ "${TUIC}" = 'true' ] && local CLASH_TUIC="- {name: \"${NODE_NAME} tuic\", type: tuic, server: ${SERVER_IP}, port: ${PORT_TUIC}, uuid: ${UUID}, password: ${UUID}, alpn: [h3], reduce-rtt: true, request-timeout: 8000, udp-relay-mode: native, congestion-controller: bbr, sni: addons.mozilla.org, skip-cert-verify: false, fingerprint: ${SELF_SIGNED_FINGERPRINT_SHA256}}" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_TUIC
"
  [ "${SHADOWTLS}" = 'true' ] && local CLASH_SHADOWTLS="- {name: \"${NODE_NAME} ShadowTLS\", type: ss, server: ${SERVER_IP}, port: ${PORT_SHADOWTLS}, cipher: ${SIP022_METHOD}, password: ${SIP022_PASSWORD}, plugin: shadow-tls, client-fingerprint: firefox, plugin-opts: {host: addons.mozilla.org, password: \"${UUID}\", version: 3}, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_SHADOWTLS
"
  [ "${SHADOWSOCKS}" = 'true' ] && local CLASH_SHADOWSOCKS="- {name: \"${NODE_NAME} shadowsocks\", type: ss, server: ${SERVER_IP}, port: $PORT_SHADOWSOCKS, cipher: ${SIP022_METHOD}, password: ${SIP022_PASSWORD}, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_SHADOWSOCKS
"
  [ "${TROJAN}" = 'true' ] && local CLASH_TROJAN="- {name: \"${NODE_NAME} trojan\", type: trojan, server: ${SERVER_IP}, port: $PORT_TROJAN, password: ${UUID}, client-fingerprint: firefox, sni: addons.mozilla.org, skip-cert-verify: false, fingerprint: ${SELF_SIGNED_FINGERPRINT_SHA256}, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_TROJAN
"
  [ "${VMESS_WS}" = 'true' ] && local CLASH_VMESS_WS="- {name: \"${NODE_NAME} vmess-ws\", type: vmess, server: ${CDN}, port: 80, uuid: ${UUID}, udp: true, tls: false, alterId: 0, cipher: auto, network: ws, ws-opts: { path: \"/${UUID}-vmess\", headers: {Host: ${ARGO_DOMAIN}} }, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_VMESS_WS
"
  [ "${VLESS_WS}" = 'true' ] && local CLASH_VLESS_WS="- {name: \"${NODE_NAME} vless-ws-tls\", type: vless, server: ${CDN}, port: 443, uuid: ${UUID}, udp: true, tls: true, servername: ${ARGO_DOMAIN}, network: ws, skip-cert-verify: false,  ws-opts: { path: \"/${UUID}-vless\", headers: {Host: ${ARGO_DOMAIN}}, max-early-data: 2560, early-data-header-name: Sec-WebSocket-Protocol }, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_VLESS_WS
"

  [ "${H2_REALITY}" = 'true' ] && local CLASH_H2_REALITY="- {name: \"${NODE_NAME} h2-reality\", type: vless, server: ${SERVER_IP}, port: ${PORT_H2_REALITY}, uuid: ${UUID}, network: http, tls: true, servername: addons.mozilla.org, client-fingerprint: firefox, reality-opts: { public-key: ${REALITY_PUBLIC}, short-id: \"\" }, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_H2_REALITY
"

  [ "${GRPC_REALITY}" = 'true' ] && local CLASH_GRPC_REALITY="- {name: \"${NODE_NAME} grpc-reality\", type: vless, server: ${SERVER_IP}, port: ${PORT_GRPC_REALITY}, uuid: ${UUID}, network: grpc, tls: true, udp: true, flow: , client-fingerprint: firefox, servername: addons.mozilla.org, grpc-opts: {  grpc-service-name: \"grpc\" }, reality-opts: { public-key: ${REALITY_PUBLIC}, short-id: \"\" }, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_GRPC_REALITY
"
  [ "${ANYTLS}" = 'true' ] && local CLASH_ANYTLS="- {name: \"${NODE_NAME} anytls\", type: anytls, server: ${SERVER_IP}, port: $PORT_ANYTLS, password: ${UUID}, client-fingerprint: firefox, udp: true, idle-session-check-interval: 30, idle-session-timeout: 30, sni: addons.mozilla.org, skip-cert-verify: false, fingerprint: ${SELF_SIGNED_FINGERPRINT_SHA256} }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_ANYTLS
"

  echo -n "${CLASH_SUBSCRIBE}" | sed -E '/^[ ]*#|^--/d' | sed '/^$/d' > ${WORK_DIR}/subscribe/proxies

# Generate clash subscription configuration file
  # Template: use proxy providers
  wget -qO---tries=3 --timeout=2 ${SUBSCRIBE_TEMPLATE}/clash | sed "s#NODE_NAME#${NODE_NAME}#g; s#PROXY_PROVIDERS_URL#https://${ARGO_DOMAIN}/${UUID}/proxies#" > ${WORK_DIR}/subscribe/clash

  # Generate ShadowRocket subscription configuration file
  [ "${XTLS_REALITY}" = 'true' ] && local SHADOWROCKET_SUBSCRIBE+="
vless://$(echo -n "auto:${UUID}@${SERVER_IP_2}:${PORT_XTLS_REALITY}" | base64 -w0)?remarks=${NODE_NAME// /%20}%20xtls-reality&obfs=none&tls=1&peer=addons.mozilla.org&xtls=2&pbk=${REALITY_PUBLIC}
"
  [ "${HYSTERIA2}" = 'true' ] && local SHADOWROCKET_SUBSCRIBE+="
hysteria2://${UUID}@${SERVER_IP_1}:${PORT_HYSTERIA2}?peer=addons.mozilla.org&hpkp=${SELF_SIGNED_FINGERPRINT_SHA256}&obfs=none#${NODE_NAME// /%20}%20hysteria2
"
  [ "${TUIC}" = 'true' ] && local SHADOWROCKET_SUBSCRIBE+="
tuic://${UUID}:${UUID}@${SERVER_IP_2}:${PORT_TUIC}?peer=addons.mozilla.org&congestion_control=bbr&udp_relay_mode=native&alpn=h3&hpkp=${SELF_SIGNED_FINGERPRINT_SHA256}#${NODE_NAME// /%20}%20tuic
"
  [ "${SHADOWTLS}" = 'true' ] && local SHADOWROCKET_SUBSCRIBE+="
ss://$(echo -n "${SIP022_METHOD}:${SIP022_PASSWORD}@${SERVER_IP_2}:${PORT_SHADOWTLS}" | base64 -w0)?shadow-tls=$(echo -n "{\"version\":\"3\",\"host\":\"addons.mozilla.org\",\"password\":\"${UUID}\"}" | base64 -w0)#${NODE_NAME// /%20}%20ShadowTLS
"
  [ "${SHADOWSOCKS}" = 'true' ] && local SHADOWROCKET_SUBSCRIBE+="
ss://$(echo -n "${SIP022_METHOD}:${SIP022_PASSWORD}@${SERVER_IP_2}:$PORT_SHADOWSOCKS" | base64 -w0)#${NODE_NAME// /%20}%20shadowsocks
"
  [ "${TROJAN}" = 'true' ] && local SHADOWROCKET_SUBSCRIBE+="
trojan://${UUID}@${SERVER_IP_1}:$PORT_TROJAN?peer=addons.mozilla.org&hpkp=${SELF_SIGNED_FINGERPRINT_SHA256}#${NODE_NAME// /%20}%20trojan
"
  [ "${VMESS_WS}" = 'true' ] && local SHADOWROCKET_SUBSCRIBE+="
----------------------------
vmess://$(echo -n "auto:${UUID}@${CDN}:80" | base64 -w0)?remarks=${NODE_NAME// /%20}%20vmess-ws&obfsParam=${ARGO_DOMAIN}&path=/${UUID}-vmess&obfs=websocket&alterId=0
"
  [ "${VLESS_WS}" = 'true' ] && local SHADOWROCKET_SUBSCRIBE+="
----------------------------
vless://$(echo -n "auto:${UUID}@${CDN}:443" | base64 -w0)?remarks=${NODE_NAME// /%20}%20vless-ws-tls&obfsParam=${ARGO_DOMAIN}&path=/${UUID}-vless?ed=2560&obfs=websocket&tls=1&peer=${ARGO_DOMAIN}
"
  [ "${H2_REALITY}" = 'true' ] && local SHADOWROCKET_SUBSCRIBE+="
----------------------------
vless://$(echo -n auto:${UUID}@${SERVER_IP_2}:${PORT_H2_REALITY} | base64 -w0)?remarks=${NODE_NAME// /%20}%20h2-reality&path=/&obfs=h2&tls=1&peer=addons.mozilla.org&alpn=h2&mux=1&pbk=${REALITY_PUBLIC}
"
  [ "${GRPC_REALITY}" = 'true' ] && local SHADOWROCKET_SUBSCRIBE+="
vless://$(echo -n "auto:${UUID}@${SERVER_IP_2}:${PORT_GRPC_REALITY}" | base64 -w0)?remarks=${NODE_NAME// /%20}%20grpc-reality&path=grpc&obfs=grpc&tls=1&peer=addons.mozilla.org&pbk=${REALITY_PUBLIC}
"
  [ "${ANYTLS}" = 'true' ] && local SHADOWROCKET_SUBSCRIBE+="
anytls://${UUID}@${SERVER_IP_1}:${PORT_ANYTLS}?peer=addons.mozilla.org&udp=1&hpkp=${SELF_SIGNED_FINGERPRINT_SHA256}#${NODE_NAME// /%20}%20anytls
"
  echo -n "$SHADOWROCKET_SUBSCRIBE" | sed -E '/^[ ]*#|^--/d' | sed '/^$/d' | base64 -w0 > ${WORK_DIR}/subscribe/shadowrocket

# Generate V2rayN subscription file
  [ "${XTLS_REALITY}" = 'true' ] && local V2RAYN_SUBSCRIBE+="
----------------------------
vless://${UUID}@${SERVER_IP_1}:${PORT_XTLS_REALITY}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=addons.mozilla.org&fp=firefox&pbk=${REALITY_PUBLIC}&type=tcp&headerType=none#${NODE_NAME// /%20}%20xtls-reality"

  [ "${HYSTERIA2}" = 'true' ] && local V2RAYN_SUBSCRIBE+="
----------------------------
hysteria2://${UUID}@${SERVER_IP_1}:${PORT_HYSTERIA2}?sni=addons.mozilla.org&alpn=h3&insecure=1&allowInsecure=1&pinSHA256=${SELF_SIGNED_FINGERPRINT_SHA256//:/}#${NODE_NAME// /%20}%20hysteria2"

  [ "${TUIC}" = 'true' ] && local V2RAYN_SUBSCRIBE+="
----------------------------
tuic://${UUID}:${UUID}@${SERVER_IP_1}:${PORT_TUIC}?sni=addons.mozilla.org&alpn=h3&insecure=1&allowInsecure=1&congestion_control=bbr#${NODE_NAME// /%20}%20tuic"

  [ "${SHADOWTLS}" = 'true' ] && local V2RAYN_SUBSCRIBE+="
----------------------------
# $(echo -e "ShadowTLS 配置文件内容，需要更新 sing_box 内核")

{
  \"log\":{
      \"level\":\"warn\"
  },
  \"inbounds\":[
      {
          \"listen\":\"127.0.0.1\",
          \"listen_port\":${PORT_SHADOWTLS},
          \"sniff\":true,
          \"sniff_override_destination\":false,
          \"tag\": \"ShadowTLS\",
          \"type\":\"mixed\"
      }
  ],
  \"outbounds\":[
      {
          \"detour\":\"shadowtls-out\",
          \"method\":\"${SIP022_METHOD}\",
          \"password\":\"${SIP022_PASSWORD}\",
          \"type\":\"shadowsocks\",
          \"udp_over_tcp\": false,
          \"multiplex\": {
            \"enabled\": true,
            \"protocol\": \"h2mux\",
            \"max_connections\": 8,
            \"min_streams\": 16,
            \"padding\": true
          }
      },
      {
          \"password\":\"${UUID}\",
          \"server\":\"${SERVER_IP}\",
          \"server_port\":${PORT_SHADOWTLS},
          \"tag\": \"shadowtls-out\",
          \"tls\":{
              \"enabled\":true,
              \"server_name\":\"addons.mozilla.org\",
              \"utls\": {
                \"enabled\": true,
                \"fingerprint\": \"firefox\"
              }
          },
          \"type\":\"shadowtls\",
          \"version\":3
      }
  ]
}"
  [ "${SHADOWSOCKS}" = 'true' ] && local V2RAYN_SUBSCRIBE+="
----------------------------
ss://$(echo -n "${SIP022_METHOD}:${SIP022_PASSWORD}@${SERVER_IP_1}:$PORT_SHADOWSOCKS" | base64 -w0)#${NODE_NAME// /%20}%20shadowsocks"

  [ "${TROJAN}" = 'true' ] && local V2RAYN_SUBSCRIBE+="
----------------------------
trojan://${UUID}@${SERVER_IP_1}:$PORT_TROJAN?security=tls&insecure=1&allowInsecure=1&pcs=${SELF_SIGNED_FINGERPRINT_SHA256//:/}&type=tcp&headerType=none#${NODE_NAME// /%20}%20trojan"

  [ "${VMESS_WS}" = 'true' ] && local V2RAYN_SUBSCRIBE+="
----------------------------
vmess://$(echo -n "{ \"v\": \"2\", \"ps\": \"${NODE_NAME} vmess-ws\", \"add\": \"${CDN}\", \"port\": \"80\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${UUID}-vmess\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\" }" | base64 -w0)"

  [ "${VLESS_WS}" = 'true' ] && local V2RAYN_SUBSCRIBE+="
----------------------------
vless://${UUID}@${CDN}:443?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${UUID}-vless%3Fed%3D2560#${NODE_NAME// /%20}%20vless-ws-tls"

  [ "${H2_REALITY}" = 'true' ] && local V2RAYN_SUBSCRIBE+="
----------------------------
vless://${UUID}@${SERVER_IP_1}:${PORT_H2_REALITY}?encryption=none&security=reality&sni=addons.mozilla.org&fp=firefox&pbk=${REALITY_PUBLIC}&type=http#${NODE_NAME// /%20}%20h2-reality"

  [ "${GRPC_REALITY}" = 'true' ] && local V2RAYN_SUBSCRIBE+="
----------------------------
vless://${UUID}@${SERVER_IP_1}:${PORT_GRPC_REALITY}?encryption=none&security=reality&sni=addons.mozilla.org&fp=firefox&pbk=${REALITY_PUBLIC}&type=grpc&serviceName=grpc&mode=gun#${NODE_NAME// /%20}%20grpc-reality"

  [ "${ANYTLS}" = 'true' ] && local V2RAYN_SUBSCRIBE+="
----------------------------
anytls://${UUID}@${SERVER_IP_1}:${PORT_ANYTLS}?security=tls&sni=addons.mozilla.org&fp=firefox&insecure=1&allowInsecure=1&type=tcp#${NODE_NAME// /%20}%20anytls"

  echo -n "$V2RAYN_SUBSCRIBE" | sed -E '/^[ ]*#|^[ ]+|^--|^\{|^\}/d' | sed '/^$/d' | base64 -w0 > ${WORK_DIR}/subscribe/v2rayn

# Generate NekoBox subscription file
  [ "${XTLS_REALITY}" = 'true' ] && local NEKOBOX_SUBSCRIBE+="
----------------------------
vless://${UUID}@${SERVER_IP_1}:${PORT_XTLS_REALITY}?security=reality&sni=addons.mozilla.org&fp=firefox&pbk=${REALITY_PUBLIC}&type=tcp&flow=xtls-rprx-vision&encryption=none#${NODE_NAME// /%20}%20xtls-reality"

  [ "${HYSTERIA2}" = 'true' ] && local NEKOBOX_SUBSCRIBE+="
----------------------------
hy2://${UUID}@${SERVER_IP_1}:${PORT_HYSTERIA2}?insecure=1&sni=addons.mozilla.org#${NODE_NAME// /%20}%20hysteria2"

  [ "${TUIC}" = 'true' ] && local NEKOBOX_SUBSCRIBE+="
----------------------------
tuic://${UUID}:${UUID}@${SERVER_IP_1}:${PORT_TUIC}?congestion_control=bbr&alpn=h3&sni=addons.mozilla.org&udp_relay_mode=native&allow_insecure=1#${NODE_NAME// /%20}%20tuic"

  [ "${SHADOWTLS}" = 'true' ] && local NEKOBOX_SUBSCRIBE+="
----------------------------
nekoray://custom#$(echo -n "{\"_v\":0,\"addr\":\"127.0.0.1\",\"cmd\":[\"\"],\"core\":\"internal\",\"cs\":\"{\n    \\\"password\\\": \\\"${UUID}\\\",\n    \\\"server\\\": \\\"${SERVER_IP_1}\\\",\n    \\\"server_port\\\": ${PORT_SHADOWTLS},\n    \\\"tag\\\": \\\"shadowtls-out\\\",\n    \\\"tls\\\": {\n        \\\"enabled\\\": true,\n        \\\"server_name\\\": \\\"addons.mozilla.org\\\"\n    },\n    \\\"type\\\": \\\"shadowtls\\\",\n    \\\"version\\\": 3\n}\n\",\"mapping_port\":0,\"name\":\"1-tls-not-use\",\"port\":1080,\"socks_port\":0}" | base64 -w0)

nekoray://shadowsocks#$(echo -n "{\"_v\":0,\"method\":\"${SIP022_METHOD}\",\"name\":\"2-ss-not-use\",\"pass\":\"${SIP022_PASSWORD}\",\"port\":0,\"stream\":{\"ed_len\":0,\"insecure\":false,\"mux_s\":0,\"net\":\"tcp\"},\"uot\":0}" | base64 -w0)"

  [ "${SHADOWSOCKS}" = 'true' ] && local NEKOBOX_SUBSCRIBE+="
----------------------------
ss://$(echo -n "${SIP022_METHOD}:${SIP022_PASSWORD}" | base64 -w0)@${SERVER_IP_1}:$PORT_SHADOWSOCKS#${NODE_NAME// /%20}%20shadowsocks"

  [ "${TROJAN}" = 'true' ] && local NEKOBOX_SUBSCRIBE+="
----------------------------
trojan://${UUID}@${SERVER_IP_1}:$PORT_TROJAN?security=tls&sni=addons.mozilla.org&allowInsecure=1&fp=firefox&type=tcp#${NODE_NAME// /%20}%20trojan"

  [ "${VMESS_WS}" = 'true' ] && local NEKOBOX_SUBSCRIBE+="
----------------------------
vmess://$(echo -n "{\"add\":\"${CDN}\",\"aid\":\"0\",\"host\":\"${ARGO_DOMAIN}\",\"id\":\"${UUID}\",\"net\":\"ws\",\"path\":\"/${UUID}-vmess\",\"port\":\"80\",\"ps\":\"${NODE_NAME} vmess-ws\",\"scy\":\"auto\",\"sni\":\"\",\"tls\":\"\",\"type\":\"\",\"v\":\"2\"}" | base64 -w0)
"

  [ "${VLESS_WS}" = 'true' ] && local NEKOBOX_SUBSCRIBE+="
----------------------------
vless://${UUID}@${CDN}:443?security=tls&sni=${ARGO_DOMAIN}&type=ws&path=/${UUID}-vless?ed%3D2560&host=${ARGO_DOMAIN}#${NODE_NAME// /%20}%20vless-ws-tls
"

  [ "${H2_REALITY}" = 'true' ] && local NEKOBOX_SUBSCRIBE+="
----------------------------
vless://${UUID}@${SERVER_IP_1}:${PORT_H2_REALITY}?security=reality&sni=addons.mozilla.org&alpn=h2&fp=firefox&pbk=${REALITY_PUBLIC}&type=http&encryption=none#${NODE_NAME// /%20}%20h2-reality"

  [ "${GRPC_REALITY}" = 'true' ] && local NEKOBOX_SUBSCRIBE+="
----------------------------
vless://${UUID}@${SERVER_IP_1}:${PORT_GRPC_REALITY}?security=reality&sni=addons.mozilla.org&fp=firefox&pbk=${REALITY_PUBLIC}&type=grpc&serviceName=grpc&encryption=none#${NODE_NAME// /%20}%20grpc-reality"

  [ "${ANYTLS}" = 'true' ] && local NEKOBOX_SUBSCRIBE+="
----------------------------
anytls://${UUID}@${SERVER_IP_1}:${PORT_ANYTLS}?security=tls&sni=addons.mozilla.org&insecure=1&fp=firefox#${NODE_NAME// /%20}%20anytls"

  echo -n "$NEKOBOX_SUBSCRIBE" | sed -E '/^[ ]*#|^--/d' | sed '/^$/d' | base64 -w0 > ${WORK_DIR}/subscribe/neko

# Generate Sing-box subscription file
  [ "${XTLS_REALITY}" = 'true' ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"vless\", \"tag\": \"${NODE_NAME} xtls-reality\", \"server\":\"${SERVER_IP}\", \"server_port\":${PORT_XTLS_REALITY}, \"uuid\":\"${UUID}\", \"flow\":\"xtls-rprx-vision\", \"tls\":{ \"enabled\":true, \"server_name\":\"addons.mozilla.org\", \"utls\":{ \"enabled\":true, \"fingerprint\":\"firefox\" }, \"reality\":{ \"enabled\":true, \"public_key\":\"${REALITY_PUBLIC}\", \"short_id\":\"\" } }, \"multiplex\": { \"enabled\": false, \"protocol\": \"h2mux\", \"max_connections\": 8, \"min_streams\": 16, \"padding\": false, \"brutal\":{ \"enabled\":false } } }," &&
  local NODE_REPLACE+="\"${NODE_NAME} xtls-reality\","

  if [ "${HYSTERIA2}" = 'true' ]; then
    local OUTBOUND_REPLACE+=" { \"type\": \"hysteria2\", \"tag\": \"${NODE_NAME} hysteria2\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_HYSTERIA2},"
    [[ -n "${PORT_HOPPING_START}" && -n "${PORT_HOPPING_END}" ]] && local OUTBOUND_REPLACE+=" \"server_ports\": [ \"${PORT_HOPPING_START}:${PORT_HOPPING_END}\" ],"
    local OUTBOUND_REPLACE+=" \"up_mbps\": 200, \"down_mbps\": 1000, \"password\": \"${UUID}\", \"tls\": { \"enabled\": true, \"certificate_public_key_sha256\": [\"$SELF_SIGNED_FINGERPRINT_BASE64\"], \"server_name\": \"addons.mozilla.org\", \"alpn\": [ \"h3\" ] } },"
    local NODE_REPLACE+="\"${NODE_NAME} hysteria2\","
  fi

  [ "${TUIC}" = 'true' ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"tuic\", \"tag\": \"${NODE_NAME} tuic\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_TUIC}, \"uuid\": \"${UUID}\", \"password\": \"${UUID}\", \"congestion_control\": \"bbr\", \"udp_relay_mode\": \"native\", \"zero_rtt_handshake\": false, \"heartbeat\": \"10s\", \"tls\": { \"enabled\": true, \"certificate_public_key_sha256\": [\"$SELF_SIGNED_FINGERPRINT_BASE64\"], \"server_name\": \"addons.mozilla.org\", \"alpn\": [ \"h3\" ] } }," &&
  local NODE_REPLACE+="\"${NODE_NAME} tuic\","

  [ "${SHADOWTLS}" = 'true' ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"shadowsocks\", \"tag\": \"${NODE_NAME} ShadowTLS\", \"method\": \"${SIP022_METHOD}\", \"password\": \"${SIP022_PASSWORD}\", \"detour\": \"shadowtls-out\", \"udp_over_tcp\": false, \"multiplex\": { \"enabled\": true, \"protocol\": \"h2mux\", \"max_connections\": 8, \"min_streams\": 16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } }, { \"type\": \"shadowtls\", \"tag\": \"shadowtls-out\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_SHADOWTLS}, \"version\": 3, \"password\": \"${UUID}\", \"tls\": { \"enabled\": true, \"server_name\": \"addons.mozilla.org\", \"utls\": { \"enabled\": true, \"fingerprint\": \"firefox\" } } }," &&
  local NODE_REPLACE+="\"${NODE_NAME} ShadowTLS\","

  [ "${SHADOWSOCKS}" = 'true' ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"shadowsocks\", \"tag\": \"${NODE_NAME} shadowsocks\", \"server\": \"${SERVER_IP}\", \"server_port\": $PORT_SHADOWSOCKS, \"method\": \"${SIP022_METHOD}\", \"password\": \"${SIP022_PASSWORD}\", \"multiplex\": { \"enabled\": true, \"protocol\": \"h2mux\", \"max_connections\": 8, \"min_streams\": 16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } }," &&
  local NODE_REPLACE+="\"${NODE_NAME} shadowsocks\","

  [ "${TROJAN}" = 'true' ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"trojan\", \"tag\": \"${NODE_NAME} trojan\", \"server\": \"${SERVER_IP}\", \"server_port\": $PORT_TROJAN, \"password\": \"${UUID}\", \"tls\": { \"enabled\":true, \"certificate_public_key_sha256\": [\"$SELF_SIGNED_FINGERPRINT_BASE64\"], \"server_name\":\"addons.mozilla.org\", \"utls\": { \"enabled\":true, \"fingerprint\":\"firefox\" } }, \"multiplex\": { \"enabled\":true, \"protocol\":\"h2mux\", \"max_connections\": 8, \"min_streams\": 16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } }," &&
  local NODE_REPLACE+="\"${NODE_NAME} trojan\","

  [ "${VMESS_WS}" = 'true' ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"vmess\", \"tag\": \"${NODE_NAME} vmess-ws\", \"server\":\"${CDN}\", \"server_port\":80, \"uuid\": \"${UUID}\", \"security\": \"auto\", \"transport\": { \"type\":\"ws\", \"path\":\"/${UUID}-vmess\", \"headers\": { \"Host\": \"${ARGO_DOMAIN}\" } }, \"multiplex\": { \"enabled\":true, \"protocol\":\"h2mux\", \"max_streams\":16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } }," && local NODE_REPLACE+="\"${NODE_NAME} vmess-ws\","

  [ "${VLESS_WS}" = 'true' ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"vless\", \"tag\": \"${NODE_NAME} vless-ws-tls\", \"server\":\"${CDN}\", \"server_port\":443, \"uuid\": \"${UUID}\", \"tls\": { \"enabled\":true, \"server_name\":\"${ARGO_DOMAIN}\", \"insecure\": false, \"utls\": { \"enabled\":true, \"fingerprint\":\"firefox\" } }, \"transport\": { \"type\":\"ws\", \"path\":\"/${UUID}-vless\", \"headers\": { \"Host\": \"${ARGO_DOMAIN}\" }, \"max_early_data\":2560, \"early_data_header_name\":\"Sec-WebSocket-Protocol\" }, \"multiplex\": { \"enabled\":true, \"protocol\":\"h2mux\", \"max_streams\":16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } }," &&
  local NODE_REPLACE+="\"${NODE_NAME} vless-ws-tls\","

  [ "${H2_REALITY}" = 'true' ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"vless\", \"tag\": \"${NODE_NAME} h2-reality\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_H2_REALITY}, \"uuid\":\"${UUID}\", \"tls\": { \"enabled\":true, \"server_name\":\"addons.mozilla.org\", \"utls\": { \"enabled\":true, \"fingerprint\":\"firefox\" }, \"reality\":{ \"enabled\":true, \"public_key\":\"${REALITY_PUBLIC}\", \"short_id\":\"\" } }, \"transport\": { \"type\": \"http\" } }," &&
  local NODE_REPLACE+="\"${NODE_NAME} h2-reality\","

  [ "${GRPC_REALITY}" = 'true' ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"vless\", \"tag\": \"${NODE_NAME} grpc-reality\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_GRPC_REALITY}, \"uuid\":\"${UUID}\", \"tls\": { \"enabled\":true, \"server_name\":\"addons.mozilla.org\", \"utls\": { \"enabled\":true, \"fingerprint\":\"firefox\" }, \"reality\":{ \"enabled\":true, \"public_key\":\"${REALITY_PUBLIC}\", \"short_id\":\"\" } }, \"transport\": { \"type\": \"grpc\", \"service_name\": \"grpc\" } }," &&
  local NODE_REPLACE+="\"${NODE_NAME} grpc-reality\","

  [ "${ANYTLS}" = 'true' ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"anytls\", \"tag\": \"${NODE_NAME} anytls\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_ANYTLS}, \"password\": \"${UUID}\", \"idle_session_check_interval\": \"30s\", \"idle_session_timeout\": \"30s\", \"min_idle_session\": 5, \"tls\": { \"enabled\": true, \"certificate_public_key_sha256\": [\"$SELF_SIGNED_FINGERPRINT_BASE64\"], \"server_name\": \"addons.mozilla.org\", \"utls\": { \"enabled\": true, \"fingerprint\": \"firefox\" } } }," &&
  local NODE_REPLACE+="\"${NODE_NAME} anytls\","

# template
  local SING_BOX_JSON=$(wget -qO---tries=3 --timeout=2 ${SUBSCRIBE_TEMPLATE}/sing-box)

  echo $SING_BOX_JSON | sed "s#\"<OUTBOUND_REPLACE>\",#$OUTBOUND_REPLACE#; s#\"<NODE_REPLACE>\"#${NODE_REPLACE%,}#g" | ${WORK_DIR}/jq > ${WORK_DIR}/subscribe/sing-box

  # Generate QR code url file
  cat > ${WORK_DIR}/subscribe/qr << EOF
Adaptive Clash /V2rayN /NekoBox /ShadowRocket /SFI /SFA /SFM Client:
Template:
https://${ARGO_DOMAIN}/${UUID}/auto

Subscribe QRcode:
Template:
https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=https://${ARGO_DOMAIN}/${UUID}/auto

Template:
$(${WORK_DIR}/qrencode "https://${ARGO_DOMAIN}/${UUID}/auto")
EOF

  # Generate configuration file
  EXPORT_LIST_FILE="*******************************************
┌────────────────┐
│                │
│     $(warning "V2rayN")     │
│                │
└────────────────┘
$(info "${V2RAYN_SUBSCRIBE}")

*******************************************
┌────────────────┐
│                │
│  $(warning "ShadowRocket")  │
│                │
└────────────────┘
----------------------------
$(hint "${SHADOWROCKET_SUBSCRIBE}")

*******************************************
┌────────────────┐
│                │
│   $(warning "Clash Verge")  │
│                │
└────────────────┘
----------------------------

$(info "$(sed '1d' <<< "${CLASH_SUBSCRIBE}")")

*******************************************
┌────────────────┐
│                │
│    $(warning "NekoBox")     │
│                │
└────────────────┘
$(hint "${NEKOBOX_SUBSCRIBE}")

*******************************************
┌────────────────┐
│                │
│    $(warning "Sing-box")    │
│                │
└────────────────┘
----------------------------

$(info "$(echo "{ \"outbounds\":[ ${OUTBOUND_REPLACE%,} ] }" | ${WORK_DIR}/jq)

Each client configuration file path: ${WORK_DIR}/subscribe/\n You can refer to the complete template:\n https://github.com/chika0801/sing-box-examples/tree/main/Tun")
"

EXPORT_LIST_FILE+="

*******************************************

$(hint "Index:
https://${ARGO_DOMAIN}/${UUID}/

QR code:
https://${ARGO_DOMAIN}/${UUID}/qr

V2rayN Subscribe:
https://${ARGO_DOMAIN}/${UUID}/v2rayn")

$(hint "NekoBox Subscription:
https://${ARGO_DOMAIN}/${UUID}/neko")

$(hint "Clash Subscribe:
https://${ARGO_DOMAIN}/${UUID}/clash

sing-box subscription:
https://${ARGO_DOMAIN}/${UUID}/sing-box

ShadowRocket Subscribe:
https://${ARGO_DOMAIN}/${UUID}/shadowrocket")

*******************************************

$(info "Adaptive Clash /V2rayN /NekoBox /ShadowRocket /SFI /SFA /SFM Client:
Template:
https://${ARGO_DOMAIN}/${UUID}/auto

 Subscribe QRcode:
Template:
https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=https://${ARGO_DOMAIN}/${UUID}/auto")

$(hint "template:")
$(${WORK_DIR}/qrencode https://${ARGO_DOMAIN}/${UUID}/auto)
"

# Generate and display node information
  echo "$EXPORT_LIST_FILE" > ${WORK_DIR}/list
  cat ${WORK_DIR}/list

  # Display script usage data
  hint "\n**********************************************\n"
  local STAT=$(wget --no-check-certificate -qO---timeout=3 "https://stat.cloudflare.now.cc/api/updateStats?script=sing-box-docker.sh")
  [[ "$STAT" =~ \"todayCount\":([0-9]+),\"totalCount\":([0-9]+) ]] && local TODAY="${BASH_REMATCH[1]}" && local TOTAL="${BASH_REMATCH[2]}"
  hint "\n The number of times the script has been run on the day: $TODAY, the cumulative number of times it has been run: $TOTAL \n"
}
# Latest version of Sing-box
update_sing-box() {
  local ONLINE=$(check_latest_sing-box)
  local LOCAL=$(${WORK_DIR}/sing-box version | awk '/version/{print $NF}')
  if [ -n "$ONLINE" ]; then
    if [[ "$ONLINE" != "$LOCAL" ]]; then
      cp -f ${WORK_DIR}/sing-box /tmp/sing-box.bak
      wget https://github.com/SagerNet/sing-box/releases/download/v$ONLINE/sing-box-$ONLINE-linux-$SING_BOX_ARCH.tar.gz -O- | tar xz -C /tmp sing-box-$ONLINE-linux-$SING_BOX_ARCH/sing-box
      mv /tmp/sing-box-$ONLINE-linux-$SING_BOX_ARCH/sing-box ${WORK_DIR}/sing-box
      local SING_BOX_PID_OLD=$(ps aux | grep '[s]ing-box run' | awk '{print $1}')
      kill -9 ${SING_BOX_PID_OLD}
      sleep 1
      local SING_BOX_PID_NEW=$(ps aux | grep '[s]ing-box run' | awk '{print $1}')
      until [[ "${SING_BOX_PID_NEW}" =~ ^[0-9]+$ ]]; do
        (( i++ ))
        [ "$i" -gt 5 ] && break
        sleep 1
        local SING_BOX_PID_NEW=$(ps aux | grep '[s]ing-box run' | awk '{print $1}')
      done
      if [[ "${SING_BOX_PID_NEW}" =~ ^[0-9]+$ ]]; then
        info " Sing-box v${ONLINE} 更新成功！"
      else
        cp -f /tmp/sing-box.bak ${WORK_DIR}/sing-box
        warning " Sing-box v${ONLINE} 运行不成功，使用回旧版本 v${LOCAL} 更新成功！"
      fi
      rm -rf ${WORK_DIR}/sing-box-$ONLINE-linux-$SING_BOX_ARCH /tmp/sing-box.bak
    else
      info " Sing-box v${ONLINE} 已是最新版本！"
    fi
  else
    warning " Не удалось получить онлайн-версию, повторите попытку позже!"
  fi
}

# Pass parameters
while getopts ":Vv" OPTNAME; do
  case "${OPTNAME,,}" in
    v ) ACTION=update
  esac
done

# Main process
case "$ACTION" in
  update )
    update_sing-box
    ;;
  * )
    install
    # Use s6-overlay as PID 1 bearer daemon
    exec /init
esac
