#!/usr/bin/env bash

# Current script version number
VERSION='v1.3.10 (2026.04.25)'

# Github anti-generation acceleration agent
GITHUB_PROXY=('https://hub.glowp.xyz/' 'https://proxy.vvvv.ee/')

#Default value of each variable
TEMP_DIR='/tmp/sing-box'
WORK_DIR='/etc/sing-box'
FIREWALL_STATE_DIR="${WORK_DIR}/firewall"
SERVICE_FIREWALL_STATE_FILE="${FIREWALL_STATE_DIR}/service_ports.list"
START_PORT_DEFAULT='8881'
MIN_PORT=100
MAX_PORT=65520
MIN_HOPPING_PORT=10000
MAX_HOPPING_PORT=65535
TLS_SERVER_DEFAULT=addons.mozilla.org
PROTOCOL_LIST=("XTLS + reality" "hysteria2" "tuic" "ShadowTLS" "shadowsocks" "trojan" "vmess + ws" "vless + ws + tls" "H2 + reality" "gRPC + reality" "AnyTLS" "naive")
NODE_TAG=("xtls-reality" "hysteria2" "tuic" "ShadowTLS" "shadowsocks" "trojan" "vmess-ws" "vless-ws-tls" "h2-reality" "grpc-reality" "anytls" "naive")
CONSECUTIVE_PORTS=${#PROTOCOL_LIST[@]}
CDN_DOMAIN=("skk.moe" "ip.sb" "time.is" "cfip.xxxxxxxx.tk" "bestcf.top" "cdn.2020111.xyz" "xn--b6gac.eu.org" "cf.090227.xyz")
SUBSCRIBE_TEMPLATE="https://raw.githubusercontent.com/fscarmen/client_template/main"
DEFAULT_NEWEST_VERSION='1.13.0-rc.4'
STEP_NUM=0      # Current step number (incremented dynamically during the installation process)
TOTAL_STEPS=''  # Total number of steps (dynamically calculated after the protocol is determined)

export DEBIAN_FRONTEND=noninteractive

cleanup_temp() {
  rm -rf "$TEMP_DIR"
}

trap cleanup_temp EXIT
trap 'cleanup_temp; printf "\n"; exit 1' INT QUIT TERM

mkdir -p "$TEMP_DIR"

E[0]="Language:\n 1. English (default) \n 2. 简体中文"
C[0]="${E[0]}"
E[1]="Added native protocol, but client support is extremely limited, with Shadowrocket offering the best compatibility. For the sing-box core, you must use the -glibc or -musl version according to the requirements; refer to the official documentation for details: https://sing-box.sagernet.org/configuration/outbound/naive/"
C[1]="Add native protocol. There are very few clients that support this protocol, and Shadowrocket has the best support. The sing-box kernel needs to use the -glibc or -musl version according to the instructions. For details, see the official instructions https://sing-box.sagernet.org/zh/configuration/outbound/naive/"
E[2]="Downloading Sing-box. Please wait a seconds ..."
C[2]="Downloading Sing-box, please wait..."
E[3]="Input errors up to 5 times.The script is aborted."
C[3]="enter error reaches 5 times, script exits"
E[4]="UUID should be 36 characters, please re-enter \(\${UUID_ERROR_TIME} times remaining\):"
C[4]="UUID should be 36 characters, please re-enter \(remaining\${UUID_ERROR_TIME} times\):"
E[5]="The script supports Debian, Ubuntu, CentOS, Alpine, Fedora or Arch systems only. Feedback: [https://github.com/fscarmen/sing-box/issues]"
C[5]="This script only supports Debian, Ubuntu, CentOS, Alpine, Fedora or Arch systems. Problem feedback: [https://github.com/fscarmen/sing-box/issues]"
E[6]="Curren operating system is \$SYS.\\\n The system lower than \$SYSTEM \${MAJOR[int]} is not supported. Feedback: [https://github.com/fscarmen/sing-box/issues]"
C[6]="The current operation is \$SYS\\\n and the following systems \$SYSTEM \${MAJOR[int]} are not supported. Problem feedback: [https://github.com/fscarmen/sing-box/issues]"
E[7]="Install dependence-list:"
C[7]="Installation dependency list:"
E[8]="All dependencies already exist and do not need to be installed additionally."
C[8]="All dependencies already exist, no additional installation is required"
E[9]="To upgrade, press [y]. No upgrade by default:"
C[9]="Please press [y] to upgrade, the default is not to upgrade:"
E[10]="Please enter VPS IP (Default: \${SERVER_IP_DEFAULT}):"
C[10]="Please enter VPS IP (default: \${SERVER_IP_DEFAULT}):"
E[11]="Please enter the starting port number. Must be \${MIN_PORT} -\${MAX_PORT}, consecutive \${NUM} free ports are required (Default: \${START_PORT_DEFAULT}):"
C[11]="Please enter the starting port number, which must be \${MIN_PORT} -\${MAX_PORT}, and requires consecutive \${NUM} idle ports (default: \${START_PORT_DEFAULT}):"
E[12]="Please enter UUID (Default: \${UUID_DEFAULT}):"
C[12]="Please enter UUID (default: \${UUID_DEFAULT}):"
E[13]="Please enter the node name. (Default: \${NODE_NAME_DEFAULT}):"
C[13]="Please enter the node name (default: \${NODE_NAME_DEFAULT}):"
E[14]="Node name only allow uppercase and lowercase letters, numeric characters, hyphens, underscores, dots and @, please re-enter \(\${a} times remaining\):"
C[14]="Node names only allow English upper and lower case, numbers, hyphens, underscores, dots and @ characters. Please re-enter \(remaining\${a} times\):"
E[15]="Sing-box script has not been installed yet."
C[15]="Sing-box script has not been installed yet"
E[16]="Sing-box is completely uninstalled."
C[16]="Sing-box has been completely uninstalled"
E[17]="Version"
C[17]="Script version"
E[18]="New features"
C[18]="New function"
E[19]="System infomation"
C[19]="System information"
E[20]="Operating System"
C[20]="Current operating system"
E[21]="Kernel"
C[21]="kernel"
E[22]="Architecture"
C[22]="Processor architecture"
E[23]="Virtualization"
C[23]="Virtualization"
E[24]="Choose:"
C[24]="Please select:"
E[25]="Curren architecture \$(uname -m) is not supported. Feedback: [https://github.com/fscarmen/sing-box/issues]"
C[25]="The current architecture \$(uname -m) is not supported yet, problem feedback: [https://github.com/fscarmen/sing-box/issues]"
E[26]="Not install"
C[26]="Not installed"
E[27]="close"
C[27]="Close"
E[28]="open"
C[28]="Open"
E[29]="View links (sb -n)"
C[29]="View node information (sb -n)"
E[30]="Listen ports  (current: \${_val})"
C[30]="Listening port  (当前: \${_val})"
E[31]="Sync Sing-box to the latest version (sb -v)"
C[31]="Synchronize Sing-box to the latest version (sb -v)"
E[32]="Upgrade kernel, turn on BBR, change Linux system (sb -b)"
C[32]="Upgrade kernel, install BBR, DD script (sb -b)"
E[33]="Uninstall (sb -u)"
C[33]="Uninstall (sb -u)"
E[34]="Install Sing-box"
C[34]="Install Sing-box"
E[35]="Exit"
C[35]="Exit"
E[36]="Please enter the correct number"
C[36]="Please enter the correct number"
E[37]="successful"
C[37]="Success"
E[38]="failed"
C[38]="Failed"
E[39]="Sing-box is not installed and cannot change the Argo tunnel."
C[39]="Sing-box is not installed, Argo tunnel cannot be replaced"
E[40]="Sing-box local verion: \$LOCAL\\\t The newest verion: \$ONLINE"
C[40]="Sing-box local version: \$LOCAL\\\t latest version: \$ONLINE"
E[41]="No upgrade required."
C[41]="No upgrade required"
E[42]="Downloading the latest version Sing-box failed, script exits. Feedback:[https://github.com/fscarmen/sing-box/issues]"
C[42]="Downloading the latest version of Sing-box failed, the script exited, problem feedback: [https://github.com/fscarmen/sing-box/issues]"
E[43]="The script must be run as root, you can enter sudo -i and then download and run again. Feedback:[https://github.com/fscarmen/sing-box/issues]"
C[43]="The script must be run as root. You can enter sudo -i and re-download and run. Problem feedback: [https://github.com/fscarmen/sing-box/issues]"
E[44]="Ports are in used: \${IN_USED[*]}"
C[44]="Port in use: \${IN_USED[*]}"
E[45]="Ports used: \${NOW_START_PORT} -\$((NOW_START_PORT+NOW_CONSECUTIVE_PORTS-1))"
C[45]="Use port: \${NOW_START_PORT} -\$((NOW_START_PORT+NOW_CONSECUTIVE_PORTS-1))"
E[46]="Warp /warp-go was detected to be running. Please enter the correct server IP:"
C[46]="It is detected that warp /warp-go is running, please enter to confirm the server IP:"
E[47]="No server ip, script exits. Feedback:[https://github.com/fscarmen/sing-box/issues]"
C[47]="No server ip, script exits, problem feedback: [https://github.com/fscarmen/sing-box/issues]"
E[48]="ShadowTLS -Copy the above two Neko links and manually set up the chained proxies in order. Tutorial: https://github.com/fscarmen/sing-box/blob/main/README.md#sekobox-%E8%AE%BE%E7%BD%AE-shadowtls-%E6%96%B9%E6%B3%95"
C[48]="ShadowTLS -Copy the above two Neko links and manually set up the chain proxy in order. Detailed tutorial: https://github.com/fscarmen/sing-box/blob/main/README.md#sekobox-%E8%AE%BE%E7%BD%AE-shadowtls-%E6%96%B9%E6%B3%95"
E[49]="Select more protocols to install (e.g. hgbd). The order of the port numbers of the protocols is related to the ordering of the multiple choices:\n a. all (default)"
C[49]="Multiple selections require the installation of a protocol (such as hgbd). The order of the port numbers of the protocols is related to the sorting of the multiple selections:\n a. all (default)"
E[50]="Please enter the \$TYPE domain name:"
C[50]="Please enter \$TYPE domain name:"
E[51]="Please choose or custom a cdn, http support is required:"
C[51]="Please select or enter cdn to support http:"
E[52]="Please set the ip \[\${WS_SERVER_IP_SHOW}] to domain \[\${TYPE_HOST_DOMAIN}], and set the origin rule to \[\${TYPE_PORT_WS}] in Cloudflare."
C[52]="Please bind the domain name of \[\${WS_SERVER_IP_SHOW}] to \[\${TYPE_HOST_DOMAIN}] in Cloudflare, and set the origin rule to \[\${TYPE_PORT_WS}]"
E[53]="Please select or enter the preferred domain or IP (Default: \${CDN_DOMAIN[0]}):"
C[53]="Please select or fill in the preferred domain name or IP (default: \${CDN_DOMAIN[0]}):"
E[54]="Copy the following full certificate chain:"
C[54]="Copy the following fixed certificate chain"
E[55]="The script runs today: \$TODAY. Total: \$TOTAL"
C[55]="The number of times the script was run on the day: \$TODAY, the cumulative number of times it was run: \$TOTAL"
E[56]="Process ID"
C[56]="Process ID"
E[57]="Selecting the ws return method:\n 1. Argo (default)\n 2. Origin rules"
C[57]="Select the ws back-to-origin method:\n 1. Argo (default)\n 2. Origin rules"
E[58]="Memory Usage"
C[58]="Memory usage"
E[59]="Install ArgoX scripts (argo + xray) [https://github.com/fscarmen/argox]"
C[59]="Install ArgoX script (argo + xray) [https://github.com/fscarmen/argox]"
E[60]="The order of the selected protocols and ports is as follows:"
C[60]="The selected protocol and port order are as follows:"
E[61]="There are no replaceable Argo tunnels."
C[61]="No replaceable Argo tunnel"
E[62]="Add /Remove protocols (sb -r)"
C[62]="Add/Delete Protocol (sb -r)"
E[63]="(1/3) Installed protocols."
C[63]="(1/3) Installed protocols"
E[64]="Please select the protocols to be removed (multiple selections possible. Press Enter to skip):"
C[64]="Please select the protocol to be deleted (multiple selections are allowed, press Enter to skip):"
E[65]="(2/3) Uninstalled protocols."
C[65]="(2/3) Uninstalled protocol"
E[66]="Please select the protocols to be added (multiple choices possible. Press Enter to skip):"
C[66]="Please select the protocol to be added (multiple selections are allowed, press Enter to skip):"
E[67]="(3/3) Confirm all protocols for reloading."
C[67]="(3/3) Confirm all protocols for reinstallation"
E[68]="Press [n] if there is an error, other keys to continue:"
C[68]="If there is an error, please press [n] and continue with other keys:"
E[69]="Install sba scripts (argo + sing-box) [https://github.com/fscarmen/sba]"
C[69]="Install sba script (argo + sing-box) [https://github.com/fscarmen/sba]"
E[70]="Please enter the reality private key (privateKey), skip to generate randomly:"
C[70]="Please enter the reality key (privateKey), skip and randomly generate:"
E[71]="Create shortcut [ sb ] successfully."
C[71]="Create shortcut [ sb ] command successfully!"
E[72]="Path to each client configuration file: ${WORK_DIR}/subscribe/\n The full template can be found at:\n https://github.com/chika0801/sing-box-examples/tree/main/Tun"
C[72]="Configuration file path of each client: ${WORK_DIR}/subscribe/\n For the complete template, please refer to:\n https://github.com/chika0801/sing-box-examples/tree/main/Tun"
E[73]="There is no protocol left, if you are sure please re-run [ sb -u ] to uninstall all."
C[73]="There are no protocols left. If confirmed, please re-execute [sb -u] to uninstall all"
E[74]="Keep protocols"
C[74]="Retention Agreement"
E[75]="Add protocols"
C[75]="New protocol"
E[76]="Install TCP brutal"
C[76]="Install TCP brutal"
E[77]="With sing-box installed, the script exits."
C[77]="sing-box has been installed, the script exits"
E[78]="Parameter [ $ERROR_PARAMETER ] error, script exits."
C[78]="[ $ERROR_PARAMETER ] Parameter error, script exits"
E[79]="Please enter the port number of nginx. Must be \${MIN_PORT} -\${MAX_PORT} (Default: \${PORT_NGINX_DEFAULT}):"
C[79]="Please enter nginx port number, it must be \${MIN_PORT} -\${MAX_PORT} (default: \${PORT_NGINX_DEFAULT}):"
E[80]="subscribe"
C[80]="Subscribe"
E[81]="Adaptive Clash /V2rayN /Throne /ShadowRocket /SFI /SFA /SFM Clients"
C[81]="Adaptive Clash /V2rayN /Throne /ShadowRocket /SFI /SFA /SFM Client"
E[82]="template"
C[82]="template"
E[83]="To uninstall Nginx press [y], it is not uninstalled by default:"
C[83]="If you want to uninstall Nginx, please press [y]. It will not be uninstalled by default:"
E[84]="Set SElinux: enforcing --> disabled"
C[84]="设置 SElinux: enforcing --> disabled"
E[85]="Please enter Argo Token, Argo Json or Cloudflare API\n\n [*] Token: Visit https://dash.cloudflare.com/, Zero Trust > Networks > Connectors > Create a tunnel > Select Cloudflared\n\n [*] Json: Users can easily obtain it through the following website: https://fscarmen.cloudflare.now.cc\n\n [*] Cloudflare API: Visit https://dash.cloudflare.com/profile/api-tokens > Create Token > Create Custom Token > Add the following permissions:\n -Account > Cloudflare One Connectors: cloudflared > Edit\n -Zone > DNS > Edit\n\n -Account Resources: Include > Required Account\n -Zone Resources: Include > Specific zone > Argo Root Domain"
C[85]="Please enter Argo Token, Argo Json or Cloudflare API\n\n [*] Token: Visit https://dash.cloudflare.com/, Zero Trust > Network > Connector > Create Tunnel > Select Cloudflared\n\n [*] Json: Users can easily get it through the following website: https://fscarmen.cloudflare.now.cc\n\n [*] Cloudflare API: Visit https://dash.cloudflare.com/profile/api-tokens > Create token > Create custom token > Add the following permissions:\n -Accounts > Cloudflare One Connector: Cloudflared > Edit\n -Zones > DNS > Edit\n\n -Account resources: Includes > Required accounts\n -Zone resources: Includes > Specific zone > Required domain name"
E[86]="Argo authentication message does not match the rules, neither Token nor Json, script exits. Feedback:[https://github.com/fscarmen/sba/issues]"
C[86]="Argo authentication information does not comply with the rules. It is neither Token nor Json. The script exits. Problem feedback: [https://github.com/fscarmen/sba/issues]"
E[87]="Please input the Argo domain (Default is temporary domain if left blank):"
C[87]="Please enter Argo domain name (if not available, you can skip to use Argo temporary domain name):"
E[88]="Please input the Argo domain (cannot be empty):"
C[88]="Please enter Argo domain name (cannot be empty):"
E[89]="( Additional dependencies: nginx )"
C[89]="(Extra dependency: nginx)"
E[90]="Argo tunnel is: \$ARGO_TYPE\\\n The domain is: \$ARGO_DOMAIN"
C[90]="Argo tunnel type is: \$ARGO_TYPE\\\n domain name is: \$ARGO_DOMAIN"
E[91]="Argo tunnel type:\n 1. Try\n 2. Token or Json. Including created through Cloudflare API"
C[91]="Argo tunnel type:\n 1. Try\n 2. Token or Json, including creation via Cloudflare API"
E[92]="Change the Argo tunnel (sb -t)"
C[92]="Replace Argo Tunnel (sb -t)"
E[93]="Can't get the temporary tunnel domain, script exits. Feedback:[https://github.com/fscarmen/sing-box/issues]"
C[93]="Cannot get the domain name of the temporary tunnel, the script exits, problem feedback: [https://github.com/fscarmen/sing-box/issues]"
E[94]="Please bind \[\${ARGO_DOMAIN}] tunnel TYPE to HTTP and URL to \[\localhost:\${PORT_NGINX}] in Cloudflare."
C[94]="Please bind \[\${ARGO_DOMAIN}] tunnel TYPE to HTTP and URL to \[\localhost:\${PORT_NGINX}] in Cloudflare"
E[95]="netfilter-persistent installation failed, but the installation progress will not stop. portHopping forwarding rules are temporary rules, reboot may be invalidated."
C[95]="netfilter-persistent installation failed, but the installation progress will not stop. PortHopping forwarding rules are temporary rules and may become invalid after restarting"
E[96]="netfilter-persistent is not started, PortHopping forwarding rules cannot be persisted. Reboot the system, the rules will be invalidated, please manually execute [netfilter-persistent save], continue the script does not affect the subsequent configuration."
C[96]="netfilter-persistent is not started, PortHopping forwarding rules cannot be persisted, restart the system, the rules will become invalid, please manually execute [netfilter-persistent save], continuing to run the script will not affect subsequent Configuration"
E[97]="Port Hopping/Multiple: Users sometimes report that their ISPs block or throttle persistent UDP connections. However, these restrictions often only apply to the specific port being used. Port hopping can be used as a workaround for this situation. This function needs to occupy multiple ports, please make sure that these ports are not listening to other services. \n Tip1: The number of ports should not be too many, the recommended number is about 1000, the minimum value: $MIN_HOPPING_PORT, the maximum value: $MAX_HOPPING_PORT.\n Tip2: nat machines have a limited number of ports to listen on, usually 20-30. If setting ports out of the nat range will cause the node to not work, please use with caution!\n This function is not used by default."
C[97]="Introduction to port hopping/multi-port (Port Hopping): Users sometimes report that operators block or limit UDP connections. However, these restrictions are often limited to a single port. Port hopping can be used as a workaround for this situation. This function needs to occupy multiple ports, please ensure that these ports are not monitoring other services\n Tip1: The number of port selections should not be too many, it is recommended to be about 1000, the minimum value: $MIN_HOPPING_PORT, the maximum value: $MAX_HOPPING_PORT\n Tip2: The number of nat chicken ports that can be used for monitoring is limited, generally 20-30. If a closed port is set, the node will be blocked, so please use it with caution! \nThis feature is not used by default"
E[98]="Enter the port range, e.g. 50000:51000. Leave blank to disable:"
C[98]="Please enter the range, such as 50000:51000. If you want to disable it, please leave it blank:"
E[99]="The \${SING_BOX_SCRIPT} is detected to be installed. Script exits."
C[99]="Detected that \${SING_BOX_SCRIPT} has been installed, the script exits!"
E[100]="Can't get the official latest version. Script exits."
C[100]="Get cannot get the latest official version, the script exits!"
E[101]="The privateKey should be a 43-character base64url encoding; please check."
C[101]="privateKey should be 43-bit base64url encoding, please check"
E[102]="Backing up old version sing-box to ${WORK_DIR}/sing-box.bak"
C[102]="Backed up old version of sing-box to ${WORK_DIR}/sing-box.bak"
E[103]="New version \$ONLINE is running successfully, backup file deleted"
C[103]="The new version \$ONLINE runs successfully and the backup file has been deleted"
E[104]="New version failed to run \$ONLINE, restoring old version \$LOCAL ..."
C[104]="The new version \$ONLINE failed to run, and the old version \$LOCAL is being restored..."
E[105]="Successfully restored old version \$LOCAL"
C[105]="Old version \$LOCAL successfully restored"
E[106]="Failed to restore old version \$LOCAL, please check manually"
C[106]="Failed to restore old version \$LOCAL, please check manually"
E[107]="Sing-box is not installed and cannot change the CDN."
C[107]="Sing-box is not installed and CDN cannot be replaced"
E[108]="Change CDN"
C[108]="Change CDN"
E[109]="Current CDN is: \${CDN_NOW}"
C[109]="The current CDN is: \${CDN_NOW}"
E[110]="No CDN protocol is currently in use"
C[110]="There is currently no protocol using CDN"
E[111]="Please select or enter a new CDN (press Enter to keep the current one):"
C[111]="Please select or enter a new CDN (enter to keep the current value):"
E[112]="Change complete, restarting service..."
C[112]="Modification completed, restarting service..."
E[113]="Failed to change CDN, using random privateKey"
C[113]="privateKey format failed too many times, a random private key has been used"
E[114]="Invalid privateKey format: expected a 43-character base64url-encoded string."
C[114]="privateKey private key format error, should be 43-bit base64url encoding"
E[115]="Quick install mode (all protocols + subscription) (sb -k)"
C[115]="Extreme installation mode (all protocols + subscriptions) (sb -l)"
E[116]="Failed to generate publicKey from privateKey, using random privateKey"
C[116]="Failed to generate publicKey from privateKey, random public private key will be used"
E[117]="Continue with quick fast tunnel"
C[117]="Continue using temporary tunnel"
E[118]="Please enter [Token, Json, API] value:"
C[118]="Please enter the value of [Token, Json, API]:"
E[119]="Using Cloudflare API to create Tunnel and handle DNS config..."
C[119]="Use Cloudflare API to create tunnels and handle DNS Configuration..."
E[120]="Found existing tunnel with the same name. Tunnel ID: \$EXISTING_TUNNEL_ID. Status: \$EXISTING_TUNNEL_STATUS. Overwrite? [y/N] (default y):"
C[120]="It was found that a tunnel with the same name has been created, tunnel ID: \$EXISTING_TUNNEL_ID, status: \$EXISTING_TUNNEL_STATUS. Do you want to overwrite it? [y/N] (default is y):"
E[121]="Change node configuration (sb -d)"
C[121]="Modify node Configuration (sb -d)"
E[122]="Invalid access token. Please roll at https://dash.cloudflare.com/profile/api-tokens to re-generate."
C[122]="Token access token is invalid. Please rotate it at https://dash.cloudflare.com/profile/api-tokens to get it again"
E[123]="Token zone resource failed. The tunnel root domain and the authorized domain of the token are inconsistent. Please go to https://dash.cloudflare.com/profile/api-tokens to re-authorize."
C[123]="Token regional resource Get failed. The root domain name of the tunnel is inconsistent with the domain name authorized by the Token. Please check https://dash.cloudflare.com/profile/api-tokens"
E[124]="API does not have enough permissions. Please check at https://dash.cloudflare.com/profile/api-tokens\n\n [*] Token: Visit https://dash.cloudflare.com/ , Zero Trust > Networks > Connectors > Create a tunnel > Select Cloudflared\n\n [*] Json: Users can easily obtain it through the following website: https://fscarmen.cloudflare.now.cc\n\n [*] Cloudflare API: Visit https://dash.cloudflare.com/profile/api-tokens > Create Token > Create Custom Token > Add the following permissions:\n - Account > Cloudflare One Connectors: cloudflared > Edit\n - Zone > DNS > Edit\n\n - Account Resources: Include > Required Account\n - Zone Resources: Include > Specific zone > Argo Root Domain"
C[124]="API does not have sufficient permissions, please check the Token permissions Configuration\n\n [*] Token at https://dash.cloudflare.com/profile/api-tokens\n\n [*] Token: Visit https://dash.cloudflare.com/, Zero Trust > Network > Connector > Create Tunnel > Select Cloudflared\n\n [*] Json: Users can easily get via the following website: https://fscarmen.cloudflare.now.cc\n\n [*] Cloudflare API: Visit https://dash.cloudflare.com/profile/api-tokens > Create Token > Create Custom Token > Add the following permissions:\n -Accounts > Cloudflare One Connector: Cloudflared > Edit\n -Zones > DNS > Edit\n\n -Account Resources: Included > Required Accounts\n -Zone Resources: Included >Specific region >Required domain name"
E[125]="API execution failed. Response: \$RESPONSE"
C[125]="Failed to execute API, return: \$RESPONSE"
E[126]="Network request URL structure is wrong. Missing Zone ID"
C[126]="The network request address (URL) structure is incorrect and the Zone ID is missing"
E[127]="Please select what to modify:"
C[127]="Please select an item to modify:"
E[128]="Preferred CDN (current: \${_val})"
C[128]="Preferred domain name/IP (current: \${_val})"
E[129]="Reality SNI (current: \${_val})"
C[129]="Reality SNI (current: \${_val})"
E[130]="Node name (current: \${_val})"
C[130]="Node name (current: \${_val})"
E[131]="UUID /Password (current: \${_val})"
C[131]="UUID /Password (current: \${_val})"
E[132]="Server IP (current: \${_val})"
C[132]="Server IP (current: \${_val})"
E[133]="Invalid IP address format"
C[133]="IP address format error"
E[134]="Please enter new value (press Enter to skip):"
C[134]="Please enter new value (Enter to skip):"
E[135]="No change was made."
C[135]="No modifications"
E[136]="Installed protocols."
C[136]="Installed protocols"
E[137]="Uninstalled protocols."
C[137]="Protocol not installed"
E[138]="Confirm all protocols for reloading."
C[138]="Confirm all protocols for reinstallation"
E[139]="Hysteria2 Port Hopping (current: \${PORT_HOPPING_RANGE:-disabled}) [leave blank to disable]"
C[139]="Hysteria2 port hopping (current: \${PORT_HOPPING_RANGE:-disabled}) [Leave blank to disable]"
E[140]="Hysteria2 bandwidth (current: up \${HY2_UP_NOW} Mbps, down \${HY2_DOWN_NOW} Mbps)"
C[140]="Hysteria2 bandwidth (current: Uplink \${HY2_UP_NOW} Mbps, Downlink \${HY2_DOWN_NOW} Mbps)"
E[141]="Please enter Hysteria2 client upload speed in Mbps (e.g. 200):"
C[141]="Please enter Hysteria2 client uplink rate Mbps (pure number, such as 200):"
E[142]="Please enter Hysteria2 client download speed in Mbps (e.g. 1000):"
C[142]="Please enter Hysteria2 client downlink rate Mbps (pure number, such as 1000):"
E[143]="Invalid input, please enter a positive integer."
C[143]="Enter is invalid, please enter a positive integer."
E[144]="UFW was detected. PortHopping forwarding rules will be managed by UFW, and iptables /netfilter-persistent will not be installed."
C[144]="UFW detected. PortHopping forwarding rules will be managed by UFW and iptables/netfilter-persistent will no longer be installed"
E[145]="UFW is not active. PortHopping forwarding rules were written, but you should manually enable UFW to make sure the policy is applied."
C[145]="UFW is not active. PortHopping forwarding rules have been written, but it is recommended to manually enable UFW to ensure that the policy takes effect"
E[146]="Failed to update UFW PortHopping forwarding rules. Please check UFW configuration files manually."
C[146]="Updating UFW's PortHopping forwarding rules failed, please manually check the UFW Configuration file"

# Custom font color, read function
warning() { echo -e "\033[31m\033[01m$*\033[0m"; }  # red
error() { echo -e "\033[31m\033[01m$*\033[0m" && exit 1; } # red
info() { echo -e "\033[32m\033[01m$*\033[0m"; }   # green
hint() { echo -e "\033[33m\033[01m$*\033[0m"; }   # yellow
reading() { read -rp "$(info "$1")" "$2"; }

# Preprocessing: Scan the E/C array and record the entry subscripts containing $ into the associative array to avoid starting the grep subprocess every time text() is called
declare -A TEXT_NEEDS_EVAL
for _text_i in "${!E[@]}"; do
  [[ "${E[${_text_i}]}" == *'$'* || "${C[${_text_i}]}" == *'$'* ]] && TEXT_NEEDS_EVAL[${_text_i}]=1
done
unset _text_i

# text <index>: Outputs the string corresponding to the current language. Entries containing $ variables are expanded with eval, and the rest are directly printed with printf
text() {
  local -n _text_arr="${L}" # nameref points to E or C, zero child processes
  local _text_val="${_text_arr[$*]}"
  if [[ -n "${TEXT_NEEDS_EVAL[$*]}" ]]; then
    eval "printf '%s' \"${_text_val}\""
  else
    printf '%s' "${_text_val}"
  fi
}

# Calculate the total number of steps in the installation process based on INSTALL_PROTOCOLS
# sing-box protocol classification: Reality class (b/j/k), Hysteria2(c), WS class (h/i)
calc_install_steps() {
  local _total=5 # Fixed steps: protocol selection, starting port, VPS IP, UUID, node name
  local HAS_REALITY=false HAS_WS=false HAS_HY2=false
  for _P in "${INSTALL_PROTOCOLS[@]}"; do
    [[ "$_P" =~ ^[bjk]$ ]] && HAS_REALITY=true
    [[ "$_P" =~ ^[hi]$ ]] && HAS_WS=true
    [[ "$_P" == 'c' ]] && HAS_HY2=true
  done
  [[ "$IS_SUB" = 'is_sub' || "$IS_ARGO" = 'is_argo' ]] && (( _total++ ))  # nginx port
  $HAS_REALITY && (( _total++ ))                # Reality private key
  $HAS_WS && (( _total++ ))                     # CDN / domain name
  $HAS_HY2 && (( _total++ ))                    # port jump
  [ "$IS_ARGO" = 'is_argo' ] && (( _total++ ))  # Argo domain name
  TOTAL_STEPS=$_total
}

# Check whether Github CDN needs to be enabled. If it can directly connect to api.github.com, do not use it.
check_cdn() {
  local PROXY CODE PID CMD
  local_WAIT_COUNT=120
  localPIDS=()
  local API_URL='https://api.github.com/repos/SagerNet/sing-box/releases'

  # Determine the download tool: wget first, curl second
  if command -v wget >/dev/null 2>&1; then
    CMD='wget'
  elif command -v curl >/dev/null 2>&1; then
    CMD='curl'
  else
    GH_PROXY=''
    return
  fi

  # Get HTTP status code
  get_code() {
    local url=$1
    if [ "$CMD" = 'wget' ]; then
      wget -qT5 -O /dev/null --server-response "$url" 2>&1 | awk '/HTTP\//{code=$2} END{print code}'
    else
      curl -skL -w "%{http_code}" "$url" -o /dev/null
    fi
  }

  # Direct connection detection
  CODE=$(get_code "$API_URL")
  if [ "$CODE" = '200' ]; then
    GH_PROXY=''
    return
  fi

  # Concurrency detection agent
  for PROXY in "${GITHUB_PROXY[@]}"; do
    {
      CODE=$(get_code "${PROXY}${API_URL}")
      [ "$CODE" = '200' ] && [ ! -e "${TEMP_DIR}/cdn_proxy" ] && printf '%s' "$PROXY" > "${TEMP_DIR}/cdn_proxy"
    } &
    PIDS+=("$!")
  done

  # Wait for the first proxy to return 200. If it times out, it will fall back to direct connection to avoid endless waiting.
  while [ ! -e "${TEMP_DIR}/cdn_proxy" ] && [ "$_WAIT_COUNT" -gt 0 ]; do
    sleep 0.05
    (( _WAIT_COUNT-- )) || true
  done

  [ -e "${TEMP_DIR}/cdn_proxy" ] && GH_PROXY=$(cat "${TEMP_DIR}/cdn_proxy") || GH_PROXY=''

  # Clean up background tasks and temporary files
  for PID in "${PIDS[@]}"; do kill "$PID" >/dev/null 2>&1 || true; done
  for PID in "${PIDS[@]}"; do wait "$PID" 2>/dev/null || true; done
  rm -f "${TEMP_DIR}/cdn_proxy"
}

# Check whether chatGPT is unlocked to decide whether to use warp chain proxy or direct out. The judgment here is adapted from https://github.com/lmc999/RegionRestrictionCheck
check_chatgpt() {
  local CHECK_STACK=-$1
  local UA_BROWSER="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
local UA_SEC_CH_UA='"Google Chrome";v="125", "Chromium";v="125", "Not.A/Brand";v="24"'
  wget --help | grep -q '\-\-ciphers' && local IS_CIPHERS=is_ciphers

  # First check API access
  local CHECK_RESULT1=$(wget --timeout=2 --tries=2 --retry-connrefused --waitretry=5 ${CHECK_STACK} -qO- --content-on-error --header='authority: api.openai.com' --header='accept: */*' --header='accept-language: en-US,en;q=0.9' --header='authorization: Bearer null' --header='content-type: application/json' --header='origin: https://platform.openai.com' --header='referer: https://platform.openai.com/' --header="sec-ch-ua: ${UA_SEC_CH_UA}" --header='sec-ch-ua-mobile: ?0' --header='sec-ch-ua-platform: "Windows"' --header='sec-fetch-dest: empty' --header='sec-fetch-mode: cors' --header='sec-fetch-site: same-site' --user-agent="${UA_BROWSER}" 'https://api.openai.com/compliance/cookie_requirements')

  [ -z "$CHECK_RESULT1" ] && grep -qw is_ciphers <<< "$IS_CIPHERS" && local CHECK_RESULT1=$(wget --timeout=2 --tries=2 --retry-connrefused --waitretry=5 ${CHECK_STACK} --ciphers=DEFAULT@SECLEVEL=1 --no-check-certificate -qO- --content-on-error --header='authority: api.openai.com' --header='accept: */*' --header='accept-language: en-US,en;q=0.9' --header='authorization: Bearer null' --header='content-type: application/json' --header='origin: https://platform.openai.com' --header='referer: https://platform.openai.com/' --header="sec-ch-ua: ${UA_SEC_CH_UA}" --header='sec-ch-ua-mobile: ?0' --header='sec-ch-ua-platform: "Windows"' --header='sec-fetch-dest: empty' --header='sec-fetch-mode: cors' --header='sec-fetch-site: same-site' --user-agent="${UA_BROWSER}" 'https://api.openai.com/compliance/cookie_requirements')

  # If the API detection fails or unsupported_country is detected, ban will be returned directly.
  if [ -z "$CHECK_RESULT1" ] || grep -qi 'unsupported_country' <<< "$CHECK_RESULT1"; then
    echo "ban"
    return
  fi

  # After the API detection passes, continue to check web page access
  local CHECK_RESULT2=$(wget --timeout=2 --tries=2 --retry-connrefused --waitretry=5 ${CHECK_STACK} -qO- --content-on-error --header='authority: ios.chat.openai.com' --header='accept: */*;q=0.8,application/signed-exchange;v=b3;q=0.7' --header='accept-language: en-US,en;q=0.9' --header="sec-ch-ua: ${UA_SEC_CH_UA}" --header='sec-ch-ua-mobile: ?0' --header='sec-ch-ua-platform: "Windows"' --header='sec-fetch-dest: document' --header='sec-fetch-mode: navigate' --header='sec-fetch-site: none' --header='sec-fetch-user: ?1' --header='upgrade-insecure-requests: 1' --user-agent="${UA_BROWSER}" https://ios.chat.openai.com/)

  [ -z "$CHECK_RESULT2" ] && grep -qw is_ciphers <<< "$IS_CIPHERS" && local CHECK_RESULT2=$(wget --timeout=2 --tries=2 --retry-connrefused --waitretry=5 ${CHECK_STACK} --ciphers=DEFAULT@SECLEVEL=1 --no-check-certificate -qO- --content-on-error --header='authority: ios.chat.openai.com' --header='accept: */*;q=0.8,application/signed-exchange;v=b3;q=0.7' --header='accept-language: en-US,en;q=0.9' --header="sec-ch-ua: ${UA_SEC_CH_UA}" --header='sec-ch-ua-mobile: ?0' --header='sec-ch-ua-platform: "Windows"' --header='sec-fetch-dest: document' --header='sec-fetch-mode: navigate' --header='sec-fetch-site: none' --header='sec-fetch-user: ?1' --header='upgrade-insecure-requests: 1' --user-agent="${UA_BROWSER}" https://ios.chat.openai.com/)

  # Check the second result
  if [ -z "$CHECK_RESULT2" ] || grep -qi 'VPN' <<< "$CHECK_RESULT2"; then
    echo "ban"
  else
    echo "unlock"
  fi
}

# Statistics of the script’s current day and cumulative number of runs
statistics_of_run_times() {
  local UPDATE_OR_GET=$1
  local SCRIPT=$2
  if grep -q 'update' <<< "$UPDATE_OR_GET"; then
    { wget --no-check-certificate -qO- --timeout=3 "https://stat.cloudflare.now.cc/api/updateStats?script=${SCRIPT}" > $TEMP_DIR/statistics 2>/dev/null || true; }&
  elif grep -q 'get' <<< "$UPDATE_OR_GET"; then
    [ -s $TEMP_DIR/statistics ] && [[ $(cat $TEMP_DIR/statistics) =~ \"todayCount\":([0-9]+),\"totalCount\":([0-9]+) ]] && local TODAY="${BASH_REMATCH[1]}" && local TOTAL="${BASH_REMATCH[2]}" && rm -f $TEMP_DIR/statistics
    hint "\n*******************************************\n\n $(text 55) \n"
  fi
}

# Select Chinese and English language
select_language() {
  if [ -z "$L" ]; then
    if [ -s ${WORK_DIR}/language ]; then
      L=$(cat ${WORK_DIR}/language)
    else
      L=E && hint "\n $(text 0) \n" && reading " $(text 24) " LANGUAGE
      [ "$LANGUAGE" = 2 ] && L=C
    fi
  fi
}

# Convert ASCII code values between letters and numbers
asc() {
  if [[ "$1" = [a-z] ]]; then
    [ "$2" = '++' ] && printf "\\$(printf '%03o' "$(( $(printf "%d" "'$1'") + 1 ))")" || printf "%d" "'$1'"
  else
[[ "$1" =~ ^[0-9]+$ ]] && printf "\\$(printf '%03o' "$1")"
  fi
}

# Include some CDNs from enthusiastic netizens and official websites
input_cdn() {
  echo ""
  for c in "${!CDN_DOMAIN[@]}"; do
    hint " $(( c+1 )). ${CDN_DOMAIN[c]} "
  done

  reading "\n ${TOTAL_STEPS:+(${STEP_NUM}/${TOTAL_STEPS}) }$(text 53) " CUSTOM_CDN
  case "$CUSTOM_CDN" in
    [1-${#CDN_DOMAIN[@]}] )
      CDN="${CDN_DOMAIN[$((CUSTOM_CDN-1))]}"
      ;;
    ?????* )
      CDN="$CUSTOM_CDN"
      ;;
    * )
      CDN="${CDN_DOMAIN[0]}"
  esac
}

# Change preferred domain name /reality SNI /node name /UUID
change_config() {
  [ ! -d "${WORK_DIR}" ] && error " $(text 107) "

  local MENU_IDX=() MENU_KEY=() MENU_VAL=()

  # Preferred CDN
  ls ${WORK_DIR}/conf/*-ws*inbounds.json >/dev/null 2>&1 && local CDN_NOW=$(awk -F '"' '/"CDN"/{print $4; exit}' ${WORK_DIR}/conf/*-ws*inbounds.json) && MENU_IDX+=(128) && MENU_KEY+=(cdn) && MENU_VAL+=("$CDN_NOW")

  # Reality SNI
  ls ${WORK_DIR}/conf/*reality_inbounds.json >/dev/null 2>&1 && local SNI_NOW=$(awk 'match($0, /"server_name"[[:space:]]*:[[:space:]]*"[^"]+"/){gsub(/.*: *"/,""); gsub(/".*/,""); print; exit}' ${WORK_DIR}/conf/*reality_inbounds.json) && MENU_IDX+=(129) && MENU_KEY+=(sni) && MENU_VAL+=("$SNI_NOW")

  # Listening port
  local PORTS_NOW=$(awk -F ':|,' '/"listen_port"/{print $2}' ${WORK_DIR}/conf/*_inbounds.json 2>/dev/null)
  if [ -n "$PORTS_NOW" ]; then
    local PORTS_NOW_START=$(awk 'NR == 1 { min = $0 } { if ($0 < min) min = $0 } END {print min}' <<< "$PORTS_NOW")
    local PORTS_NOW_COUNT=$(awk 'END { print NR }' <<< "$PORTS_NOW")
    local PORTS_NOW_END=$((PORTS_NOW_START + PORTS_NOW_COUNT -1))
    MENU_IDX+=(30) && MENU_KEY+=(ports) && MENU_VAL+=("${PORTS_NOW_START} -${PORTS_NOW_END}")
fi

  # Node name
  local NAME_NOW=$(awk '/"tag"/{gsub(/^.*"tag": *"/,""); gsub(/".*/,""); sub(/ [^ ]*$/,""); print; exit}' ${WORK_DIR}/conf/*_inbounds.json)
  [ -n "$NAME_NOW" ] && MENU_IDX+=(130) && MENU_KEY+=(name) && MENU_VAL+=("$NAME_NOW")

  # UUID / Password
  local UUID_NOW="$(awk -F'"' '/"uuid"[[:space:]]*:[[:space:]]*"/ || /"id"[[:space:]]*:[[:space:]]*"/ {print $4; exit}' ${WORK_DIR}/conf/*_inbounds.json)"
  [ -n "$UUID_NOW" ] && MENU_IDX+=(131) && MENU_KEY+=(uuid) && MENU_VAL+=("$UUID_NOW")

  # Server IP
  ls ${WORK_DIR}/conf/*-ws*inbounds.json >/dev/null 2>&1 && local SERVER_IP_NOW=$(awk -F '"' '/"WS_SERVER_IP_SHOW"/{print $4; exit}' ${WORK_DIR}/conf/*-ws*inbounds.json) || local SERVER_IP_NOW=$(grep -A1 '"tag"' ${WORK_DIR}/list | sed -E '/-ws(-tls)*",$/{N;d}' | awk -F '"' '/"server"/{count++; if (count == 1) {print $4; exit}}')
  [ -n "$SERVER_IP_NOW" ] && MENU_IDX+=(132) && MENU_KEY+=(serverip) && MENU_VAL+=("$SERVER_IP_NOW")

  # Hysteria2 bandwidth and port jump (only displayed when Hysteria2 is installed)
  if ls ${WORK_DIR}/conf/*_${NODE_TAG[1]}_inbounds.json >/dev/null 2>&1; then
    local HY2_LINE=$(grep 'type: hysteria2' ${WORK_DIR}/subscribe/proxies)
    if [[ "$HY2_LINE" =~ up:[[:space:]]*\"([0-9]+)[[:space:]]*Mbps\".*down:[[:space:]]*\"([0-9]+)[[:space:]]*Mbps\" ]]; then
      HY2_UP_NOW="${BASH_REMATCH[1]}"
      HY2_DOWN_NOW="${BASH_REMATCH[2]}"
    elif [[ "$HY2_LINE" =~ down:[[:space:]]*\"([0-9]+)[[:space:]]*Mbps\".*up:[[:space:]]*\"([0-9]+)[[:space:]]*Mbps\" ]]; then
      HY2_DOWN_NOW="${BASH_REMATCH[1]}"
      HY2_UP_NOW="${BASH_REMATCH[2]}"
    fi
    HY2_UP_NOW=${HY2_UP_NOW:-200}
    HY2_DOWN_NOW=${HY2_DOWN_NOW:-1000}

    MENU_IDX+=(140) && MENU_KEY+=(hy2bw) && MENU_VAL+=("${HY2_UP_NOW}/${HY2_DOWN_NOW}")

    check_port_hopping_nat
    MENU_IDX+=(139) && MENU_KEY+=(hy2hopping) && MENU_VAL+=("${PORT_HOPPING_RANGE}")
  fi

  [ "${#MENU_IDX[@]}" -eq 0 ] && error " $(text 110) "

  # Show dynamic menu
  hint "\n $(text 127)\n"
  for _i in "${!MENU_IDX[@]}"; do
    local _val="${MENU_VAL[_i]}"
    local _raw
    eval "_raw=\"\${${L}[${MENU_IDX[_i]}]}\""
    eval "hint \" $(( _i+1 )). ${_raw}\""
  done
  hint ""
  reading " $(text 24) " CHOOSE_NODE_INFO

  if ! [[ "$CHOOSE_NODE_INFO" =~ ^[0-9]+$ ]] || \
     [ "$CHOOSE_NODE_INFO" -lt 1 ] || \
     [ "$CHOOSE_NODE_INFO" -gt "${#MENU_IDX[@]}" ]; then
    info " $(text 135) " && return
  fi

  local IDX=$(( CHOOSE_NODE_INFO - 1 ))
  local KEY="${MENU_KEY[IDX]}"
  local OLD="${MENU_VAL[IDX]}"

  # Special operation routing (without general replacement logic)
  if [ "$KEY" = "ports" ]; then
    change_start_port
    return
  elif [ "$KEY" = "hy2bw" ]; then
    # Modify Hysteria2 bandwidth
    local HY2_UP HY2_DOWN
    while true; do
      reading " $(text 141) " HY2_UP
      [[ "$HY2_UP" =~ ^[1-9][0-9]*$ ]] && break
      warning " $(text 143) "
    done
    while true; do
      reading " $(text 142) " HY2_DOWN
      [[ "$HY2_DOWN" =~ ^[1-9][0-9]*$ ]] && break
      warning " $(text 143) "
    done
sed -i -E "s/(up: \")([0-9]+)( Mbps\")/\1${HY2_UP}\3/g; s/(down: \")([0-9]+)( Mbps\")/\1${HY2_DOWN}\3/g" ${WORK_DIR}/subscribe/proxies
    sync_firewall_rules
    hint " $(text 112) "
    export_list
    return
  elif [ "$KEY" = "hy2hopping" ]; then
    # Modify Hysteria2 port jumping
    check_port_hopping_nat
    local OLD_START="$PORT_HOPPING_START" OLD_END="$PORT_HOPPING_END"
    hint "\n $(text 97) \n"

    local HOPPING_ERROR_TIME=6
    local NEW_RANGE=""
    until [ -n "$IS_HOPPING_SET" ]; do
      if [ -z "$NEW_RANGE" ]; then
        (( HOPPING_ERROR_TIME-- )) || true
        case "$HOPPING_ERROR_TIME" in
          0 ) error "\n $(text 3) \n" ;;
          5 ) reading " $(text 98) " NEW_RANGE ;;
          * ) reading " $(text 98) " NEW_RANGE ;;
        esac
      fi

      # Preprocessing: Unify all delimiters into colons and filter illegal characters
      NEW_RANGE=$(sed 's/[--——:]/:/g' <<< "$NEW_RANGE" | tr -cd '0-9:')

      if [[ -z "$NEW_RANGE" || "${NEW_RANGE,,}" =~ ^(n|no)$ ]]; then
        # Disable port jumping
        [ -n "$OLD_START" ] && [ -n "$OLD_END" ] && del_port_hopping_nat
        unset PORT_HOPPING_START PORT_HOPPING_END PORT_HOPPING_RANGE
        IS_HOPPING_SET=true
      elif [[ "$NEW_RANGE" =~ ^[0-9]{4,5}:[0-9]{4,5}$ ]]; then
        local NEW_START=${NEW_RANGE%:*} NEW_END=${NEW_RANGE#*:}
if [[ "$NEW_START" -lt "$NEW_END" && "$NEW_START" -ge "$MIN_HOPPING_PORT" && "$NEW_END" -le "$MAX_HOPPING_PORT" ]]; then
          # Delete old rules and add new rules
          [ -n "$OLD_START" ] && [ -n "$OLD_END" ] && del_port_hopping_nat
          PORT_HOPPING_START=$NEW_START
          PORT_HOPPING_END=$NEW_END
          PORT_HOPPING_RANGE="$NEW_RANGE"
          local HOPPING_TARGET="$PORT_HOPPING_TARGET"
[ -z "$HOPPING_TARGET" ] && HOPPING_TARGET=$(awk -F '[:,]' '/"listen_port"/{print $2; exit}' ${WORK_DIR}/conf/*_${NODE_TAG[1]}_inbounds.json 2>/dev/null)
          # Silently add port hopping rules without displaying UFW detection and success prompts
          (add_port_hopping_nat "$PORT_HOPPING_START" "$PORT_HOPPING_END" "$HOPPING_TARGET") >/dev/null 2>&1
          IS_HOPPING_SET=true
        else
          warning "\n $(text 36) " && unset NEW_RANGE
        fi
      else
        warning "\n $(text 36) " && unset NEW_RANGE
      fi
    done

    export_list
    return
  fi

  hint ""
  reading " $(text 134) " NEW_VAL
  [ -z "$NEW_VAL" ] && info " $(text 135) " && return

  # Verification of each key
  if [ "$KEY" = "uuid" ]; then
    [[ ! "${NEW_VAL,,}" =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ ]] && error " $(text 4) "
  elif [ "$KEY" = "sni" ]; then
    ssl_certificate "$NEW_VAL"
  elif [ "$KEY" = "serverip" ]; then
    [[ ! "$NEW_VAL" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && [[ ! "$NEW_VAL" =~ ^[0-9a-fA-F:]+$ ]] && error " $(text 133) "
  fi

  # Batch replacement
  hint " $(text 112) "

  if [ "$KEY" = "serverip" ]; then
# There are many forms of IP appearing in Configuration, replace them one by one.
    find ${WORK_DIR} -type f | xargs -P 50 sed -i \
      -e "s|\"server\": \"${OLD}\"|\"server\": \"${NEW_VAL}\"|g" \
      -e "s|WS_SERVER_IP_SHOW\": \"${OLD}\"|WS_SERVER_IP_SHOW\": \"${NEW_VAL}\"|g" \
      2>/dev/null
    # Also update the naked IPs that may appear in text files such as subscribe/list
    find ${WORK_DIR}/subscribe -type f | xargs -P 50 sed -i "s|${OLD}|${NEW_VAL}|g" 2>/dev/null
  else
    find ${WORK_DIR} -type f | xargs -P 50 sed -i "s|${OLD}|${NEW_VAL}|g" 2>/dev/null
  fi

  cmd_systemctl restart sing-box
  sleep 2
  cmd_systemctl status sing-box &>/dev/null && \
    info "\n Sing-box $(text 28) $(text 37) \n" || \
    warning "\n Sing-box $(text 27) $(text 38) \n"

  export_list
}

# Create Argo Tunnel API
create_argo_tunnel() {
  local CLOUDFLARE_API_TOKEN="$1"
  local ARGO_DOMAIN="$2"
  local SERVICE_PORT="$3"
  local TUNNEL_NAME=${ARGO_DOMAIN%%.*}
  local ROOT_DOMAIN=${ARGO_DOMAIN#*.}

  api_error() {
    local RESPONSE="$1"
    local CHECK_ZONE_ID="$2"

    if grep -q '"code":9109,' <<< "$RESPONSE"; then
      warning " $(text 122) " && sleep 2 && return 2
    elif grep -q '"code":7003,' <<< "$RESPONSE"; then
      warning " $(text 126) " && sleep 2 && return 3
    elif grep -q 'check_zone_id' <<< "$CHECK_ZONE_ID" && grep -q '"count":0,' <<< "$RESPONSE"; then
      warning " $(text 123) " && sleep 2 && return 4
    elif grep -q '"code":10000,' <<< "$RESPONSE"; then
      warning " $(text 124) " && sleep 2 && return 1
    elif grep -q '"success":true' <<< "$RESPONSE"; then
      return 0
    else
      warning " $(text 125) " && sleep 2 && return 5
    fi
  }

  # Step 1: Get Zone ID and Account ID
  local ZONE_RESPONSE=$(wget --no-check-certificate -qO- --content-on-error \
    --header="Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    --header="Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones?name=${ROOT_DOMAIN}")

  api_error "$ZONE_RESPONSE" 'check_zone_id' || return $?

  [[ "$ZONE_RESPONSE" =~ \"id\":\"([^\"]+)\".*\"account\":\{\"id\":\"([^\"]+)\" ]] && local ZONE_ID="${BASH_REMATCH[1]}" ACCOUNT_ID="${BASH_REMATCH[2]}" || \
  return 5

  # Step 2: Query and process existing tunnels
  local TUNNEL_LIST=$(wget --no-check-certificate -qO---content-on-error \
    --header="Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    --header="Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/cfd_tunnel?is_deleted=false")

  api_error "$TUNNEL_LIST" || return $?
local TUNNEL_LIST_SPLIT=$(awk 'BEGIN{RS="";FS=""}{s=substr($0,index($0,"\"result\":[")+10);d=0;b="";for(i=1;i<=length(s);i++){c=substr(s,i,1);if(c=="{")d++;if(d>0)b=b c;if(c=="}"){d--;if(d==0){print b;b=""}}}}' <<< "$TUNNEL_LIST")

  # Check whether a tunnel with the same name exists
  while true; do
    unset TUNNEL_CHECK EXISTING_TUNNEL_ID EXISTING_TUNNEL_STATUS
    local TUNNEL_CHECK=$(grep '\"name\":\"'$TUNNEL_NAME'\"' <<< "$TUNNEL_LIST_SPLIT")
    if [[ "$TUNNEL_CHECK" =~ \"id\":\"([^\"]+)\".*\"status\":\"([^\"]+)\" ]]; then
      local EXISTING_TUNNEL_ID=${BASH_REMATCH[1]} EXISTING_TUNNEL_STATUS=${BASH_REMATCH[2]}
      # Handle localization of status display
      grep -qw 'C' <<< "$L" && EXISTING_TUNNEL_STATUS=$(sed 's/inactive/inactive/; s/down/offline/; s/healthy/connecting/; s/degraded/degraded/' <<< "$EXISTING_TUNNEL_STATUS")
      reading "\n $(text 120) " OVERWRITE
      if grep -qw 'n' <<< "${OVERWRITE,,}"; then
        # Ask the user to enter another domain name prefix
        unset ARGO_DOMAIN
        reading "\n $(text 87) " ARGO_DOMAIN

        # The user presses Enter directly, uses the temporary domain name, and exits the current process.
        ! grep -q '\.' <<< "$ARGO_DOMAIN" && return 5
# Update TUNNEL_NAME and ROOT_DOMAIN, the loop will automatically check the new name
        TUNNEL_NAME=${ARGO_DOMAIN%%.*}
        ROOT_DOMAIN=${ARGO_DOMAIN#*.}
      else
        # If the user chooses to overwrite, the loop will be broken out and the creation process will continue.
        break
      fi
    else
      # If the new domain name does not exist, jump out of the loop and continue the creation process.
      unset TUNNEL_CHECK EXISTING_TUNNEL_ID EXISTING_TUNNEL_STATUS
      break
    fi
  done

  # If the tunnel with the same name does not exist, create it first
  if grep -q '^$' <<< "$EXISTING_TUNNEL_ID"; then
    # generate Tunnel Secret (at least 32 bytes base64 encoded)
    local TUNNEL_SECRET=$(openssl rand -base64 32)

    #Create new Tunnel
    local CREATE_RESPONSE=$(wget --no-check-certificate -qO- --content-on-error \
      --header="Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      --header="Content-Type: application/json" \
      --post-data="{
        \"name\": \"$TUNNEL_NAME\",
        \"config_src\": \"cloudflare\",
        \"tunnel_secret\": \"$TUNNEL_SECRET\"
      }" \
      "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/cfd_tunnel")

    api_error "$CREATE_RESPONSE" || return $?

    [[ $CREATE_RESPONSE =~ \"id\":\"([^\"]+)\".*\"token\":\"([^\"]+)\" ]] && \
    local TUNNEL_ID=${BASH_REMATCH[1]} TUNNEL_TOKEN=${BASH_REMATCH[2]} || \
    return 5
  else
    # If there is a Tunnel with the same name (EXISTING_TUNNEL_ID is not empty), get its TOKEN
    local EXISTING_TUNNEL_TOKEN=$(wget -qO---content-on-error \
      --header="Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      --header="Content-Type: application/json" \
      "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/cfd_tunnel/${EXISTING_TUNNEL_ID}/token")

    api_error "$EXISTING_TUNNEL_TOKEN" || return $?

    local TUNNEL_ID=$EXISTING_TUNNEL_ID \
TUNNEL_TOKEN=$(sed -n 's/.*"result":"\([^"]\+\)".*/\1/p' <<< "$EXISTING_TUNNEL_TOKEN") && \
    TUNNEL_SECRET=$(base64 -d <<< "$TUNNEL_TOKEN" | sed 's/.*"s":"\([^"]\+\)".*/\1/') || \
    return 5
  fi

  # Step 3: Configuration Tunnel ingress rules... Regardless of the original rules, one-rate coverage processing
 local CONFIG_RESPONSE=$(wget --no-check-certificate -qO- --content-on-error \
  --method=PUT \
  --header="Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  --header="Content-Type: application/json" \
  --body-data="{
    \"config\": {
      \"ingress\": [
        {
          \"service\": \"http://localhost:${SERVICE_PORT}\",
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

  api_error "$CONFIG_RESPONSE" || return $?

  # Step 4: Manage DNS records
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
    --header="Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    --header="Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=CNAME&name=${ARGO_DOMAIN}")

  api_error "$DNS_LIST" || return $?

  # If the required DNS record already exists, skip it
  if [[ "$DNS_LIST" =~ \"id\":\"([^\"]+)\".*\"$ARGO_DOMAIN\".*\"content\":\"([^\"]+)\" ]]; then
    local EXISTING_DNS_ID="${BASH_REMATCH[1]}" EXISTED_DNS_CONTENT="${BASH_REMATCH[2]}"

    # If the DNS record does not match the tunnel ID, overwrite the original CNAME record
    if ! grep -qw "$EXISTING_TUNNEL_ID" <<< "${EXISTED_DNS_CONTENT%%.*}"; then
      local DNS_RESPONSE=$(wget --no-check-certificate -qO---content-on-error \
        --method=PATCH \
--header="Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        --header="Content-Type: application/json" \
        --body-data="$DNS_PAYLOAD" \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${EXISTING_DNS_ID}")

      api_error "$DNS_RESPONSE" || return $?
    fi
  else
    # Existing DNS record not found, created using POST
    local DNS_RESPONSE=$(wget --no-check-certificate -qO- --content-on-error \
      --method=POST \
      --header="Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      --header="Content-Type: application/json" \
      --body-data="$DNS_PAYLOAD" \
      "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records")

    api_error "$DNS_RESPONSE" || return $?
  fi

  # Return Argo Tunnel Token or Json
  ARGO_JSON="{\"AccountTag\":\"$ACCOUNT_ID\",\"TunnelSecret\":\"$TUNNEL_SECRET\",\"TunnelID\":\"$TUNNEL_ID\",\"Endpoint\":\"\"}"
  ARGO_TOKEN="$TUNNEL_TOKEN"
}

# enter Nginx service port
input_nginx_port() {
  local NUM=$1
  localPORT_ERROR_TIME=6
  # generate 1000 -65535 random default port number
  local PORT_NGINX_DEFAULT=$(shuf -i ${MIN_PORT}-${MAX_PORT} -n 1)
  [[ "$IS_FAST_INSTALL" = 'is_fast_install' && -z "$PORT_NGINX" ]] && PORT_NGINX="$PORT_NGINX_DEFAULT"
  while true; do
    [[ "$PORT_ERROR_TIME" > 1 && "$PORT_ERROR_TIME" < 6 ]] && unset IN_USED PORT_NGINX
    (( PORT_ERROR_TIME-- )) || true
    if [ "$PORT_ERROR_TIME" = 0 ]; then
      error "\n $(text 3) \n"
    else
      [ -z "$PORT_NGINX" ] && reading "\n ${TOTAL_STEPS:+(${STEP_NUM}/${TOTAL_STEPS}) }$(text 79) " PORT_NGINX
    fi
    PORT_NGINX=${PORT_NGINX:-"$PORT_NGINX_DEFAULT"}
    if [[ "$PORT_NGINX" =~ ^[1-9][0-9]{1,4}$ && "$PORT_NGINX" -ge "$MIN_PORT" && "$PORT_NGINX" -le "$MAX_PORT" ]]; then
      ss -nltup | grep -q ":$PORT_NGINX" && warning "\n $(text 44) \n" || break
    fi
  done
}

# enter hysteria2 jump port
input_hopping_port() {
  local HOPPING_ERROR_TIME=6
  until [ -n "$IS_HOPPING" ]; do
    if [ -z "$PORT_HOPPING_RANGE" ]; then
      (( HOPPING_ERROR_TIME-- )) || true
      case "$HOPPING_ERROR_TIME" in
        0 )
          error "\n $(text 3) \n"
          ;;
        5 )
          hint "\n $(text 97) \n" && reading " ${TOTAL_STEPS:+(${STEP_NUM}/${TOTAL_STEPS}) }$(text 98) " PORT_HOPPING_RANGE
          ;;
        * )
          reading " ${TOTAL_STEPS:+(${STEP_NUM}/${TOTAL_STEPS}) }$(text 98) " PORT_HOPPING_RANGE
      esac
    fi

    # Preprocessing: full-width colons/dashes are uniformly replaced with half-width characters, and illegal characters are filtered out
    PORT_HOPPING_RANGE=$(sed 's/[-－—：]/:/g' <<< "$PORT_HOPPING_RANGE" | tr -cd '0-9:')

    if [[ "$PORT_HOPPING_RANGE" =~ ^[0-9]{4,5}:[0-9]{4,5}$ ]]; then
      PORT_HOPPING_START=${PORT_HOPPING_RANGE%:*}
      PORT_HOPPING_END=${PORT_HOPPING_RANGE#*:}
      if [[ "$PORT_HOPPING_START" -lt "$PORT_HOPPING_END" && \
            "$PORT_HOPPING_START" -ge "$MIN_HOPPING_PORT" && \
            "$PORT_HOPPING_END" -le "$MAX_HOPPING_PORT" ]]; then
        IS_HOPPING=is_hopping
      else
        warning "\n $(text 114) " && unset PORT_HOPPING_RANGE
      fi
    elif [[ -z "$PORT_HOPPING_RANGE" || "${PORT_HOPPING_RANGE,,}" =~ ^(n|no)$ ]]; then
      IS_HOPPING=no_hopping
    else
      warning "\n $(text 36) " && unset PORT_HOPPING_RANGE
    fi
  done
}

# Enter Reality Key
input_reality_key() {
  [[ "$NONINTERACTIVE_INSTALL" != 'noninteractive_install' && "$IS_FAST_INSTALL" != 'is_fast_install' ]] && [ -z "$REALITY_PRIVATE" ] && reading "\n ${TOTAL_STEPS:+(${STEP_NUM}/${TOTAL_STEPS}) }$(text 70) " REALITY_PRIVATE
  [ -z "$REALITY_PRIVATE" ] && unset REALITY_PRIVATE && return

  local PRIVATEKEY_ERROR_TIME=5
  until [[ "$REALITY_PRIVATE" =~ ^[A-Za-z0-9_-]{43}$ || -z "$REALITY_PRIVATE" ]]; do
    (( PRIVATEKEY_ERROR_TIME-- )) || true
    [ "$PRIVATEKEY_ERROR_TIME" = 0 ] && unset REALITY_PRIVATE && hint "\n $(text 113) \n" && break
    warning "\n $(text 114) "
    reading "\n $(text 70) " REALITY_PRIVATE
    # Even if REALITY_PRIVATE is empty, the number of REALITY_PRIVATE arrays ${REALITY_PRIVATE[@]} is 1, which affects subsequent processing, so it must be left empty.
    [ -z "$REALITY_PRIVATE" ] && unset REALITY_PRIVATE && break
  done
}

# Enter Argo domain name and authentication information
input_argo_auth() {
  local IS_CHANGE_ARGO=$1
  [ -n "$IS_CHANGE_ARGO" ] && local EMPTY_ERROR_TIME=5
  local DOMAIN_ERROR_TIME=6 ARGO_AUTH_LENGTH=40

  # Handle possible input errors, remove leading and trailing spaces, remove the last :
  if [ "$IS_CHANGE_ARGO" = 'is_change_argo' ]; then
    until [ -n "$ARGO_DOMAIN" ]; do
      (( EMPTY_ERROR_TIME-- )) || true
      [ "$EMPTY_ERROR_TIME" = 0 ] && error "\n $(text 3) \n"
      reading "\n $(text 88) " ARGO_DOMAIN
      [ -n "$IS_CHANGE_ARGO" ] && ARGO_DOMAIN=$(sed 's/[ ]*//g; s/:[ ]*//' <<< "$ARGO_DOMAIN")
    done
  elif [[ "$NONINTERACTIVE_INSTALL" != 'noninteractive_install' && "$IS_FAST_INSTALL" != 'is_fast_install' ]]; then
    [ -z "$ARGO_DOMAIN" ] && reading "\n ${TOTAL_STEPS:+(${STEP_NUM}/${TOTAL_STEPS}) }$(text 87) " ARGO_DOMAIN
    ARGO_DOMAIN=$(sed 's/[ ]*//g; s/:[ ]*//' <<< "$ARGO_DOMAIN")
  fi

  if [[ ( -z "$ARGO_DOMAIN" || "$ARGO_DOMAIN" =~ trycloudflare\.com$ ) && ( "$IS_CHANGE_ARGO" = 'is_add_protocols' || "$IS_CHANGE_ARGO" = 'is_install' || "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ) ]]; then
    ARGO_RUNS="${WORK_DIR}/cloudflared tunnel --edge-ip-version auto --no-autoupdate --url http://localhost:$PORT_NGINX"
  elif [ -n "${ARGO_DOMAIN}" ]; then
    if [ -z "${ARGO_AUTH}" ]; then
      until [[ "$ARGO_AUTH" =~ TunnelSecret || "$ARGO_AUTH" =~ [A-Z0-9a-z=]{150,250}$ || "${#ARGO_AUTH}" = $ARGO_AUTH_LENGTH ]]; do
        [ "$DOMAIN_ERROR_TIME" != 6 ] && warning "\n $(text 86) \n"
      (( DOMAIN_ERROR_TIME-- )) || true
        [ "$DOMAIN_ERROR_TIME" != 0 ] && hint "\n $(text 85) \n " && reading "\n $(text 118) " ARGO_AUTH || error "\n $(text 3) \n"
      done
    fi

    # Based on the content of ARGO_AUTH, decide whether it is Json, Token or API application.
    if [[ "$ARGO_AUTH" =~ TunnelSecret ]]; then
      ARGO_TYPE=is_json_argo
      ARGO_JSON=${ARGO_AUTH//[ ]/}
      [ "$IS_CHANGE_ARGO" = 'is_install' ] && export_argo_json_file $TEMP_DIR || export_argo_json_file ${WORK_DIR}
      ARGO_RUNS="${WORK_DIR}/cloudflared tunnel --edge-ip-version auto --config ${WORK_DIR}/tunnel.yml run"
    elif [[ "${ARGO_AUTH}" =~ [A-Z0-9a-z=]{150,250}$ ]]; then
      ARGO_TYPE=is_token_argo
      ARGO_TOKEN=$(awk '{print $NF}' <<< "$ARGO_AUTH")
      ARGO_RUNS="${WORK_DIR}/cloudflared tunnel --edge-ip-version auto run --token ${ARGO_TOKEN}"
    elif [[ "${#ARGO_AUTH}" = $ARGO_AUTH_LENGTH ]]; then
      hint "\n $(text 119) \n "
      create_argo_tunnel "${ARGO_AUTH}" "${ARGO_DOMAIN}" "${PORT_NGINX}"
      if [[ "$ARGO_JSON" =~ TunnelSecret ]]; then
        ARGO_TYPE=is_json_argo
        [ "$IS_CHANGE_ARGO" = 'is_install' ] && export_argo_json_file $TEMP_DIR || export_argo_json_file ${WORK_DIR}
        ARGO_RUNS="${WORK_DIR}/cloudflared tunnel --edge-ip-version auto --config ${WORK_DIR}/tunnel.yml run"
      elif [ "${#ARGO_TOKEN}" = 180 ]; then
        ARGO_TYPE=is_token_argo
        ARGO_RUNS="${WORK_DIR}/cloudflared tunnel --edge-ip-version auto run --token ${ARGO_TOKEN}"
      else
        # Failed to create tunnel, fell back to using temporary tunnel
        hint "\n $(text 117) \n "
        unset ARGO_DOMAIN
        ARGO_RUNS="${WORK_DIR}/cloudflared tunnel --edge-ip-version auto --no-autoupdate --url http://localhost:$PORT_NGINX"
      fi
    fi
  fi
}

# Change Argo tunnel type
change_argo() {
  check_install
  if [ "${STATUS[0]}" = "$(text 26)" ]; then
    error "\n $(text 39) "
  elif [ "${STATUS[1]}" = "$(text 26)" ]; then
    error "\n $(text 61) "
  fi

  # Check Argo service Configuration according to system type
  local ARGO_CONFIG=$(grep -E '^(command_args=|ExecStart=)' ${ARGO_DAEMON_FILE})

  case "$ARGO_CONFIG" in
    *--config* )
      ARGO_TYPE='Json'
      ;;
    *--token* )
      ARGO_TYPE='Token'
      ;;
    * )
      ARGO_TYPE='Try'
      cmd_systemctl enable argo && sleep 2 && cmd_systemctl status argo &>/dev/null && fetch_quicktunnel_domain
  esac

  fetch_nodes_value
  hint "\n $(text 90) \n"
  unset ARGO_DOMAIN
  hint " $(text 91) \n" && reading " $(text 24) " CHANGE_TO

  case "$CHANGE_TO" in
    1 )
      cmd_systemctl disable argo
      [ -s ${WORK_DIR}/tunnel.json ] && rm -f ${WORK_DIR}/tunnel.{json,yml}

      # Modify the Configuration file according to the system type
      [ "$SYSTEM" = 'Alpine' ] && sed -i "s@^command_args=.*@command_args=\"--edge-ip-version auto --no-autoupdate --url http://localhost:$PORT_NGINX\"@g" ${ARGO_DAEMON_FILE} || sed -i "s@ExecStart=.*@ExecStart=${WORK_DIR}/cloudflared tunnel --edge-ip-version auto --no-autoupdate --url http://localhost:$PORT_NGINX@g" ${ARGO_DAEMON_FILE}
      ;;
    2 )
      [ -s ${WORK_DIR}/tunnel.json ] && rm -f ${WORK_DIR}/tunnel.{json,yml}
      input_argo_auth is_change_argo
cmd_systemctl disable argo

      if [ -n "$ARGO_TOKEN" ]; then
        [ "$SYSTEM" = 'Alpine' ] && sed -i "s@^command_args=.*@command_args=\"--edge-ip-version auto run --token ${ARGO_TOKEN}\"@g" ${ARGO_DAEMON_FILE} || sed -i "s@ExecStart=.*@ExecStart=${WORK_DIR}/cloudflared tunnel --edge-ip-version auto run --token ${ARGO_TOKEN}@g" ${ARGO_DAEMON_FILE}
      elif [ -n "$ARGO_JSON" ]; then
[ "$SYSTEM" = 'Alpine' ] && sed -i "s@^command_args=.*@command_args=\"--edge-ip-version auto --config ${WORK_DIR}/tunnel.yml run\"@g" ${ARGO_DAEMON_FILE} || sed -i "s@ExecStart=.*@ExecStart=${WORK_DIR}/cloudflared tunnel --edge-ip-version auto --config ${WORK_DIR}/tunnel.yml run@g" ${ARGO_DAEMON_FILE}
      fi

      # Update the domain name in the relevant Configuration file
      [ -s ${WORK_DIR}/conf/17_${NODE_TAG[6]}_inbounds.json ] && sed -i "s/VMESS_HOST_DOMAIN.*/VMESS_HOST_DOMAIN\": \"$ARGO_DOMAIN\"/" ${WORK_DIR}/conf/17_${NODE_TAG[6]}_inbounds.json
      [ -s ${WORK_DIR}/conf/18_${NODE_TAG[7]}_inbounds.json ] && sed -i "s/\"server_name\":.*/\"server_name\": \"$ARGO_DOMAIN\",/" ${WORK_DIR}/conf/18_${NODE_TAG[7]}_inbounds.json
      ;;
    * )
      exit 0
  esac

  # Enable Argo service
  cmd_systemctl enable argo

  # Update node information and Configuration
  fetch_nodes_value
  export_nginx_conf_file
  export_list
}

check_root() {
  [ "$(id -u)" != 0 ] && error "\n $(text 43) \n"
}

# Determine processor architecture
check_arch() {
  [ "$SYSTEM" = 'Alpine' ] && local IS_MUSL='-musl'

  case "$(uname -m)" in
    aarch64|arm64 )
      SING_BOX_ARCH=arm64${IS_MUSL}; JQ_ARCH=arm64; QRENCODE_ARCH=arm64; ARGO_ARCH=arm64
      ;;
    x86_64|amd64 )
      SING_BOX_ARCH=amd64${IS_MUSL}; JQ_ARCH=amd64; QRENCODE_ARCH=amd64; ARGO_ARCH=amd64
      ;;
    armv7l )
      SING_BOX_ARCH=armv7${IS_MUSL}; JQ_ARCH=armhf; QRENCODE_ARCH=arm; ARGO_ARCH=arm
      ;;
    * )
      error " $(text 25) "
  esac
}

