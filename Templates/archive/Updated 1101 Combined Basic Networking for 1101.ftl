<#-- Begin eCVD template -->
<#-- Version 1.5         -->

<#-- Default BootStrap Configuration -->

<#assign sublist 		= "${far.eid}"?split("+")[0..1]>
<#assign pid = sublist[0]>
<#assign model = pid[0..4]>
<#assign sn = sublist[1]>

<#assign model = "IR1101">
<#assign ether_if = "GigabitEthernet 0/0/0">
<#assign cell_if = "Cellular 0/1/0">

<#-- Interface Menu -->
<#assign FastEthernet1 = "${far.fastEthernet1}">
<#assign FastEthernet2 = "${far.fastEthernet2}">
<#assign FastEthernet3 = "${far.fastEthernet3}">
<#assign FastEthernet4 = "${far.fastEthernet4}">

<#-- WAN Menu -->
<#if far.apn?has_content>
<#assign APN			= "${far.apn}">
</#if>

<#-- Set default interface -->
<#if far.cell0Priority == "1">
<#assign EthernetPriority = 102>
<#assign Cell0Priority 	= 101>
<#else>
<#assign EthernetPriority = 101>
<#assign Cell0Priority 	= 102>
</#if>


<#-- LAN Menu -->
<#assign lanIP 		= "${far.lanIPAddress}"?split(".")>
<#assign lanNet 	= "${far.lanNetmask}"?split(".")>

<#-- Network Menu -->

<#-- VPN Settings Menu -->
<#assign herIpAddress 	= "${far.herIpAddress}">
<#assign herPsk			= "${far.herPsk}">
<#if far.backupHerIpAddress?has_content>
  <#assign backupHerIpAddress = "${far.backupHerIpAddress}">
  <#if far.backupHerPsk?has_content>
    <#assign backupHerPsk	= "${far.backupHerPsk}">
  <#else>
    <#assign backupHerPsk = "nodefaultPSK">
  </#if>
</#if>

<#-- Device Settings Menu -->
<#if far.localDomainName?has_content>
<#assign domainName = "${far.localDomainName}">
<#else>
<#assign domainName = "local">
</#if>
<#-- Assign Umbrella DNS servers for additional Security -->
<#assign DNSIP		= "208.67.222.222 208.67.220.220">

<#if far.clockTZ?has_content>
<#assign clockTZ 	= "${far.clockTZ}">
<#else>
<#assign clockTZ	= "edt">
</#if>
<#-- assign clockDST	= "${far.clockDST}"--> 
<#if far.ntpIP?has_content>
<#assign ntpIP 		= "${far.ntpIP}">
<#else>
<#assign ntpIP		= "time.nist.gov">
</#if>

<#-- Calculate Netmasks -->

<#assign  lan_ip=[]  lan_netmask=[]>

<#-- Binary Conversion of LAN IP-->

<#list lanIP as lann> 
<#assign lan=lann?number>
<#list 1..100 as y>
<#if lan < 1> 
<#if lan == 0>
<#list 1..8 as s> <#assign lan_ip=lan_ip+["0"]> </#list> </#if>
<#if lan_ip?size % 8 != 0> <#list 1..8 as s> <#assign lan_ip=lan_ip+["0"]> <#if lan_ip?size % 8 == 0> <#break> </#if> </#list> </#if>
<#assign ip_bit = lan_ip?reverse> <#break> </#if>

<#assign x=lan%2 st=x?string lan_ip=lan_ip+[st] lan=lan/2> </#list></#list>

<#-- Binary Conversion of NetMask-->

<#list lanNet as lann> 
<#assign lan=lann?number>
<#list 1..100 as y>
<#if lan < 1 >
<#if lan == 0>
<#list 1..8 as s> <#assign lan_netmask=lan_netmask+["0"]> </#list> </#if>
<#if lan_netmask?size % 8 != 0>
<#list 1..8 as s> <#assign lan_netmask=lan_netmask+["0"]> <#if lan_netmask?size % 8 == 0> <#break>
</#if> </#list> </#if>
<#assign subnet_bit= lan_netmask?reverse> <#break> </#if>