# Check whether the system has tcp-brutal installed
check_brutal() {
  IS_BRUTAL=false && command -v lsmod >/dev/null 2>&1 && lsmod 2>/dev/null | grep -q 'brutal' && IS_BRUTAL=true
  [ "$IS_BRUTAL" = 'false' ] && command -v modprobe >/dev/null 2>&1 && modprobe brutal 2>/dev/null && IS_BRUTAL=true
}

# Check the installation and running status, subscript 0: sing-box, subscript 1: argo, subscript 2: nginx; status code: 26 not installed, 27 installed but not running, 28 running
check_install() {
  local PS_LIST=$(ps -eo pid,args | grep -E "$WORK_DIR.*([s]ing-box|[c]loudflared|[n]ginx)" | sed 's/^[ ]\+//g')

  [[ "$IS_SUB" = 'is_sub' || -s ${WORK_DIR}/subscribe/qr ]] && IS_SUB=is_sub || IS_SUB=no_sub
  if ls ${WORK_DIR}/conf/*${NODE_TAG[1]}_inbounds.json >/dev/null 2>&1; then
    check_port_hopping_nat
    [ -n "$PORT_HOPPING_END" ] && IS_HOPPING=is_hopping || IS_HOPPING=no_hopping
  fi

  if [ "$SYSTEM" = 'Alpine' ]; then
    # Alpine systems use OpenRC inspection services
    if [ -s ${SINGBOX_DAEMON_FILE} ]; then
      local OPENRC_EXECSTART=$(grep '^command=' ${SINGBOX_DAEMON_FILE})
      case "$OPENRC_EXECSTART" in
        *"${WORK_DIR}/sing-box"* )
          if rc-service sing-box status &>/dev/null; then
            STATUS[0]=$(text 28)
          else
            STATUS[0]=$(text 27)
          fi
          ;;
        * )
          SING_BOX_SCRIPT='Unknown or customized sing-box' && error "\n $(text 99) \n"
      esac
    else
      STATUS[0]=$(text 26)
    fi
  else
    # Non-Alpine systems use systemd to check the service
    if [ -s ${SINGBOX_DAEMON_FILE} ]; then
      SYSTEMD_EXECSTART=$(grep '^ExecStart=' ${SINGBOX_DAEMON_FILE})
      case "$SYSTEMD_EXECSTART" in
        "ExecStart=${WORK_DIR}/sing-box run -C ${WORK_DIR}/conf/" | "ExecStart=${WORK_DIR}/sing-box run -C ${WORK_DIR}/conf" )
          [ "$(systemctl is-active sing-box)" = 'active' ] && STATUS[0]=$(text 28) || STATUS[0]=$(text 27)
          ;;
        'ExecStart=/etc/v2ray-agent/sing-box/sing-box run -c /etc/v2ray-agent/sing-box/conf/config.json' )
          SING_BOX_SCRIPT='mack-a/v2ray-agent' && error "\n $(text 99) \n"
          ;;
        'ExecStart=/etc/s-box/sing-box run -c /etc/s-box/sb.json' )
          SING_BOX_SCRIPT='yonggekkk/sing-box_hysteria2_tuic_argo_reality' && error "\n $(text 99) \n"
          ;;
        'ExecStart=/usr/local/s-ui/bin/runSingbox.sh' )
          SING_BOX_SCRIPT='alireza0/s-ui' && error "\n $(text 99) \n"
          ;;
        'ExecStart=/usr/local/bin/sing-box run -c /usr/local/etc/sing-box/config.json' )
          SING_BOX_SCRIPT='FranzKafkaYu/sing-box-yes' && error "\n $(text 99) \n"
          ;;
        * )
          # Check if it was installed by your own script, but with a slightly different path
          if [[ "$SYSTEMD_EXECSTART" =~ "ExecStart=${WORK_DIR}/sing-box run" ]]; then
            [ "$(systemctl is-active sing-box)" = 'active' ] && STATUS[0]=$(text 28) || STATUS[0]=$(text 27)
          else
            SING_BOX_SCRIPT='Unknown or customized sing-box' && error "\n $(text 99) \n"
          fi
      esac
    elif [ -s /lib/systemd/system/sing-box.service ]; then
      SYSTEMD_EXECSTART=$(grep '^ExecStart=' /lib/systemd/system/sing-box.service)
      case "$SYSTEMD_EXECSTART" in
        'ExecStart=/etc/sing-box/bin/sing-box run -c /etc/sing-box/config.json -C /etc/sing-box/conf' )
          SING_BOX_SCRIPT='233boy/sing-box' && error "\n $(text 99) \n"
          ;;
        * )
          # Check if it was installed by your own script, but with a slightly different path
          if [[ "$SYSTEMD_EXECSTART" =~ "ExecStart=${WORK_DIR}/sing-box run" ]]; then
            [ "$(systemctl is-active sing-box)" = 'active' ] && STATUS[0]=$(text 28) || STATUS[0]=$(text 27)
          else
            SING_BOX_SCRIPT='Unknown or customized sing-box' && error "\n $(text 99) \n"
          fi
      esac
    else
      STATUS[0]=$(text 26)
    fi
  fi

  # Concurrently download subscription templates (clash, clash2, sing-box-template), which will be used during new installations and protocol changes
  {
    wget --no-check-certificate --continue -qO $TEMP_DIR/clash ${GH_PROXY}${SUBSCRIBE_TEMPLATE}/clash 2>/dev/null &
    wget --no-check-certificate --continue -qO $TEMP_DIR/clash2 ${GH_PROXY}${SUBSCRIBE_TEMPLATE}/clash2 2>/dev/null &
    wget --no-check-certificate --continue -qO $TEMP_DIR/sing-box-template ${GH_PROXY}${SUBSCRIBE_TEMPLATE}/sing-box 2>/dev/null &
    wait
  } &

  # If necessary, download sing-box silently in the background
if [ "${STATUS[0]}" = "$(text 26)" ] && [ ! -s ${WORK_DIR}/sing-box ]; then
    # Task 1: Download sing-box
    {
      local ONLINE=$(get_sing_box_version)
      local SB_DIR="$TEMP_DIR/sing-box-$ONLINE-linux-$SING_BOX_ARCH"
      local SB_BIN="$SB_DIR/sing-box"
      wget --no-check-certificate --continue \
        ${GH_PROXY}https://github.com/SagerNet/sing-box/releases/download/v$ONLINE/sing-box-$ONLINE-linux-$SING_BOX_ARCH.tar.gz \
        -qO- | tar xz -C $TEMP_DIR 2>/dev/null
      [ -s "$SB_BIN" ] && [ -x "$SB_BIN" ] && mv "$SB_BIN" "$TEMP_DIR/sing-box" && chmod +x "$TEMP_DIR/sing-box"
    } &

    # Task 2: Download jq
    {
      wget --no-check-certificate --continue -qO $TEMP_DIR/jq \
        ${GH_PROXY}https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-$JQ_ARCH 2>/dev/null \
        && chmod +x $TEMP_DIR/jq
    } &

    # Task 3: Download qrencode
    {
      wget --no-check-certificate --continue -qO $TEMP_DIR/qrencode \
        ${GH_PROXY}https://github.com/fscarmen/client_template/raw/main/qrencode-go/qrencode-go-linux-$QRENCODE_ARCH 2>/dev/null \
&& chmod +x $TEMP_DIR/qrencode
    } &

  elif [ "${STATUS[0]}" != "$(text 26)" ]; then
    # Check the sing-box process number, running time, memory usage, and occupied ports
    SING_BOX_VERSION="Version: $(${WORK_DIR}/sing-box version | awk '/version/{print $NF}')"
    [ "${STATUS[0]}" = "$(text 28)" ] && SING_BOX_PID=$(awk '/sing-box run/{print $1}' <<< "$PS_LIST") && [[ "$SING_BOX_PID" =~ ^[0-9]+$ ]] && SING_BOX_MEMORY_USAGE="$(text 58): $(awk '/VmRSS/{printf "%.1f\n", $2/1024}' /proc/$SING_BOX_PID/status) MB"

    NOW_PORTS=$(awk -F ':|,' '/listen_port/{print $2}' ${WORK_DIR}/conf/*)
    NOW_START_PORT=$(awk 'NR == 1 { min = $0 } { if ($0 < min) min = $0; count++ } END {print min}' <<< "$NOW_PORTS")
    NOW_CONSECUTIVE_PORTS=$(awk 'END { print NR }' <<< "$NOW_PORTS")
  fi

  if [ "$NONINTERACTIVE_INSTALL" != 'noninteractive_install' ]; then
    # Check Argo service status
    STATUS[1]=$(text 26) && IS_ARGO=no_argo
    [ -s ${ARGO_DAEMON_FILE} ] && IS_ARGO=is_argo && STATUS[1]=$(text 27)
    cmd_systemctl status argo &>/dev/null && STATUS[1]=$(text 28)
  fi

  # Check Argo service type
  if [ "$SYSTEM" = 'Alpine' ]; then
    if [ -s ${ARGO_DAEMON_FILE} ]; then
      local ARGO_CONTENT=$(grep '^command_args=' ${ARGO_DAEMON_FILE})
      if grep -q '\--token' <<< "$ARGO_CONTENT"; then
        ARGO_TYPE=is_token_argo
      elif grep -q '\--config' <<< "$ARGO_CONTENT"; then
        ARGO_TYPE=is_json_argo
      elif grep -q '\--url' <<< "$ARGO_CONTENT"; then
        ARGO_TYPE=is_quicktunnel_argo
      fi
    fi
  else
    if [ -s ${ARGO_DAEMON_FILE} ]; then
      local ARGO_CONTENT=$(grep '^ExecStart' ${ARGO_DAEMON_FILE})
      if grep -q '\--token' <<< "$ARGO_CONTENT"; then
        ARGO_TYPE=is_token_argo
      elif grep -q '\--config' <<< "$ARGO_CONTENT"; then
        ARGO_TYPE=is_json_argo
      elif grep -q '\--url' <<< "$ARGO_CONTENT"; then
        ARGO_TYPE=is_quicktunnel_argo
      fi
    fi
  fi

  # If necessary, download silently in the background cloudflared
  if [[ "${STATUS[1]}" = "$(text 26)" || "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]] && [ ! -s ${WORK_DIR}/cloudflared ]; then
    {
      wget --no-check-certificate -qO $TEMP_DIR/cloudflared ${GH_PROXY}https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$ARGO_ARCH >/dev/null 2>&1 && chmod +x $TEMP_DIR/cloudflared >/dev/null 2>&1
    }&
  elif [ "${STATUS[1]}" != "$(text 26)" ]; then
    # Check Argo process number, running time and memory usage
    ARGO_VERSION=$(${WORK_DIR}/cloudflared -v | awk '{print $3}' | sed "s@^@Version: &@g")
    [ "${STATUS[1]}" = "$(text 28)" ] && ARGO_PID=$(awk '/cloudflared/{print $1}' <<< "$PS_LIST") && [[ "$ARGO_PID" =~ ^[0-9]+$ ]] && ARGO_MEMORY_USAGE="$(text 58): $(awk '/VmRSS/{printf "%.1f\n", $2/1024}' /proc/$ARGO_PID/status) MB"
  fi

  # Check Nginx status
  if ! command -v nginx >/dev/null 2>&1; then
    STATUS[2]=$(text 26)
  elif [ -s ${WORK_DIR}/nginx.conf ]; then
    # Check Nginx process number, running time and memory usage
    NGINX_VERSION=$(nginx -v 2>&1 | sed "s#.*/##; s/ ([^)]*)//" | sed "s@^@Version: &@g")
    NGINX_PID=$(awk '/nginx/{print $1}' <<< "${PS_LIST}")
    if [[ "$NGINX_PID" =~ ^[0-9]+$ ]]; then
      STATUS[2]=$(text 28)
      NGINX_MEMORY_USAGE="$(text 58): $(awk '/VmRSS/{printf "%.1f\n", $2/1024}' /proc/$NGINX_PID/status) MB"
    else
      STATUS[2]=$(text 27)
    fi
  else
    STATUS[2]=$(text 27)
  fi
}

# In order to adapt to alpine, define the function of cmd_systemctl
cmd_systemctl() {
  nginx_run() {
    $(command -v nginx) -c $WORK_DIR/nginx.conf
  }

  nginx_stop() {
    local NGINX_PID=$(ps -eo pid,args | awk -v work_dir="$WORK_DIR" '$0~(work_dir"/nginx.conf"){print $1;exit}')
    ss -nltp | sed -n "/pid=$NGINX_PID,/ s/,/ /gp" | grep -oP 'pid=\K\S+' | sort -u | xargs kill -9 >/dev/null 2>&1
  }

  if [ "$SYSTEM" = 'Alpine' ]; then
    case "$1" in
      enable )
        rc-update add "$2" default >/dev/null 2>&1
        rc-service "$2" start >/dev/null 2>&1
        ;;
      disable )
        rc-service "$2" stop >/dev/null 2>&1
        rc-update del "$2" default >/dev/null 2>&1
        ;;
      restart )
        rc-service "$2" restart >/dev/null 2>&1
        ;;
      status )
        rc-service "$2" status
        ;;
    esac
  else
    systemctl daemon-reload
    case "$1" in
      enable | disable )
        systemctl "$1" --now "$2" >/dev/null 2>&1
        if [ "$IS_CENTOS" = 'CentOS7' ] && [ "$2" = 'sing-box' ] && [ -s $WORK_DIR/nginx.conf ]; then
          if [ "$1" = 'enable' ]; then
            nginx_run
          else
            nginx_stop
          fi
        fi
        ;;
      restart )
        [ "$IS_CENTOS" = 'CentOS7' ] && [ "$2" = 'sing-box' ] && [ -s $WORK_DIR/nginx.conf ] && nginx_stop
        systemctl restart "$2" >/dev/null 2>&1
        [ "$IS_CENTOS" = 'CentOS7' ] && [ "$2" = 'sing-box' ] && [ -s $WORK_DIR/nginx.conf ] && nginx_run
        ;;
      status )
        systemctl is-active "$2"
        ;;
      * )
        systemctl "$@" >/dev/null 2>&1
        ;;
    esac
  fi
}

check_system_info() {
  [ -s /etc/os-release ] && SYS="$(awk -F '"' 'tolower($0) ~ /pretty_name/{print $2}' /etc/os-release)"
  [[ -z "$SYS" ]] && command -v hostnamectl >/dev/null 2>&1 && SYS="$(hostnamectl | awk -F ': ' 'tolower($0) ~ /operating system/{print $2}')"
  [[ -z "$SYS" ]] && command -v lsb_release >/dev/null 2>&1 && SYS="$(lsb_release -sd)"
  [[ -z "$SYS" && -s /etc/lsb-release ]] && SYS="$(awk -F '"' 'tolower($0) ~ /distrib_description/{print $2}' /etc/lsb-release)"
  [[ -z "$SYS" && -s /etc/redhat-release ]] && SYS="$(cat /etc/redhat-release)"
  [[ -z "$SYS" && -s /etc/issue ]] && SYS="$(sed -E '/^$|^\\/d' /etc/issue | awk -F '\\' '{print $1}' | sed 's/[ ]*$//g')"

  REGEX=("debian" "ubuntu" "centos|red hat|kernel|alma|rocky" "arch linux" "alpine" "fedora")
  RELEASE=("Debian" "Ubuntu" "CentOS" "Arch" "Alpine" "Fedora")
  EXCLUDE=("")
  MAJOR=("9" "16" "7" "3" "" "37")
  PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update --skip-broken" "pacman -Sy" "apk update -f" "dnf -y update")
  PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "pacman -S --noconfirm" "apk add --no-cache" "dnf -y install")
  PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "pacman -Rcnsu --noconfirm" "apk del -f" "dnf -y autoremove")

  for int in "${!REGEX[@]}"; do
    [[ "${SYS,,}" =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && break
  done

  # Customized systems for each manufacturer
  if [ -z "$SYSTEM" ]; then
    command -v yum >/dev/null 2>&1 && int=2 && SYSTEM='CentOS' || error " $(text 5) "
  fi

  # First exclude specific systems included in EXCLUDE. Other systems need to be compared with larger releases.
  for ex in "${EXCLUDE[@]}"; do [[ ! "{$SYS,,}"  =~ $ex ]]; done &&
  [[ "$(sed -E 's/[^0-9.]//g; s/\..*//' <<< "$SYS")" -lt "${MAJOR[int]}" ]] && error " $(text 6) "

  # For special processing on some systems, CentOS7 uses yum, and the above uses dnf.
  ARGO_DAEMON_FILE='/etc/systemd/system/argo.service'; SINGBOX_DAEMON_FILE='/etc/systemd/system/sing-box.service'
  if [ "$SYSTEM" = 'CentOS' ]; then
    IS_CENTOS="CentOS$(sed -E 's/[^0-9.]//g; s/\..*//' <<< "$SYS")"
    [ "$IS_CENTOS" != 'CentOS7' ] && int=5
  elif [ "$SYSTEM" = 'Alpine' ]; then
    ARGO_DAEMON_FILE='/etc/init.d/argo'; SINGBOX_DAEMON_FILE='/etc/init.d/sing-box'
  fi

  # Determine virtualization
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT=$(systemd-detect-virt)
  elif grep -qa container= /proc/1/environ 2>/dev/null; then
    VIRT=$(tr '\0' '\n' </proc/1/environ | awk -F= '/container=/{print $2; exit}')
  elif grep -Eq '(lxc|docker|kubepods|containerd)' /proc/1/cgroup 2>/dev/null; then
    VIRT=$(grep -Eo '(lxc|docker|kubepods|containerd)' /proc/1/cgroup | sed -n 1p)
  elif command -v hostnamectl >/dev/null 2>&1; then
    VIRT=$(hostnamectl | awk '/Virtualization/{print $NF}')
  else
    command -v virt-what >/dev/null 2>&1 && ${PACKAGE_INSTALL[int]} virt-what >/dev/null 2>&1
    command -v virt-what >/dev/null 2>&1 && VIRT=$(virt-what | sed -n 1p) || VIRT=unknown
  fi
}

# Get sing-box latest version
get_sing_box_version() {
  # FORCE_VERSION is used to force the specified version when a bug occurs in a main program of sing-box to prevent running errors.
  local FORCE_VERSION=$(wget --no-check-certificate --tries=2 --timeout=3 -qO-${GH_PROXY}https://raw.githubusercontent.com/fscarmen/sing-box/refs/heads/main/force_version | sed 's/^[vV]//g; s/\r//g')
  if grep -q '.' <<< "$FORCE_VERSION"; then
    local RESULT_VERSION="$FORCE_VERSION"
  else
    # First determine whether the http status code returned by github api is 200. Sometimes the IP will be restricted, resulting in Get not being able to get the latest version.
local API_RESPONSE=$(wget --no-check-certificate --server-response --tries=2 --timeout=3 -qO-"${GH_PROXY}https://api.github.com/repos/SagerNet/sing-box/releases" 2>&1 | grep -E '^[ ]+HTTP/|tag_name')
    if grep -q 'HTTP.*200' <<< "$API_RESPONSE"; then
      local VERSION_LATEST=$(awk -F '["v-]' '/tag_name/{print $5}' <<< "$API_RESPONSE" | sort -Vr | sed -n '1p')
local RESULT_VERSION=$(wget --no-check-certificate --tries=2 --timeout=3 -qO-${GH_PROXY}https://api.github.com/repos/SagerNet/sing-box/releases | awk -F '["v]' -v var="tag_name.*$VERSION_LATEST" '$0 ~ var {print $5; exit}')
    else
      local RESULT_VERSION="$DEFAULT_NEWEST_VERSION"
    fi
  fi
  echo "$RESULT_VERSION"
}

# Add port jump
add_port_hopping_nat() {
  local PORT_HOPPING_START=$1
  local PORT_HOPPING_END=$2
  local PORT_HOPPING_TARGET=$3
  local COMMENT="NAT ${PORT_HOPPING_START}:${PORT_HOPPING_END} to ${PORT_HOPPING_TARGET} (Sing-box Family Bucket)"
  local FW_BACKEND
  local FW_CHECK=() FW_INSTALL=() FW_TO_INSTALL=()

  FW_BACKEND=$(check_port_hopping_firewall)

  case "$FW_BACKEND" in
    ufw )
      info "\n $(text 144) \n"
      ;;
    alpine-iptables )
      FW_CHECK=("iptables")
      FW_INSTALL=("iptables")
      ;;
    firewalld )
      FW_CHECK=("firewall-cmd")
      FW_INSTALL=("firewalld")
      ;;
    * )
      FW_CHECK=("iptables" "netfilter-persistent")
      FW_INSTALL=("iptables" "netfilter-persistent")
      ;;
  esac

  for i in "${!FW_CHECK[@]}"; do
    ! command -v "${FW_CHECK[i]}" >/dev/null 2>&1 && FW_TO_INSTALL+=("${FW_INSTALL[i]}")
  done

  if [ "${#FW_TO_INSTALL[@]}" -gt 0 ]; then
    FW_TO_INSTALL=($(printf "%s\n" "${FW_TO_INSTALL[@]}" | sort -u))
    [ "$SYSTEM" != 'CentOS' ] && ${PACKAGE_UPDATE[int]} >/dev/null 2>&1
    ${PACKAGE_INSTALL[int]} "${FW_TO_INSTALL[@]}" >/dev/null 2>&1
  fi

  if [ "$FW_BACKEND" = 'firewalld' ]; then
    [ "$(systemctl is-active firewalld 2>/dev/null)" != 'active' ] && cmd_systemctl enable firewalld >/dev/null 2>&1
    [ "$(firewall-cmd --zone=public --get-target 2>/dev/null)" != 'ACCEPT' ] && firewall-cmd --zone=public --set-target=ACCEPT --permanent >/dev/null 2>&1
    firewall-cmd --reload >/dev/null 2>&1
  fi

  if [ "$FW_BACKEND" = 'ufw' ]; then
    add_port_hopping_ufw_rules "$PORT_HOPPING_START" "$PORT_HOPPING_END" "$PORT_HOPPING_TARGET" || warning "\n $(text 146) \n"

  elif [ "$SYSTEM" = 'Alpine' ]; then
    # Add firewall rules
    iptables --table nat -A PREROUTING -p udp --dport ${PORT_HOPPING_START}:${PORT_HOPPING_END} -m comment --comment "$COMMENT" -j DNAT --to-destination :${PORT_HOPPING_TARGET} 2>/dev/null
    ip6tables --table nat -A PREROUTING -p udp --dport ${PORT_HOPPING_START}:${PORT_HOPPING_END} -m comment --comment "$COMMENT" -j DNAT --to-destination :${PORT_HOPPING_TARGET} 2>/dev/null

    # Add iptables, ip6tables to default runlevel
rc-update show default | grep -q 'iptables' || rc-update add iptables >/dev/null 2>&1
    rc-update show default | grep -q 'ip6tables' || rc-update add ip6tables >/dev/null 2>&1
    rc-update show default | grep -q 'iptables' && rc-update show default | grep -q 'ip6tables' || warning "\n $(text 96) \n"

    # Save the current iptables, ip6tables rule set for restoration at boot
    rc-service iptables  save >/dev/null 2>&1
    rc-service ip6tables save >/dev/null 2>&1

  elif command -v firewall-cmd >/dev/null 2>&1 || [ "$SYSTEM" = 'CentOS' ]; then
    if [ "$(firewall-cmd --zone=public --query-masquerade --permanent 2>/dev/null)" != 'yes' ]; then
      firewall-cmd --zone=public --add-masquerade --permanent >/dev/null 2>&1
      firewall-cmd --reload >/dev/null 2>&1
      [ "$(firewall-cmd --zone=public --query-masquerade --permanent 2>/dev/null)" = 'yes' ] && info "\n firewalld masquerade $(text 28) $(text 37) \n" || warning "\n firewalld masquerade $(text 28) $(text 38) \n"
    fi

    #Add firewall rules
    firewall-cmd --zone=public --add-forward-port=port=${PORT_HOPPING_START}-${PORT_HOPPING_END}:proto=udp:toport=${PORT_HOPPING_TARGET} --permanent >/dev/null 2>&1
    firewall-cmd --reload >/dev/null 2>&1

  else
    #Add firewall rules
    iptables --table nat -A PREROUTING -p udp --dport ${PORT_HOPPING_START}:${PORT_HOPPING_END} -m comment --comment "$COMMENT" -j DNAT --to-destination :${PORT_HOPPING_TARGET} 2>/dev/null
ip6tables --table nat -A PREROUTING -p udp --dport ${PORT_HOPPING_START}:${PORT_HOPPING_END} -m comment --comment "$COMMENT" -j DNAT --to-destination :${PORT_HOPPING_TARGET} 2>/dev/null

    # Save the current iptables, ip6tables rule set for restoration at boot
    [ "$(systemctl is-active netfilter-persistent)" != 'active' ] && warning "\n $(text 96) \n" || netfilter-persistent save 2>/dev/null
  fi
}

# Delete port jump
del_port_hopping_nat() {
  local FW_BACKEND
  FW_BACKEND=$(check_port_hopping_firewall)

  check_port_hopping_nat
  [ -z "$PORT_HOPPING_START" ] && return

  if [ "$FW_BACKEND" = 'ufw' ]; then
    del_port_hopping_ufw_rules || warning "\n $(text 146) \n"

  elif [ "$SYSTEM" = 'Alpine' ]; then
    local COMMENT="NAT ${PORT_HOPPING_START}:${PORT_HOPPING_END} to ${PORT_HOPPING_TARGET} (Sing-box Family Bucket)"
    iptables  --table nat -D PREROUTING -p udp --dport ${PORT_HOPPING_START}:${PORT_HOPPING_END} -m comment --comment "$COMMENT" -j DNAT --to-destination :${PORT_HOPPING_TARGET} 2>/dev/null
    ip6tables --table nat -D PREROUTING -p udp --dport ${PORT_HOPPING_START}:${PORT_HOPPING_END} -m comment --comment "$COMMENT" -j DNAT --to-destination :${PORT_HOPPING_TARGET} 2>/dev/null

  elif command -v firewall-cmd >/dev/null 2>&1 || [ "$SYSTEM" = 'CentOS' ]; then
    firewall-cmd --zone=public --permanent --remove-forward-port=port=${PORT_HOPPING_START}-${PORT_HOPPING_END}:proto=udp:toport=${PORT_HOPPING_TARGET} >/dev/null 2>&1
    firewall-cmd --reload >/dev/null 2>&1

  else
    local COMMENT="NAT ${PORT_HOPPING_START}:${PORT_HOPPING_END} to ${PORT_HOPPING_TARGET} (Sing-box Family Bucket)"
    iptables  --table nat -D PREROUTING -p udp --dport ${PORT_HOPPING_START}:${PORT_HOPPING_END} -m comment --comment "$COMMENT" -j DNAT --to-destination :${PORT_HOPPING_TARGET} 2>/dev/null
    ip6tables --table nat -D PREROUTING -p udp --dport ${PORT_HOPPING_START}:${PORT_HOPPING_END} -m comment --comment "$COMMENT" -j DNAT --to-destination :${PORT_HOPPING_TARGET} 2>/dev/null
    [ "$(systemctl is-active netfilter-persistent)" = 'active' ] && netfilter-persistent save 2>/dev/null
  fi
}

# Check the dnat port of port jump
check_port_hopping_nat() {
  local FW_BACKEND
  FW_BACKEND=$(check_port_hopping_firewall)

  unset PORT_HOPPING_START PORT_HOPPING_END PORT_HOPPING_RANGE
  PORT_HOPPING_TARGET=$(awk -F '[:,]' '/"listen_port"/{print $2; exit}' ${WORK_DIR}/conf/*${NODE_TAG[1]}_inbounds.json 2>/dev/null)

  if [ "$FW_BACKEND" = 'ufw' ]; then
    check_port_hopping_ufw_rules

  elif [ "$SYSTEM" = 'Alpine' ]; then
    local IPTABLES_PREROUTING_LIST=$(iptables --table nat --list-rules PREROUTING 2>/dev/null | grep 'Sing-box Family Bucket')
    [ -n "$IPTABLES_PREROUTING_LIST" ] && \
      PORT_HOPPING_RANGE=$(awk '{for (i=1; i<=NF; i++) if ($i=="--dport") {print $(i+1); exit}}' <<< "$IPTABLES_PREROUTING_LIST") && \
      PORT_HOPPING_TARGET=$(awk '{for (i=1; i<=NF; i++) if ($i=="--to-destination") {gsub(/^:/,"",$(i+1)); print $(i+1); exit}}' <<< "$IPTABLES_PREROUTING_LIST")
    [ -n "$PORT_HOPPING_RANGE" ] && PORT_HOPPING_START=${PORT_HOPPING_RANGE%:*} && PORT_HOPPING_END=${PORT_HOPPING_RANGE#*:}

  elif command -v firewall-cmd >/dev/null 2>&1 || [ "$SYSTEM" = 'CentOS' ]; then
    local FIREWALL_LIST=$(firewall-cmd --zone=public --list-forward-ports --permanent 2>/dev/null | grep "toport=${PORT_HOPPING_TARGET}")
    [ -n "$FIREWALL_LIST" ] && \
      PORT_HOPPING_START=$(sed "s/.*port=\([0-9]\+\)-.*/\1/" <<< "$FIREWALL_LIST") && \
      PORT_HOPPING_END=$(sed "s/.*port=${PORT_HOPPING_START}-\([0-9]\+\):.*/\1/" <<< "$FIREWALL_LIST") && \
      PORT_HOPPING_TARGET=$(sed "s/.*toport=\([0-9]\+\).*/\1/" <<< "$FIREWALL_LIST")

  else
    local IPTABLES_PREROUTING_LIST=$(iptables --table nat --list-rules PREROUTING 2>/dev/null | grep 'Sing-box Family Bucket')
    [ -n "$IPTABLES_PREROUTING_LIST" ] && \
      PORT_HOPPING_RANGE=$(awk '{for (i=1; i<=NF; i++) if ($i=="--dport") {print $(i+1); exit}}' <<< "$IPTABLES_PREROUTING_LIST") && \
      PORT_HOPPING_TARGET=$(awk '{for (i=1; i<=NF; i++) if ($i=="--to-destination") {gsub(/^:/,"",$(i+1)); print $(i+1); exit}}' <<< "$IPTABLES_PREROUTING_LIST")
    [ -n "$PORT_HOPPING_RANGE" ] && PORT_HOPPING_START=${PORT_HOPPING_RANGE%:*} && PORT_HOPPING_END=${PORT_HOPPING_RANGE#*:}
  fi

  [ -n "$PORT_HOPPING_START" ] && [ -n "$PORT_HOPPING_END" ] && PORT_HOPPING_RANGE="${PORT_HOPPING_START}:${PORT_HOPPING_END}"
}

# Detect IPv4 IPv6 information
check_system_ip() {
  [ "$L" = 'C' ] && local IS_CHINESE='?lang=zh-CN'
  local DEFAULT_LOCAL_INTERFACE4=$(ip -4 route show default | awk '/default/{for (i=0; i<NF; i++) if ($i=="dev") {print $(i+1); exit}}')
  local DEFAULT_LOCAL_INTERFACE6=$(ip -6 route show default | awk '/default/{for (i=0; i<NF; i++) if ($i=="dev") {print $(i+1); exit}}')
  if [ -n ""${DEFAULT_LOCAL_INTERFACE4}${DEFAULT_LOCAL_INTERFACE6}"" ]; then
local DEFAULT_LOCAL_IP4=$(ip -4 addr show $DEFAULT_LOCAL_INTERFACE4 | sed -n 's#.*inet \([^/]\+\)/[0-9]\+.*global.*#\1#gp')
    local DEFAULT_LOCAL_IP6=$(ip -6 addr show $DEFAULT_LOCAL_INTERFACE6 | sed -n 's#.*inet6 \([^/]\+\)/[0-9]\+.*global.*#\1#gp')
    [ -n "$DEFAULT_LOCAL_IP4" ] && local BIND_ADDRESS4="--bind-address=$DEFAULT_LOCAL_IP4"
    [ -n "$DEFAULT_LOCAL_IP6" ] && local BIND_ADDRESS6="--bind-address=$DEFAULT_LOCAL_IP6"
  fi

  # Parallel detection of IPv4 and IPv6 information
  {
    local CHECK_IP4=$(wget $BIND_ADDRESS4 -4 -qO- --no-check-certificate --tries=2 --timeout=2 https://ip.cloudflare.now.cc${IS_CHINESE})
    grep -q '.' <<< "$CHECK_IP4" && echo "$CHECK_IP4" > $TEMP_DIR/ip4.json
  }&

  {
    local CHECK_IP6=$(wget $BIND_ADDRESS6 -6 -qO- --no-check-certificate --tries=2 --timeout=2 https://ip.cloudflare.now.cc${IS_CHINESE})
    grep -q '.' <<< "$CHECK_IP6" && echo "$CHECK_IP6" > $TEMP_DIR/ip6.json
  }&

  wait

  [ -s $TEMP_DIR/ip4.json ] &&
  local IP4_JSON=$(cat $TEMP_DIR/ip4.json) &&
  WAN4=$(awk -F '"' '/"ip"/{print $4}' <<< "$IP4_JSON") &&
  COUNTRY4=$(awk -F '"' '/"country"/{print $4}' <<< "$IP4_JSON") &&
  EMOJI4=$(awk -F '"' '/"emoji"/{print $4}' <<< "$IP4_JSON") &&
  ASNORG4=$(awk -F '"' '/"isp"/{print $4}' <<< "$IP4_JSON") &&
  rm -f $TEMP_DIR/ip4.json

  [ -s $TEMP_DIR/ip6.json ] &&
  local IP6_JSON=$(cat $TEMP_DIR/ip6.json) &&
  WAN6=$(awk -F '"' '/"ip"/{print $4}' <<< "$IP6_JSON") &&
  COUNTRY6=$(awk -F '"' '/"country"/{print $4}' <<< "$IP6_JSON") &&
  EMOJI6=$(awk -F '"' '/"emoji"/{print $4}' <<< "$IP6_JSON") &&
  ASNORG6=$(awk -F '"' '/"isp"/{print $4}' <<< "$IP6_JSON") &&
  rm -f $TEMP_DIR/ip6.json
}

# Enter the starting port function
input_start_port() {
  local NUM=$1
  local PORT_ERROR_TIME=6
  while true; do
    [ "$PORT_ERROR_TIME" -lt 6 ] && unset IN_USED START_PORT
    (( PORT_ERROR_TIME-- )) || true
    if [ "$PORT_ERROR_TIME" = 0 ]; then
      error "\n $(text 3) \n"
    else
      [ -z "$START_PORT" ] && reading "\n ${TOTAL_STEPS:+(${STEP_NUM}/${TOTAL_STEPS}) }$(text 11) " START_PORT
    fi
    START_PORT=${START_PORT:-"$START_PORT_DEFAULT"}
    if [[ "$START_PORT" =~ ^[1-9][0-9]{2,4}$ && "$START_PORT" -ge "$MIN_PORT" && "$START_PORT" -le "$MAX_PORT" ]]; then
      for port in $(eval echo {$START_PORT..$[START_PORT+NUM-1]}); do
        ss -nltup | grep -q ":$port" && IN_USED+=("$port")
      done
      [ "${#IN_USED[*]}" -eq 0 ] && break || warning "\n $(text 44) \n"
    fi
  done
}

# Define Sing-box variables
sing-box_variables() {
  STEP_NUM=0
  # Calculate the maximum total number of steps using all-selected protocols in advance, which will be displayed when the protocol selection prompts (1/?)
  local _saved_protocols=("${INSTALL_PROTOCOLS[@]}")
  INSTALL_PROTOCOLS=(b c d e f g h i j k l m)
  calc_install_steps
  INSTALL_PROTOCOLS=("${_saved_protocols[@]}")

  if grep -qi 'cloudflare' <<< "$ASNORG4$ASNORG6"; then
    if grep -qi 'cloudflare' <<< "$ASNORG6" && [ -n "$WAN4" ] && ! grep -qi 'cloudflare' <<< "$ASNORG4"; then
      SERVER_IP_DEFAULT=$WAN4
    elif grep -qi 'cloudflare' <<< "$ASNORG4" && [ -n "$WAN6" ] && ! grep -qi 'cloudflare' <<< "$ASNORG6"; then
      SERVER_IP_DEFAULT=$WAN6
    else
      local a=6
      until [ -n "$SERVER_IP" ]; do
        ((a--)) || true
        [ "$a" = 0 ] && error "\n $(text 3) \n"
        reading "\n $(text 46) " SERVER_IP
      done
    fi
  elif [ -n "$WAN4" ]; then
    SERVER_IP_DEFAULT=$WAN4
  elif [ -n "$WAN6" ]; then
    SERVER_IP_DEFAULT=$WAN6
  fi

  # Select the installed protocol. Since option a is all protocols, the number of options does not start from a, but from b. Process the input: change all uppercase letters to lowercase, remove incompatible options, and merge duplicate options.
  MAX_CHOOSE_PROTOCOLS=$(asc $(( CONSECUTIVE_PORTS+96+1 )))
  (( STEP_NUM++ )) || true
  if [ -z "$CHOOSE_PROTOCOLS" ]; then
    hint "\n (${STEP_NUM}/${TOTAL_STEPS:-?}) $(text 49) "
    for e in "${!PROTOCOL_LIST[@]}"; do
      hint " $(asc $(( e+98 ))). ${PROTOCOL_LIST[e]} "
    done
    reading "\n $(text 24) " CHOOSE_PROTOCOLS
  fi
# Input processing logic for the selection protocol: first convert all uppercase letters to lowercase, remove all undeleted options, and finally sort them in the order of input. If the option a(all) coexists with other options, a will be ignored, such as abc, it will be processed as bc
  [[ ! "${CHOOSE_PROTOCOLS,,}" =~ [b-$MAX_CHOOSE_PROTOCOLS] ]] && INSTALL_PROTOCOLS=($(eval echo {b..$MAX_CHOOSE_PROTOCOLS})) || INSTALL_PROTOCOLS=($(grep -o . <<< "$CHOOSE_PROTOCOLS" | sed "/[^b-$MAX_CHOOSE_PROTOCOLS]/d" | awk '!seen[$0]++'))

  # The protocol has been determined, recalculate the total number of steps according to the actual selection
  calc_install_steps

  # Display the selected protocols and their order, enter the starting port number
  if [ -z "$START_PORT" ]; then
    (( STEP_NUM++ )) || true
    hint "\n $(text 60) "
    for w in "${!INSTALL_PROTOCOLS[@]}"; do
      [ "$w" -ge 9 ] && hint " $(( w+1 )). ${PROTOCOL_LIST[$(($(asc ${INSTALL_PROTOCOLS[w]}) - 98))]} " || hint " $(( w+1 )) . ${PROTOCOL_LIST[$(($(asc ${INSTALL_PROTOCOLS[w]}) - 98))]} "
    done
    input_start_port ${#INSTALL_PROTOCOLS[@]}
  fi

  #Select the output mode, enter the Nginx service port number used for subscription, and install the dependencies in the background according to the selection.
  if [[ "$IS_SUB" = 'is_sub' || "$IS_ARGO" = 'is_argo' ]]; then
    (( STEP_NUM++ )) || true
    input_nginx_port
  fi

  # Enter the server IP. The default is the detected server IP. If all are empty, prompt and exit the script.
  if [ "$IS_FAST_INSTALL" = 'is_fast_install' ]; then
    grep -q '^$' <<< "$SERVER_IP" && grep -q '.' <<< "$WAN4" && SERVER_IP=$WAN4
    grep -q '^$' <<< "$SERVER_IP" && grep -q '.' <<< "$WAN6" && SERVER_IP=$WAN6
  fi
  if [ -z "$SERVER_IP" ]; then
    (( STEP_NUM++ )) || true
reading "\n (${STEP_NUM}/${TOTAL_STEPS}) $(text 10) " SERVER_IP
  fi
  SERVER_IP=${SERVER_IP:-"$SERVER_IP_DEFAULT"} && WS_SERVER_IP_SHOW=$SERVER_IP
  [ -z "$SERVER_IP" ] && error " $(text 47) "

  # Make different DNS policies based on the network status of IPv4 and IPv6
  command -v ping >/dev/null 2>&1 && for i in {1..3}; do
    ping -c 1 -W 1 "151.101.1.91" &>/dev/null && local IS_IPV4=is_ipv4 && break
  done

  if command -v ping6 >/dev/null 2>&1; then
    for i in {1..3}; do
      ping6 -c 1 -W 1 "2a04:4e42:200::347" &>/dev/null && local IS_IPV6=is_ipv6 && break
    done
  elif command -v ping >/dev/null 2>&1; then
    for i in {1..3}; do
      ping -c 1 -W 1 "2a04:4e42:200::347" &>/dev/null && local IS_IPV6=is_ipv6 && break
    done
  fi

  case "${IS_IPV4}@${IS_IPV6}" in
    is_ipv4@is_ipv6)
      STRATEGY=prefer_ipv4
      ;;
    is_ipv4@)
      STRATEGY=ipv4_only
      ;;
    @is_ipv6)
      STRATEGY=ipv6_only
      ;;
    *)
      STRATEGY=prefer_ipv4
      ;;
  esac

  # Check whether chatGPT is unlocked
  CHATGPT_OUT=warp-ep;
  [ "$(check_chatgpt $(grep -oE '[46]' <<< "$STRATEGY"))" = 'unlock' ] && CHATGPT_OUT=direct

  # If you choose to have these reality protocols b j k, customize the reality public and private keys, if not, automatically generate
  if [ "$NONINTERACTIVE_INSTALL" != 'noninteractive_install' ] && [[ "${INSTALL_PROTOCOLS[@]}" =~ 'b'|'j'|'k' ]]; then
    (( STEP_NUM++ )) || true
    input_reality_key
  fi

  # If c. hysteria2 is selected, choose whether to use port jumping
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ 'c' ]]; then
    (( STEP_NUM++ )) || true