<#assign x=lan%2 st=x?string lan_netmask=lan_netmask+[st] lan=lan/2> </#list> </#list>

<#-- Logical AND operation between IP and NetMask-->

<#assign lan_netID=[]>
<#list ip_bit as rev_index>
<#if rev_index?string == "1" && subnet_bit[rev_index?index] == "1"><#assign lan_netID=lan_netID+["1"]></#if>
<#if rev_index?string == "1" && subnet_bit[rev_index?index] == "0"><#assign lan_netID=lan_netID+["0"]></#if>
<#if rev_index?string == "0" && subnet_bit[rev_index?index] == "1"><#assign lan_netID=lan_netID+["0"]></#if>
<#if rev_index?string == "0" && subnet_bit[rev_index?index] == "0"><#assign lan_netID=lan_netID+["0"]></#if>
</#list>
<#assign netid_bit=lan_netID?reverse>

<#--Binary to Decimal conversion of Logical AND product-->

<#assign netid=[]>
<#list netid_bit?chunk(8) as row> <#assign num=0 pow=1> <#list row as bit> <#assign num=num+pow*bit?number pow=pow*2> </#list>
<#assign netid=netid+[num]>
</#list>

<#--Network Address-->

<#assign lanNtwk = netid?join(".")?string>
<#assign lanWild = "${(255 - (lanNet[0])?number)?abs}.${(255 - (lanNet[1])?number)?abs}.${(255 - (lanNet[2])?number)?abs}.${(255 - (lanNet[3])?number)?abs}">

<#-- Configure timezone offset -->

<#assign TZ = { "anat":"+12", "sbt":"+11", "aest":"+10", "jst":"+9", "cst":"+8", "wib":"+7", "bst":"+6", "uzt":"+5", "gst":"+4", "msk":"+3", "cest":"+2", "bst":"+1", "gmt":"0", "cvt":"-1", "wgst":"-2", "art":"-3", "edt":"-4", "cdt":"-5", "mst":"-6", "pdt":"-7", "akdt":"-8", "hdt":"-9", "hst":"-10", "nut":"-11", "aeo":"-12" }>
<#list TZ as x, y >
	<#if x != clockTZ>
		<#continue>
	<#else>
		<#assign offset = y>
	</#if>
</#list>

<#-- Configure Device Settings -->

service tcp-keepalives-in
service tcp-keepalives-out
service timestamps debug datetime msec
service timestamps log datetime msec
service password-encryption
service call-home
platform qfp utilization monitor load 80
no platform punt-keepalive disable-kernel-core
!
no logging console
!
clock timezone ${clockTZ} ${offset}
ntp server ${ntpIP}
!
ip name-server ${DNSIP}
ip domain name ${domainName}

<#-- Exclude the first 5 IP addresses of the LAN -->
<#assign gwips = far.lanIPAddress?split(".")>
<#assign nwk_suffix = (gwips[3]?number / 32)?int * 32>
<#assign nwk_addr = gwips[0] + "." + gwips[1] + "." + gwips[2] + "." + (nwk_suffix + 5)>
ip dhcp excluded-address ${far.lanIPAddress} ${nwk_addr}
!

ip dhcp pool subtended
    network ${lanNtwk} ${far.lanNetmask}
    default-router ${far.lanIPAddress} 
    dns-server ${DNSIP}
    lease 0 0 10
!
!
<#list far.Users as user >
		username ${user['userName']} privilege ${user['userPriv']} algorithm-type scrypt secret ${user['userPassword']}
</#list> 
!
<#-- S2S VPN Configuration -->   
!
<#if !section.vpn_primaryheadend?? || section.vpn_primaryheadend == "true">

crypto ikev2 authorization policy CVPN 
 	route set interface
 	route accept any distance 70