input_hopping_port
  fi

  # If h. vmess + ws or i. vless + ws is selected, first check whether there is a supported http port available, and if so, you will be asked to enter the domain name and cdn
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ 'h' ]]; then
    if [ "$IS_ARGO" = 'is_argo' ]; then
      if [ "$ARGO_READY" != 'argo_ready' ]; then
        (( STEP_NUM++ )) || true
        input_argo_auth is_install
      fi
      local ARGO_READY=argo_ready
    else
      local DOMAIN_ERROR_TIME=5
      until [ -n "$VMESS_HOST_DOMAIN" ]; do
        (( DOMAIN_ERROR_TIME-- )) || true
        [ "$DOMAIN_ERROR_TIME" != 0 ] && TYPE=VMESS && reading "\n $(text 50) " VMESS_HOST_DOMAIN || error "\n $(text 3) \n"
      done
    fi
  fi

  if [[ "${INSTALL_PROTOCOLS[@]}" =~ 'i' ]]; then
    if [ "$IS_ARGO" = 'is_argo' ]; then
      if [ "$ARGO_READY" != 'argo_ready' ]; then
        (( STEP_NUM++ )) || true
        input_argo_auth is_install
      fi
      local ARGO_READY=argo_ready
    else
      local DOMAIN_ERROR_TIME=5
      until [ -n "$VLESS_HOST_DOMAIN" ]; do
        (( DOMAIN_ERROR_TIME-- )) || true
        [ "$DOMAIN_ERROR_TIME" != 0 ] && TYPE=VLESS && reading "\n $(text 50) " VLESS_HOST_DOMAIN || error "\n $(text 3) \n"
      done
    fi
  fi

  # Select or enter cdn
  if [[ -z "$CDN" && -n "${VMESS_HOST_DOMAIN}${VLESS_HOST_DOMAIN}${ARGO_READY}" ]]; then
    (( STEP_NUM++ )) || true
    input_cdn
  fi

  # Enter UUID. If there are more than 5 errors, it will exit.
  UUID_DEFAULT=$(cat /proc/sys/kernel/random/uuid)
  [ "$IS_FAST_INSTALL" = 'is_fast_install' ] && UUID_CONFIRM="$UUID_DEFAULT"
  if [ -z "$UUID_CONFIRM" ]; then
    (( STEP_NUM++ )) || true
    reading "\n (${STEP_NUM}/${TOTAL_STEPS}) $(text 12) " UUID_CONFIRM
  fi
  local UUID_ERROR_TIME=5
until [[ -z "$UUID_CONFIRM" || "${UUID_CONFIRM,,}" =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ ]]; do
    (( UUID_ERROR_TIME--)) || true
    [ "$UUID_ERROR_TIME" = 0 ] && error "\n $(text 3) \n" || reading "\n $(text 4) \n" UUID_CONFIRM
  done
  UUID_CONFIRM=${UUID_CONFIRM:-"$UUID_DEFAULT"}

  # Enter the node name, using the system hostname as the default
  local EMOJI="${EMOJI4:-$EMOJI6}"
  local EMOJI="${EMOJI}${EMOJI:+ }"
  if [ -z "$NODE_NAME_CONFIRM" ]; then
    if command -v hostname >/dev/null 2>&1; then
      local NODE_NAME_DEFAULT="${EMOJI}$(hostname)"
    elif [ -s /etc/hostname ]; then
      local NODE_NAME_DEFAULT="${EMOJI}$(cat /etc/hostname)"
    else
      local NODE_NAME_DEFAULT="${EMOJI}Sing-Box"
    fi
    [ "$IS_FAST_INSTALL" = 'is_fast_install' ] && NODE_NAME_CONFIRM="${NODE_NAME_DEFAULT}"
    if [ -z "$NODE_NAME_CONFIRM" ]; then
      (( STEP_NUM++ )) || true
      reading "\n (${STEP_NUM}/${TOTAL_STEPS}) $(text 13) " NODE_NAME
    fi
    grep -q '^$' <<< "$NODE_NAME" && NODE_NAME_CONFIRM="$NODE_NAME_DEFAULT" || NODE_NAME_CONFIRM="${EMOJI}${NODE_NAME}"
  fi
}

check_dependencies() {
  local DEPS=() DEPS_CHECK=() DEPS_INSTALL=()

  # 1.Alpine-specific handling: check BusyBox wget, set IS_PREFER_GO
  if [ "$SYSTEM" = 'Alpine' ]; then
    IS_PREFER_GO=true
    local CHECK_WGET=$(wget 2>&1 | sed -n 1p)
    grep -qi 'busybox' <<< "$CHECK_WGET" && DEPS+=("wget")

    DEPS_CHECK+=("bash" "rc-update")
    DEPS_INSTALL+=("bash" "openrc")
  else
    # For non-Alpine systems, check the systemd-resolved status for the prefer_go field in DNS Configuration
command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet systemd-resolved && IS_PREFER_GO=false || IS_PREFER_GO=true
  fi

  # 2. Basic common dependencies (excluding firewall, firewall is only installed on demand when port jumps)
  DEPS_CHECK+=("wget" "tar" "ss" "ip" "bash" "openssl" "ping")
  DEPS_INSTALL+=("wget" "tar" "iproute2" "iproute2" "bash" "openssl" "iputils-ping")

  [ "$SYSTEM" != 'Alpine' ] && DEPS_CHECK+=("systemctl") && DEPS_INSTALL+=("systemctl")

  # CentOS7 requires epel-release
  [ "$SYSTEM" = 'CentOS' ] && [ "$IS_CENTOS" = 'CentOS7' ] && \
    yum repolist 2>/dev/null | grep -q epel || { [ "$SYSTEM" = 'CentOS' ] && [ "$IS_CENTOS" = 'CentOS7' ] && DEPS+=("epel-release"); }

  for g in "${!DEPS_CHECK[@]}"; do
    ! command -v "${DEPS_CHECK[g]}" >/dev/null 2>&1 && DEPS+=("${DEPS_INSTALL[g]}")
  done

  # 3. Remove duplicates and install
  DEPS=($(printf "%s\n" "${DEPS[@]}" | sort -u))
  if [ "${#DEPS[@]}" -gt 0 ]; then
    info "\n $(text 7) $(sed "s//,&/g" <<< "${DEPS[*]}") \n"
    [[ ! "$SYSTEM" =~ Alpine|CentOS ]] && ${PACKAGE_UPDATE[int]} >/dev/null 2>&1
    ${PACKAGE_INSTALL[int]} "${DEPS[@]}" >/dev/null 2>&1
  else
    info "\n $(text 8) \n"
  fi

  # 4. For Alpine systems, ensure that the OpenRC service is started
  if [ "$SYSTEM" = 'Alpine' ]; then
    if ! rc-service --list | grep -q "^openrc"; then
rc-update add openrc boot >/dev/null 2>&1
      rc-service openrc start >/dev/null 2>&1
    fi
  fi
}

# generate UFW PortHopping 备注
add_port_hopping_ufw_rules() {
  local PORT_HOPPING_START=$1
  local PORT_HOPPING_END=$2
  local PORT_HOPPING_TARGET=$3
  local TARGET_PORT="$3"
  local COMMENT="Sing-box Family Bucket UFW NAT ${PORT_HOPPING_START}:${PORT_HOPPING_END} -> ${TARGET_PORT}"

  [ -z "$PORT_HOPPING_START" ] && return 1
  [ -z "$PORT_HOPPING_END" ] && return 1
  [ -z "$TARGET_PORT" ] && return 1

  local UFW_BEFORE_RULES='/etc/ufw/before.rules'
  local UFW_BEFORE6_RULES='/etc/ufw/before6.rules'
  local UFW_IPV4_BLOCK_BEGIN="# ${COMMENT} IPv4 BEGIN"
  local UFW_IPV4_BLOCK_END="# ${COMMENT} IPv4 END"
  local UFW_IPV6_BLOCK_BEGIN="# ${COMMENT} IPv6 BEGIN"
  local UFW_IPV6_BLOCK_END="# ${COMMENT} IPv6 END"

  # First clean up all historical residual rules to ensure that the files and numbered rules are clean
  del_port_hopping_ufw_rules >/dev/null 2>&1

  # Note: TARGET_PORT must be used here, and PORT_HOPPING_TARGET which may be changed by downstream functions cannot be used.
  add_port_hopping_ufw_block "$UFW_BEFORE_RULES"  "$UFW_IPV4_BLOCK_BEGIN" "$UFW_IPV4_BLOCK_END" "$PORT_HOPPING_START" "$PORT_HOPPING_END" "$TARGET_PORT" "$COMMENT" || return 1
  add_port_hopping_ufw_block "$UFW_BEFORE6_RULES" "$UFW_IPV6_BLOCK_BEGIN" "$UFW_IPV6_BLOCK_END" "$PORT_HOPPING_START" "$PORT_HOPPING_END" "$TARGET_PORT" "$COMMENT" || return 1

  ufw delete allow ${PORT_HOPPING_START}:${PORT_HOPPING_END}/udp >/dev/null 2>&1 || true
  ufw allow ${PORT_HOPPING_START}:${PORT_HOPPING_END}/udp comment "$COMMENT" >/dev/null 2>&1 || return 1
  ufw reload >/dev/null 2>&1 || return 1

  [ "$(ufw status 2>/dev/null | awk '/^Status/{print $NF; exit}')" != 'active' ] && warning "\n $(text 145) \n"

  return 0
}

# Writes a PortHopping NAT rule block to the specified UFW rules file
add_port_hopping_ufw_block() {
  local RULES_FILE=$1
  local BLOCK_BEGIN=$2
  local BLOCK_END=$3
  local PORT_HOPPING_START=$4
  local PORT_HOPPING_END=$5
  local PORT_HOPPING_TARGET=$6
  local COMMENT=$7

  [ ! -e "$RULES_FILE" ] && return 0
  [ -z "$PORT_HOPPING_START" ] && return 1
  [ -z "$PORT_HOPPING_END" ] && return 1
  [ -z "$PORT_HOPPING_TARGET" ] && return 1
  [ -z "$COMMENT" ] && return 1

  awk \
    -v begin="$BLOCK_BEGIN" \
    -v end="$BLOCK_END" \
    -v start="$PORT_HOPPING_START" \
    -v finish="$PORT_HOPPING_END" \
    -v target="$PORT_HOPPING_TARGET" \
    -v comment="$COMMENT" '
    BEGIN { inserted=0 }
    {
      if ($0 ~ /^\*filter/ && inserted==0) {
        print begin
        print "*nat"
        print ":PREROUTING ACCEPT [0:0]"
        print "-A PREROUTING -p udp --dport " start ":" finish " -m comment --comment \"" comment "\" -j DNAT --to-destination :" target
        print "COMMIT"
        print end
        inserted=1
      }
      print
    }
    END {
      if (inserted==0) {
        print begin
        print "*nat"
        print ":PREROUTING ACCEPT [0:0]"
        print "-A PREROUTING -p udp --dport " start ":" finish " -m comment --comment \"" comment "\" -j DNAT --to-destination :" target
        print "COMMIT"
        print end
      }
    }
  ' "$RULES_FILE" > "${TEMP_DIR}/$(basename "$RULES_FILE")" && mv "${TEMP_DIR}/$(basename "$RULES_FILE")" "$RULES_FILE"
}

# Delete the PortHopping NAT rule block in the specified UFW rules file
del_port_hopping_ufw_block() {
  local RULES_FILE=$1
  local IP_VERSION=$2
  local TEMP_RULES_FILE

  [ ! -e "$RULES_FILE" ] && return 0

  TEMP_RULES_FILE="${TEMP_DIR}/$(basename "$RULES_FILE")"

  awk -v ip_version="$IP_VERSION" '
    BEGIN { in_block=0 }
    {
      if ($0 ~ "^# Sing-box Family Bucket UFW NAT .* " ip_version " BEGIN$") {
        in_block=1
        next
      }
      if (in_block==1 && $0 ~ "^# Sing-box Family Bucket UFW NAT .* " ip_version " END$") {
        in_block=0
        next
      }
      if (in_block==0) print
    }
  ' "$RULES_FILE" > "$TEMP_RULES_FILE" && mv "$TEMP_RULES_FILE" "$RULES_FILE"
}

# Delete UFW PortHopping NAT rules
del_port_hopping_ufw_rules() {
  local UFW_BEFORE_RULES='/etc/ufw/before.rules'
  local UFW_BEFORE6_RULES='/etc/ufw/before6.rules'
  local COMMENT_PREFIX='Sing-box Family Bucket UFW NAT'
  local RULE_NUM
  local OLD_START OLD_END

  check_port_hopping_ufw_rules
  OLD_START="$PORT_HOPPING_START"
  OLD_END="$PORT_HOPPING_END"

  del_port_hopping_ufw_block "$UFW_BEFORE_RULES" "IPv4" >/dev/null 2>&1
  del_port_hopping_ufw_block "$UFW_BEFORE6_RULES" "IPv6" >/dev/null 2>&1

  if [ -n "$OLD_START" ] && [ -n "$OLD_END" ]; then
    ufw delete allow ${OLD_START}:${OLD_END}/udp >/dev/null 2>&1 || true
  fi

  while read -r RULE_NUM; do
    [ -n "$RULE_NUM" ] && ufw --force delete "$RULE_NUM" >/dev/null 2>&1 || true
  done < <(
    ufw status numbered 2>/dev/null | \
    grep "$COMMENT_PREFIX" | \
    awk -F'[][]' '{print $2}' | sort -rn
  )

  ufw reload >/dev/null 2>&1 || return 1

  unset PORT_HOPPING_START PORT_HOPPING_END PORT_HOPPING_RANGE
  return 0
}

# Check UFW PortHopping NAT rules
check_port_hopping_ufw_rules() {
  unset PORT_HOPPING_START PORT_HOPPING_END PORT_HOPPING_RANGE
  local DETECTED_TARGET
  local UFW_BEFORE_RULES='/etc/ufw/before.rules'
  local UFW_BEFORE6_RULES='/etc/ufw/before6.rules'
  local UFW_RULE

  DETECTED_TARGET=$(awk -F '[:,]' '/"listen_port"/{gsub(/[[:space:]]/, "", $2); print $2; exit}' ${WORK_DIR}/conf/*${NODE_TAG[1]}_inbounds.json 2>/dev/null)

  if [ -s "$UFW_BEFORE_RULES" ]; then
    UFW_RULE=$(awk '
      /Sing-box Family Bucket UFW NAT .* IPv4 BEGIN/ { in_block=1; next }
      /Sing-box Family Bucket UFW NAT .* IPv4 END/   { in_block=0 }
      in_block && /-A PREROUTING -p udp/ { print; exit }
    ' "$UFW_BEFORE_RULES")
  fi

  if [ -z "$UFW_RULE" ] && [ -s "$UFW_BEFORE6_RULES" ]; then
    UFW_RULE=$(awk '
      /Sing-box Family Bucket UFW NAT .* IPv6 BEGIN/ { in_block=1; next }
      /Sing-box Family Bucket UFW NAT .* IPv6 END/   { in_block=0 }
      in_block && /-A PREROUTING -p udp/ { print; exit }
    ' "$UFW_BEFORE6_RULES")
  fi

  [ -z "$UFW_RULE" ] && {
    PORT_HOPPING_TARGET="$DETECTED_TARGET"
    return 0
  }

  if [[ "$UFW_RULE" =~ --dport[[:space:]]+([0-9]+):([0-9]+) ]]; then
    PORT_HOPPING_START="${BASH_REMATCH[1]}"
    PORT_HOPPING_END="${BASH_REMATCH[2]}"
    PORT_HOPPING_RANGE="${PORT_HOPPING_START}:${PORT_HOPPING_END}"
  fi

  if [[ "$UFW_RULE" =~ --to-destination[[:space:]]+:([0-9]+) ]]; then
    PORT_HOPPING_TARGET="${BASH_REMATCH[1]}"
  else
    PORT_HOPPING_TARGET="$DETECTED_TARGET"
  fi
}

# Detect firewall backend
check_firewall_backend() {
  local UFW_STATUS

  if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(ufw status 2>/dev/null | awk '/^Status/{print $NF; exit}')
    [ "$UFW_STATUS" = 'active' ] && {
      echo 'ufw'
      return
    }
  fi

  if [ "$SYSTEM" = 'Alpine' ]; then
    echo 'alpine-iptables'
  elif command -v firewall-cmd >/dev/null 2>&1 || [ "$SYSTEM" = 'CentOS' ]; then
    echo 'firewalld'
  else
    echo 'iptables'
  fi
}

# Compatible with old calls
check_port_hopping_firewall() {
  check_firewall_backend
}

# Initialize firewall status directory
init_firewall_state_dir() {
  [ ! -d "$FIREWALL_STATE_DIR" ] && mkdir -p "$FIREWALL_STATE_DIR"
}

# Read the last common port rule managed by the script
append_unique_port() {
  local ARRAY_NAME=$1
  localPORT=$2
  local -n ARRAY_REF="$ARRAY_NAME"

  [ -z "$PORT" ] && return 0
  [[ ! "$PORT" =~ ^[0-9]+$ ]] && return 0

  local ITEM
  for ITEM in "${ARRAY_REF[@]}"; do
    [ "$ITEM" = "$PORT" ] && return 0
  done

  ARRAY_REF+=("$PORT")
}

# Collect common ports that should be currently open to the outside world
collect_exposed_ports() {
  EXPOSED_TCP_PORTS=()
  EXPOSED_UDP_PORTS=()

  local FILE BASENAME PORT NGINX_PORT HAS_NGINX=false

  if [ -s "${WORK_DIR}/nginx.conf" ]; then
    HAS_NGINX=true
    NGINX_PORT=$(awk '
      /listen[[:space:]]+[0-9]+[[:space:]]*;/ && $2 !~ /^\[/ {
        gsub(/;/, "", $2)
        print $2
        exit
      }
    ' "${WORK_DIR}/nginx.conf")
    append_unique_port EXPOSED_TCP_PORTS "$NGINX_PORT"
  fi

  for FILE in ${WORK_DIR}/conf/*_inbounds.json; do
    [ ! -s "$FILE" ] && continue
    BASENAME=$(basename "$FILE")
    PORT=$(awk -F '[:,]' '/"listen_port"/{gsub(/[[:space:]]/, "", $2); print $2; exit}' "$FILE")
    [ -z "$PORT" ] && continue

    case "$BASENAME" in
      *hysteria2_inbounds.json|*tuic_inbounds.json )
        append_unique_port EXPOSED_UDP_PORTS "$PORT"
        ;;
      *vmess-ws_inbounds.json|*vless-ws-tls_inbounds.json )
        [ "$HAS_NGINX" = false ] && append_unique_port EXPOSED_TCP_PORTS "$PORT"
        ;;
      * )
        append_unique_port EXPOSED_TCP_PORTS "$PORT"
        ;;
    esac
  done
}

#Remarks on UFW common port rules
service_port_ufw_comment() {
  local PROTO=$1
  localPORT=$2
  echo "Sing-box Family Bucket UFW PORT ${PROTO} ${PORT}"
}

# Add UFW common port rules
add_service_port_rule_ufw() {
  local PROTO=$1
  localPORT=$2
  local COMMENT
  COMMENT=$(service_port_ufw_comment "$PROTO" "$PORT")

  [ -z "$PROTO" ] || [ -z "$PORT" ] && return 1
  ufw allow ${PORT}/${PROTO} comment "$COMMENT" >/dev/null 2>&1
}

# Delete UFW common port rules
del_service_port_rule_ufw() {
  local PROTO=$1
  local PORT=$2
  local COMMENT_PREFIX='Sing-box Family Bucket UFW PORT'
  local RULE_NUM

  [ -z "$PROTO" ] || [ -z "$PORT" ] && return 0

  ufw --force delete allow ${PORT}/${PROTO} >/dev/null 2>&1 || true

  while read -r RULE_NUM; do
    [ -n "$RULE_NUM" ] && ufw --force delete "$RULE_NUM" >/dev/null 2>&1 || true
  done < <(
    ufw status numbered 2>/dev/null | \
    grep "$COMMENT_PREFIX ${PROTO} ${PORT}" | \
awk -F'[][]' '{print $2}' | sort -rn
  )
}

# Clean up all UFW common port rules managed by scripts
purge_service_port_rules_ufw() {
  local RULE_NUM
  local COMMENT_PREFIX='Sing-box Family Bucket UFW PORT'

  while read -r RULE_NUM; do
    [ -n "$RULE_NUM" ] && ufw --force delete "$RULE_NUM" >/dev/null 2>&1 || true
  done < <(
    ufw status numbered 2>/dev/null | \
    grep "$COMMENT_PREFIX" | \
    awk -F'[][]' '{print $2}' | sort -rn
  )

  ufw reload >/dev/null 2>&1 || true
}

# Add firewalld common port rules
add_service_port_rule_firewalld() {
  local PROTO=$1
  localPORT=$2
  [ -z "$PROTO" ] || [ -z "$PORT" ] && return 1
  firewall-cmd --zone=public --add-port=${PORT}/${PROTO} --permanent >/dev/null 2>&1
}

# Delete firewalld ordinary port rules
del_service_port_rule_firewalld() {
  local PROTO=$1
  localPORT=$2
  [ -z "$PROTO" ] || [ -z "$PORT" ] && return 0
  firewall-cmd --zone=public --remove-port=${PORT}/${PROTO} --permanent >/dev/null 2>&1
}

# iptables Common port rule remarks
add_service_port_rule_iptables() {
  local PROTO=$1
  local PORT=$2
  local COMMENT="Sing-box Family Bucket PORT ${PROTO} ${PORT}"

  [ -z "$PROTO" ] || [ -z "$PORT" ] && return 1

  iptables -C INPUT -p ${PROTO} --dport ${PORT} -m comment --comment "$COMMENT" -j ACCEPT >/dev/null 2>&1 || \
  iptables -A INPUT -p ${PROTO} --dport ${PORT} -m comment --comment "$COMMENT" -j ACCEPT >/dev/null 2>&1

  ip6tables -C INPUT -p ${PROTO} --dport ${PORT} -m comment --comment "$COMMENT" -j ACCEPT >/dev/null 2>&1 || \
  ip6tables -A INPUT -p ${PROTO} --dport ${PORT} -m comment --comment "$COMMENT" -j ACCEPT >/dev/null 2>&1
}

# Delete iptables common port rules
del_service_port_rule_iptables() {
  local PROTO=$1
  localPORT=$2
  local COMMENT="Sing-box Family Bucket PORT ${PROTO} ${PORT}"

  [ -z "$PROTO" ] || [ -z "$PORT" ] && return 0

  iptables -D INPUT -p ${PROTO} --dport ${PORT} -m comment --comment "$COMMENT" -j ACCEPT >/dev/null 2>&1 || true
  ip6tables -D INPUT -p ${PROTO} --dport ${PORT} -m comment --comment "$COMMENT" -j ACCEPT >/dev/null 2>&1 || true
}

# Save/reload firewall rules by backend
reload_or_save_firewall_rules() {
  local FW_BACKEND
  FW_BACKEND=$(check_firewall_backend)

  case "$FW_BACKEND" in
    ufw )
      ufw reload >/dev/null 2>&1 || true
      ;;
    firewalld )
      firewall-cmd --reload >/dev/null 2>&1 || true
      ;;
    alpine-iptables )
      rc-service iptables save >/dev/null 2>&1 || true
      rc-service ip6tables save >/dev/null 2>&1 || true
      ;;
    * )
      [ "$(systemctl is-active netfilter-persistent 2>/dev/null)" = 'active' ] && netfilter-persistent save >/dev/null 2>&1 || true
      ;;
  esac
}

# Clean up common port rules last managed by a script
purge_service_firewall_rules() {
  local FW_BACKEND
  FW_BACKEND=$(check_firewall_backend)

  init_firewall_state_dir
  MANAGED_TCP_PORTS=()
  MANAGED_UDP_PORTS=()

  [ ! -s "$SERVICE_FIREWALL_STATE_FILE" ] || while read -r PROTO PORT; do
    case "$PROTO" in
      tcp ) MANAGED_TCP_PORTS+=("$PORT") ;;
      udp ) MANAGED_UDP_PORTS+=("$PORT") ;;
    esac
  done < "$SERVICE_FIREWALL_STATE_FILE"

  case "$FW_BACKEND" in
    ufw )
      purge_service_port_rules_ufw
      ;;
    firewalld )
      local PORT
      for PORT in "${MANAGED_TCP_PORTS[@]}"; do
        del_service_port_rule_firewalld tcp "$PORT"
      done
      for PORT in "${MANAGED_UDP_PORTS[@]}"; do
        del_service_port_rule_firewalld udp "$PORT"
      done
      ;;
    alpine-iptables|iptables )
      local PORT
      for PORT in "${MANAGED_TCP_PORTS[@]}"; do
        del_service_port_rule_iptables tcp "$PORT"
      done
      for PORT in "${MANAGED_UDP_PORTS[@]}"; do
        del_service_port_rule_iptables udp "$PORT"
      done
      ;;
  esac

  : > "$SERVICE_FIREWALL_STATE_FILE"
  reload_or_save_firewall_rules
}

# Synchronize common service port rules
# Synchronize all firewall rules
sync_firewall_rules() {
  local FW_BACKEND
  local PORT
  local HY2_FILE="${WORK_DIR}/conf/*${NODE_TAG[1]}_inbounds.json"
  local HY2_TARGET DESIRED_START DESIRED_END
  local EXISTING_START EXISTING_END EXISTING_TARGET
  local FILE BASENAME NGINX_PORT HAS_NGINX=false

  EXPOSED_TCP_PORTS=()
  EXPOSED_UDP_PORTS=()

  if [ -s "${WORK_DIR}/nginx.conf" ]; then
    HAS_NGINX=true
    NGINX_PORT=$(awk '
      /listen[[:space:]]+[0-9]+[[:space:]]*;/ && $2 !~ /^\[/ {
        gsub(/;/, "", $2)
        print $2
        exit
      }
    ' "${WORK_DIR}/nginx.conf")
    append_unique_port EXPOSED_TCP_PORTS "$NGINX_PORT"
  fi

  for FILE in ${WORK_DIR}/conf/*_inbounds.json; do
    [ ! -s "$FILE" ] && continue
    BASENAME=$(basename "$FILE")
    PORT=$(awk -F '[:,]' '/"listen_port"/{gsub(/[[:space:]]/, "", $2); print $2; exit}' "$FILE")
    [ -z "$PORT" ] && continue

    case "$BASENAME" in
      *hysteria2_inbounds.json|*tuic_inbounds.json )
        append_unique_port EXPOSED_UDP_PORTS "$PORT"
        ;;
      *vmess-ws_inbounds.json|*vless-ws-tls_inbounds.json )
        [ "$HAS_NGINX" = false ] && append_unique_port EXPOSED_TCP_PORTS "$PORT"
        ;;
      * )
        append_unique_port EXPOSED_TCP_PORTS "$PORT"
        ;;
    esac
  done

  FW_BACKEND=$(check_firewall_backend)

  init_firewall_state_dir
  MANAGED_TCP_PORTS=()
  MANAGED_UDP_PORTS=()
  if [ -s "$SERVICE_FIREWALL_STATE_FILE" ]; then
    while read -r PROTO PORT; do
      case "$PROTO" in
        tcp ) MANAGED_TCP_PORTS+=("$PORT") ;;
        udp ) MANAGED_UDP_PORTS+=("$PORT") ;;
      esac
    done < "$SERVICE_FIREWALL_STATE_FILE"
  fi

  case "$FW_BACKEND" in
    ufw )
      purge_service_port_rules_ufw
      ;;
    firewalld )
      for PORT in "${MANAGED_TCP_PORTS[@]}"; do
        del_service_port_rule_firewalld tcp "$PORT"
      done
      for PORT in "${MANAGED_UDP_PORTS[@]}"; do
        del_service_port_rule_firewalld udp "$PORT"
      done
      ;;
    alpine-iptables|iptables )
      for PORT in "${MANAGED_TCP_PORTS[@]}"; do
        del_service_port_rule_iptables tcp "$PORT"
      done
      for PORT in "${MANAGED_UDP_PORTS[@]}"; do
        del_service_port_rule_iptables udp "$PORT"
      done
      ;;
  esac

  : > "$SERVICE_FIREWALL_STATE_FILE"
  reload_or_save_firewall_rules

  case "$FW_BACKEND" in
    ufw )
      for PORT in "${EXPOSED_TCP_PORTS[@]}"; do
        add_service_port_rule_ufw tcp "$PORT"
      done
      for PORT in "${EXPOSED_UDP_PORTS[@]}"; do
        add_service_port_rule_ufw udp "$PORT"
      done
      ;;
    firewalld )
      for PORT in "${EXPOSED_TCP_PORTS[@]}"; do
        add_service_port_rule_firewalld tcp "$PORT"
      done
      for PORT in "${EXPOSED_UDP_PORTS[@]}"; do
        add_service_port_rule_firewalld udp "$PORT"
      done
      ;;
    alpine-iptables|iptables )
      for PORT in "${EXPOSED_TCP_PORTS[@]}"; do
        add_service_port_rule_iptables tcp "$PORT"
      done
      for PORT in "${EXPOSED_UDP_PORTS[@]}"; do
        add_service_port_rule_iptables udp "$PORT"
      done
      ;;
  esac

  : > "$SERVICE_FIREWALL_STATE_FILE"
  for PORT in "${EXPOSED_TCP_PORTS[@]}"; do
    [ -n "$PORT" ] && echo "tcp $PORT" >> "$SERVICE_FIREWALL_STATE_FILE"
  done
  for PORT in "${EXPOSED_UDP_PORTS[@]}"; do
    [ -n "$PORT" ] && echo "udp $PORT" >> "$SERVICE_FIREWALL_STATE_FILE"
  done
  reload_or_save_firewall_rules

  HY2_TARGET=$(awk -F '[:,]' '/"listen_port"/{gsub(/[[:space:]]/, "", $2); print $2; exit}' ${HY2_FILE} 2>/dev/null)

  check_port_hopping_nat
  EXISTING_START="$PORT_HOPPING_START"
  EXISTING_END="$PORT_HOPPING_END"
  EXISTING_TARGET="$PORT_HOPPING_TARGET"

  DESIRED_START="${PORT_HOPPING_START:-$EXISTING_START}"
  DESIRED_END="${PORT_HOPPING_END:-$EXISTING_END}"

  if [ -z "$HY2_TARGET" ]; then
    [ -n "$EXISTING_START" ] && [ -n "$EXISTING_END" ] && del_port_hopping_nat
    unset PORT_HOPPING_START PORT_HOPPING_END PORT_HOPPING_RANGE PORT_HOPPING_TARGET
    return 0
  fi

  if [ -z "$DESIRED_START" ] || [ -z "$DESIRED_END" ]; then
    [ -n "$EXISTING_START" ] && [ -n "$EXISTING_END" ] && del_port_hopping_nat
    unset PORT_HOPPING_START PORT_HOPPING_END PORT_HOPPING_RANGE
    PORT_HOPPING_TARGET="$HY2_TARGET"
    return 0
  fi

  if [ "$EXISTING_START" != "$DESIRED_START" ] ||      [ "$EXISTING_END" != "$DESIRED_END" ] ||      [ "$EXISTING_TARGET" != "$HY2_TARGET" ]; then
    [ -n "$EXISTING_START" ] && [ -n "$EXISTING_END" ] && del_port_hopping_nat
    PORT_HOPPING_START="$DESIRED_START"
    PORT_HOPPING_END="$DESIRED_END"
    PORT_HOPPING_RANGE="${DESIRED_START}:${DESIRED_END}"
    PORT_HOPPING_TARGET="$HY2_TARGET"
    add_port_hopping_nat "$PORT_HOPPING_START" "$PORT_HOPPING_END" "$PORT_HOPPING_TARGET"
  fi
}
export_argo_json_file() {
  local FILE_PATH=$1
  [[ -z "$PORT_NGINX" && -s ${WORK_DIR}/nginx.conf ]] && local PORT_NGINX=$(awk '/listen/{print $2; exit}' ${WORK_DIR}/nginx.conf)
  [ ! -s $FILE_PATH/tunnel.json ] && echo $ARGO_JSON > $FILE_PATH/tunnel.json
  [ ! -s $FILE_PATH/tunnel.yml ] && cat > $FILE_PATH/tunnel.yml << EOF
tunnel: $(awk -F '"' '{print $12}' <<< "$ARGO_JSON")
credentials-file: ${WORK_DIR}/tunnel.json

ingress:
  - hostname: ${ARGO_DOMAIN}
    service: http://localhost:${PORT_NGINX}
  - service: http_status:404
EOF
}

# Generate self-signed certificate, use IPv4 /IPv6 /domain name differently
# By default, cert.pem (36500 days) and cert_200.pem (200 days) are updated at the same time
# When passing parameter naive_only, only check whether cert_200.pem is missing/expired/SNI inconsistent, and update only if the conditions are met.
ssl_certificate() {
  local TLS_SERVER="$1"
  local CERT_MODE="$2"
  local CERT_200_FILE="${WORK_DIR}/cert/cert_200.pem"
  local CERT_200_SNI

  [ ! -d ${WORK_DIR}/cert ] && mkdir -p ${WORK_DIR}/cert

  if [ "$CERT_MODE" != 'naive_only' ]; then
    openssl ecparam -genkey -name prime256v1 -out ${WORK_DIR}/cert/private.key
  elif [ ! -s ${WORK_DIR}/cert/private.key ] || [ ! -s ${WORK_DIR}/cert/cert.pem ]; then
    CERT_MODE=''
    openssl ecparam -genkey -name prime256v1 -out ${WORK_DIR}/cert/private.key
  fi

  cat > ${WORK_DIR}/cert/cert.conf << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = $(awk -F . '{print $(NF-1)"."$NF}' <<< "$TLS_SERVER")

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS = ${TLS_SERVER}
EOF

  if [ "$CERT_MODE" != 'naive_only' ]; then
    openssl req -new -x509 -days 36500 -key ${WORK_DIR}/cert/private.key -out ${WORK_DIR}/cert/cert.pem -config ${WORK_DIR}/cert/cert.conf -extensions v3_req
    openssl req -new -x509 -days 200 -key ${WORK_DIR}/cert/private.key -out ${WORK_DIR}/cert/cert_200.pem -config ${WORK_DIR}/cert/cert.conf -extensions v3_req
  else
    CERT_200_SNI=$(openssl x509 -noout -ext subjectAltName -in "$CERT_200_FILE" 2>/dev/null | awk -F 'DNS:' '/DNS:/{gsub(/,.*/, "", $2); print $2}')
    if [ ! -s "$CERT_200_FILE" ] || ! openssl x509 -checkend 0 -noout -in "$CERT_200_FILE" >/dev/null 2>&1 || [ "$CERT_200_SNI" != "$TLS_SERVER" ]; then
      openssl req -new -x509 -days 200 -key ${WORK_DIR}/cert/private.key -out ${WORK_DIR}/cert/cert_200.pem -config ${WORK_DIR}/cert/cert.conf -extensions v3_req
    fi
  fi

  rm -f ${WORK_DIR}/cert/cert.conf
}

# Nginx Configuration file
export_nginx_conf_file() {
  # When adding a protocol and need to use nginx, first check whether it has been installed
  if ! command -v nginx >/dev/null 2>&1; then
    info "\n $(text 7) nginx"
    ${PACKAGE_INSTALL[int]} nginx >/dev/null 2>&1
  fi

  NGINX_CONF="user  root;
worker_processes  auto;

error_log  /dev/null;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
"
  [ "$IS_SUB" = 'is_sub' ] && NGINX_CONF+="
  map \$http_user_agent \$path1 {
    default                    /;               # 默认路径
    ~*v2rayN                   /v2rayn;         # 匹配 V2rayN 客户端
    ~*clash                    /clash;          # 匹配 Clash 客户端
    ~*Neko|Throne              /neko;           # 匹配 Neko / Throne 客户端
    ~*ShadowRocket             /shadowrocket;   # 匹配 ShadowRocket 客户端
    ~*SFM|SFI|SFA              /sing-box;       # 匹配 Sing-box 官方客户端
#   ~*Chrome|Firefox|Mozilla   /;               # 添加更多的分流规则
  }
  map \$http_user_agent \$path2 {
    default                    /;               # 默认路径
    ~*v2rayN                   /v2rayn;         # 匹配 V2rayN 客户端
    ~*clash                    /clash2;         # 匹配 Clash 客户端
    ~*Neko|Throne              /neko;           # 匹配 Neko 客户端
    ~*ShadowRocket             /shadowrocket;   # 匹配 ShadowRocket 客户端
    ~*SFM|SFI|SFA              /sing-box;       # 匹配 Sing-box 官方客户端
#   ~*Chrome|Firefox|Mozilla   /;               # 添加更多的分流规则
  }"

  [ "$IS_SUB" = 'is_sub' ] && NGINX_CONF+="
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
"

  NGINX_CONF+="
    access_log  /dev/null;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    #include /etc/nginx/conf.d/*.conf;

  server {
    listen $PORT_NGINX ;  # ipv4
    listen [::]:$PORT_NGINX ;  # ipv6
    server_name localhost;
"

  [[ -n "$PORT_VMESS_WS" && "$IS_ARGO" = 'is_argo' ]] && NGINX_CONF+="
    # 反代 sing-box vmess websocket
    location /${UUID_CONFIRM}-vmess {
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
    }
"

  [[ -n "$PORT_VLESS_WS" && "$IS_ARGO" = 'is_argo' ]] && NGINX_CONF+="
    # 反代 sing-box vless websocket
    location /${UUID_CONFIRM}-vless {
      if (\$http_upgrade != "websocket") {
         return 404;
      }
      proxy_http_version                  1.1;
      proxy_pass                          https://127.0.0.1:${PORT_VLESS_WS};
      proxy_ssl_protocols                 TLSv1.3;
      proxy_set_header Upgrade            \$http_upgrade;
      proxy_set_header Connection         "upgrade";
      proxy_set_header X-Real-IP          \$remote_addr;
      proxy_set_header X-Forwarded-For    \$proxy_add_x_forwarded_for;
      proxy_set_header Host               \$host;
      proxy_redirect                      off;
    }
"

  [ "$IS_SUB" = 'is_sub' ] && NGINX_CONF+="
    # 来自 /auto2 的分流
    location ~ ^/${UUID_CONFIRM}/auto2 {
      default_type 'text/plain; charset=utf-8';
      alias ${WORK_DIR}/subscribe/\$path2;
    }

    # 来自 /auto 的分流
    location ~ ^/${UUID_CONFIRM}/auto {
      default_type 'text/plain; charset=utf-8';
      alias ${WORK_DIR}/subscribe/\$path1;
    }

    location ~ ^/${UUID_CONFIRM}/(.*) {
      autoindex on;
      proxy_set_header X-Real-IP \$proxy_protocol_addr;
      default_type 'text/plain; charset=utf-8';
      alias ${WORK_DIR}/subscribe/\$1;
    }
"

  NGINX_CONF+="  }
}"

  echo "$NGINX_CONF" > ${WORK_DIR}/nginx.conf
}

# generate sing-box Configuration file
sing-box_json() {
  local IS_CHANGE=$1
  mkdir -p ${WORK_DIR}/conf ${WORK_DIR}/logs ${WORK_DIR}/subscribe

  # Determine whether it is a new installation. If it is not change, it is a new installation.
  if [ "$IS_CHANGE" = 'change' ]; then
    # Determine the path where the sing-box main program is located
    DIR=${WORK_DIR}
  else
    DIR=$TEMP_DIR

    # generate log Configuration
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

    # generate outbound Configuration
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

    # generate endpoint Configuration
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

    # generate route Configuration
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

    # generate cache files
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

    # generate dns Configuration file
    cat > ${WORK_DIR}/conf/05_dns.json << EOF
{
    "dns":{
        "servers":[
            {
                "type":"local",
                "prefer_go": ${IS_PREFER_GO}
            }
        ],
        "strategy": "${STRATEGY}"
    }
}
EOF

    # Built-in NTP client service Configuration file, which is useful in environments where time synchronization is not possible
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
  fi

  # generate Reality public and private keys. When installing for the first time, if there is a specified private key, use the private key and the public key corresponding to generate; if no private key is specified, use the new generated one; when adding a protocol, use the first non-empty value in the corresponding array. If it is empty, use the new generated one as in the first installation.
  generate_reality_keypair() {
    [ "$1" = 'convert_error' ] && hint " $(text 116) "
    REALITY_KEYPAIR=$($DIR/sing-box generate reality-keypair) && REALITY_PRIVATE=$(awk '/PrivateKey/{print $NF}' <<< "$REALITY_KEYPAIR") && REALITY_PUBLIC=$(awk '/PublicKey/{print $NF}' <<< "$REALITY_KEYPAIR")
  }

  if [[ "${#REALITY_PRIVATE}" = 43 && "${#REALITY_PUBLIC}" = 0 ]]; then
    if command -v xxd >/dev/null 2>&1; then
      until [ -n "$REALITY_PUBLIC" ]; do
        # convert base64url -> base64 (standard), add padding
        local B64=$(printf '%s' "$REALITY_PRIVATE" | tr '_-' '/+')
        local MOD=$(( ${#B64} % 4 ))
        if [ $MOD -eq 2 ]; then
          B64="${B64}=="
        elif [ $MOD -eq 3 ]; then
          B64="${B64}="
        elif [ $MOD -eq 1 ]; then
          generate_reality_keypair convert_error
          continue
        fi

        # decode to raw 32 bytes
        echo "$B64" | base64 -d > $TEMP_DIR/_X25519_PRIV_RAW || { generate_reality_keypair convert_error; continue; }

        local PRIV_LEN=$(stat -c%s $TEMP_DIR/_X25519_PRIV_RAW 2>/dev/null || stat -f%z $TEMP_DIR/_X25519_PRIV_RAW)
        [ "$PRIV_LEN" -ne 32 ] && { generate_reality_keypair convert_error; continue; }

        # DER prefix for PKCS#8 private key with OID 1.3.101.110 (X25519)
        # Hex: 30 2e 02 01 00 30 05 06 03 2b 65 6e 04 22 04 20
        local PREFIX_HEX="302e020100300506032b656e04220420"

        # append raw private key hex and create DER
        local PRIV_HEX=$(xxd -p -c 256 $TEMP_DIR/_X25519_PRIV_RAW | tr -d '\n')
        printf "%s%s" "$PREFIX_HEX" "$PRIV_HEX" | xxd -r -p > $TEMP_DIR/_X25519_PRIV_DER

        # convert DER PKCS8 -> PEM private key
        openssl pkcs8 -inform DER -in $TEMP_DIR/_X25519_PRIV_DER -nocrypt -out $TEMP_DIR/_X25519_PRIV_PEM 2>/dev/null

        # extract public key in DER
        openssl pkey -in $TEMP_DIR/_X25519_PRIV_PEM -pubout -outform DER > $TEMP_DIR/_X25519_PUB_DER 2>/dev/null

        # last 32 bytes are the raw public key
        tail -c 32 $TEMP_DIR/_X25519_PUB_DER > $TEMP_DIR/_X25519_PUB_RAW

        # encode to base64url (no padding)
        REALITY_PUBLIC=$(base64 -w0 $TEMP_DIR/_X25519_PUB_RAW | tr '+/' '-_' | sed -E 's/=+$//')
      done
    else
      REALITY_PUBLIC=$(wget --no-check-certificate -qO- --tries=3 --timeout=2 https://realitykey.cloudflare.now.cc/?privateKey=$REALITY_PRIVATE | awk -F '"' '/publicKey/{print $4}')
    fi
  elif [[ "${#REALITY_PRIVATE[@]}" = 0 && "${#REALITY_PUBLIC[@]}" = 0 ]]; then
    generate_reality_keypair new_keypair
  else
    REALITY_PRIVATE=$(awk '{print $1}' <<< "${REALITY_PRIVATE[@]}") && REALITY_PUBLIC=$(awk '{print $1}' <<< "${REALITY_PUBLIC[@]}")
  fi

  # Get the domain name of the self-signed certificate
  TLS_SERVER=$(openssl x509 -noout -ext subjectAltName -in ${WORK_DIR}/cert/cert.pem 2>/dev/null | awk -F 'DNS:' '/DNS:/{gsub(/,.*/, "", $2); print $2}')

  # naive When adding a new protocol with -r, if cert_200.pem is expired/missing/SNI is inconsistent, it will be automatically updated.
  [[ "${INSTALL_PROTOCOLS[@]}" =~ 'm' ]] && ssl_certificate "$TLS_SERVER" naive_only

  # generate 2022-blake3-aes-128-gcm of password
  local SIP022_PASSWORD=${SIP022_PASSWORD:-"$(openssl rand -base64 16)"}

  # The first agreement is b (a is all)，generate XTLS + Reality Configuration
  CHECK_PROTOCOLS=b
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_XTLS_REALITY" ] && PORT_XTLS_REALITY=$(( START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}") ))
    NODE_NAME[11]=${NODE_NAME[11]:-"$NODE_NAME_CONFIRM"} && UUID[11]=${UUID[11]:-"$UUID_CONFIRM"} && REALITY_PRIVATE[11]=${REALITY_PRIVATE[11]:-"$REALITY_PRIVATE"} && REALITY_PUBLIC[11]=${REALITY_PUBLIC[11]:-"$REALITY_PUBLIC"} &&
    cat > ${WORK_DIR}/conf/11_${NODE_TAG[0]}_inbounds.json << EOF
//  "public_key":"${REALITY_PUBLIC[11]}"
{
    "inbounds":[
        {
            "type":"vless",
            "tag":"${NODE_NAME[11]} ${NODE_TAG[0]}",
            "listen":"::",
            "listen_port":$PORT_XTLS_REALITY,
            "users":[
                {
                    "uuid":"${UUID[11]}",
                    "flow":"xtls-rprx-vision"
                }
            ],
            "tls":{
                "enabled":true,
                "server_name":"${TLS_SERVER}",
                "reality":{
                    "enabled":true,
                    "handshake":{
                        "server":"${TLS_SERVER}",
                        "server_port":443
                    },
                    "private_key":"${REALITY_PRIVATE[11]}",
                    "short_id":[
                        ""
                    ]
                }
            },
            "multiplex":{
                "enabled":false,
                "padding":false,
                "brutal":{
                    "enabled":false,
                    "up_mbps":1000,
                    "down_mbps":1000
                }
            }
        }
    ]
}
EOF
  fi

  # generate Hysteria2 Configuration
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_HYSTERIA2" ] && PORT_HYSTERIA2=$[START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")]
    [ "$IS_HOPPING" = 'is_hopping' ] && add_port_hopping_nat $PORT_HOPPING_START $PORT_HOPPING_END $PORT_HYSTERIA2
    NODE_NAME[12]=${NODE_NAME[12]:-"$NODE_NAME_CONFIRM"} && UUID[12]=${UUID[12]:-"$UUID_CONFIRM"}
    cat > ${WORK_DIR}/conf/12_${NODE_TAG[1]}_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"hysteria2",
            "tag":"${NODE_NAME[12]} ${NODE_TAG[1]}",
            "listen":"::",
            "listen_port":$PORT_HYSTERIA2,
            "users":[
                {
                    "password":"${UUID[12]}"
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
  fi

  # generate Tuic V5 Configuration
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_TUIC" ] && PORT_TUIC=$[START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")]
    NODE_NAME[13]=${NODE_NAME[13]:-"$NODE_NAME_CONFIRM"} && UUID[13]=${UUID[13]:-"$UUID_CONFIRM"} && TUIC_PASSWORD=${TUIC_PASSWORD:-"$UUID_CONFIRM"} && TUIC_CONGESTION_CONTROL=${TUIC_CONGESTION_CONTROL:-"bbr"}
    cat > ${WORK_DIR}/conf/13_${NODE_TAG[2]}_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"tuic",
            "tag":"${NODE_NAME[13]} ${NODE_TAG[2]}",
            "listen":"::",
            "listen_port":$PORT_TUIC,
            "users":[
                {
                    "uuid":"${UUID[13]}",
                    "password":"$TUIC_PASSWORD"
                }
            ],
            "congestion_control": "$TUIC_CONGESTION_CONTROL",
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
  fi

  # generate ShadowTLS V5 Configuration
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_SHADOWTLS" ] && PORT_SHADOWTLS=$[START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")]
    NODE_NAME[14]=${NODE_NAME[14]:-"$NODE_NAME_CONFIRM"} && UUID[14]=${UUID[14]:-"$UUID_CONFIRM"} && SHADOWTLS_PASSWORD=${SHADOWTLS_PASSWORD:-"$SIP022_PASSWORD"} && SHADOWTLS_METHOD=${SHADOWTLS_METHOD:-"2022-blake3-aes-128-gcm"}

    cat > ${WORK_DIR}/conf/14_${NODE_TAG[3]}_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"shadowtls",
            "tag":"${NODE_NAME[14]} ${NODE_TAG[3]}",
            "listen":"::",
            "listen_port":$PORT_SHADOWTLS,
            "detour":"shadowtls-in",
            "version":3,
            "users":[
                {
                    "password":"${UUID[14]}"
                }
            ],
            "handshake":{
                "server":"${TLS_SERVER}",
                "server_port":443
            },
            "strict_mode":true
        },
        {
            "type":"shadowsocks",
            "tag":"shadowtls-in",
            "listen":"127.0.0.1",
            "network":"tcp",
            "method":"$SHADOWTLS_METHOD",
            "password":"$SHADOWTLS_PASSWORD",
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
  fi

  # generate Shadowsocks Configuration
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_SHADOWSOCKS" ] && PORT_SHADOWSOCKS=$[START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")]
    NODE_NAME[15]=${NODE_NAME[15]:-"$NODE_NAME_CONFIRM"} && SHADOWSOCKS_PASSWORD=${SHADOWSOCKS_PASSWORD:-"$SIP022_PASSWORD"} && SHADOWSOCKS_METHOD=${SHADOWSOCKS_METHOD:-"2022-blake3-aes-128-gcm"}
    cat > ${WORK_DIR}/conf/15_${NODE_TAG[4]}_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"shadowsocks",
            "tag":"${NODE_NAME[15]} ${NODE_TAG[4]}",
            "listen":"::",
            "listen_port":$PORT_SHADOWSOCKS,
            "method":"${SHADOWSOCKS_METHOD}",
            "password":"${SHADOWSOCKS_PASSWORD}",
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
  fi

  # generate Trojan Configuration
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_TROJAN" ] && PORT_TROJAN=$[START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")]
    NODE_NAME[16]=${NODE_NAME[16]:-"$NODE_NAME_CONFIRM"} && TROJAN_PASSWORD=${TROJAN_PASSWORD:-"$UUID_CONFIRM"}
    cat > ${WORK_DIR}/conf/16_${NODE_TAG[5]}_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"trojan",
            "tag":"${NODE_NAME[16]} ${NODE_TAG[5]}",
            "listen":"::",
            "listen_port":$PORT_TROJAN,
            "users":[
                {
                    "password":"$TROJAN_PASSWORD"
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
  fi

  # generate vmess + ws Configuration
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_VMESS_WS" ] && PORT_VMESS_WS=$[START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")]
    NODE_NAME[17]=${NODE_NAME[17]:-"$NODE_NAME_CONFIRM"} && UUID[17]=${UUID[17]:-"$UUID_CONFIRM"} && WS_SERVER_IP[17]=${WS_SERVER_IP[17]:-"$SERVER_IP"} && CDN[17]=${CDN[17]:-"$CDN"} && VMESS_WS_PATH=${VMESS_WS_PATH:-"${UUID[17]}-vmess"}
    cat > ${WORK_DIR}/conf/17_${NODE_TAG[6]}_inbounds.json << EOF