!
crypto ikev2 keyring Flex_key
!
 peer ${herIpAddress}   
  address ${herIpAddress} 
  identity key-id ${herIpAddress}
  pre-shared-key ${herPsk}
!
<#if !section.vpn_backupheadend?? || section.vpn_backupheadend == "true">
  peer ${backupHerIpAddress}   
  address ${backupHerIpAddress}
  identity key-id ${backupHerIpAddress}
  pre-shared-key ${backupHerPsk}
!
</#if>
!
!
crypto ikev2 profile CVPN_I2PF
 match identity remote key-id ${herIpAddress} 
<#if !section.vpn_backupheadend?? || section.vpn_backupheadend == "true">
  match identity remote key-id ${backupHerIpAddress}
</#if>
 identity local email ${sn}@iotspdev.io  
 authentication remote pre-share
 authentication local pre-share
 keyring local Flex_key
 dpd 29 2 periodic
 aaa authorization group psk list CVPN CVPN
!
!
crypto ipsec profile CVPN_IPS_PF
 set ikev2-profile CVPN_I2PF
!
!
interface Tunnel2
 ip address negotiated
 ip mtu 1358
 ip nat outside
 ip tcp adjust-mss 1318
 tunnel source dynamic
 tunnel mode ipsec ipv4
 tunnel destination dynamic
 tunnel path-mtu-discovery
 tunnel protection ipsec profile CVPN_IPS_PF
!
!
crypto ikev2 client flexvpn Tunnel2
  peer 1 ${herIpAddress} 
<#if !section.vpn_backupheadend?? || section.vpn_backupheadend == "true">
  peer 2 ${backupHerIpAddress}
</#if>
<#if EthernetPriority == 101>
  source 1 ${ether_if} track 30
  source 2 ${cell_if}  track 40
<#else>
  source 1 ${cell_if} track 40
  source 2 ${ether_if}  track 30
</#if>  
  client connect Tunnel2
!
!
</#if>
<#-- interface priorities -->

ip sla 30
 icmp-echo 208.67.222.222 source-interface ${ether_if}
 frequency 10
!
ip sla schedule 30 life forever start-time now

ip sla 40
 icmp-echo 208.67.220.220 source-interface ${cell_if}
 frequency 50
!
ip sla schedule 40 life forever start-time now

track 5 interface ${ether_if} line-protocol
!
track 7 interface ${cell_if} line-protocol
!
track 30 ip sla 30 reachability
!
track 40 ip sla 40 reachability
!

<#-- Enable GPS and Gyroscope -->
controller ${cell_if}
	lte gps mode standalone
  	lte gps nmea
!

interface ${ether_if}
    ip dhcp client route track 30
    ip address dhcp
    no shutdown
    ip nat outside
!
!
interface ${cell_if}
    ip address negotiated
    ip nat outside
    dialer in-band
    dialer idle-timeout 0
    dialer-group 1
    pulse-time 1
!
!
interface Vlan1
    ip address ${far.lanIPAddress} ${far.lanNetmask}
    ip nbar protocol-discovery
    ip nat inside
    ip verify unicast source reachable-via rx
!
!
   
<#-- enabling/disabling of ethernet ports -->

interface FastEthernet0/0/1
<#if FastEthernet1 != "true">
    shutdown
<#else>
	no shutdown
</#if>
!
interface FastEthernet0/0/2
<#if FastEthernet2 != "true">
    shutdown
<#else>
	no shutdown
</#if>   
!
interface FastEthernet0/0/3
<#if FastEthernet3 != "true">
    shutdown
<#else>
	no shutdown
</#if>    
!
interface FastEthernet0/0/4
<#if FastEthernet4 != "true">
    shutdown
<#else>
	no shutdown
</#if>

interface Async0/2/0
    no ip address
    encapsulation scada
!
   
<#-- Enable IOx -->
iox
   
<#-- Configure NAT and routing -->

ip forward-protocol nd
!
ip nat inside source route-map RM_WAN_ACL interface ${cell_if} overload
ip nat inside source route-map RM_WAN_ACL2 interface ${ether_if} overload
   