//  "WS_SERVER_IP_SHOW": "${WS_SERVER_IP[17]}"
//  "VMESS_HOST_DOMAIN": "${VMESS_HOST_DOMAIN}${ARGO_DOMAIN}"
//  "CDN": "${CDN[17]}"
{
    "inbounds":[
        {
            "type":"vmess",
            "tag":"${NODE_NAME[17]} ${NODE_TAG[6]}",
            "listen":"::",
            "listen_port":$PORT_VMESS_WS,
            "tcp_fast_open":false,
            "proxy_protocol":false,
            "users":[
                {
                    "uuid":"${UUID[17]}",
                    "alterId":0
                }
            ],
            "transport":{
                "type":"ws",
                "path":"/$VMESS_WS_PATH",
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
  fi

  # generate vless + ws + tls Configuration
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_VLESS_WS" ] && PORT_VLESS_WS=$[START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")]
    NODE_NAME[18]=${NODE_NAME[18]:-"$NODE_NAME_CONFIRM"} && UUID[18]=${UUID[18]:-"$UUID_CONFIRM"} && WS_SERVER_IP[18]=${WS_SERVER_IP[18]:-"$SERVER_IP"} && CDN[18]=${CDN[18]:-"$CDN"} && VLESS_WS_PATH=${VLESS_WS_PATH:-"${UUID[18]}-vless"}
    cat > ${WORK_DIR}/conf/18_${NODE_TAG[7]}_inbounds.json << EOF
//  "WS_SERVER_IP_SHOW": "${WS_SERVER_IP[18]}"
//  "CDN": "${CDN[18]}"
{
    "inbounds":[
        {
            "type":"vless",
            "tag":"${NODE_NAME[18]} ${NODE_TAG[7]}",
            "listen":"::",
            "listen_port":$PORT_VLESS_WS,
            "tcp_fast_open":false,
            "proxy_protocol":false,
            "users":[
                {
                    "name":"sing-box",
                    "uuid":"${UUID[18]}"
                }
            ],
            "transport":{
                "type":"ws",
                "path":"/$VLESS_WS_PATH",
                "max_early_data":2560,
                "early_data_header_name":"Sec-WebSocket-Protocol"
            },
            "tls":{
                "enabled":true,
                "server_name":"${VLESS_HOST_DOMAIN}${ARGO_DOMAIN}",
                "min_version":"1.3",
                "max_version":"1.3",
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
  fi

  # generate H2 + Reality Configuration
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_H2_REALITY" ] && PORT_H2_REALITY=$[START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")]
    NODE_NAME[19]=${NODE_NAME[19]:-"$NODE_NAME_CONFIRM"} && UUID[19]=${UUID[19]:-"$UUID_CONFIRM"} && REALITY_PRIVATE[19]=${REALITY_PRIVATE[19]:-"$REALITY_PRIVATE"} && REALITY_PUBLIC[19]=${REALITY_PUBLIC[19]:-"$REALITY_PUBLIC"}
    cat > ${WORK_DIR}/conf/19_${NODE_TAG[8]}_inbounds.json << EOF
//  "public_key":"${REALITY_PUBLIC[19]}"
{
    "inbounds":[
        {
            "type":"vless",
            "tag":"${NODE_NAME[19]} ${NODE_TAG[8]}",
            "listen":"::",
            "listen_port":$PORT_H2_REALITY,
            "users":[
                {
                    "uuid":"${UUID[19]}"
                }
            ],
            "tls":{
                "enabled":true,
                "server_name":"${TLS_SERVER}",
                "reality":{
                    "enabled":true,
                    "handshake":{
                        "server":"${TLS_SERVER}",
                        "server_port":443
                    },
                    "private_key":"${REALITY_PRIVATE[19]}",
                    "short_id":[
                        ""
                    ]
                }
            },
            "transport":{
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
  fi

  # generate gRPC + Reality Configuration
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_GRPC_REALITY" ] && PORT_GRPC_REALITY=$[START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")]
    NODE_NAME[20]=${NODE_NAME[20]:-"$NODE_NAME_CONFIRM"} && UUID[20]=${UUID[20]:-"$UUID_CONFIRM"} && REALITY_PRIVATE[20]=${REALITY_PRIVATE[20]:-"$REALITY_PRIVATE"} && REALITY_PUBLIC[20]=${REALITY_PUBLIC[20]:-"$REALITY_PUBLIC"}
    cat > ${WORK_DIR}/conf/20_${NODE_TAG[9]}_inbounds.json << EOF
//  "public_key":"${REALITY_PUBLIC[20]}"
{
    "inbounds":[
        {
            "type":"vless",
            "tag":"${NODE_NAME[20]} ${NODE_TAG[9]}",
            "listen":"::",
            "listen_port":$PORT_GRPC_REALITY,
            "users":[
                {
                    "uuid":"${UUID[20]}"
                }
            ],
            "tls":{
                "enabled":true,
                "server_name":"${TLS_SERVER}",
                "reality":{
                    "enabled":true,
                    "handshake":{
                        "server":"${TLS_SERVER}",
                        "server_port":443
                    },
                    "private_key":"${REALITY_PRIVATE[20]}",
                    "short_id":[
                        ""
                    ]
                }
            },
            "transport":{
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
  fi

  # generate anytls Configuration
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_ANYTLS" ] && PORT_ANYTLS=$[START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")]
    NODE_NAME[21]=${NODE_NAME[21]:-"$NODE_NAME_CONFIRM"} && UUID[21]=${UUID[21]:-"$UUID_CONFIRM"}

    cat > ${WORK_DIR}/conf/21_${NODE_TAG[10]}_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"anytls",
            "tag":"${NODE_NAME[21]} ${NODE_TAG[10]}",
            "listen":"::",
            "listen_port":$PORT_ANYTLS,
            "users":[
                {
                    "password":"${UUID[21]}"
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
  fi

  # Generate naive configuration
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    [ -z "$PORT_NAIVE" ] && PORT_NAIVE=$[START_PORT+$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")]
    NODE_NAME[22]=${NODE_NAME[22]:-"$NODE_NAME_CONFIRM"} && UUID[22]=${UUID[22]:-"$UUID_CONFIRM"}

    cat > ${WORK_DIR}/conf/22_${NODE_TAG[11]}_inbounds.json << EOF
{
    "inbounds":[
        {
            "type":"naive",
            "tag":"${NODE_NAME[22]} ${NODE_TAG[11]}",
            "listen":"::",
            "listen_port":$PORT_NAIVE,
            "users":[
                {
                    "username":"${UUID[22]}",
                    "password":"${UUID[22]}"
                }
            ],
            "tls":{
                "enabled":true,
                "certificate_path":"${WORK_DIR}/cert/cert_200.pem",
                "key_path":"${WORK_DIR}/cert/private.key"
            }
        }
    ]
}
EOF
  fi
}

# Sing-box Generate daemon file
sing-box_systemd() {
  if [ "$SYSTEM" = 'Alpine' ]; then
    local OPENRC_SERVICE="#!/sbin/openrc-run

name=\"sing-box\"
description=\"sing-box service\"
command=\"${WORK_DIR}/sing-box\"
command_args=\"run -C ${WORK_DIR}/conf\"
pidfile=\"/var/run/\${RC_SVCNAME}.pid\"
command_background=\"yes\"
output_log=\"${WORK_DIR}/logs/sing-box.log\"
error_log=\"${WORK_DIR}/logs/sing-box.log\"

depend() {
    need net
    after net"

    # If Nginx is configured, add dependencies
    [ -n "$PORT_NGINX" ] && OPENRC_SERVICE+="
    need nginx"

    # Add the start_pre function to ensure the directory exists and set correct permissions
    OPENRC_SERVICE+="
}

start_pre() {
    # Make sure the log directory and PID directory exist and have correct permissions
    mkdir -p ${WORK_DIR}/logs
    mkdir -p /var/run
    chmod 755 /var/run"

    # If Nginx is configured, start Nginx
    [ -n "$PORT_NGINX" ] && OPENRC_SERVICE+="
    $(command -v nginx) -c ${WORK_DIR}/nginx.conf"

    OPENRC_SERVICE+="
    # Make sure the PID file does not exist to avoid startup failure
    rm -f \$pidfile
}"

    # Add the stop_post function to clean up the nginx process after the service is stopped.
    [ -n "$PORT_NGINX" ] && OPENRC_SERVICE+="

stop_post() {
    # 停止 nginx：优先用内置命令
    if command -v /usr/sbin/nginx >/dev/null 2>&1; then
        /usr/sbin/nginx -s quit -c ${WORK_DIR}/nginx.conf 2>/dev/null
        sleep 1 # 等待优雅关闭
        # 如果仍运行，用 SIGKILL
        local NGINX_MASTER=\$(pgrep -f \"nginx: master process /usr/sbin/nginx -c ${WORK_DIR}/nginx.conf\")
        if [ -n \"\$NGINX_MASTER\" ]; then
            kill -KILL \$NGINX_MASTER 2>/dev/null
        fi
    fi
}

stop() {
    ebegin \"Stopping \${RC_SVCNAME}\"
    # 先停止主进程（OpenRC 会调用）
    start-stop-daemon --stop --pidfile \$pidfile --retry 5
    eend \$? \"Failed to stop \${RC_SVCNAME}\"

    # 然后运行 post 清理
    stop_post
}"

    echo "$OPENRC_SERVICE" > ${SINGBOX_DAEMON_FILE}
    chmod +x ${SINGBOX_DAEMON_FILE}
  else
    # Original systemd service creation code
    SING_BOX_SERVICE="[Unit]
Description=sing-box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
User=root
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
WorkingDirectory=${WORK_DIR}
"
    [[ -n "$PORT_NGINX" && "$IS_CENTOS" != 'CentOS7' ]] && SING_BOX_SERVICE+="ExecStartPre=$(command -v nginx) -c ${WORK_DIR}/nginx.conf
"
    SING_BOX_SERVICE+="ExecStart=${WORK_DIR}/sing-box run -C ${WORK_DIR}/conf
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target"

    echo "$SING_BOX_SERVICE" > ${SINGBOX_DAEMON_FILE}
    systemctl daemon-reload
  fi
}

# Argo Generate daemon file
argo_systemd() {
  if [ "$SYSTEM" = 'Alpine' ]; then
    # Separate commands and parameters
    local COMMAND="${ARGO_RUNS%% --*}"   # Extract the command part (including cloudflared tunnel）
    local ARGS="${ARGO_RUNS#$COMMAND }"  # Extract parameter part

    cat > ${ARGO_DAEMON_FILE} << EOF
#!/sbin/openrc-run

name="argo"
description="Cloudflare Tunnel service"
command="${COMMAND}"
command_args="${ARGS}"
pidfile="/var/run/\${RC_SVCNAME}.pid"
command_background="yes"
output_log="${WORK_DIR}/logs/argo.log"
error_log="${WORK_DIR}/logs/argo.log"

depend() {
    need net
    after net
}

start_pre() {
    # Make sure the log directory and PID directory exist and have correct permissions
    mkdir -p ${WORK_DIR}/logs
    mkdir -p /var/run
    chmod 755 /var/run

    # Make sure the PID file does not exist to avoid startup failure
    rm -f \$pidfile
}
EOF
    chmod +x ${ARGO_DAEMON_FILE}
  else
    # Original systemd service creation code
    cat > ${ARGO_DAEMON_FILE} << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
WorkingDirectory=$WORK_DIR
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=${ARGO_RUNS}
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
  fi
}

# Get existing parameters for each protocol, first clear all key-value pairs
fetch_nodes_value() {
  unset NODE_NAME PORT_XTLS_REALITY UUID TLS_SERVER REALITY_PRIVATE REALITY_PUBLIC PORT_HYSTERIA2 PORT_TUIC TUIC_PASSWORD TUIC_CONGESTION_CONTROL PORT_SHADOWTLS SHADOWTLS_PASSWORD SHADOWSOCKS_METHOD PORT_SHADOWSOCKS PORT_TROJAN TROJAN_PASSWORD PORT_VMESS_WS VMESS_WS_PATH WS_SERVER_IP WS_SERVER_IP_SHOW VMESS_HOST_DOMAIN CDN PORT_VLESS_WS VLESS_WS_PATH VLESS_HOST_DOMAIN PORT_H2_REALITY PORT_GRPC_REALITY ARGO_DOMAIN PORT_ANYTLS PORT_NAIVE SELF_SIGNED_FINGERPRINT_SHA256 SELF_SIGNED_FINGERPRINT_BASE64

  # Get public data
  ls ${WORK_DIR}/conf/*-ws*inbounds.json >/dev/null 2>&1 && SERVER_IP=$(awk -F '"' '/"WS_SERVER_IP_SHOW"/{print $4; exit}' ${WORK_DIR}/conf/*-ws*inbounds.json) || SERVER_IP=$(grep -A1 '"tag"' ${WORK_DIR}/list | sed -E '/-ws(-tls)*",$/{N;d}' | awk -F '"' '/"server"/{count++; if (count == 1) {print $4; exit}}')
  EXISTED_PORTS=$(awk -F ':|,' '/listen_port/{print $2}' ${WORK_DIR}/conf/*_inbounds.json)
  START_PORT=$(awk 'NR == 1 { min = $0 } { if ($0 < min) min = $0; count++ } END {print min}' <<< "$EXISTED_PORTS")
  [[ -z "$NODE_NAME_CONFIRM" && -s ${WORK_DIR}/subscribe/clash ]] && NODE_NAME_CONFIRM=$(awk -F "'" '/u: &u/{print $2; exit}' ${WORK_DIR}/subscribe/clash)

  # If any Argo，Get Argo Tunnel
  [[ ${STATUS[1]} =~ $(text 27)|$(text 28) ]] && grep -q '\--url' ${ARGO_DAEMON_FILE} && { cmd_systemctl enable argo; sleep 2 && cmd_systemctl status argo &>/dev/null && fetch_quicktunnel_domain; }

  # Get Nginx port and path
  [[ "${IS_SUB}" = 'is_sub' || "${IS_ARGO}" = 'is_argo' ]] && local NGINX_JSON=$(cat ${WORK_DIR}/nginx.conf) &&
  PORT_NGINX=$(awk '/listen/{print $2; exit}' <<< "$NGINX_JSON") &&
  UUID_CONFIRM=$(grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' <<< "$NGINX_JSON" | sed -n '1p')

  # Get XTLS + Reality key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[0]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[0]}_inbounds.json) && NODE_NAME[11]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[0]}.*/\1/p" <<< "$JSON") && PORT_XTLS_REALITY=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && UUID[11]=$(awk -F '"' '/"uuid"/{print $4}' <<< "$JSON") && REALITY_PRIVATE[11]=$(awk -F '"' '/"private_key"/{print $4}' <<< "$JSON") && REALITY_PUBLIC[11]=$(awk -F '"' '/"public_key"/{print $4}' <<< "$JSON")

  # Get Hysteria2 key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[1]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[1]}_inbounds.json) && NODE_NAME[12]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[1]}.*/\1/p" <<< "$JSON") && PORT_HYSTERIA2=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && UUID[12]=$(awk -F '"' '/"password"/{count++; if (count == 1) {print $4; exit}}' <<< "$JSON") && check_port_hopping_nat

  # Get Tuic V5 key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[2]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[2]}_inbounds.json) && NODE_NAME[13]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[2]}.*/\1/p" <<< "$JSON") && PORT_TUIC=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && UUID[13]=$(awk -F '"' '/"uuid"/{print $4}' <<< "$JSON") && TUIC_PASSWORD=$(awk -F '"' '/"password"/{print $4}' <<< "$JSON") && TUIC_CONGESTION_CONTROL=$(awk -F '"' '/"congestion_control"/{print $4}' <<< "$JSON")

  # Get ShadowTLS key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[3]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[3]}_inbounds.json) && NODE_NAME[14]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[3]}.*/\1/p" <<< "$JSON") && PORT_SHADOWTLS=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && UUID[14]=$(awk -F '"' '/"password"/{count++; if (count == 1) {print $4; exit}}' <<< "$JSON") && SHADOWTLS_PASSWORD=$(awk -F '"' '/"password"/{count++; if (count == 2) {print $4; exit}}' <<< "$JSON") && SHADOWTLS_METHOD=$(awk -F '"' '/"method"/{print $4}' <<< "$JSON")

  # Get Shadowsocks key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[4]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[4]}_inbounds.json) && NODE_NAME[15]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[4]}.*/\1/p" <<< "$JSON") && PORT_SHADOWSOCKS=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && SHADOWSOCKS_PASSWORD=$(awk -F '"' '/"password"/{print $4}' <<< "$JSON") && SHADOWSOCKS_METHOD=$(awk -F '"' '/"method"/{print $4}' <<< "$JSON")

  # Get Trojan key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[5]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[5]}_inbounds.json) && NODE_NAME[16]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[5]}.*/\1/p" <<< "$JSON") && PORT_TROJAN=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && TROJAN_PASSWORD=$(awk -F '"' '/"password"/{print $4}' <<< "$JSON")

  # Get vmess + ws key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[6]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[6]}_inbounds.json) && NODE_NAME[17]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[6]}.*/\1/p" <<< "$JSON") && PORT_VMESS_WS=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && UUID[17]=$(awk -F '"' '/"uuid"/{print $4}' <<< "$JSON") && VMESS_WS_PATH=$(sed -n 's#.*"path":"/\(.*\)",#\1#p' <<< "$JSON") && WS_SERVER_IP[17]=$(awk  -F '"' '/"WS_SERVER_IP_SHOW"/{print $4}' <<< "$JSON") && CDN[17]=$(awk  -F '"' '/"CDN"/{print $4}' <<< "$JSON") && [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] && ARGO_DOMAIN=$(awk  -F '"' '/"VMESS_HOST_DOMAIN"/{print $4}' <<< "$JSON") || VMESS_HOST_DOMAIN=$(awk  -F '"' '/"VMESS_HOST_DOMAIN"/{print $4}' <<< "$JSON")

  # Get vless + ws + tls key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[7]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[7]}_inbounds.json) && NODE_NAME[18]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[7]}.*/\1/p" <<< "$JSON") && PORT_VLESS_WS=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && UUID[18]=$(awk -F '"' '/"uuid"/{print $4}' <<< "$JSON") && VLESS_WS_PATH=$(sed -n 's#.*"path":"/\(.*\)",#\1#p' <<< "$JSON") && WS_SERVER_IP[18]=$(awk  -F '"' '/"WS_SERVER_IP_SHOW"/{print $4}' <<< "$JSON") && CDN[18]=$(awk  -F '"' '/"CDN"/{print $4}' <<< "$JSON") && [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] && ARGO_DOMAIN=$(awk -F '"' '/"server_name"/{print $4}' <<< "$JSON") || VLESS_HOST_DOMAIN=$(awk -F '"' '/"server_name"/{print $4}' <<< "$JSON")

  # Get H2 + Reality key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[8]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[8]}_inbounds.json) && NODE_NAME[19]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[8]}.*/\1/p" <<< "$JSON") && PORT_H2_REALITY=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && UUID[19]=$(awk -F '"' '/"uuid"/{print $4}' <<< "$JSON") && REALITY_PRIVATE[19]=$(awk -F '"' '/"private_key"/{print $4}' <<< "$JSON") && REALITY_PUBLIC[19]=$(awk -F '"' '/"public_key"/{print $4}' <<< "$JSON")

  # Get gRPC + Reality key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[9]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[9]}_inbounds.json) && NODE_NAME[20]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[9]}.*/\1/p" <<< "$JSON") && PORT_GRPC_REALITY=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && UUID[20]=$(awk -F '"' '/"uuid"/{print $4}' <<< "$JSON") && REALITY_PRIVATE[20]=$(awk -F '"' '/"private_key"/{print $4}' <<< "$JSON") && REALITY_PUBLIC[20]=$(awk -F '"' '/"public_key"/{print $4}' <<< "$JSON")

  # Get anytls key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[10]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[10]}_inbounds.json) && NODE_NAME[21]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[10]}.*/\1/p" <<< "$JSON") && PORT_ANYTLS=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && UUID[21]=$(awk -F '"' '/"password"/{print $4}' <<< "$JSON")

  # Get naive key-value
  [ -s ${WORK_DIR}/conf/*_${NODE_TAG[11]}_inbounds.json ] && local JSON=$(cat ${WORK_DIR}/conf/*_${NODE_TAG[11]}_inbounds.json) && NODE_NAME[22]=$(sed -n "s/.*\"tag\":\"\(.*\) ${NODE_TAG[11]}.*/\1/p" <<< "$JSON") && PORT_NAIVE=$(sed -n 's/.*"listen_port":\([0-9]\+\),/\1/gp' <<< "$JSON") && UUID[22]=$(awk -F '"' '/"username"/{print $4; exit}' <<< "$JSON")
}

# Get Argo Temporary tunnel domain name
fetch_quicktunnel_domain() {
  unset CLOUDFLARED_PID METRICS_ADDRESS ARGO_DOMAIN
  local QUICKTUNNEL_ERROR_TIME=20
  until [ -n "$ARGO_DOMAIN" ]; do
    local CLOUDFLARED_PID=$(ps -eo pid,args | awk -v work_dir="$WORK_DIR" '$0~(work_dir"/cloudflared"){print $1;exit}')
    [[ -z "$METRICS_ADDRESS" && "$CLOUDFLARED_PID" =~ ^[0-9]+$ ]] && local METRICS_ADDRESS=$(ss -nltp | grep "pid=$CLOUDFLARED_PID" | awk '{print $4}')
    [ -n "$METRICS_ADDRESS" ] && ARGO_DOMAIN=$(wget -qO- http://$METRICS_ADDRESS/quicktunnel | awk -F '"' '{print $4}')
    if [[ ! "$ARGO_DOMAIN" =~ trycloudflare\.com$ ]]; then
      (( QUICKTUNNEL_ERROR_TIME-- )) || true
      [ "$QUICKTUNNEL_ERROR_TIME" = '0' ] && error " $(text 93) "
      sleep 2
    else
      break
    fi
  done

  # Write the temporary tunnel to the corresponding ws inbounds file of Sing-box
  [ -s ${WORK_DIR}/conf/17_${NODE_TAG[6]}_inbounds.json ] && sed -i "s/VMESS_HOST_DOMAIN.*/VMESS_HOST_DOMAIN\": \"$ARGO_DOMAIN\"/" ${WORK_DIR}/conf/17_${NODE_TAG[6]}_inbounds.json
  [ -s ${WORK_DIR}/conf/18_${NODE_TAG[7]}_inbounds.json ] && sed -i "s/\"server_name\":.*/\"server_name\": \"$ARGO_DOMAIN\",/" ${WORK_DIR}/conf/18_${NODE_TAG[7]}_inbounds.json
}

#Install sing-box family bucket
install_sing-box() {
  sing-box_variables
  if [ -n "$PORT_NGINX" ] && ! command -v nginx >/dev/null 2>&1; then
    info "\n $(text 7) nginx \n"
    ${PACKAGE_UPDATE[int]} >/dev/null 2>&1
    ${PACKAGE_INSTALL[int]} nginx >/dev/null 2>&1
    cmd_systemctl disable nginx
  fi
  [ ! -d ${WORK_DIR}/logs ] && mkdir -p ${WORK_DIR}/logs
  [ ! -d ${TEMP_DIR} ] && mkdir -p $TEMP_DIR
  ssl_certificate $TLS_SERVER_DEFAULT
  hint "\n $(text 2) " && wait
  sing-box_json
echo "${L^^}" > ${WORK_DIR}/language
  cp $TEMP_DIR/sing-box $TEMP_DIR/jq ${WORK_DIR}
  [ -x $TEMP_DIR/qrencode ] && cp $TEMP_DIR/qrencode ${WORK_DIR}

  # Generate sing-box systemd configuration file
  sing-box_systemd

 # Generate the Argo systemd configuration file and copy the cloudflared executable binary
  cp $TEMP_DIR/cloudflared ${WORK_DIR}
  [ -n "$ARGO_RUNS" ] && argo_systemd

  # If it is Json Argo, copy the configuration file to the working directory
  [ -n "$ARGO_JSON" ] && cp $TEMP_DIR/tunnel.*${WORK_DIR}

  # Generate Nginx configuration file
  [ -n "$PORT_NGINX" ] && export_nginx_conf_file

  # System starts sing-box service
  cmd_systemctl enable sing-box

  # Wait for the service to start
  sleep 2

  # Process firewall related ports
  sync_firewall_rules

  # Check whether the service started successfully
  if cmd_systemctl status sing-box &>/dev/null; then
STATUS[0]=$(text 28)
    info "\n Sing-box $(text 28) $(text 37) \n"
  else
    STATUS[0]=$(text 27)
    error "\n Sing-box $(text 27) $(text 38) \n"
    # If startup fails, try restarting again
    cmd_systemctl restart sing-box
  fi

# If Argo is configured, also start the Argo service
  if [ -s ${ARGO_DAEMON_FILE} ]; then
    cmd_systemctl enable argo

    sleep 2

    # Check whether the Argo service is started successfully
    if cmd_systemctl status argo &>/dev/null; then
      STATUS[1]=$(text 28)
      info "\n Argo $(text 28) $(text 37) \n"
    else
      STATUS[1]=$(text 27)
      error "\n Argo $(text 27) $(text 38) \n"
      # If startup fails, try restarting again
      cmd_systemctl restart argo
    fi
  fi
}

export_list() {
  IS_INSTALL=$1

  check_install
[ "$IS_INSTALL" != 'install' ] && fetch_nodes_value

  # IP handling for IPv6
  if [[ "$SERVER_IP" =~ : ]]; then
    SERVER_IP_1="[$SERVER_IP]"
    SERVER_IP_2="[[$SERVER_IP]]"
  else
    SERVER_IP_1="$SERVER_IP"
    SERVER_IP_2="$SERVER_IP"
  fi

  # When using Argo, get the temporary tunnel domain name
  ls ${WORK_DIR}/conf/*-ws*inbounds.json >/dev/null 2>&1 && [ "$IS_ARGO" = 'is_argo' ] && [ -z "$ARGO_DOMAIN" ] && [[ "${STATUS[1]}" = "$(text 28)" || "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]] && fetch_quicktunnel_domain

  # If you use Json or Token Argo, use the encrypted and fixed Argo tunnel domain name, otherwise use the http service of IP:PORT
  [[ "$ARGO_TYPE" = 'is_token_argo' || "$ARGO_TYPE" = 'is_json_argo' ]] && SUBSCRIBE_ADDRESS="https://$ARGO_DOMAIN" || SUBSCRIBE_ADDRESS="http://${SERVER_IP_1}:${PORT_NGINX}"

  # v1.3.0 (2025.11.10) and later reality uses xtls-rprx-vision flow control instead of multiplexing multiplex, but in order to be compatible with the installed client URI of older versions, make a judgment here
  if [ -n "$PORT_XTLS_REALITY" ]; then
    local FLOW="$(awk -F '"' '/"flow"/{print $4}' ${WORK_DIR}/conf/*_${NODE_TAG[0]}_inbounds.json)"

    if [ "${FLOW}" = 'xtls-rprx-vision' ]; then
local VISION_OR_MUX_SHADOWROCKET='xtls=2' && local VISION_FLOW='&flow=xtls-rprx-vision' && local VISION_OR_MUX_CLASH=', flow: xtls-rprx-vision' && local MULTIPLEX_PADDING_ENABLED='false' && local VISION_BRUTAL_ENABLED='false'
    else
      local VISION_OR_MUX_SHADOWROCKET='mux=1' && local MULTIPLEX_PADDING_ENABLED='true' && local VISION_BRUTAL_ENABLED="${IS_BRUTAL}"
    fi
  fi

  # Get self-signed certificate fingerprint. The origin rules or argo returned to the origin are trusted certificates (non-self-signed) issued by Google Trust Services as an intermediate CA (CN=WE1)
  local SELF_SIGNED_FINGERPRINT_SHA256=$(openssl x509 -fingerprint -noout -sha256 -in ${WORK_DIR}/cert/cert.pem | awk -F '=' '{print $NF}')
  local SELF_SIGNED_FINGERPRINT_BASE64=$(openssl x509 -in ${WORK_DIR}/cert/cert.pem -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)

  local CERT_URL=$(awk '{printf "%s,", $0}' ${WORK_DIR}/cert/cert.pem | sed 's/,$//')
  local CERT_200_URL=$(awk '{printf "%s,", $0}' ${WORK_DIR}/cert/cert_200.pem | sed 's/,$//')

  # Read the currently used SNI from the SAN of the self-signed certificate, take the SAN first, and fall back to CN
  local TLS_SERVER=$(openssl x509 -noout -ext subjectAltName -in ${WORK_DIR}/cert/cert.pem 2>/dev/null | awk -F 'DNS:' '/DNS:/{gsub(/,.*/, "", $2); print $2}')

  # Special handling of naive protocols
  if [ -n "$PORT_NAIVE" ]; then
    # When viewing the node with -n, if cert_200.pem is expired/missing/SNI is inconsistent, it will be automatically updated.
    ssl_certificate "$TLS_SERVER" naive_only

    # Read the naive self-signed certificate and format it as JSON string array content; multi-line/single-line positions share this variable
local CERT200_JSON=$(awk 'BEGIN{sep=""} {gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); printf "%s\"%s\"", sep, $0; sep=",\n"}' "${WORK_DIR}/cert/cert_200.pem")

    # Get the fingerprint of the naive self-signed certificate
    local SELF_SIGNED_200_FINGERPRINT_SHA256=$(openssl x509 -fingerprint -noout -sha256 -in ${WORK_DIR}/cert/cert_200.pem | awk -F '=' '{print $NF}')
  fi

  # Generate each subscription file
  # Generate Clash proxy providers subscription file
  local CLASH_SUBSCRIBE='proxies:'

  [ -n "$PORT_XTLS_REALITY" ] && local CLASH_XTLS_REALITY="- {name: \"${NODE_NAME[11]} ${NODE_TAG[0]}\", type: vless, server: ${SERVER_IP}, port: ${PORT_XTLS_REALITY}, uuid: ${UUID[11]}, network: tcp, udp: true, tls: true${VISION_OR_MUX_CLASH}, servername: ${TLS_SERVER}, client-fingerprint: firefox, reality-opts: {public-key: ${REALITY_PUBLIC[11]}, short-id: \"\"}, smux: { enabled: ${MULTIPLEX_PADDING_ENABLED}, protocol: 'h2mux', padding: ${MULTIPLEX_PADDING_ENABLED}, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${VISION_BRUTAL_ENABLED}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_XTLS_REALITY
"
  if [ -n "$PORT_HYSTERIA2" ]; then
    [[ -n "$PORT_HOPPING_START" && -n "$PORT_HOPPING_END" ]] && local CLASH_HOPPING=" ports: ${PORT_HOPPING_START}-${PORT_HOPPING_END}, hop-interval: 30,"
    local HY2_UP=${HY2_UP:-200}
    local HY2_DOWN=${HY2_DOWN:-1000}
    local CLASH_HYSTERIA2="- {name: \"${NODE_NAME[12]} ${NODE_TAG[1]}\", type: hysteria2, server: ${SERVER_IP}, port: ${PORT_HYSTERIA2},${CLASH_HOPPING} up: \"${HY2_UP} Mbps\", down: \"${HY2_DOWN} Mbps\", password: ${UUID[12]}, sni: ${TLS_SERVER}, skip-cert-verify: false, fingerprint: ${SELF_SIGNED_FINGERPRINT_SHA256}}" &&
    local CLASH_SUBSCRIBE+="
  $CLASH_HYSTERIA2
"
  fi

  [ -n "$PORT_TUIC" ] && local CLASH_TUIC="- {name: \"${NODE_NAME[13]} ${NODE_TAG[2]}\", type: tuic, server: ${SERVER_IP}, port: ${PORT_TUIC}, uuid: ${UUID[13]}, password: ${TUIC_PASSWORD}, alpn: [h3], reduce-rtt: true, request-timeout: 8000, udp-relay-mode: native, congestion-controller: $TUIC_CONGESTION_CONTROL, sni: ${TLS_SERVER}, skip-cert-verify: false, fingerprint: ${SELF_SIGNED_FINGERPRINT_SHA256}}" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_TUIC
"
  [ -n "$PORT_SHADOWTLS" ] && local CLASH_SHADOWTLS="- {name: \"${NODE_NAME[14]} ${NODE_TAG[3]}\", type: ss, server: ${SERVER_IP}, port: ${PORT_SHADOWTLS}, cipher: $SHADOWTLS_METHOD, password: $SHADOWTLS_PASSWORD, plugin: shadow-tls, client-fingerprint: firefox, plugin-opts: {host: ${TLS_SERVER}, password: \"${UUID[14]}\", version: 3}, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_SHADOWTLS
"

  [ -n "$PORT_SHADOWSOCKS" ] && local CLASH_SHADOWSOCKS="- {name: \"${NODE_NAME[15]} ${NODE_TAG[4]}\", type: ss, server: ${SERVER_IP}, port: $PORT_SHADOWSOCKS, cipher: ${SHADOWSOCKS_METHOD}, password: ${SHADOWSOCKS_PASSWORD}, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_SHADOWSOCKS
"
  [ -n "$PORT_TROJAN" ] && local CLASH_TROJAN="- {name: \"${NODE_NAME[16]} ${NODE_TAG[5]}\", type: trojan, server: ${SERVER_IP}, port: $PORT_TROJAN, password: $TROJAN_PASSWORD, client-fingerprint: firefox, sni: ${TLS_SERVER}, skip-cert-verify: false, fingerprint: ${SELF_SIGNED_FINGERPRINT_SHA256}, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_TROJAN
"
  if [ -n "$PORT_VMESS_WS" ]; then
    if [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] || [[ "$IS_ARGO" = 'is_argo' && "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]]; then
      local CLASH_VMESS_WS="- {name: \"${NODE_NAME[17]} ${NODE_TAG[6]}\", type: vmess, server: ${CDN[17]}, port: 80, uuid: ${UUID[17]}, udp: true, tls: false, alterId: 0, cipher: auto, network: ws, ws-opts: { path: \"/$VMESS_WS_PATH\", headers: {Host: $ARGO_DOMAIN} }, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
      local CLASH_SUBSCRIBE+="
  $CLASH_VMESS_WS
"
      [ "$ARGO_TYPE" = 'is_token_argo' ] && CLASH_SUBSCRIBE+="
  # $(text 94)
"
    else
      local CLASH_VMESS_WS="- {name: \"${NODE_NAME[17]} ${NODE_TAG[6]}\", type: vmess, server: ${CDN[17]}, port: 80, uuid: ${UUID[17]}, udp: true, tls: false, alterId: 0, cipher: auto, network: ws, ws-opts: { path: \"/$VMESS_WS_PATH\", headers: {Host: $VMESS_HOST_DOMAIN} }, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
      local WS_SERVER_IP_SHOW=${WS_SERVER_IP[17]} && local TYPE_HOST_DOMAIN=$VMESS_HOST_DOMAIN && local TYPE_PORT_WS=$PORT_VMESS_WS &&
      local CLASH_SUBSCRIBE+="
  $CLASH_VMESS_WS

  # $(text 52)
"
    fi
  fi

  if [ -n "$PORT_VLESS_WS" ]; then
     if [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] || [[ "$IS_ARGO" = 'is_argo' && "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]]; then
      local CLASH_VLESS_WS="- {name: \"${NODE_NAME[18]} ${NODE_TAG[7]}\", type: vless, server: ${CDN[18]}, port: 443, uuid: ${UUID[18]}, udp: true, tls: true, servername: $ARGO_DOMAIN, network: ws, skip-cert-verify: false, ws-opts: { path: \"/$VLESS_WS_PATH\", headers: {Host: $ARGO_DOMAIN}, max-early-data: 2560, early-data-header-name: Sec-WebSocket-Protocol }, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
      local CLASH_SUBSCRIBE+="
  $CLASH_VLESS_WS
"
      [ "$ARGO_TYPE" = 'is_token_argo' ] && CLASH_SUBSCRIBE+="
  # $(text 94)
"
    else
      local CLASH_VLESS_WS="- {name: \"${NODE_NAME[18]} ${NODE_TAG[7]}\", type: vless, server: ${CDN[18]}, port: 443, uuid: ${UUID[18]}, udp: true, tls: true, servername: $VLESS_HOST_DOMAIN, network: ws, skip-cert-verify: false, ws-opts: { path: \"/$VLESS_WS_PATH\", headers: {Host: $VLESS_HOST_DOMAIN}, max-early-data: 2560, early-data-header-name: Sec-WebSocket-Protocol }, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
      local WS_SERVER_IP_SHOW=${WS_SERVER_IP[18]} && local TYPE_HOST_DOMAIN=$VLESS_HOST_DOMAIN && local TYPE_PORT_WS=$PORT_VLESS_WS &&
      local CLASH_SUBSCRIBE+="
  $CLASH_VLESS_WS

  # $(text 52)
"
    fi
  fi

  [ -n "$PORT_H2_REALITY" ] && local CLASH_H2_REALITY="- {name: \"${NODE_NAME[19]} ${NODE_TAG[8]}\", type: vless, server: ${SERVER_IP}, port: ${PORT_H2_REALITY}, uuid: ${UUID[19]}, network: http, tls: true, servername: ${TLS_SERVER}, client-fingerprint: firefox, reality-opts: { public-key: ${REALITY_PUBLIC[19]}, short-id: \"\" }, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_H2_REALITY
"

  [ -n "$PORT_GRPC_REALITY" ] && local CLASH_GRPC_REALITY="- {name: \"${NODE_NAME[20]} ${NODE_TAG[9]}\", type: vless, server: ${SERVER_IP}, port: ${PORT_GRPC_REALITY}, uuid: ${UUID[20]}, network: grpc, tls: true, udp: true, flow: , client-fingerprint: firefox, servername: ${TLS_SERVER}, grpc-opts: {  grpc-service-name: \"grpc\" }, reality-opts: { public-key: ${REALITY_PUBLIC[20]}, short-id: \"\" }, smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }, brutal-opts: { enabled: ${IS_BRUTAL}, up: '1000 Mbps', down: '1000 Mbps' } }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_GRPC_REALITY
"

  [ -n "$PORT_ANYTLS" ] && local CLASH_ANYTLS="- {name: \"${NODE_NAME[21]} ${NODE_TAG[10]}\", type: anytls, server: ${SERVER_IP}, port: $PORT_ANYTLS, password: ${UUID[21]}, client-fingerprint: firefox, udp: true, idle-session-check-interval: 30, idle-session-timeout: 30, sni: ${TLS_SERVER}, skip-cert-verify: false, fingerprint: ${SELF_SIGNED_FINGERPRINT_SHA256} }" &&
  local CLASH_SUBSCRIBE+="
  $CLASH_ANYTLS
"

  echo -n "${CLASH_SUBSCRIBE}" | sed -E '/^[ ]*#|^--/d' | sed '/^$/d' > ${WORK_DIR}/subscribe/proxies

# Generate clash subscription configuration file in the background
  {
    # Template 1: Using proxy providers
    cat ${TEMP_DIR}/clash | sed "s#NODE_NAME#${NODE_NAME_CONFIRM}#g; s#PROXY_PROVIDERS_URL#$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/proxies#" > ${WORK_DIR}/subscribe/clash

    # Template 2: Do not use proxy providers
    CLASH2_PORT=("$PORT_XTLS_REALITY" "$PORT_HYSTERIA2" "$PORT_TUIC" "$PORT_SHADOWTLS" "$PORT_SHADOWSOCKS" "$PORT_TROJAN" "$PORT_VMESS_WS" "$PORT_VLESS_WS" "$PORT_GRPC_REALITY" "$PORT_ANYTLS")
    CLASH2_PROXY_INSERT=("$CLASH_XTLS_REALITY" "$CLASH_HYSTERIA2" "$CLASH_TUIC" "$CLASH_SHADOWTLS" "$CLASH_SHADOWSOCKS" "$CLASH_TROJAN" "$CLASH_VMESS_WS" "$CLASH_VLESS_WS" "$CLASH_GRPC_REALITY" "$CLASH_ANYTLS")
    CLASH2_PROXY_GROUPS_INSERT=("- ${NODE_NAME[11]} ${NODE_TAG[0]}" "- ${NODE_NAME[12]} ${NODE_TAG[1]}" "- ${NODE_NAME[13]} ${NODE_TAG[2]}" "- ${NODE_NAME[14]} ${NODE_TAG[3]}" "- ${NODE_NAME[15]} ${NODE_TAG[4]}" "- ${NODE_NAME[16]} ${NODE_TAG[5]}" "- ${NODE_NAME[17]} ${NODE_TAG[6]}" "- ${NODE_NAME[18]} ${NODE_TAG[7]}" "- ${NODE_NAME[20]} ${NODE_TAG[9]}" "- ${NODE_NAME[21]} ${NODE_TAG[10]}")

    CLASH2_YAML=$(cat ${TEMP_DIR}/clash2)
    for x in ${!CLASH2_PORT[@]}; do
   [[ ${CLASH2_PORT[x]} =~ [0-9]+ ]] && { CLASH2_YAML=$(sed "/proxy-groups:/i\ ${CLASH2_PROXY_INSERT[x]}" <<< "$CLASH2_YAML"); CLASH2_YAML=$(sed -E "/-name: (♻️ Automatic selection|📲 Telegram News|💬 OpenAi|📹 YouTube Video|🎥 Netflix Video|📺 Bahamut|📺 Bilibili|🌍 Foreign Media|🌏 Domestic Media|📢 Google FCM|Ⓜ️ Microsoft Bing|Ⓜ️ Microsoft Cloud Drive|Ⓜ️ Microsoft Services|🍎 Apple Services|🎮 Game Platform|🎶 NetEase Music|🎯 Global Direct)|^rules:$/i\ ${CLASH2_PROXY_GROUPS_INSERT[x]}" <<< "$CLASH2_YAML"); }
    done
    echo "$CLASH2_YAML" > ${WORK_DIR}/subscribe/clash2

    rm -f ${TEMP_DIR}/clash{,2}
  } &>/dev/null

  # Generate ShadowRocket subscription configuration file
  [ -n "$PORT_XTLS_REALITY" ] && local SHADOWROCKET_SUBSCRIBE+="
vless://$(echo -n "auto:${UUID[11]}@${SERVER_IP_2}:${PORT_XTLS_REALITY}" | base64 -w0)?remarks=${NODE_NAME[11]// /%20}%20${NODE_TAG[0]}&tls=1&peer=${TLS_SERVER}&${VISION_OR_MUX_SHADOWROCKET}&pbk=${REALITY_PUBLIC[11]}
"
  if [ -n "$PORT_HYSTERIA2" ]; then
    local SHADOWROCKET_PARAMS="peer=${TLS_SERVER}&hpkp=${SELF_SIGNED_FINGERPRINT_SHA256}&obfs=none&upmbps=${HY2_UP}&downmbps=${HY2_DOWN}"
    [[ -n "$PORT_HOPPING_START" && -n "$PORT_HOPPING_END" ]] && SHADOWROCKET_PARAMS+="&keepalive=30&mport=${PORT_HYSTERIA2},${PORT_HOPPING_START}-${PORT_HOPPING_END}"
    local SHADOWROCKET_SUBSCRIBE+="
hysteria2://${UUID[12]}@${SERVER_IP_1}:${PORT_HYSTERIA2}?${SHADOWROCKET_PARAMS}#${NODE_NAME[12]// /%20}%20${NODE_TAG[1]}
"
  fi
  [ -n "$PORT_TUIC" ] && local SHADOWROCKET_SUBSCRIBE+="
tuic://${TUIC_PASSWORD}:${UUID[13]}@${SERVER_IP_2}:${PORT_TUIC}?peer=${TLS_SERVER}&congestion_control=$TUIC_CONGESTION_CONTROL&udp_relay_mode=native&alpn=h3&hpkp=${SELF_SIGNED_FINGERPRINT_SHA256}#${NODE_NAME[13]// /%20}%20${NODE_TAG[2]}
"
  [ -n "$PORT_SHADOWTLS" ] && local SHADOWROCKET_SUBSCRIBE+="
ss://$(echo -n "$SHADOWTLS_METHOD:$SHADOWTLS_PASSWORD@${SERVER_IP_2}:${PORT_SHADOWTLS}" | base64 -w0)?shadow-tls=$(echo -n "{\"version\":\"3\",\"host\":\"${TLS_SERVER}\",\"password\":\"${UUID[14]}\"}" | base64 -w0)#${NODE_NAME[14]// /%20}%20${NODE_TAG[3]}
"
  [ -n "$PORT_SHADOWSOCKS" ] && local SHADOWROCKET_SUBSCRIBE+="
ss://$(echo -n "${SHADOWSOCKS_METHOD}:${SHADOWSOCKS_PASSWORD}@${SERVER_IP_2}:$PORT_SHADOWSOCKS" | base64 -w0)#${NODE_NAME[15]// /%20}%20${NODE_TAG[4]}
"
  [ -n "$PORT_TROJAN" ] && local SHADOWROCKET_SUBSCRIBE+="
trojan://${TROJAN_PASSWORD}@${SERVER_IP_1}:$PORT_TROJAN?peer=${TLS_SERVER}&hpkp=${SELF_SIGNED_FINGERPRINT_SHA256}#${NODE_NAME[16]// /%20}%20${NODE_TAG[5]}
"
  if [ -n "$PORT_VMESS_WS" ]; then
     if [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] || [[ "$IS_ARGO" = 'is_argo' && "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]]; then
      local SHADOWROCKET_SUBSCRIBE+="
----------------------------
vmess://$(echo -n "auto:${UUID[17]}@${CDN[17]}:80" | base64 -w0)?remarks=${NODE_NAME[17]// /%20}%20${NODE_TAG[6]}&obfsParam=$ARGO_DOMAIN&path=/$VMESS_WS_PATH&obfs=websocket&alterId=0
"
      [ "$ARGO_TYPE" = 'is_token_argo' ] && SHADOWROCKET_SUBSCRIBE+="
  # $(text 94)
"
    else
      WS_SERVER_IP_SHOW=${WS_SERVER_IP[17]} && TYPE_HOST_DOMAIN=$VMESS_HOST_DOMAIN && TYPE_PORT_WS=$PORT_VMESS_WS && local SHADOWROCKET_SUBSCRIBE+="
----------------------------
vmess://$(echo -n "auto:${UUID[17]}@${CDN[17]}:80" | base64 -w0)?remarks=${NODE_NAME[17]// /%20}%20${NODE_TAG[6]}&obfsParam=$VMESS_HOST_DOMAIN&path=/$VMESS_WS_PATH&obfs=websocket&alterId=0

# $(text 52)
"
    fi
  fi

  if [ -n "$PORT_VLESS_WS" ]; then
     if [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] || [[ "$IS_ARGO" = 'is_argo' && "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]]; then
      local SHADOWROCKET_SUBSCRIBE+="
----------------------------
vless://$(echo -n "auto:${UUID[18]}@${CDN[18]}:443" | base64 -w0)?remarks=${NODE_NAME[18]// /%20}%20${NODE_TAG[7]}&obfsParam=$ARGO_DOMAIN&path=/$VLESS_WS_PATH?ed=2560&obfs=websocket&tls=1&peer=$ARGO_DOMAIN
"
      [ "$ARGO_TYPE" = 'is_token_argo' ] && SHADOWROCKET_SUBSCRIBE+="
  # $(text 94)
"
    else
      WS_SERVER_IP_SHOW=${WS_SERVER_IP[18]} && TYPE_HOST_DOMAIN=$VLESS_HOST_DOMAIN && TYPE_PORT_WS=$PORT_VLESS_WS && local SHADOWROCKET_SUBSCRIBE+="
----------------------------
vless://$(echo -n "auto:${UUID[18]}@${CDN[18]}:443" | base64 -w0)?remarks=${NODE_NAME[18]// /%20}%20${NODE_TAG[7]}&obfsParam=$VLESS_HOST_DOMAIN&path=/$VLESS_WS_PATH?ed=2560&obfs=websocket&tls=1&peer=$VLESS_HOST_DOMAIN

# $(text 52)
"
    fi
  fi

  [ -n "$PORT_H2_REALITY" ] && local SHADOWROCKET_SUBSCRIBE+="
----------------------------
vless://$(echo -n auto:${UUID[19]}@${SERVER_IP_2}:${PORT_H2_REALITY} | base64 -w0)?remarks=${NODE_NAME[19]// /%20}%20${NODE_TAG[8]}&path=/&obfs=h2&tls=1&peer=${TLS_SERVER}&alpn=h2&mux=1&pbk=${REALITY_PUBLIC[19]}
"
  [ -n "$PORT_GRPC_REALITY" ] && local SHADOWROCKET_SUBSCRIBE+="
vless://$(echo -n "auto:${UUID[20]}@${SERVER_IP_2}:${PORT_GRPC_REALITY}" | base64 -w0)?remarks=${NODE_NAME[20]// /%20}%20${NODE_TAG[9]}&path=grpc&obfs=grpc&tls=1&peer=${TLS_SERVER}&pbk=${REALITY_PUBLIC[20]}
"
  [ -n "$PORT_ANYTLS" ] && local SHADOWROCKET_SUBSCRIBE+="
anytls://${UUID[21]}@${SERVER_IP_1}:${PORT_ANYTLS}?peer=${TLS_SERVER}&udp=1&hpkp=${SELF_SIGNED_FINGERPRINT_SHA256}#${NODE_NAME[21]// /%20}%20${NODE_TAG[10]}
"
  [ -n "$PORT_NAIVE" ] && local SHADOWROCKET_SUBSCRIBE+="
http2://$(echo -n "${UUID[22]}:${UUID[22]}@${SERVER_IP_2}:${PORT_NAIVE}" | base64 -w0)?peer=${TLS_SERVER}&alpn=h2,http/1.1&padding=1&uot=2&hpkp=${SELF_SIGNED_200_FINGERPRINT_SHA256}#${NODE_NAME[22]// /%20}%20${NODE_TAG[11]}%20http2

http3://$(echo -n "${UUID[22]}:${UUID[22]}@${SERVER_IP_2}:${PORT_NAIVE}" | base64 -w0)?peer=${TLS_SERVER}&alpn=h3&padding=1&hpkp=${SELF_SIGNED_200_FINGERPRINT_SHA256}#${NODE_NAME[22]// /%20}%20${NODE_TAG[11]}%20http3
"
  echo -n "$SHADOWROCKET_SUBSCRIBE" | sed -E '/^[ ]*#|^--/d' | sed '/^$/d' | base64 -w0 > ${WORK_DIR}/subscribe/shadowrocket

  # Generate V2rayN subscription file
  [ -n "$PORT_XTLS_REALITY" ] && local V2RAYN_SUBSCRIBE+="
----------------------------
vless://${UUID[11]}@${SERVER_IP_1}:${PORT_XTLS_REALITY}?encryption=none${VISION_FLOW}&security=reality&sni=${TLS_SERVER}&fp=firefox&pbk=${REALITY_PUBLIC[11]}&type=tcp&headerType=none#${NODE_NAME[11]// /%20}%20${NODE_TAG[0]}"

  if [ -n "$PORT_HYSTERIA2" ]; then
    local V2RAYN_PARAMS="sni=${TLS_SERVER}&alpn=h3&insecure=1&allowInsecure=1&pinSHA256=${SELF_SIGNED_FINGERPRINT_SHA256//:/}"
    [[ -n "$PORT_HOPPING_START" && -n "$PORT_HOPPING_END" ]] && V2RAYN_PARAMS+="&mport=${PORT_HOPPING_START}-${PORT_HOPPING_END}"
    local V2RAYN_SUBSCRIBE+="
----------------------------
hysteria2://${UUID[12]}@${SERVER_IP_1}:${PORT_HYSTERIA2}?${V2RAYN_PARAMS}#${NODE_NAME[12]// /%20}%20${NODE_TAG[1]}"
  fi

  [ -n "$PORT_TUIC" ] && local V2RAYN_SUBSCRIBE+="
----------------------------
tuic://${UUID[13]}:${TUIC_PASSWORD}@${SERVER_IP_1}:${PORT_TUIC}?sni=${TLS_SERVER}&alpn=h3&insecure=1&allowInsecure=1&congestion_control=$TUIC_CONGESTION_CONTROL#${NODE_NAME[13]// /%20}%20${NODE_TAG[2]}"

  [ -n "$PORT_SHADOWTLS" ] && local V2RAYN_SUBSCRIBE+="
----------------------------
{
    \"log\": {
        \"level\": \"warn\"
    },
    \"inbounds\": [
        {
            \"listen\": \"127.0.0.1\",
            \"listen_port\": ${PORT_SHADOWTLS},
            \"tag\": \"${PROTOCOL_LIST[3]}\",
            \"type\": \"mixed\"
        }
    ],
    \"outbounds\": [
        {
            \"detour\": \"shadowtls-out\",
            \"method\": \"$SHADOWTLS_METHOD\",
            \"password\": \"$SHADOWTLS_PASSWORD\",
            \"type\": \"shadowsocks\",
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
            \"password\": \"${UUID[14]}\",
            \"server\": \"${SERVER_IP}\",
            \"server_port\": ${PORT_SHADOWTLS},
            \"tag\": \"shadowtls-out\",
            \"tls\": {
                \"enabled\": true,
                \"server_name\": \"${TLS_SERVER}\",
                \"utls\": {
                  \"enabled\": true,
                  \"fingerprint\": \"firefox\"
                }
            },
            \"type\": \"shadowtls\",
            \"version\": 3
        }
    ]
}"
  [ -n "$PORT_SHADOWSOCKS" ] && local V2RAYN_SUBSCRIBE+="
----------------------------
ss://$(echo -n "${SHADOWSOCKS_METHOD}:${SHADOWSOCKS_PASSWORD}@${SERVER_IP_1}:$PORT_SHADOWSOCKS" | base64 -w0)#${NODE_NAME[15]// /%20}%20${NODE_TAG[4]}"

  [ -n "$PORT_TROJAN" ] && local V2RAYN_SUBSCRIBE+="
----------------------------
trojan://$TROJAN_PASSWORD@${SERVER_IP_1}:$PORT_TROJAN?security=tls&insecure=1&allowInsecure=1&pcs=${SELF_SIGNED_FINGERPRINT_SHA256//:/}&type=tcp&headerType=none#${NODE_NAME[16]// /%20}%20${NODE_TAG[5]}"

  if [ -n "$PORT_VMESS_WS" ]; then
     if [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] || [[ "$IS_ARGO" = 'is_argo' && "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]]; then
      local V2RAYN_SUBSCRIBE+="
----------------------------
vmess://$(echo -n "{ \"v\": \"2\", \"ps\": \"${NODE_NAME[17]} ${NODE_TAG[6]}\", \"add\": \"${CDN[17]}\", \"port\": \"80\", \"id\": \"${UUID[17]}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"auto\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$VMESS_WS_PATH\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\" }" | base64 -w0)"
      [ "$ARGO_TYPE" = 'is_token_argo' ] && V2RAYN_SUBSCRIBE+="

  # $(text 94)
"
    else
      WS_SERVER_IP_SHOW=${WS_SERVER_IP[17]} && TYPE_HOST_DOMAIN=$VMESS_HOST_DOMAIN && TYPE_PORT_WS=$PORT_VMESS_WS && local V2RAYN_SUBSCRIBE+="
----------------------------
vmess://$(echo -n "{ \"v\": \"2\", \"ps\": \"${NODE_NAME[17]} ${NODE_TAG[6]}\", \"add\": \"${CDN[17]}\", \"port\": \"80\", \"id\": \"${UUID[17]}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"auto\", \"host\": \"$VMESS_HOST_DOMAIN\", \"path\": \"/$VMESS_WS_PATH\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\" }" | base64 -w0)

# $(text 52)"
    fi
  fi

  if [ -n "$PORT_VLESS_WS" ]; then
     if [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] || [[ "$IS_ARGO" = 'is_argo' && "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]]; then
      local V2RAYN_SUBSCRIBE+="
----------------------------
vless://${UUID[18]}@${CDN[18]}:443?encryption=none&security=tls&sni=$ARGO_DOMAIN&type=ws&host=$ARGO_DOMAIN&path=%2F$VLESS_WS_PATH%3Fed%3D2560#${NODE_NAME[18]// /%20}%20${NODE_TAG[7]}"
      [ "$ARGO_TYPE" = 'is_token_argo' ] && V2RAYN_SUBSCRIBE+="

  # $(text 94)
"
    else
      WS_SERVER_IP_SHOW=${WS_SERVER_IP[18]} && TYPE_HOST_DOMAIN=$VLESS_HOST_DOMAIN && TYPE_PORT_WS=$PORT_VLESS_WS && local V2RAYN_SUBSCRIBE+="
----------------------------
vless://${UUID[18]}@${CDN[18]}:443?encryption=none&security=tls&sni=$VLESS_HOST_DOMAIN&type=ws&host=$VLESS_HOST_DOMAIN&path=%2F$VLESS_WS_PATH%3Fed%3D2560#${NODE_NAME[18]// /%20}%20${NODE_TAG[7]}

# $(text 52)"
    fi
  fi

  [ -n "$PORT_H2_REALITY" ] && local V2RAYN_SUBSCRIBE+="
----------------------------
vless://${UUID[19]}@${SERVER_IP_1}:${PORT_H2_REALITY}?encryption=none&security=reality&sni=${TLS_SERVER}&fp=firefox&pbk=${REALITY_PUBLIC[19]}&type=http#${NODE_NAME[19]// /%20}%20${NODE_TAG[8]}"

  [ -n "$PORT_GRPC_REALITY" ] && local V2RAYN_SUBSCRIBE+="
----------------------------
vless://${UUID[20]}@${SERVER_IP_1}:${PORT_GRPC_REALITY}?encryption=none&security=reality&sni=${TLS_SERVER}&fp=firefox&pbk=${REALITY_PUBLIC[20]}&type=grpc&serviceName=grpc&mode=gun#${NODE_NAME[20]// /%20}%20${NODE_TAG[9]}"

  [ -n "$PORT_ANYTLS" ] && local V2RAYN_SUBSCRIBE+="
----------------------------
anytls://${UUID[21]}@${SERVER_IP_1}:${PORT_ANYTLS}?security=tls&sni=${TLS_SERVER}&fp=firefox&insecure=1&allowInsecure=1&type=tcp#${NODE_NAME[21]// /%20}%20${NODE_TAG[10]}"

  [ -n "$PORT_NAIVE" ] && local V2RAYN_SUBSCRIBE+="
----------------------------
naive+https://${UUID[22]}:${UUID[22]}@${SERVER_IP_1}:${PORT_NAIVE}?security=tls&sni=${TLS_SERVER}&insecure=0&allowInsecure=0&type=tcp&headerType=none#${NODE_NAME[22]// /%20}%20${NODE_TAG[11]}%20http2
----------------------------
naive+quic://${UUID[22]}:${UUID[22]}@${SERVER_IP_1}:${PORT_NAIVE}?security=tls&sni=${TLS_SERVER}&insecure=0&allowInsecure=0&type=tcp&headerType=none#${NODE_NAME[22]// /%20}%20${NODE_TAG[11]}%20quic

# $(text 54)
$(cat ${WORK_DIR}/cert/cert_200.pem)
"

  echo -n "$V2RAYN_SUBSCRIBE" | sed '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/d' | sed -E '/^[ ]*#|^[ ]+|^\{|^\}/d' | sed '/^$/d' | base64 -w0 > ${WORK_DIR}/subscribe/v2rayn

  # Generate Throne subscription file
  [ -n "$PORT_XTLS_REALITY" ] && local THRONE_SUBSCRIBE+="
----------------------------
vless://${UUID[11]}@${SERVER_IP_1}:${PORT_XTLS_REALITY}?security=reality&sni=${TLS_SERVER}&fp=firefox&pbk=${REALITY_PUBLIC[11]}&type=tcp${VISION_FLOW}&encryption=none#${NODE_NAME[11]// /%20}%20${NODE_TAG[0]}"

  if [ -n "$PORT_HYSTERIA2" ]; then
    local THRONE_PARAMS="insecure=1&security=tls&sni=${TLS_SERVER}&upmbps=${HY2_UP}&downmbps=${HY2_DOWN}&security=tls&tls_certificate=${CERT_URL}"
    if [[ -n "$PORT_HOPPING_START" && -n "$PORT_HOPPING_END" ]]; then
      THRONE_PARAMS+="&mport=${PORT_HOPPING_START}-${PORT_HOPPING_END}&hop_interval=30"
    fi
    local THRONE_SUBSCRIBE+="
----------------------------
hy2://${UUID[12]}@${SERVER_IP_1}:${PORT_HYSTERIA2}?${THRONE_PARAMS}#${NODE_NAME[12]// /%20}%20${NODE_TAG[1]}"
  fi

  [ -n "$PORT_TUIC" ] && local THRONE_SUBSCRIBE+="
----------------------------
tuic://${TUIC_PASSWORD}:${UUID[13]}@${SERVER_IP_1}:${PORT_TUIC}?congestion_control=$TUIC_CONGESTION_CONTROL&alpn=h3&sni=${TLS_SERVER}&udp_relay_mode=native&allow_insecure=1&security=tls&tls_certificate=${CERT_URL}#${NODE_NAME[13]// /%20}%20${NODE_TAG[2]}"
  [ -n "$PORT_SHADOWTLS" ] && local THRONE_SUBSCRIBE+="
----------------------------
nekoray://custom#$(echo -n "{\"_v\":0,\"addr\":\"127.0.0.1\",\"cmd\":[\"\"],\"core\":\"internal\",\"cs\":\"{\n    \\\"password\\\": \\\"${UUID[14]}\\\",\n    \\\"server\\\": \\\"${SERVER_IP_1}\\\",\n    \\\"server_port\\\": ${PORT_SHADOWTLS},\n    \\\"tag\\\": \\\"shadowtls-out\\\",\n    \\\"tls\\\": {\n        \\\"enabled\\\": true,\n        \\\"server_name\\\": \\\"${TLS_SERVER}\\\"\n    },\n    \\\"type\\\": \\\"shadowtls\\\",\n    \\\"version\\\": 3\n}\n\",\"mapping_port\":0,\"name\":\"1-tls-not-use\",\"port\":1080,\"socks_port\":0}" | base64 -w0)

nekoray://shadowsocks#$(echo -n "{\"_v\":0,\"method\":\"$SHADOWTLS_METHOD\",\"name\":\"2-ss-not-use\",\"pass\":\"$SHADOWTLS_PASSWORD\",\"port\":0,\"stream\":{\"ed_len\":0,\"insecure\":false,\"mux_s\":0,\"net\":\"tcp\"},\"uot\":0}" | base64 -w0)"

  [ -n "$PORT_SHADOWSOCKS" ] && local THRONE_SUBSCRIBE+="
----------------------------
ss://$(echo -n "${SHADOWSOCKS_METHOD}:${SHADOWSOCKS_PASSWORD}" | base64 -w0)@${SERVER_IP_1}:$PORT_SHADOWSOCKS#${NODE_NAME[15]// /%20}%20${NODE_TAG[4]}"

  [ -n "$PORT_TROJAN" ] && local THRONE_SUBSCRIBE+="
----------------------------
trojan://${TROJAN_PASSWORD}@${SERVER_IP_1}:$PORT_TROJAN?security=tls&sni=${TLS_SERVER}&allowInsecure=1&tls_certificate=${CERT_URL}&fp=firefox&type=tcp#${NODE_NAME[16]// /%20}%20${NODE_TAG[5]}"

  if [ -n "$PORT_VMESS_WS" ]; then
     if [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] || [[ "$IS_ARGO" = 'is_argo' && "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]]; then
      THRONE_SUBSCRIBE+="
----------------------------
vmess://$(echo -n "{\"add\":\"${CDN[17]}\",\"aid\":\"0\",\"host\":\"$ARGO_DOMAIN\",\"id\":\"${UUID[17]}\",\"net\":\"ws\",\"path\":\"/$VMESS_WS_PATH\",\"port\":\"80\",\"ps\":\"${NODE_NAME[17]} ${NODE_TAG[6]}\",\"scy\":\"auto\",\"sni\":\"\",\"tls\":\"\",\"type\":\"\",\"v\":\"2\"}" | base64 -w0)"
      [ "$ARGO_TYPE" = 'is_token_argo' ] && THRONE_SUBSCRIBE+="

  # $(text 94)
"
    else
      WS_SERVER_IP_SHOW=${WS_SERVER_IP[17]} && TYPE_HOST_DOMAIN=$VMESS_HOST_DOMAIN && TYPE_PORT_WS=$PORT_VMESS_WS && local THRONE_SUBSCRIBE+="
----------------------------
vmess://$(echo -n "{\"add\":\"${CDN[17]}\",\"aid\":\"0\",\"host\":\"$VMESS_HOST_DOMAIN\",\"id\":\"${UUID[17]}\",\"net\":\"ws\",\"path\":\"/$VMESS_WS_PATH\",\"port\":\"80\",\"ps\":\"${NODE_NAME[17]} ${NODE_TAG[6]}\",\"scy\":\"auto\",\"sni\":\"\",\"tls\":\"\",\"type\":\"\",\"v\":\"2\"}" | base64 -w0)

# $(text 52)"
    fi
  fi

  if [ -n "$PORT_VLESS_WS" ]; then
     if [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] || [[ "$IS_ARGO" = 'is_argo' && "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]]; then
      local THRONE_SUBSCRIBE+="
----------------------------
vless://${UUID[18]}@${CDN[18]}:443?security=tls&sni=$ARGO_DOMAIN&type=ws&path=/$VLESS_WS_PATH?ed%3D2560&host=$ARGO_DOMAIN&encryption=zero#${NODE_NAME[18]// /%20}%20${NODE_TAG[7]}"
      [ "$ARGO_TYPE" = 'is_token_argo' ] && THRONE_SUBSCRIBE+="

  # $(text 94)
"
    else
      WS_SERVER_IP_SHOW=${WS_SERVER_IP[18]} && TYPE_HOST_DOMAIN=$VLESS_HOST_DOMAIN && TYPE_PORT_WS=$PORT_VLESS_WS && local THRONE_SUBSCRIBE+="
----------------------------
vless://${UUID[18]}@${CDN[18]}:443?security=tls&sni=$VLESS_HOST_DOMAIN&type=ws&path=/$VLESS_WS_PATH?ed%3D2560&host=$VLESS_HOST_DOMAIN&encryption=zero#${NODE_NAME[18]// /%20}%20${NODE_TAG[7]}

# $(text 52)"
    fi
  fi

  [ -n "$PORT_H2_REALITY" ] && local THRONE_SUBSCRIBE+="
----------------------------
vless://${UUID[19]}@${SERVER_IP_1}:${PORT_H2_REALITY}?security=reality&sni=${TLS_SERVER}&alpn=h2&fp=firefox&pbk=${REALITY_PUBLIC[19]// /%20}&type=http&encryption=none#${NODE_NAME[19]// /%20}%20${NODE_TAG[8]}"

  [ -n "$PORT_GRPC_REALITY" ] && local THRONE_SUBSCRIBE+="
----------------------------
vless://${UUID[20]}@${SERVER_IP_1}:${PORT_GRPC_REALITY}?security=reality&sni=${TLS_SERVER}&fp=firefox&pbk=${REALITY_PUBLIC[20]// /%20}&type=grpc&serviceName=grpc&encryption=none#${NODE_NAME[20]// /%20}%20${NODE_TAG[9]}"

  [ -n "$PORT_ANYTLS" ] && local THRONE_SUBSCRIBE+="
----------------------------
anytls://${UUID[21]}@${SERVER_IP_1}:${PORT_ANYTLS}?idle_session_check_interval=30s&idle_session_timeout=30s&min_idle_session=5&insecure=1&security=tls&sni=${TLS_SERVER}&tls_certificate=${CERT_URL}&fp=firefox#${NODE_NAME[21]// /%20}%20${NODE_TAG[10]}"

  [ -n "$PORT_NAIVE" ] && {
    local THRONE_SUBSCRIBE+="
----------------------------
naive+https://${UUID[22]}:${UUID[22]}@${SERVER_IP_1}:${PORT_NAIVE}?uot=1&security=tls&sni=${TLS_SERVER}&tls_certificate=${CERT_200_URL}#${NODE_NAME[22]// /%20}%20${NODE_TAG[11]}%20http2
----------------------------
naive+quic://${UUID[22]}:${UUID[22]}@${SERVER_IP_1}:${PORT_NAIVE}?congestion_control=bbr&security=tls&sni=${TLS_SERVER}&tls_certificate=${CERT_200_URL}#${NODE_NAME[22]// /%20}%20${NODE_TAG[11]}%20quic"
  }

  echo -n "$THRONE_SUBSCRIBE" | sed -E '/^[ ]*#|^--/d' | sed '/^$/d' | base64 -w0 > ${WORK_DIR}/subscribe/neko

  # Generate Sing-box subscription file
  [ -n "$PORT_XTLS_REALITY" ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"vless\", \"tag\": \"${NODE_NAME[11]} ${NODE_TAG[0]}\", \"server\":\"${SERVER_IP}\", \"server_port\":${PORT_XTLS_REALITY}, \"uuid\":\"${UUID[11]}\", \"flow\":\"${FLOW}\", \"tls\":{ \"enabled\":true, \"server_name\":\"${TLS_SERVER}\", \"utls\":{ \"enabled\":true, \"fingerprint\":\"firefox\" }, \"reality\":{ \"enabled\":true, \"public_key\":\"${REALITY_PUBLIC[11]}\", \"short_id\":\"\" } }, \"multiplex\": { \"enabled\": ${MULTIPLEX_PADDING_ENABLED}, \"protocol\": \"h2mux\", \"max_connections\": 8, \"min_streams\": 16, \"padding\": ${MULTIPLEX_PADDING_ENABLED}, \"brutal\":{ \"enabled\":${VISION_BRUTAL_ENABLED}, \"up_mbps\":1000, \"down_mbps\":1000 } } }," &&
  local NODE_REPLACE+="\"${NODE_NAME[11]} ${NODE_TAG[0]}\","

  if [ -n "$PORT_HYSTERIA2" ]; then
    local HYSTERIA2_CONFIG=" { \"type\": \"hysteria2\", \"tag\": \"${NODE_NAME[12]} ${NODE_TAG[1]}\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_HYSTERIA2}, \"up_mbps\": ${HY2_UP}, \"down_mbps\": ${HY2_DOWN}, \"password\": \"${UUID[12]}\", \"tls\": { \"enabled\": true, \"server_name\": \"${TLS_SERVER}\", \"certificate_public_key_sha256\": [\"$SELF_SIGNED_FINGERPRINT_BASE64\"], \"alpn\": [ \"h3\" ] } },"
    if [[ -n "${PORT_HOPPING_START}" && -n "${PORT_HOPPING_END}" ]]; then
      HYSTERIA2_CONFIG="${HYSTERIA2_CONFIG/\"server_port\": ${PORT_HYSTERIA2},/\"server_port\": ${PORT_HYSTERIA2}, \"server_ports\": [ \"${PORT_HOPPING_START}:${PORT_HOPPING_END}\" ], \"hop_interval\": \"30s\", \"hop_interval_max\": \"60s\",}"
    fi
    local OUTBOUND_REPLACE+="${HYSTERIA2_CONFIG}"
    local NODE_REPLACE+="\"${NODE_NAME[12]} ${NODE_TAG[1]}\","
  fi

  [ -n "$PORT_TUIC" ] &&
  local TUIC_INBOUND=" { \"type\": \"tuic\", \"tag\": \"${NODE_NAME[13]} ${NODE_TAG[2]}\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_TUIC}, \"uuid\": \"${UUID[13]}\", \"password\": \"${TUIC_PASSWORD}\", \"congestion_control\": \"$TUIC_CONGESTION_CONTROL\", \"udp_relay_mode\": \"native\", \"zero_rtt_handshake\": false, \"heartbeat\": \"10s\", \"tls\": { \"enabled\": true, \"server_name\": \"${TLS_SERVER}\", \"certificate_public_key_sha256\": [\"$SELF_SIGNED_FINGERPRINT_BASE64\"], \"alpn\": [ \"h3\" ] } }," &&
  local OUTBOUND_REPLACE+="${TUIC_INBOUND}" &&
  local NODE_REPLACE+="\"${NODE_NAME[13]} ${NODE_TAG[2]}\","

  [ -n "$PORT_SHADOWTLS" ] &&
  local SHADOWTLS_INBOUND=" { \"type\": \"shadowsocks\", \"tag\": \"${NODE_NAME[14]} ${NODE_TAG[3]}\", \"method\": \"$SHADOWTLS_METHOD\", \"password\": \"$SHADOWTLS_PASSWORD\", \"detour\": \"shadowtls-out\", \"udp_over_tcp\": false, \"multiplex\": { \"enabled\": true, \"protocol\": \"h2mux\", \"max_connections\": 8, \"min_streams\": 16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } }, { \"type\": \"shadowtls\", \"tag\": \"shadowtls-out\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_SHADOWTLS}, \"version\": 3, \"password\": \"${UUID[14]}\", \"tls\": { \"enabled\": true, \"server_name\": \"${TLS_SERVER}\", \"utls\": { \"enabled\": true, \"fingerprint\": \"firefox\" } } }," &&
  local OUTBOUND_REPLACE+="${SHADOWTLS_INBOUND}" &&
  local NODE_REPLACE+="\"${NODE_NAME[14]} ${NODE_TAG[3]}\","

  [ -n "$PORT_SHADOWSOCKS" ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"shadowsocks\", \"tag\": \"${NODE_NAME[15]} ${NODE_TAG[4]}\", \"server\": \"${SERVER_IP}\", \"server_port\": $PORT_SHADOWSOCKS, \"method\": \"${SHADOWSOCKS_METHOD}\", \"password\": \"${SHADOWSOCKS_PASSWORD}\", \"multiplex\": { \"enabled\": true, \"protocol\": \"h2mux\", \"max_connections\": 8, \"min_streams\": 16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } }," &&
  local NODE_REPLACE+="\"${NODE_NAME[15]} ${NODE_TAG[4]}\","

  [ -n "$PORT_TROJAN" ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"trojan\", \"tag\": \"${NODE_NAME[16]} ${NODE_TAG[5]}\", \"server\": \"${SERVER_IP}\", \"server_port\": $PORT_TROJAN, \"password\": \"$TROJAN_PASSWORD\", \"tls\": { \"enabled\": true, \"certificate_public_key_sha256\": [\"$SELF_SIGNED_FINGERPRINT_BASE64\"], \"server_name\":\"${TLS_SERVER}\", \"utls\": { \"enabled\":true, \"fingerprint\":\"firefox\" } }, \"multiplex\": { \"enabled\":true, \"protocol\":\"h2mux\", \"max_connections\": 8, \"min_streams\": 16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } }," &&
  local NODE_REPLACE+="\"${NODE_NAME[16]} ${NODE_TAG[5]}\","

  if [ -n "$PORT_VMESS_WS" ]; then
     if [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] || [[ "$IS_ARGO" = 'is_argo' && "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]]; then
      local OUTBOUND_REPLACE+=" { \"type\": \"vmess\", \"tag\": \"${NODE_NAME[17]} ${NODE_TAG[6]}\", \"server\":\"${CDN[17]}\", \"server_port\":80, \"uuid\": \"${UUID[17]}\", \"security\": \"auto\", \"transport\": { \"type\":\"ws\", \"path\":\"/$VMESS_WS_PATH\", \"headers\": { \"Host\": \"$ARGO_DOMAIN\" } }, \"multiplex\": { \"enabled\":true, \"protocol\":\"h2mux\", \"max_streams\":16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } },"
      [ "$ARGO_TYPE" = 'is_token_argo' ] && [ -z "$PROMPT" ] && local PROMPT="
  # $(text 94)"
    else
      local WS_SERVER_IP_SHOW=${WS_SERVER_IP[17]} &&
      local TYPE_HOST_DOMAIN=$VMESS_HOST_DOMAIN &&
      local TYPE_PORT_WS=$PORT_VMESS_WS &&
      local PROMPT+="
      # $(text 52)" &&
      local OUTBOUND_REPLACE+=" { \"type\": \"vmess\", \"tag\": \"${NODE_NAME[17]} ${NODE_TAG[6]}\", \"server\":\"${CDN[17]}\", \"server_port\":80, \"uuid\":\"${UUID[17]}\", \"security\": \"auto\", \"transport\": { \"type\":\"ws\", \"path\":\"/$VMESS_WS_PATH\", \"headers\": { \"Host\": \"$VMESS_HOST_DOMAIN\" } }, \"multiplex\": { \"enabled\":true, \"protocol\":\"h2mux\", \"max_streams\":16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } },"
    fi
    local NODE_REPLACE+="\"${NODE_NAME[17]} ${NODE_TAG[6]}\","
  fi

  if [ -n "$PORT_VLESS_WS" ]; then
    if [[ "${STATUS[1]}" =~ $(text 27)|$(text 28) ]] || [[ "$IS_ARGO" = 'is_argo' && "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]]; then
      local OUTBOUND_REPLACE+=" { \"type\": \"vless\", \"tag\": \"${NODE_NAME[18]} ${NODE_TAG[7]}\", \"server\":\"${CDN[18]}\", \"server_port\":443, \"uuid\": \"${UUID[18]}\", \"tls\": { \"enabled\":true, \"server_name\":\"$ARGO_DOMAIN\", \"insecure\": false, \"utls\": { \"enabled\":true, \"fingerprint\":\"firefox\" } }, \"transport\": { \"type\":\"ws\", \"path\":\"/$VLESS_WS_PATH\", \"headers\": { \"Host\": \"$ARGO_DOMAIN\" }, \"max_early_data\":2560, \"early_data_header_name\":\"Sec-WebSocket-Protocol\" }, \"multiplex\": { \"enabled\":true, \"protocol\":\"h2mux\", \"max_streams\":16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } },"
      [ "$ARGO_TYPE" = 'is_token_argo' ] && [ -z "$PROMPT" ] && local PROMPT="
  # $(text 94)"
    else
      local WS_SERVER_IP_SHOW=${WS_SERVER_IP[18]} &&
      local TYPE_HOST_DOMAIN=$VLESS_HOST_DOMAIN &&
      local TYPE_PORT_WS=$PORT_VLESS_WS &&
      local PROMPT+="
      # $(text 52)" &&
      local OUTBOUND_REPLACE+=" { \"type\": \"vless\", \"tag\": \"${NODE_NAME[18]} ${NODE_TAG[7]}\", \"server\":\"${CDN[18]}\", \"server_port\":443, \"uuid\": \"${UUID[18]}\",\"tls\": { \"enabled\":true, \"server_name\":\"$VLESS_HOST_DOMAIN\", \"insecure\": false, \"utls\": { \"enabled\":true, \"fingerprint\":\"firefox\" } }, \"transport\": { \"type\":\"ws\", \"path\":\"/$VLESS_WS_PATH\", \"headers\": { \"Host\": \"$VLESS_HOST_DOMAIN\" }, \"max_early_data\":2560, \"early_data_header_name\":\"Sec-WebSocket-Protocol\" }, \"multiplex\": { \"enabled\":true, \"protocol\":\"h2mux\", \"max_streams\":16, \"padding\": true, \"brutal\":{ \"enabled\":${IS_BRUTAL}, \"up_mbps\":1000, \"down_mbps\":1000 } } },"
    fi
    local NODE_REPLACE+="\"${NODE_NAME[18]} ${NODE_TAG[7]}\","
  fi

  [ -n "$PORT_H2_REALITY" ] &&
  local REALITY_H2_INBOUND=" { \"type\": \"vless\", \"tag\": \"${NODE_NAME[19]} ${NODE_TAG[8]}\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_H2_REALITY}, \"uuid\":\"${UUID[19]}\", \"tls\": { \"enabled\":true, \"server_name\":\"${TLS_SERVER}\", \"utls\": { \"enabled\":true, \"fingerprint\":\"firefox\" }, \"reality\":{ \"enabled\":true, \"public_key\":\"${REALITY_PUBLIC[19]}\", \"short_id\":\"\" } }, \"transport\": { \"type\": \"http\" } }," &&
  local REALITY_H2_NODE="\"${NODE_NAME[19]} ${NODE_TAG[8]}\"" &&
  local NODE_REPLACE+="${REALITY_H2_NODE}," &&
  local OUTBOUND_REPLACE+=" ${REALITY_H2_INBOUND}"

  [ -n "$PORT_GRPC_REALITY" ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"vless\", \"tag\": \"${NODE_NAME[20]} ${NODE_TAG[9]}\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_GRPC_REALITY}, \"uuid\":\"${UUID[20]}\", \"tls\": { \"enabled\":true, \"server_name\":\"${TLS_SERVER}\", \"utls\": { \"enabled\":true, \"fingerprint\":\"firefox\" }, \"reality\":{ \"enabled\":true, \"public_key\":\"${REALITY_PUBLIC[20]}\", \"short_id\":\"\" } }, \"transport\": { \"type\": \"grpc\", \"service_name\": \"grpc\" } }," &&
  local NODE_REPLACE+="\"${NODE_NAME[20]} ${NODE_TAG[9]}\","

  [ -n "$PORT_ANYTLS" ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"anytls\", \"tag\": \"${NODE_NAME[21]} ${NODE_TAG[10]}\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_ANYTLS}, \"password\": \"${UUID[21]}\", \"idle_session_check_interval\": \"30s\", \"idle_session_timeout\": \"30s\", \"min_idle_session\": 5, \"tls\": { \"enabled\": true, \"certificate_public_key_sha256\": [\"$SELF_SIGNED_FINGERPRINT_BASE64\"], \"server_name\": \"${TLS_SERVER}\", \"utls\": { \"enabled\": true, \"fingerprint\": \"firefox\" } } }," &&
  local NODE_REPLACE+="\"${NODE_NAME[21]} ${NODE_TAG[10]}\","

  [ -n "$PORT_NAIVE" ] &&
  local OUTBOUND_REPLACE+=" { \"type\": \"naive\", \"tag\": \"${NODE_NAME[22]} ${NODE_TAG[11]} http2\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_NAIVE}, \"username\": \"${UUID[22]}\", \"password\": \"${UUID[22]}\", \"udp_over_tcp\": true, \"quic\": false, \"tls\": { \"enabled\": true, \"certificate\": [$(tr -d '\n' <<< "$CERT200_JSON")], \"server_name\": \"${TLS_SERVER}\" } }, { \"type\": \"naive\", \"tag\": \"${NODE_NAME[22]} ${NODE_TAG[11]} quic\", \"server\": \"${SERVER_IP}\", \"server_port\": ${PORT_NAIVE}, \"username\": \"${UUID[22]}\", \"password\": \"${UUID[22]}\", \"udp_over_tcp\": false, \"quic\": true, \"quic_congestion_control\": \"bbr\", \"tls\": { \"enabled\": true, \"certificate\": [$(tr -d '\n' <<< "$CERT200_JSON")], \"server_name\": \"${TLS_SERVER}\" } }," &&
  local NODE_REPLACE+="\"${NODE_NAME[22]} ${NODE_TAG[11]} http2\",\"${NODE_NAME[22]} ${NODE_TAG[11]} quic\","

  {
   #Generate sing-box SFM SFA SFI subscription file
    [ ! -s "$TEMP_DIR/sing-box-template" ] && wget --no-check-certificate --continue -qO "$TEMP_DIR/sing-box-template" "${GH_PROXY}${SUBSCRIBE_TEMPLATE}/sing-box" 2>/dev/null
    cat $TEMP_DIR/sing-box-template | sed "s#\"<OUTBOUND_REPLACE>\",#$OUTBOUND_REPLACE#; s#\"<NODE_REPLACE>\"#${NODE_REPLACE%,}#g" | ${WORK_DIR}/jq > ${WORK_DIR}/subscribe/sing-box
    rm -f $TEMP_DIR/sing-box-template
  } &>/dev/null

  # Generate QR code url file
  [ "$IS_SUB" = 'is_sub' ] && cat > ${WORK_DIR}/subscribe/qr << EOF
$(text 81):
$(text 82) 1:
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto

$(text 82) 2:
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto2

$(text 80) QRcode:
$(text 82) 1:
https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto

$(text 82) 2:
https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto2

$(text 82) 1:
$(${WORK_DIR}/qrencode "$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto")

$(text 82) 2:
$(${WORK_DIR}/qrencode "$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto2")
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
│     $(warning "Throne")     │
│                │
└────────────────┘
$(hint "${THRONE_SUBSCRIBE}")

*******************************************
┌────────────────┐
│                │
│    $(warning "Sing-box")    │
│                │
└────────────────┘
----------------------------

$(info "$(echo "{ \"outbounds\":[ ${OUTBOUND_REPLACE%,} ] }" | ${WORK_DIR}/jq)

${PROMPT}

  $(text 72)")
"

  [ "$IS_SUB" = 'is_sub' ] && EXPORT_LIST_FILE+="

*******************************************

$(hint "Index:
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/

QR code:
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/qr

V2rayN $(text 80):
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/v2rayn")

$(hint "Throne $(text 80):
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/neko")

$(hint "Clash $(text 80):
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/clash
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/clash2

SFI / SFA / SFM $(text 80):
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/sing-box

ShadowRocket $(text 80):
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/shadowrocket")

*******************************************

$(info " $(text 81):
$(text 82) 1:
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto

$(text 82) 2:
$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto2

 $(text 80) QRcode:
$(text 82) 1:
https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto

$(text 82) 2:
https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto2")

$(hint "$(text 82) 1:")
$(${WORK_DIR}/qrencode $SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto)

$(hint "$(text 82) 2:")
$(${WORK_DIR}/qrencode $SUBSCRIBE_ADDRESS/${UUID_CONFIRM}/auto2)
"

# Generate and display node information
  echo "$EXPORT_LIST_FILE" > ${WORK_DIR}/list
  cat ${WORK_DIR}/list

  # Display script usage data
  statistics_of_run_times get
}

#Create shortcut
create_shortcut() {
  cat > ${WORK_DIR}/sb.sh << EOF
#!/usr/bin/env bash

bash <(wget --no-check-certificate -qO-https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh) \$@
EOF
  chmod +x ${WORK_DIR}/sb.sh
  ln -sf ${WORK_DIR}/sb.sh /usr/bin/sb
  [ -s /usr/bin/sb ] && info "\n $(text 71) "
}

# Change the listening port of each protocol
change_start_port() {
  OLD_PORTS=$(awk -F ':|,' '/listen_port/{print $2}' ${WORK_DIR}/conf/*)
  OLD_START_PORT=$(awk 'NR == 1 { min = $0 } { if ($0 < min) min = $0; count++ } END {print min}' <<< "$OLD_PORTS")
  OLD_CONSECUTIVE_PORTS=$(awk 'END { print NR }' <<< "$OLD_PORTS")
  input_start_port $OLD_CONSECUTIVE_PORTS
  cmd_systemctl disable sing-box
  for ((a=0; a<$OLD_CONSECUTIVE_PORTS; a++)) do
    [ -s ${WORK_DIR}/conf/${CONF_FILES[a]} ] && sed -i "s/\(.*listen_port.*:\)$((OLD_START_PORT+a))/\1$((START_PORT+a))/" ${WORK_DIR}/conf/*
  done
  fetch_nodes_value
  [ -n "$PORT_NGINX" ] && UUID_CONFIRM=$(sed -n 's#.*location[ ]\+\/\(.*\)-v[ml]ess.*#\1#gp' /etc/sing-box/nginx.conf | sed -n '1p') && export_nginx_conf_file
  cmd_systemctl enable sing-box
  [ -n "$ARGO_DOMAIN" ] && export_argo_json_file
  sync_firewall_rules
  sleep 2
  export_list
  cmd_systemctl status sing-box &>/dev/null && info " Sing-box $(text 121) $(text 37) " || error " Sing-box $(text 121) $(text 38) "
}

# Add or delete protocols
change_protocols() {
  check_install
  [ "${STATUS[0]}" = "$(text 26)" ] && error "\n Sing-box $(text 26) "

  # Check server IP
  check_system_ip

  # Find the installed protocol and traverse its name in all protocol lists. After getting the protocol name, it is stored in EXISTED_PROTOCOLS; if there is no protocol, it is stored in NOT_EXISTED_PROTOCOLS.
  INSTALLED_PROTOCOLS_LIST=$(awk -F '"' '/"tag":/{print $4}' ${WORK_DIR}/conf/*_inbounds.json | grep -v 'shadowtls-in' | awk '{print $NF}')
  for f in ${!NODE_TAG[@]}; do [[ $INSTALLED_PROTOCOLS_LIST =~ "${NODE_TAG[f]}" ]] && EXISTED_PROTOCOLS+=("${PROTOCOL_LIST[f]}") || NOT_EXISTED_PROTOCOLS+=("${PROTOCOL_LIST[f]}"); done

  # List installed protocols
  hint "\n $(text 136) (${#EXISTED_PROTOCOLS[@]})"
for h in "${!EXISTED_PROTOCOLS[@]}"; do
    hint " $(asc $(( h+97 ))). ${EXISTED_PROTOCOLS[h]} "
  done

  # Select the protocol name that needs to be deleted from the installed protocols and store it in REMOVE_PROTOCOLS, and store the protocol of the saved protocol in KEEP_PROTOCOLS
  reading "\n $(text 64) " REMOVE_SELECT
  # Unify to lowercase, remove duplicate options, process options that are not in the optional list, and process special symbols
  REMOVE_SELECT=$(sed "s/[^a-$(asc $(( ${#EXISTED_PROTOCOLS[@]} + 96 )))]//g" <<< "${REMOVE_SELECT,,}" | awk 'BEGIN{RS=""; FS=""}{delete seen; output=""; for(i=1; i<=NF; i++){ if(!seen[$i]++){ output=output $i } } print output}')

  for ((j=0; j<${#REMOVE_SELECT}; j++)); do
    REMOVE_PROTOCOLS+=("${EXISTED_PROTOCOLS[$(( $(asc "$(awk "NR==$[j+1] {print}" <<< "$(grep -o . <<< "$REMOVE_SELECT")")") - 97 ))]}")
  done

  for k in "${EXISTED_PROTOCOLS[@]}"; do
    [[ ! "${REMOVE_PROTOCOLS[@]}" =~ "$k" ]] && KEEP_PROTOCOLS+=("$k")
  done

# If there are uninstalled protocols, display the list and select installation, and put the added protocols in ADD_PROTOCOLS
  if [ "${#NOT_EXISTED_PROTOCOLS[@]}" -gt 0 ]; then
    hint "\n $(text 137) (${#NOT_EXISTED_PROTOCOLS[@]}) "
    for i in "${!NOT_EXISTED_PROTOCOLS[@]}"; do
      hint " $(asc $(( i+97 ))). ${NOT_EXISTED_PROTOCOLS[i]} "
    done
    reading "\n $(text 66) " ADD_SELECT
    # Unify to lowercase, remove duplicate options, process options that are not in the optional list, and process special symbols
ADD_SELECT=$(sed "s/[^a-$(asc $(( ${#NOT_EXISTED_PROTOCOLS[@]} + 96 )))]//g" <<< "${ADD_SELECT,,}" | awk 'BEGIN{RS=""; FS=""}{delete seen; output=""; for(i=1; i<=NF; i++){ if(!seen[$i]++){ output=output $i } } print output}')

    for ((l=0; l<${#ADD_SELECT}; l++)); do
      ADD_PROTOCOLS+=("${NOT_EXISTED_PROTOCOLS[$(( $(asc "$(awk "NR==$[l+1] {print}" <<< "$(grep -o . <<< "$ADD_SELECT")")") -97 ))]}")
    done
  fi

  # Reinstall = keep + add, if the number is 0, uninstall is triggered
REINSTALL_PROTOCOLS=("${KEEP_PROTOCOLS[@]}" "${ADD_PROTOCOLS[@]}")
  [ "${#REINSTALL_PROTOCOLS[@]}" = 0 ] && error "\n $(text 73) "

  # Display the reinstalled protocol list and confirm whether it is correct
  hint "\n $(text 138) (${#REINSTALL_PROTOCOLS[@]}) "
  [ "${#KEEP_PROTOCOLS[@]}" -gt 0 ] && hint "\n $(text 74) (${#KEEP_PROTOCOLS[@]}) "
  for r in "${!KEEP_PROTOCOLS[@]}"; do
    hint " $[r+1]. ${KEEP_PROTOCOLS[r]} "
  done

  [ "${#ADD_PROTOCOLS[@]}" -gt 0 ] && hint "\n $(text 75) (${#ADD_PROTOCOLS[@]}) "
  for r in "${!ADD_PROTOCOLS[@]}"; do
    hint " $[r+1]. ${ADD_PROTOCOLS[r]} "
  done

  reading "\n $(text 68) " CONFIRM
  [ "${CONFIRM,,}" = 'n' ] && exit 0

# Traverse the array of all protocol lists for the confirmed installed protocols, find their subscripts and change them into English lowercase
  for m in "${!REINSTALL_PROTOCOLS[@]}"; do
    for n in "${!PROTOCOL_LIST[@]}"; do
      if [ "${REINSTALL_PROTOCOLS[m]}" = "${PROTOCOL_LIST[n]}" ]; then
        INSTALL_PROTOCOLS+=($(asc $[n+98]))
      fi
    done
  done

  # Get information about each node
  fetch_nodes_value

  # Configuration information for new nodes
  UUID_CONFIRM=$(awk '{print $1}' <<< "${UUID[@]} $TROJAN_PASSWORD")
  for v in "${NODE_NAME[@]}"; do
    [ -n "$v" ] && NODE_NAME_CONFIRM="$v" && break
  done
  [ "${#WS_SERVER_IP[@]}" -gt 0 ] && WS_SERVER_IP_SHOW=$(awk '{print $1}' <<< "${WS_SERVER_IP[@]}") && CDN=$(awk '{print $1}' <<< "${CDN[@]}")

  #Find the inbound file name of the protocol to be deleted
  for o in "${REMOVE_PROTOCOLS[@]}"; do
    for s in ${!PROTOCOL_LIST[@]}; do
      [ "$o" = "${PROTOCOL_LIST[s]}" ] && REMOVE_FILE+=("${NODE_TAG[s]}_inbounds.json")
    done
  done

  # If necessary, delete the hysteria2 jump port and add it back later.
  [ "$IS_HOPPING" = 'is_hopping' ] && del_port_hopping_nat

  # Delete unnecessary protocol configuration files
  [ "${#REMOVE_FILE[@]}" -gt 0 ] && for t in "${REMOVE_FILE[@]}"; do
    rm -f ${WORK_DIR}/conf/*${t}
  done

  # Find the original port number in the existing agreement
  for p in "${KEEP_PROTOCOLS[@]}"; do
    for u in "${!PROTOCOL_LIST[@]}"; do
      [ "$p" = "${PROTOCOL_LIST[u]}" ] && KEEP_PORTS+=("$(awk -F '[:,]' '/listen_port/{print $2}' ${WORK_DIR}/conf/*${NODE_TAG[u]}_inbounds.json)")
    done
  done

  # Find the free port number according to all protocols
  for q in "${!REINSTALL_PROTOCOLS[@]}"; do
    [[ ! ${KEEP_PORTS[@]} =~ $[START_PORT + q] ]] && ADD_PORTS+=($[START_PORT + q])
  done

  # Port numbers of all protocols
  REINSTALL_PORTS=(${KEEP_PORTS[@]} ${ADD_PORTS[@]})

  CHECK_PROTOCOLS=b
  # Get Reality port
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_XTLS_REALITY=${REINSTALL_PORTS[POSITION]}
    NEED_PRIVATE_KEY='need_private_key'
  else
    unset PORT_XTLS_REALITY
  fi

  # Get Hysteria2 port
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_HYSTERIA2=${REINSTALL_PORTS[POSITION]}
    [ -z "${PORT_HOPPING_START}${PORT_HOPPING_END}" ] && input_hopping_port
  else
    unset PORT_HYSTERIA2
  fi

  # Get Tuic V5 port
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_TUIC=${REINSTALL_PORTS[POSITION]}
  else
    unset PORT_TUIC
  fi

  # Get ShadowTLS port
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_SHADOWTLS=${REINSTALL_PORTS[POSITION]}
  fi

 # Get Shadowsocks port
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_SHADOWSOCKS=${REINSTALL_PORTS[POSITION]}
  else
    unset PORT_SHADOWSOCKS
  fi

  # Get Trojan port
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_TROJAN=${REINSTALL_PORTS[POSITION]}
  else
    unset PORT_TROJAN
  fi

  #Enjoy ws or argo based origin
  if [ -s ${ARGO_DAEMON_FILE} ]; then
    local ARGO_ORIGIN_RULES_STATUS=is_argo
    [ "$SYSTEM" = 'Alpine' ] && ARGO_RUNS="$(sed -n's/command="\(.*\)"/\1/gp' $ARGO_DAEMON_FILE) $(sed -n's/command_args="\(.*\)"/\1/gp' $ARGO_DAEMON_FILE)" || ARGO_RUNS=$(sed -n "s/^ExecStart=\(.*\)/\1/gp" ${ARGO_DAEMON_FILE})
  elif ls ${WORK_DIR}/conf/*-ws*inbounds.json >/dev/null 2>&1; then
    local ARGO_ORIGIN_RULES_STATUS=is_origin
  else
local ARGO_ORIGIN_RULES_STATUS=no_argo_no_origin
  fi

# Get vmess + ws configuration information
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    local DOMAIN_ERROR_TIME=5
    if [[ "$ARGO_READY" != 'argo_ready' || "$ORIGIN_READY" != 'origin_ready' ]]; then
      if [ "$ARGO_ORIGIN_RULES_STATUS" = 'is_origin' ]; then
        until [ -n "$VMESS_HOST_DOMAIN" ]; do
          (( DOMAIN_ERROR_TIME--)) || true
[ "$DOMAIN_ERROR_TIME" != 0 ] && TYPE=VMESS && reading "\n $(text 50) " VMESS_HOST_DOMAIN || error "\n $(text 3) \n"
        done
      elif [ "$ARGO_ORIGIN_RULES_STATUS" = 'no_argo_no_origin' ]; then
        [ -z "$ARGO_OR_ORIGIN_RULES" ] && hint "\n $(text 57) " && reading "\n $(text 24) " ARGO_OR_ORIGIN_RULES
        [ "$ARGO_OR_ORIGIN_RULES" != '2' ] && ARGO_OR_ORIGIN_RULES=1 && IS_ARGO=is_argo || IS_ARGO=no_argo
        if [ "$IS_ARGO" = 'is_argo' ]; then
# If there is no nginx configuration originally, you need to obtain nginx port information
          [ -z "$PORT_NGINX"  ] && input_nginx_port
          until [ -n "$ARGO_RUNS" ]; do
            input_argo_auth is_add_protocols
            [ -n "$ARGO_RUNS" ] && local ARGO_READY=argo_ready && break
          done
        else
          until [ -n "$VMESS_HOST_DOMAIN" ]; do
            (( DOMAIN_ERROR_TIME-- )) || true
            [ "$DOMAIN_ERROR_TIME" != 0 ] && TYPE=VMESS && reading "\n $(text 50) " VMESS_HOST_DOMAIN || error "\n $(text 3) \n"
          done
          local ORIGIN_READY=origin_ready
        fi
      fi
    fi
    POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_VMESS_WS=${REINSTALL_PORTS[POSITION]}
  else
    unset PORT_VMESS_WS
  fi

  # Get vless + ws + tls configuration information
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    local DOMAIN_ERROR_TIME=5
    if [[ "$ARGO_READY" != 'argo_ready' || "$ORIGIN_READY" != 'origin_ready' ]]; then
      if [ "$ARGO_ORIGIN_RULES_STATUS" = 'is_origin' ]; then
        until [ -n "$VLESS_HOST_DOMAIN" ]; do
          (( DOMAIN_ERROR_TIME-- )) || true
          [ "$DOMAIN_ERROR_TIME" != 0 ] && TYPE=VLESS && reading "\n $(text 50) " VLESS_HOST_DOMAIN || error "\n $(text   3) \n"
        done
      elif [ "$ARGO_ORIGIN_RULES_STATUS" = 'no_argo_no_origin' ]; then
        [ -z "$ARGO_OR_ORIGIN_RULES" ] && hint "\n $(text 57) " && reading "\n $(text 24) " ARGO_OR_ORIGIN_RULES
        [ "$ARGO_OR_ORIGIN_RULES" != '2' ] && ARGO_OR_ORIGIN_RULES=1 && IS_ARGO=is_argo || IS_ARGO=no_argo
        if [ "$IS_ARGO" = 'is_argo' ]; then
           #If there is no nginx configuration originally, you need to obtain nginx port information
          [ -z "$PORT_NGINX"  ] && input_nginx_port
          until [ -n "$ARGO_RUNS" ]; do
            [ "$ARGO_READY" != 'argo_ready' ] && input_argo_auth is_add_protocols
            [ -n "$ARGO_RUNS" ] && local ARGO_READY=argo_ready && break
          done
        else
          until [ -n "$VLESS_HOST_DOMAIN" ]; do
            (( DOMAIN_ERROR_TIME-- )) || true
            [ "$DOMAIN_ERROR_TIME" != 0 ] && TYPE=VLESS && reading "\n $(text 50) " VLESS_HOST_DOMAIN || error "\n $(text   3) \n"
          done
          local ORIGIN_READY=origin_ready
        fi
      fi
    fi
    POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_VLESS_WS=${REINSTALL_PORTS[POSITION]}
  else
    unset PORT_VLESS_WS
  fi

  # If there was no ws before and now there is a new ws, confirm the server IP and enter cdn
  if [[ "${#CDN[@]}" = '0' && ( "$ARGO_READY" = 'argo_ready' || "$ORIGIN_READY" = 'origin_ready' ) ]]; then
    if grep -qi 'cloudflare' <<< "$ASNORG4$ASNORG6"; then
      if grep -qi 'cloudflare' <<< "$ASNORG6" && [ -n "$WAN4" ] && ! grep -qi 'cloudflare' <<< "$ASNORG4"; then
        SERVER_IP_DEFAULT=$WAN4
      elif grep -qi 'cloudflare' <<< "$ASNORG4" && [ -n "$WAN6" ] && ! grep -qi 'cloudflare' <<< "$ASNORG6"; then
        SERVER_IP_DEFAULT=$WAN6
      else
        local a=6
        until [ -n "$SERVER_IP" ]; do
          ((a--)) || true
          [ "$a" = 0 ] && error "\n $(text 3) \n"
          reading "\n $(text 46) " SERVER_IP
        done
      fi
    elif [ -n "$WAN4" ]; then
      SERVER_IP_DEFAULT=$WAN4
    elif [ -n "$WAN6" ]; then
      SERVER_IP_DEFAULT=$WAN6
    fi

  # Enter the server IP. The default is the detected server IP. If all are empty, prompt and exit the script.
    [ -z "$SERVER_IP" ] && reading "\n $(text 10) " SERVER_IP
    SERVER_IP=${SERVER_IP:-"$SERVER_IP_DEFAULT"} && WS_SERVER_IP_SHOW=$SERVER_IP
    [ -z "$SERVER_IP" ] && error " $(text 47) "

    input_cdn
  fi

  # Get H2 + Reality port
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_H2_REALITY=${REINSTALL_PORTS[POSITION]}
    NEED_PRIVATE_KEY='need_private_key'
  else
    unset PORT_H2_REALITY
  fi

  # Get gRPC + Reality port
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_GRPC_REALITY=${REINSTALL_PORTS[POSITION]}
    NEED_PRIVATE_KEY='need_private_key'
  else
    unset PORT_GRPC_REALITY
  fi
# If there was no Reality before, and now the new reality is added, confirm the privateKey
  [[ "${#REALITY_PRIVATE[@]}" = 0 && "${NEED_PRIVATE_KEY}" = 'need_private_key' ]] && input_reality_key

  # Make ShadowTLS and shadowsocks passwords the same
  if [[ -n "$SHADOWTLS_PASSWORD" && -z "$SHADOWSOCKS_PASSWORD" ]]; then
    SIP022_PASSWORD=$SHADOWTLS_PASSWORD
  elif [[ -z "$SHADOWTLS_PASSWORD" && -n "$SHADOWSOCKS_PASSWORD" ]]; then
    SIP022_PASSWORD=$SHADOWSOCKS_PASSWORD
  fi

  # Get anytls port
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_ANYTLS=${REINSTALL_PORTS[POSITION]}
  else
    unset PORT_ANYTLS
  fi

  # Get naive port
  CHECK_PROTOCOLS=$(asc "$CHECK_PROTOCOLS" ++)
  if [[ "${INSTALL_PROTOCOLS[@]}" =~ "$CHECK_PROTOCOLS" ]]; then
    POSITION=$(awk -v target=$CHECK_PROTOCOLS '{ for(i=1; i<=NF; i++) if($i == target) { print i-1; break } }' <<< "${INSTALL_PROTOCOLS[*]}")
    PORT_NAIVE=${REINSTALL_PORTS[POSITION]}
  else
    unset PORT_NAIVE
  fi

 # Stop sing-box service
  cmd_systemctl disable sing-box

  # Close firewall related ports

  # Generate Nginx configuration file
  [ -n "$PORT_NGINX" ] && export_nginx_conf_file

  # Regenerate Sing-box daemon file
  sing-box_systemd

  # Generate json files for each protocol
  sing-box_json change

  # Install and remove Argo services if necessary
  if ls ${WORK_DIR}/conf/*-ws*inbounds.json >/dev/null 2>&1; then
    if [[ "$ARGO_OR_ORIGIN_RULES" != '2' && "$ARGO_ORIGIN_RULES_STATUS" != 'is_origin' && ! -s ${ARGO_DAEMON_FILE} ]]; then
      argo_systemd
cmd_systemctl enable argo >/dev/null 2>&1
    fi
  elif [ -s ${ARGO_DAEMON_FILE} ]; then
    cmd_systemctl disable argo >/dev/null 2>&1
    rm -f ${ARGO_DAEMON_FILE}
    [ -s ${WORK_DIR}/tunnel.json ] && rm -f ${WORK_DIR}/tunnel.*
  fi

  # If necessary, delete nginx configuration file
  ! ls ${ARGO_DAEMON_FILE} >/dev/null 2>&1 && [[ -s ${WORK_DIR}/nginx.conf && "$IS_SUB" = 'no_sub' ]] && IS_ARGO=no_argo && rm -f ${WORK_DIR}/nginx.conf

  # 运行 sing-box
  cmd_systemctl enable sing-box

  # Open firewall related ports
  sync_firewall_rules

  # Wait for the service to start
  sleep 3

  # Check the status again and run sing-box
  check_install
  case "${STATUS[0]}" in
    "$(text 26)" )
      error "\n Sing-box $(text 28) $(text 38) \n"
      ;;
    "$(text 27)" )
      cmd_systemctl enable sing-box
      cmd_systemctl status sing-box &>/dev/null && info "\n Sing-box $(text 28) $(text 37) \n" || error "\n Sing-box $(text 28) $(text 38) \n"
      ;;
    "$(text 28)" )
      info "\n Sing-box $(text 28) $(text 37) \n"
esac

  # Export node and subscription service information
  export_list
}

# Uninstall sing-box family bucket
uninstall() {
  if [ -d ${WORK_DIR} ]; then
    [ -s ${ARGO_DAEMON_FILE} ] && cmd_systemctl disable argo &>/dev/null
    [ -s ${SINGBOX_DAEMON_FILE} ] && cmd_systemctl disable sing-box &>/dev/null
    sleep 1
    [[ -s ${WORK_DIR}/nginx.conf && "$(ps -ef | grep -c '[n]ginx')" = 0 ]] && reading "\n $(text 83) " REMOVE_NGINX
    [ "${REMOVE_NGINX,,}" = 'y' ] && ${PACKAGE_UNINSTALL[int]} nginx >/dev/null 2>&1
    purge_service_firewall_rules
    del_port_hopping_nat >/dev/null 2>&1 || true
    rm -rf ${WORK_DIR} ${TEMP_DIR} ${ARGO_DAEMON_FILE} ${SINGBOX_DAEMON_FILE} /usr/bin/sb
    info "\n $(text 16) \n"
  else
    error "\n $(text 15) \n"
  fi
}


# Latest version of Sing-box
version() {
  # Get the sing-box version that needs to be downloaded
  local ONLINE=$(get_sing_box_version)

  grep -q '.' <<< "$ONLINE" || error " $(text 100) \n"
  local LOCAL=$(${WORK_DIR}/sing-box version | awk '/version/{print $NF}')
  info "\n $(text 40) "
  [[ -n "$ONLINE" && "$ONLINE" != "$LOCAL" ]] && reading "\n $(text 9) " UPDATE || info " $(text 41) "

  if [ "${UPDATE,,}" = 'y' ]; then
    check_system_info
    wget --no-check-certificate --continue ${GH_PROXY}https://github.com/SagerNet/sing-box/releases/download/v$ONLINE/sing-box-$ONLINE-linux-$SING_BOX_ARCH.tar.gz -qO- | tar xz -C $TEMP_DIR sing-box-$ONLINE-linux-$SING_BOX_ARCH/sing-box

    if [ -s $TEMP_DIR/sing-box-$ONLINE-linux-$SING_BOX_ARCH/sing-box ]; then
      cmd_systemctl disable sing-box
# Back up old version
      cp ${WORK_DIR}/sing-box ${WORK_DIR}/sing-box.bak
      hint "\n $(text 102) \n"

      # Install new version
      chmod +x $TEMP_DIR/sing-box-$ONLINE-linux-$SING_BOX_ARCH/sing-box && mv $TEMP_DIR/sing-box-$ONLINE-linux-$SING_BOX_ARCH/sing-box ${WORK_DIR}/sing-box
      cmd_systemctl enable sing-box
      sleep 2

      # Check if the new version runs successfully
      if cmd_systemctl status sing-box &>/dev/null; then
        # The new version runs successfully, delete the backup
        rm -f ${WORK_DIR}/sing-box.bak
info "\n $(text 103) \n"
      else
        # If the new version fails to run, restore the old version
        warning "\n $(text 104) \n"
        mv ${WORK_DIR}/sing-box.bak ${WORK_DIR}/sing-box
        cmd_systemctl enable sing-box
        sleep 2

        if cmd_systemctl status sing-box &>/dev/null; then
          info "\n $(text 105) \n"
        else
          error "\n $(text 106) \n"
        fi
      fi
    else
      error "\n $(text 42) "
    fi
  fi
}

# Determine the current running status of Sing-box and assign values ​​to menus and actions accordingly
menu_setting() {
  if [[ "${STATUS[0]}" =~ $(text 27)|$(text 28) ]]; then
    OPTION[1]="1 .  $(text 29)"
    [ "${STATUS[0]}" = "$(text 28)" ] && OPTION[2]="2 .  $(text 27) Sing-box (sb -s)" || OPTION[2]="2 .  $(text 28) Sing-box (sb -s)"
    [ "${STATUS[1]}" = "$(text 28)" ] && OPTION[3]="3 .  $(text 27) Argo (sb -a)" || OPTION[3]="3 .  $(text 28) Argo (sb -a)"
    OPTION[4]="4 .  $(text 92)"
    OPTION[5]="5 .  $(text 121)"
    OPTION[6]="6 .  $(text 31)"
    OPTION[7]="7 .  $(text 32)"
    OPTION[8]="8 .  $(text 62)"
    OPTION[9]="9 .  $(text 33)"
    OPTION[10]="10.  $(text 59)"
    OPTION[11]="11.  $(text 69)"
    OPTION[12]="12.  $(text 76)"

    ACTION[1]() { export_list; exit 0; }

    [ "${STATUS[0]}" = "$(text 28)" ] &&
    ACTION[2]() {
      cmd_systemctl disable sing-box
      cmd_systemctl status sing-box &>/dev/null && error " Sing-box $(text 27) $(text 38) " || info " Sing-box $(text 27) $(text 37)"
    } ||
    ACTION[2]() {
      cmd_systemctl enable sing-box
      sleep 2
      cmd_systemctl status sing-box &>/dev/null && info " Sing-box $(text 28) $(text 37)" || error " Sing-box $(text 28) $(text 38) "
    }

    [ "${STATUS[1]}" = "$(text 28)" ] &&
    ACTION[3]() {
      cmd_systemctl disable argo
      cmd_systemctl status argo &>/dev/null && error " Argo $(text 27) $(text 38) " || info " Argo $(text 27) $(text 37)"
    } ||
    ACTION[3]() {
      cmd_systemctl enable argo
      sleep 2
      cmd_systemctl status argo &>/dev/null &&  info " Argo $(text 28) $(text 37)" || error " Argo $(text 28) $(text 38) "
      grep -qs '\--url' ${ARGO_DAEMON_FILE} && fetch_quicktunnel_domain && export_list
    }

    ACTION[4]() { change_argo; exit; }
    ACTION[5]() { change_config; exit; }
    ACTION[6]() { version; exit; }
    ACTION[7]() { bash <(wget --no-check-certificate -qO- ${GH_PROXY}https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh); exit; }
    ACTION[8]() { change_protocols; exit; }
    ACTION[9]() { uninstall; exit; }
    ACTION[10]() { bash <(wget --no-check-certificate -qO- ${GH_PROXY}https://raw.githubusercontent.com/fscarmen/argox/main/argox.sh) -$L; exit; }
    ACTION[11]() { bash <(wget --no-check-certificate -qO- ${GH_PROXY}https://raw.githubusercontent.com/fscarmen/sba/main/sba.sh) -$L; exit; }
    ACTION[12]() { bash <(wget --no-check-certificate -qO- https://tcp.hy2.sh/); exit; }
  else
    OPTION[1]="1.  $(text 115)"
    OPTION[2]="2.  $(text 34) + Argo + $(text 80) $(text 89)"
    OPTION[3]="3.  $(text 34) + Argo $(text 89)"
    OPTION[4]="4.  $(text 34) + $(text 80) $(text 89)"
    OPTION[5]="5.  $(text 34)"
    OPTION[6]="6.  $(text 32)"
    OPTION[7]="7.  $(text 59)"
    OPTION[8]="8.  $(text 69)"
    OPTION[9]="9.  $(text 76)"

    ACTION[1]() { IS_FAST_INSTALL='is_fast_install'; CHOOSE_PROTOCOLS=${CHOOSE_PROTOCOLS:-'a'}; START_PORT=${START_PORT:-"$START_PORT_DEFAULT"}; CDN=${CDN:-"${CDN_DOMAIN[0]}"}; IS_SUB='is_sub'; IS_ARGO='is_argo'; PORT_HOPPING_RANGE=${PORT_HOPPING_RANGE:-'50000:51000'}; install_sing-box; export_list install; create_shortcut; exit; }
    ACTION[2]() { IS_SUB=is_sub; IS_ARGO=is_argo; install_sing-box; export_list install; create_shortcut; exit; }
    ACTION[3]() { IS_SUB=no_sub; IS_ARGO=is_argo; install_sing-box; export_list install; create_shortcut; exit; }
    ACTION[4]() { IS_SUB=is_sub; IS_ARGO=no_argo; install_sing-box; export_list install; create_shortcut; exit; }
    ACTION[5]() { install_sing-box; export_list install; create_shortcut; exit; }
    ACTION[6]() { bash <(wget --no-check-certificate -qO- ${GH_PROXY}https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh); exit; }
    ACTION[7]() { bash <(wget --no-check-certificate -qO- ${GH_PROXY}https://raw.githubusercontent.com/fscarmen/argox/main/argox.sh) -$L; exit; }
    ACTION[8]() { bash <(wget --no-check-certificate -qO- ${GH_PROXY}https://raw.githubusercontent.com/fscarmen/sba/main/sba.sh) -$L; exit; }
    ACTION[9]() { bash <(wget --no-check-certificate -qO- ${GH_PROXY}https://tcp.hy2.sh/); exit; }
  fi

  [ "${#OPTION[@]}" -ge '10' ] && OPTION[0]="0 .  $(text 35)" || OPTION[0]="0.  $(text 35)"
  ACTION[0]() { exit; }
}

menu() {
  clear
  echo -e "======================================================================================================================\n"
  info " $(text 17): $VERSION\n $(text 18): $(text 1)\n $(text 19):\n\t $(text 20): $SYS\n\t $(text 21): $(uname -r)\n\t $(text 22): $SING_BOX_ARCH\n\t $(text 23): $VIRT "
  info "\t IPv4: $WAN4 $WARPSTATUS4 $COUNTRY4  $ASNORG4 "
  info "\t IPv6: $WAN6 $WARPSTATUS6 $COUNTRY6  $ASNORG6 "
  # Alignment display: Chinese double-width characters are filled with spaces according to the number of characters, and English is fixed width according to the longest status word "Not install" (11 characters)
  _sv() {
    local s="$1"
    if [ "$L" = 'C' ]; then
      [ "${#s}" -le 2 ] && printf '%s  ' "$s" || printf '%s' "$s"
    else
      printf '%-11s' "$s"
    fi
  }
  local _SBV; printf -v _SBV '%-26s' "$SING_BOX_VERSION"
  local _AV;  printf -v _AV  '%-26s' "$ARGO_VERSION"
  local _NV;  printf -v _NV  '%-26s' "$NGINX_VERSION"
  info "\t Sing-box: $(_sv "${STATUS[0]}")  ${_SBV}${SING_BOX_MEMORY_USAGE}\n\t Argo:     $(_sv "${STATUS[1]}")  ${_AV}${ARGO_MEMORY_USAGE}\n\t Nginx:    $(_sv "${STATUS[2]}")  ${_NV}${NGINX_MEMORY_USAGE}"
  echo -e "\n======================================================================================================================\n"
  for ((b=1;b<=${#OPTION[*]};b++)); do [ "$b" = "${#OPTION[*]}" ] && hint " ${OPTION[0]} " || hint " ${OPTION[b]} "; done
  reading "\n $(text 24) " CHOOSE

# Input must be a number and less than or equal to the maximum optional options
  if grep -qE "^[0-9]{1,2}$" <<< "$CHOOSE" && [ "$CHOOSE" -lt "${#OPTION[*]}" ]; then
    ACTION[$CHOOSE]
  else
    warning " $(text 36) [0-$((${#OPTION[*]}-1))] " && sleep 1 && menu
  fi
}

check_cdn
statistics_of_run_times update sing-box.sh 2>/dev/null

# Pass parameters
[[ "${*^^}" =~ '-E'|'-K' ]] && L=E
[[ "${*^^}" =~ '-C'|'-B'|'-L' ]] && L=C

# Get the value of the -F parameter
CONFIG_FILE=$(awk '-F[ =]' 'tolower($1) ~ /^-f$/{print $2}' <<< "$*")
if [[ -n "$CONFIG_FILE" && -s "$CONFIG_FILE" ]]; then
  NONINTERACTIVE_INSTALL=noninteractive_install
  . $CONFIG_FILE
  L=${LANGUAGE^^}
  [ "$ARGO" = 'true' ] && IS_ARGO=is_argo || IS_ARGO=no_argo
  [ "$SUBSCRIBE" = 'true' ] && IS_SUB=is_sub || IS_SUB=no_sub
fi

check_root
select_language
check_system_info
check_brutal

# It can be in the form of Key Value or Key=Value. When passing parameters,
# Parameter passing processing 1: Change all = to spaces, but retain =" because Json TunnelSecret ends with =", such as {"AccountTag":"9cc9e3e4d8f29d2a02e297f14f20513a","TunnelSecret":"6AYfKBOoNlPiTAu Wg64ZwujsNuERpWLm6pPJ2qpN8PM=","TunnelID":"1ac55430-f4dc-47d5-a850-bdce824c4101"}
# Parameter transfer processing 2: Remove sudo cloudflared service install to facilitate users to input Token and correctly read the real Value starting with key
ALL_PARAMETER=($(sed -E 's/(-c|-e|-f|-C|-E|-F) //; s/=([^"])/ \1/g; s/sudo cloudflared service install //' <<< $*))
[[ "${#ALL_PARAMETER[@]}" > 11 && "${ALL_PARAMETER[@]^^}" == *"--LANGUAGE"* && "${ALL_PARAMETER[@]^^}" == *"--CHOOSE_PROTOCOLS"* && "${ALL_PARAMETER[@]^^}" == *"--START_PORT"* && "${ALL_PARAMETER[@]^^}" == *"--SERVER_IP"* && "${ALL_PARAMETER[@]^^}" == *"--UUID"* && "${ALL_PARAMETER[@]^^}" == *"--NODE_NAME"* ]] && NONINTERACTIVE_INSTALL=noninteractive_install

# Parameter transfer processing, quick installation of parameters without interaction
for z in ${!ALL_PARAMETER[@]}; do
  case "${ALL_PARAMETER[z]^^}" in
    -K|-L )
      ((z++))
      IS_FAST_INSTALL=is_fast_install
      ;;
    -S )
      check_install
      if [ "${STATUS[0]}" = "$(text 26)" ]; then
        error "\n Sing-box $(text 26) "
      elif [ "${STATUS[0]}" = "$(text 28)" ]; then
        cmd_systemctl disable sing-box
        cmd_systemctl status sing-box &>/dev/null && error " Sing-box $(text 27) $(text 38) " || info "\n Sing-box $(text 27) $(text 37)"
      elif [ "${STATUS[0]}" = "$(text 27)" ]; then
        cmd_systemctl enable sing-box
        sleep 2
        cmd_systemctl status sing-box &>/dev/null && info "\n Sing-box $(text 28) $(text 37)" || error "\n Sing-box $(text 28) $(text 38)"
      fi
      exit 0
      ;;
    -A )
      check_install
      if [ "${STATUS[1]}" = "$(text 26)" ]; then
        error "\n Argo $(text 26) "
      elif [ "${STATUS[1]}" = "$(text 28)" ]; then
        cmd_systemctl disable argo
        cmd_systemctl status argo &>/dev/null && error " Argo $(text 27) $(text 38) " || info "\n Argo $(text 27) $(text 37)"
      elif [ "${STATUS[1]}" = "$(text 27)" ]; then
        cmd_systemctl enable argo
        sleep 2
        cmd_systemctl status argo &>/dev/null && info "\n Argo $(text 28) $(text 37)" || error "\n Argo $(text 28) $(text 38) "
        grep -qs '\--url' ${ARGO_DAEMON_FILE} && fetch_quicktunnel_domain && export_list
      fi
      exit 0
      ;;
    -T )
      change_argo; exit 0
      ;;
    -D )
      change_config; exit 0
      ;;
    -U )
      check_install; uninstall; exit 0
      ;;
    -N )
      [ ! -s ${WORK_DIR}/list ] && error " Sing-box $(text 26) "; export_list; exit 0
      ;;
    -V )
      check_system_info; check_arch; version; exit 0
      ;;
    -B )
      bash <(wget --no-check-certificate -qO- ${GH_PROXY}https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh); exit
      ;;
    -R )
      change_protocols; exit 0
      ;;
    --LANGUAGE )
      ((z++)); [[ "${ALL_PARAMETER[z]^^}" =~ ^C ]] && LANGUAGE=C || LANGUAGE=E
      ;;
    --CHOOSE_PROTOCOLS )
      ((z++)); CHOOSE_PROTOCOLS=${ALL_PARAMETER[z]}
      ;;
    --START_PORT )
      ((z++)); START_PORT=${ALL_PARAMETER[z]}
      ;;
    --PORT_NGINX )
      ((z++)); PORT_NGINX=${ALL_PARAMETER[z]}
      ;;
    --SERVER_IP )
      ((z++)); SERVER_IP=${ALL_PARAMETER[z]}
      ;;
    --VMESS_HOST_DOMAIN )
      ((z++)); VMESS_HOST_DOMAIN=${ALL_PARAMETER[z]}
      ;;
    --VLESS_HOST_DOMAIN )
      ((z++)); VLESS_HOST_DOMAIN=${ALL_PARAMETER[z]}
      ;;
    --CDN )
      ((z++)); CDN=${ALL_PARAMETER[z]}
      ;;
    --UUID_CONFIRM )
      ((z++)); UUID_CONFIRM=${ALL_PARAMETER[z]}
      ;;
    --NODE_NAME_CONFIRM )
      ((z++))
      for ((z=$z; z<${#ALL_PARAMETER[@]}; z++)); do
        [[ ! "${ALL_PARAMETER[z]}" =~ ^- ]] && NODE_NAME_ARRAY+=(${ALL_PARAMETER[z]}) || break
      done
      NODE_NAME_CONFIRM=${NODE_NAME_ARRAY[@]}
      ;;
    --SUBSCRIBE )
      ((z++)); [ "${ALL_PARAMETER[z]}" = 'true' ] && IS_SUB=is_sub
      ;;
    --ARGO )
      ((z++)); [ "${ALL_PARAMETER[z]}" = 'true' ] && IS_ARGO=is_argo
      ;;
    --ARGO_DOMAIN )
      ((z++)); ARGO_DOMAIN=${ALL_PARAMETER[z]}
      ;;
    --ARGO_AUTH )
      ((z++)); ARGO_AUTH=${ALL_PARAMETER[z]}
      ;;
    --PORT_HOPPING_RANGE )
      ((z++)); [[ "${ALL_PARAMETER[z]//:/-}" =~ ^[1-6][0-9]{4}-[1-6][0-9]{4}$ ]] && PORT_HOPPING_RANGE=${ALL_PARAMETER[z]//-/:} && PORT_HOPPING_START=${ALL_PARAMETER[z]%:*} && PORT_HOPPING_END=${ALL_PARAMETER[z]#*:}
      [[ "$PORT_HOPPING_START" < "$PORT_HOPPING_END" && "$PORT_HOPPING_START" -ge "$MIN_HOPPING_PORT" && "$PORT_HOPPING_END" -le "$MAX_HOPPING_PORT" ]] && IS_HOPPING=is_hopping
      ;;
    --REALITY_PRIVATE )
      ((z++)); REALITY_PRIVATE=${ALL_PARAMETER[z]}
      ;;
  esac
done

check_arch
check_dependencies
check_system_ip
check_install
if [ "$NONINTERACTIVE_INSTALL" = 'noninteractive_install' ]; then
  # preset default value
  IS_SUB=${IS_SUB:-'no_sub'}
  IS_ARGO=${IS_ARGO:-'no_argo'}
  IS_HOPPING=${IS_HOPPING:-'no_hopping'}

  install_sing-box
  export_list install
  create_shortcut
elif [ "$IS_FAST_INSTALL" = 'is_fast_install' ]; then
  # preset default value
  CHOOSE_PROTOCOLS=${CHOOSE_PROTOCOLS:-'a'}
  START_PORT=${START_PORT:-"$START_PORT_DEFAULT"}
  CDN=${CDN:-"${CDN_DOMAIN[0]}"}
  IS_SUB='is_sub'
  IS_ARGO='is_argo'
  [[ "$PORT_HOPPING_RANGE" =~ ^[0-9]+:[0-9]+$ ]] && IS_HOPPING='is_hopping' || IS_HOPPING='no_hopping'

  install_sing-box
  export_list install
  create_shortcut
else
  menu_setting
  menu
fi