<#-- Use default i/f to set PAT -->

<#list far.portForwarding as PAT>
  <#if PAT['protocol']?has_content>
  	<#if EthernetPriority == 101>
  			ip nat inside source static ${PAT['protocol']} ${PAT['privateIP']} ${PAT['localPort']} interface ${ether_if} ${PAT['publicPort']}
	<#else>
			ip nat inside source static ${PAT['protocol']} ${PAT['privateIP']} ${PAT['localPort']} interface ${cell_if} ${PAT['publicPort']}
	</#if>
  </#if>
</#list>

<#-- remove this route from the bootstrap config to allow failover -->
no ip route 0.0.0.0 0.0.0.0 ${cell_if} 100
   
<#-- add IPSLA tracking to allow i/f failover -->
ip route 0.0.0.0 0.0.0.0 ${ether_if} dhcp ${EthernetPriority}
ip route 0.0.0.0 0.0.0.0 ${cell_if} ${Cell0Priority} track 7

ip route 208.67.222.222 255.255.255.255 dhcp
ip route 208.67.220.220 255.255.255.255 ${cell_if} track 7
ip route 208.67.220.220 255.255.255.255 Null0 3
ip route 208.67.222.222 255.255.255.255 Null0 3

<#if !section.vpn_primaryheadend?? || section.vpn_primaryheadend == "true">
ip route ${herIpAddress}  255.255.255.255 ${ether_if} dhcp   
<#if backupHerIpAddress?has_content>
ip route ${backupHerIpAddress} 255.255.255.255 ${ether_if} dhcp
</#if>
</#if>
!
ip nat inside source route-map RM_Tu2 interface Tunnel2 overload
!
ip ssh rsa keypair-name SSHKEY
ip ssh version 2
ip scp server enable
!
ip access-list extended filter-internet
 permit icmp any any echo
 permit icmp any any echo-reply
 permit icmp any any unreachable
 permit icmp any any packet-too-big
 permit icmp any any ttl-exceeded
 permit udp any eq bootps host 255.255.255.255 eq bootpc
 <#if !section.vpn_primaryheadend?? || section.vpn_primaryheadend == "true">
  permit esp host ${herIpAddress} any
<#if backupHerIpAddress?has_content>
  permit esp host ${backupHerIpAddress} any
</#if>
</#if>
!
   
ip access-list extended NAT_ACL
     permit ip ${lanNtwk} ${lanWild} any
     permit ip ${nwk_addr} 0.0.0.31 any
!
route-map RM_Tu2 permit 10
     match ip address NAT_ACL
     match interface Tunnel2
!
dialer-list 1 protocol ip permit
!
!
route-map RM_WAN_ACL permit 10 
    match ip address NAT_ACL
    match interface ${cell_if}
!
route-map RM_WAN_ACL2 permit 10 
    match ip address NAT_ACL
    match interface ${ether_if}
!
line vty 0 4
    exec-timeout 5 0
    length 0
    transport input ssh
!
<#-- Improve WAN failover performance -->
event manager applet Eth-to-cell-failover
 event track 30 state any
 action 0.1 syslog msg "Gig0/0/0 connecitivity change. Clearing NAT translations."
 action 0.2 cli command "enable"
 action 1.0 cli command "clear ip nat translation *"
event manager applet Cell-to-eth-failover
 event track 40 state any
 action 0.1 syslog msg "Cell0/1/0 connectivity change. Clearing NAT translations."
 action 0.2 cli command "enable"
 action 1.0 cli command "clear ip nat translation *"

<#-- Set APN -->

<#if APN?has_content>
event manager applet change_apn
event timer countdown time 10
action 5 syslog msg "Changing APN Profile"
action 10 cli command "enable"
action 15 cli command "${cell_if} lte profile create 1 ${APN}" pattern "confirm"
action 20 cli command "y"
!
!
</#if>
<#-- End eCVD template -->
