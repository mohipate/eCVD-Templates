<#-- ---- Begin eCVD template for IR1101 ----- -->
<#-- ---- Version 1.71 ------------------------ -->
<#-- ----------------------------------------- -->

<#compress>

<#-- extract PID and SN from EID - ie. IR1101-K9+FCW23510HKN -->
<#assign sublist 		= "${far.eid}"?split("+")[0..1]>
<#assign pid = sublist[0]>
<#assign model = pid[0..5]>
<#assign sn = sublist[1]>

<#if pid != "IR1101-K9" && pid != "IR1101-A-K9">
  ${provisioningFailed("This template does not support ${pid}")}
</#if>

<#-- PLATFORM SPECIFIC VARIABLES -->
<#assign ether_if = "GigabitEthernet 0/0/0">
<#assign cell_if1 = "Cellular 0/1/0">
<#assign cell_if2 = "Cellular 0/3/0">
<#assign wgb_if = "Vlan 50">

<#-- TEMPLATE CONSTANTS -->
<#assign umbrella_dns1_ip = "208.67.222.222">
<#assign umbrella_dns2_ip = "208.67.220.220">

<#-- VARIABLES INITIALIZATION -->
<#assign highestPriorityIfName = 1>
<#assign priorityIfNameTable = []>
<#assign isTunnelEnabledTable = []>
<#assign isCellIntTable = []>
<#assign EthernetPortPriority = 200>
<#assign WgbIntPriority = 200>
<#assign Cell2PortPriority = 200>
<#assign Cell1PortPriority = 200>


<#-- IP SLA destination IP addresses -->

<#assign ipslaDestIPaddress = [far.IcmpReachableIPaddress1!"4.2.2.1",
    far.IcmpReachableIPaddress2!"4.2.2.2",
    far.IcmpReachableIPaddress3!"9.9.9.10",
    far.IcmpReachableIPaddress4!"9.9.9.11"]>

<#-- ADDED 1 LINES BELOW FOR ADVANCED -->

<#-- Interface Menu - which Ethernet interfaces are enabled? -->
<#assign FastEthernet1_enabled = far.fastEthernet1!"true">
<#assign FastEthernet2_enabled = far.fastEthernet2!"true">
<#assign FastEthernet3_enabled = far.fastEthernet3!"true">
<#assign FastEthernet4_enabled = far.fastEthernet4!"true">

<#-- WAN Menu -->
<#if section.wan_cellular1?has_content && section.wan_cellular1 == "true">
  <#if far.apn1?has_content>
    <#assign APN1			= "${far.apn1}">
  </#if>
</#if>

<#if section.wan_cellular2?has_content && section.wan_cellular2 == "true">
  <#if far.apn2?has_content>
    <#assign APN2			= "${far.apn2}">
  </#if>
</#if>

<#-- LAN Menu -->
<#assign lanIP 		= "${far.lanIPAddress}"?split(".")>
<#assign lanNet 	= "${far.lanNetmask}"?split(".")>

<#-- Network Menu -->

<#-- Security Menu -->
<#if !section.security_umbrella?? || section.security_umbrella == "true">
  <#if far.umbrellaToken?has_content>
    <#assign UmbrellaToken = "${far.umbrellaToken}">
  </#if>
</#if>

<#if !section.security_netflow?? || section.security_netflow == "true">
  <#assign isNetFlow = far.isNetFlow!"false">
</#if>

<#-- VPN Settings Menu -->
<#if !section.vpn_primaryheadend?? || section.vpn_primaryheadend == "true">
  <#if far.herIpAddress??>
    <#assign herIpAddress 	= "${far.herIpAddress}">
    <#assign herPsk			    = "${far.herPsk}">
  </#if>
  <#if !section.vpn_backupheadend?? || section.vpn_backupheadend == "true">
    <#assign isBackupHer	= "true">
    <#if far.backupHerIpAddress??>
      <#assign backupHerIpAddress = "${far.backupHerIpAddress}">
      <#assign backupHerPsk	= "${far.backupHerPsk}">
    </#if>
  <#else>
    <#assign isBackupHer = "false">
  </#if>
</#if>

<#-- Device Settings Menu -->
<#if far.localDomainName?has_content>
  <#assign domainName = "${far.localDomainName}">
<#else>
  <#assign domainName = "local">
</#if>

<#-- If no DNS specified, assign Umbrella DNS servers -->
<#assign umbrella_dns1_ip = "208.67.222.222">
<#assign umbrella_dns2_ip = "208.67.220.220">
<#assign dns1 = far.lanDNSIPAddress1!umbrella_dns1_ip>
<#assign dns2 = far.lanDNSIPAddress2!umbrella_dns2_ip>
<#assign DNSIP		= "${dns1} ${dns2}">

<#-- Setting up time zone settings -->
<#if far.clockTZ?has_content>
  <#assign clockTZ = far.clockTZ>
<#else>
  <#assign clockTZ = "gmt">
</#if>

<#if far.ntpIP?has_content>
  <#assign ntpIP = far.ntpIP>
<#else>
  <#assign ntpIP = "time.nist.gov">
</#if>

<#-- Calculate Netmasks -->

<#function ipv4_to_binary ipaddr>
  <#assign bin_ip=[]>
  <#list ipaddr as lann>
    <#assign lan=lann?number>
    <#list 1..100 as y>
      <#if lan < 1 >
        <#if lan == 0>
          <#list 1..8 as s>
            <#assign bin_ip=bin_ip+["0"]>
          </#list>
	      </#if>
        <#if bin_ip?size % 8 != 0>
          <#list 1..8 as s>
	          <#assign bin_ip=bin_ip+["0"]>
	          <#if bin_ip?size % 8 == 0>
	            <#break>
            </#if>
	        </#list>
	      </#if>
        <#break>
      </#if>
      <#assign x=lan%2 st=x?string bin_ip=bin_ip+[st] lan=lan/2>
    </#list>
  </#list>
  <#return (bin_ip)>
</#function>

<#assign  lan_ip=[]  lan_netmask=[]>

<#-- Binary Conversion of LAN IP-->

<#assign lan_ip=ipv4_to_binary(lanIP)>
<#assign ip_bit = lan_ip?reverse>
<#assign lan_netmask=ipv4_to_binary(lanNet)>
<#assign subnet_bit=lan_netmask?reverse>

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
<#assign offset = 0>
<#list TZ as x, y >
	<#if x == clockTZ>
		<#assign offset = y>
		<#break>
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
<#-- #TODO We may need to disable logging console later in production -->
<#-- no logging console -->
!
<#-- ADDED 3 LINES BELOW FOR ADVANCED -->
<#if !section.devicesettings_snmp?? || section.devicesettings_snmp == "true">
  <#if far.communityString?has_content>
    <#list far.communityString as CS>
      <#if CS['snmpCommunity']?has_content>
        snmp-server community ${CS['snmpCommunity']} ${CS['snmpType']}
      </#if>
      <#if far.snmpVersion == "3">
        snmp-server  user ${far.snmpV3User} group1 v3 auth md5 ${far.snmpV3Pass}
        snmp-server  host ${far.snmpHost} version ${far.snmpVersion} auth ${CS['snmpCommunity']}
      <#else>
        snmp-server host ${far.snmpHost} version ${far.snmpVersion} ${CS['snmpCommunity']}
      </#if>
    </#list>
  </#if>
</#if>
!
clock timezone ${clockTZ} ${offset}
ntp server ${ntpIP}
!
<#-- ip name-server ${DNSIP} -->
ip domain name ${domainName}

<#-- Exclude the first 5 IP addresses of the LAN -->
<#assign gwips = far.lanIPAddress?split(".")>
<#assign nwk_suffix = (gwips[3]?number / 32)?int * 32>
<#assign nwk_addr = gwips[0] + "." + gwips[1] + "." + gwips[2] + "." + (nwk_suffix + 5)>
ip dhcp excluded-address ${far.lanIPAddress} ${nwk_addr}
!
!
ip dhcp pool subtended
    network ${lanNtwk} ${far.lanNetmask}
    default-router ${far.lanIPAddress}
    dns-server ${DNSIP}
    lease 0 0 10
!
<#-- PLACEHOLDER AS THIS IS NOT SUPPORTED YET IN UPT -->
<#-- if far..lanIPAddressDHCPexcludeRangeStart?? && far..lanIPAddressDHCPexcludeRangeEnd?? -->
<#-- ip dhcp excluded-address ${far..lanIPAddressDHCPexcludeRangeStart} ${far..lanIPAddressDHCPexcludeRangeEnd} -->
<#-- /#if -->
!
<#if far.Users?has_content>
  <#list far.Users as user >
		<#if user['userName'] == "admin">
		  <#-- "admin" user is already used by IoT OC, ignore -->
		  <#continue>
		</#if>
		username ${user['userName']} privilege ${user['userPriv']} algorithm-type scrypt secret ${user['userPassword']}
  </#list>
</#if>
!
<#-- S2S VPN Configuration -->
!
<#if !section.vpn_primaryheadend?? || section.vpn_primaryheadend == "true">
  <#if herIpAddress?has_content && herPsk?has_content>
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
		  <#if backupHerIpAddress?has_content && backupHerPsk?has_content>
        peer ${backupHerIpAddress}
        address ${backupHerIpAddress}
        identity key-id ${backupHerIpAddress}
        pre-shared-key ${backupHerPsk}
      </#if>
		</#if>
!
  crypto ikev2 profile CVPN_I2PF
    match identity remote key-id ${herIpAddress}
    <#if isBackupHer == "true">
      <#if backupHerIpAddress?has_content>
        match identity remote key-id ${backupHerIpAddress}
	    </#if>
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
</#if>
</#if>

<#-- interface priorities -->

<#list 1..4 as p>
  <#if far.isEthernetEnable?has_content && far.isEthernetEnable == "true"
        && ether_if?? && far.ethernetPriority?has_content
        && far.ethernetPriority == p?string>
    <#assign priorityIfNameTable += [ether_if]>
    <#assign isTunnelEnabledTable += [far.enableTunnelOverEthernet!"false"]>
    <#assign isCellIntTable += ["false"]>
    <#assign EthernetPortPriority = 100+p>
  <#elseif far.isWgbEnable?has_content && far.isWgbEnable == "true"
        && wgb_if?? && far.wgbPriority?has_content
        && far.wgbPriority == p?string>
    <#assign priorityIfNameTable += [wgb_if]>
    <#assign isTunnelEnabledTable += [far.enableTunnelOverWGB!"false"]>
    <#assign isCellIntTable += ["false"]>
    <#assign WgbIntPriority = 100+p>
  <#elseif far.wan_cellular1?has_content && far.wan_cellular1 == "true"
        && cell_if1?? && far.firstCellularIntPriority?has_content
        && far.firstCellularIntPriority == p?string>
    <#assign priorityIfNameTable += [cell_if1]>
    <#assign isTunnelEnabledTable += [far.enableTunnelOverCell1!"false"]>
    <#assign isCellIntTable += ["true"]>
    <#assign Cell1PortPriority = 100+p>
  <#elseif far.wan_cellular2?has_content && far.wan_cellular2 == "true"
        && cell_if2?? && far.secondCellularIntPriority?has_content
        && far.secondCellularIntPriority == p?string>
    <#assign priorityIfNameTable += [cell_if2]>
    <#assign isTunnelEnabledTable += [far.enableTunnelOverCell2!"false"]>
    <#assign Cell2PortPriority = 100+p>
  </#if>
</#list>

<#if priorityIfNameTable?size <=0>
  <#-- No interface in the priority table
       This scenario should never happen -->
  Provisioning failed
<#else>
  <#-- Iterate over interface table list, by configured priority from 1 to 4 -->
  <#list 0 .. (priorityIfNameTable?size-1) as p>
    !
    ! ***** ${priorityIfNameTable[p]} configuration *****
    !
    <#-- Config for Cell interface are slightly different -->
    <#if isCellIntTable[p] == "true">
      track ${p+10} interface ${priorityIfNameTable[p]} line-protocol
      ip route 0.0.0.0 0.0.0.0 ${priorityIfNameTable[p]} ${100+p} track ${p+10}
    <#else>
      ip route 0.0.0.0 0.0.0.0 ${priorityIfNameTable[p]} dhcp ${100+p}
    </#if>
    ip sla ${p+40}
      icmp-echo ${ipslaDestIPaddress[p]} source-interface ${priorityIfNameTable[p]}
      frequency <#if isCellIntTable[p] == "true">50<#else>10</#if>
    !
    ip sla schedule ${p+40} life forever start-time now
    track ${p+40} ip sla ${p+40} reachability
    int ${priorityIfNameTable[p]}
      zone-member security INTERNET
    <#if isTunnelEnabledTable[p] == "true">
      crypto ikev2 client flexvpn Tunnel2
      source ${p+1} ${priorityIfNameTable[p]} track ${p+40}
    </#if>
  </#list>
</#if>

<#-- Umbrella DNS -->
<#if !section.security_umbrella?? || section.security_umbrella == "true">
crypto pki trustpoint umbrella
 revocation-check none
crypto pki certificate chain umbrella
 certificate ca 01FDA3EB6ECA75C888438B724BCFBC91
  30820494 3082037C A0030201 02021001 FDA3EB6E CA75C888 438B724B CFBC9130
  0D06092A 864886F7 0D01010B 05003061 310B3009 06035504 06130255 53311530
  13060355 040A130C 44696769 43657274 20496E63 31193017 06035504 0B131077
  77772E64 69676963 6572742E 636F6D31 20301E06 03550403 13174469 67694365
  72742047 6C6F6261 6C20526F 6F742043 41301E17 0D313330 33303831 32303030
  305A170D 32333033 30383132 30303030 5A304D31 0B300906 03550406 13025553
  31153013 06035504 0A130C44 69676943 65727420 496E6331 27302506 03550403
  131E4469 67694365 72742053 48413220 53656375 72652053 65727665 72204341
  30820122 300D0609 2A864886 F70D0101 01050003 82010F00 3082010A 02820101
  00DCAE58 904DC1C4 30159035 5B6E3C82 15F52C5C BDE3DBFF 7143FA64 2580D4EE
  18A24DF0 66D00A73 6E119836 1764AF37 9DFDFA41 84AFC7AF 8CFE1A73 4DCF3397
  90A29687 53832BB9 A675482D 1D56377B DA31321A D7ACAB06 F4AA5D4B B74746DD
  2A93C390 2E798080 EF13046A 143BB59B 92BEC207 654EFCDA FCFF7AAE DC5C7E55
  310CE839 07A4D7BE 2FD30B6A D2B1DF5F FE577453 3B3580DD AE8E4498 B39F0ED3
  DAE0D7F4 6B29AB44 A74B5884 6D924B81 C3DA738B 12974890 0445751A DD373197
  92E8CD54 0D3BE4C1 3F395E2E B8F35C7E 108E8641 008D4566 47B0A165 CEA0AA29
  094EF397 EBE82EAB 0F72A730 0EFAC7F4 FD1477C3 A45B2857 C2B3F982 FDB74558
  9B020301 0001A382 015A3082 01563012 0603551D 130101FF 04083006 0101FF02
  0100300E 0603551D 0F0101FF 04040302 01863034 06082B06 01050507 01010428
  30263024 06082B06 01050507 30018618 68747470 3A2F2F6F 6373702E 64696769
  63657274 2E636F6D 307B0603 551D1F04 74307230 37A035A0 33863168 7474703A
  2F2F6372 6C332E64 69676963 6572742E 636F6D2F 44696769 43657274 476C6F62
  616C526F 6F744341 2E63726C 3037A035 A0338631 68747470 3A2F2F63 726C342E
  64696769 63657274 2E636F6D 2F446967 69436572 74476C6F 62616C52 6F6F7443
  412E6372 6C303D06 03551D20 04363034 30320604 551D2000 302A3028 06082B06
  01050507 0201161C 68747470 733A2F2F 7777772E 64696769 63657274 2E636F6D
  2F435053 301D0603 551D0E04 1604140F 80611C82 3161D52F 28E78D46 38B42CE1
  C6D9E230 1F060355 1D230418 30168014 03DE5035 56D14CBB 66F0A3E2 1B1BC397
  B23DD155 300D0609 2A864886 F70D0101 0B050003 82010100 233EDF4B D23142A5
  B67E425C 1A44CC69 D168B45D 4BE00421 6C4BE26D CCB1E097 8FA65309 CDAA2A65
  E5394F1E 83A56E5C 98A22426 E6FBA1ED 93C72E02 C64D4ABF B042DF78 DAB3A8F9
  6DFF2185 5336604C 76CEEC38 DCD65180 F0C5D6E5 D44D2764 AB9BC73E 71FB4897
  B8336DC9 1307EE96 A21B1815 F65C4C40 EDB3C2EC FF71C1E3 47FFD4B9 00B43742
  DA20C9EA 6E8AEE14 06AE7DA2 599888A8 1B6F2DF4 F2C9145F 26CF2C8D 7EED37C0
  A9D539B9 82BF190C EA34AF00 2168F8AD 73E2C932 DA38250B 55D39A1D F06886ED
  2E4134EF 7CA5501D BF3AF9D3 C1080CE6 ED1E8A58 25E4B877 AD2D6EF5 52DDB474
  8FAB492E 9D3B9334 281F78CE 94EAC7BD D3C96D1C DE5C32F3
        quit

!
parameter-map type regex dns_bypass
pattern .*\.cisco\..*
!
parameter-map type umbrella global
<#if UmbrellaToken?has_content>
  token ${UmbrellaToken}
</#if>

local-domain dns_bypass
dnscrypt
udp-timeout 5
!
no ip dns server
!
interface Vlan 1
ip nbar protocol-discovery
!
</#if>

<#-- Zone based firewall.  Expands on Bootstrap config -->

  ip access-list extended eCVD-deny-from-outside

<#assign count = 10>
<#if far.firewallIP??>
<#list far.firewallIP as FW>
  <#if FW['fwType']?has_content>
   <#if FW['fwType'] == "deny">
    <#if FW['fwProtocol'] == "ip" || FW['fwProtocol'] == "icmp">
   ${count} deny ${FW['fwProtocol']} ${FW['fwSrcIp']} ${FW['fwSrcMask']} any
    <#else>
   ${count} deny ${FW['fwProtocol']} ${FW['fwSrcIp']} ${FW['fwSrcMask']} eq ${FW['fwPort']} any
    </#if>
   <#assign count += 10>
   </#if>
  </#if>
 </#list>
</#if>

  ip access-list extended eCVD-permit-from-outside

<#assign count = 10>
<#if far.firewallIP??>
<#list far.firewallIP as FW>
  <#if FW['fwType']?has_content>
   <#if FW['fwType'] == "allow">
    <#if FW['fwProtocol'] == "ip" || FW['fwProtocol'] == "icmp">
   ${count} permit ${FW['fwProtocol']} ${FW['fwSrcIp']} ${FW['fwSrcMask']} any
    <#else>
   ${count} permit ${FW['fwProtocol']} ${FW['fwSrcIp']} ${FW['fwSrcMask']} eq ${FW['fwPort']} any
    </#if>
   <#assign count += 10>
   </#if>
  </#if>
 </#list>
</#if>
!
 class-map type inspect match-any eCVD-deny-list
   match access-group name eCVD-deny-from-outside
!
 class-map type inspect match-any eCVD-permit-list
   match access-group name eCVD-permit-from-outside
!
!
  policy-map type inspect INTERNET2Any
    class type inspect eCVD-permit-list
      pass
    class type inspect eCVD-deny-list
      drop
!
int ${ether_if}
  zone-member security INTERNET
  !
<#if !section.wan_cellular1?? || section.wan_cellular1 == "true">
int ${cell_if1}
  zone-member security INTERNET
  !
</#if>
<#if !section.wan_cellular2?? || section.wan_cellular2 == "true">
int ${cell_if2}
  zone-member security INTERNET
  !
  !
</#if>
!

<#-- ---------------------------------------------- -->
<#-- etychon - ok until here on  IR1101-FCW23510HKN -->
<#-- ---------------------------------------------- -->

<#-- ADDED LINES BELOW FOR ADVANCED -->
<#-- QOS config -->

<#if section.network_qos?has_content && section.network_qos == "true">
  <#if far.qosBandwidth?has_content>
    <#assign QOSbw = far.qosBandwidth?number>

    <#if far.qos?has_content>
      class-map match-any CLASS-GOLD
      <#-- traffic class possible values are listed below.  User should be able to place multiple TCs in a class (gold, silver, bronze). -->
      <#list far.qos as QOS>
        <#if QOS['qosType']?has_content>
          <#if QOS['qosPriority'] == "hi">
            match protocol attribute traffic-class ${QOS['qosType']}
          </#if>
        </#if>
      </#list>
!
      class-map match-any CLASS-SILVER
      <#list far.qos as QOS>
        <#if QOS['qosType']?has_content>
          <#if QOS['qosPriority'] == "med">
            match protocol attribute traffic-class ${QOS['qosType']}
          </#if>
        </#if>
      </#list>
!
      class-map match-any CLASS-BRONZE
      <#list far.qos as QOS>
        <#if QOS['qosType']?has_content>
          <#if QOS['qosPriority'] == "low">
            match protocol attribute traffic-class ${QOS['qosType']}
          </#if>
        </#if>
      </#list>
!
      class-map match-any CLASS-SILVER-BRONZE
      <#list far.qos as QOS>
        <#if QOS['qosType']?has_content>
          <#if QOS['qosPriority'] == "med" || QOS['qosPriority'] == "low">
            match protocol attribute traffic-class ${QOS['qosType']}
          </#if>
        </#if>
      </#list>
!
      policy-map PMAP-LEVEL3
        class CLASS-SILVER
        <#-- calculate based on 37.5% of SILVER-BRONZE bandwidth, units of Kbps -->
        <#assign qosbwkb = QOSbw * 0.375>
        bandwidth ${qosbwkb?int?c}
!
        class CLASS-BRONZE
        <#-- calculate based on 62.5% of SILVER-BRONZE bandwidth, units of Kbps -->
        <#assign qosbwkb = QOSbw * 0.625>
          bandwidth ${qosbwkb?int?c}
!
      policy-map PMAP-LEVEL2
        class CLASS-GOLD
        priority 100
        class CLASS-SILVER-BRONZE
        <#-- calculate based on 25% of total upstream throughput, units of Kbps -->
          <#assign qosbwkb = QOSbw * 0.25>
          bandwidth ${qosbwkb?int?c}
          <#-- calculate based on 25% of total upstream throughput units of bits per second-->
          <#assign qbw = QOSbw * 0.25 * 1000>
          shape average ${qbw?int?c}

      service-policy PMAP-LEVEL3
        class class-default
        fair-queue
        random-detect dscp-based
!
      policy-map PMAP-LEVEL1
        class class-default
        <#-- input value from user based on real-world upstream throughput. Units of bits per second -->
        bandwidth ${QOSbw}
        <#assign qbw = QOSbw * 1000>
        shape average ${qbw?int?c}
        service-policy PMAP-LEVEL2
!

      <#if section.wan_cellular1?? && section.wan_cellular1 == "true">
        interface ${cell_if1}
          service-policy output PMAP-LEVEL1
      </#if>

      <#if !section.wan_cellular2?? || section.wan_cellular2 == "true">
        interface ${cell_if2}
          service-policy output PMAP-LEVEL1
      </#if>
    </#if>
  </#if>
</#if>

<#-- ------------------------------------------ -->



<#-- Enable GPS  -->
<#if !section.wan_cellular1?? || section.wan_cellular1 == "true">
!! controller ${cell_if1}
!! 	lte gps mode standalone
!!  lte gps nmea
</#if>
!

interface ${ether_if}
    ip dhcp client route track 30
    ip address dhcp
    no shutdown
    ip nat outside
<#-- ADDED 1 LINES BELOW FOR ADVANCED -->
<#if !section.security_umbrella?? || section.security_umbrella == "true">
     umbrella out
</#if>
!
!
<#if !section.wan_cellular1?? || section.wan_cellular1 == "true">
interface ${cell_if1}
    ip address negotiated
    ip nat outside
    dialer in-band
    dialer idle-timeout 0
    dialer-group 1
    pulse-time 1
<#-- ADDED 1 LINES BELOW FOR ADVANCED -->
<#if !section.security_umbrella?? || section.security_umbrella == "true">
     umbrella out
</#if>
!
</#if>
<#-- ADDED 8 LINES BELOW FOR ADVANCED -->
<#if !section.wan_cellular2?? || section.wan_cellular2 == "true">
interface ${cell_if2}
    ip address negotiated
    ip nat outside
    dialer in-band
    dialer idle-timeout 0
    dialer-group 1
    pulse-time 1
<#if !section.security_umbrella?? || section.security_umbrella == "true">
    umbrella out
</#if>
!
</#if>

interface Vlan1
    ip address ${far.lanIPAddress} ${far.lanNetmask}
    ip nbar protocol-discovery
    ip nat inside
    ip verify unicast source reachable-via rx
<#-- ADDED 1 LINES BELOW FOR ADVANCED -->
<#if !section.security_umbrella?? || section.security_umbrella == "true">
     umbrella in my_tag
</#if>
!
!

<#-- enabling/disabling of ethernet ports -->

interface FastEthernet0/0/1
<#if FastEthernet1_enabled != "true">
    shutdown
<#else>
	no shutdown
</#if>
!
interface FastEthernet0/0/2
<#if FastEthernet2_enabled != "true">
    shutdown
<#else>
	no shutdown
</#if>
!
interface FastEthernet0/0/3
<#if FastEthernet3_enabled != "true">
    shutdown
<#else>
	no shutdown
</#if>
!
interface FastEthernet0/0/4
<#if FastEthernet4_enabled != "true">
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

<#-- Enable NAT and routing -->
ip access-list extended NAT_ACL
     permit ip ${lanNtwk} ${lanWild} any
     permit ip ${nwk_addr} 0.0.0.31 any
!
<#if !section.vpn_primaryheadend?? || section.vpn_primaryheadend == "true">
route-map RM_Tu2 permit 10
     match ip address NAT_ACL
     match interface Tunnel2
</#if>
!
dialer-list 1 protocol ip permit
!
!
<#if !section.wan_cellular1?? || section.wan_cellular1 == "true">
route-map RM_WAN_ACL permit 10
    match ip address NAT_ACL
    match interface ${cell_if1}
!
</#if>
route-map RM_WAN_ACL2 permit 10
    match ip address NAT_ACL
    match interface ${ether_if}
!
<#-- ADDED 3 LINES BELOW FOR ADVANCED -->
<#if !section.wan_cellular2?? || section.wan_cellular2 == "true">
route-map RM_WAN_ACL3 permit 10
    match ip address NAT_ACL
    match interface ${cell_if2}
</#if>
!

ip forward-protocol nd
!
<#if !section.wan_cellular1?? || section.wan_cellular1 == "true">
ip nat inside source route-map RM_WAN_ACL interface ${cell_if1} overload
</#if>
ip nat inside source route-map RM_WAN_ACL2 interface ${ether_if} overload
<#-- ADDED 1 LINES BELOW FOR ADVANCED -->
<#if !section.wan_cellular2?? || section.wan_cellular2 == "true">
ip nat inside source route-map RM_WAN_ACL3 interface ${cell_if2} overload
</#if>

<#-- Use default i/f to set PAT -->

<#if far.portForwarding??>
<#list far.portForwarding as PAT>
  <#if PAT['protocol']?has_content>
  <#if EthernetPortPriority == 101>
        ip nat inside source static ${PAT['protocol']} ${PAT['privateIP']} ${PAT['localPort']} interface ${ether_if} ${PAT['publicPort']}
  <#else>
     <#if !section.wan_cellular1?? || section.wan_cellular1 == "true">
      ip nat inside source static ${PAT['protocol']} ${PAT['privateIP']} ${PAT['localPort']} interface ${cell_if1} ${PAT['publicPort']}
     </#if>
  </#if>
  </#if>
</#list>
</#if>

<#-- remove this route from the bootstrap config to allow failover -->
<#if !section.wan_cellular1?? || section.wan_cellular1 == "true">
no ip route 0.0.0.0 0.0.0.0 ${cell_if1} 100
</#if>

<#-- add IPSLA tracking to allow i/f failover -->
ip route 0.0.0.0 0.0.0.0 ${ether_if} dhcp ${EthernetPortPriority}
<#if !section.wan_cellular1?? || section.wan_cellular1 == "true">
ip route 0.0.0.0 0.0.0.0 ${cell_if1} ${Cell1PortPriority} track 7
</#if>
<#-- ADDED 1 LINES BELOW FOR ADVANCED -->
<#if !section.wan_cellular2?? || section.wan_cellular2 == "true">
ip route 0.0.0.0 0.0.0.0 ${cell_if2} 103 track 8
</#if>

ip route ${umbrella_dns1_ip} 255.255.255.255 dhcp
<#if !section.wan_cellular1?? || section.wan_cellular1 == "true">
ip route ${umbrella_dns2_ip} 255.255.255.255 ${cell_if1} track 7
</#if>
<#-- ADDED 1 LINES BELOW FOR ADVANCED -->
<#if !section.wan_cellular2?? || section.wan_cellular2 == "true">
ip route 9.9.9.9 255.255.255.255 ${cell_if2} track 8
</#if>


<#-- ip route ${umbrella_dns2_ip} 255.255.255.255 Null0 3 -->
<#-- ip route ${umbrella_dns1_ip} 255.255.255.255 Null0 3 -->
<#-- ip route 8.8.8.8 255.255.255.255 Null0 3 tag 786 -->

<#if !section.wan_cellular1?? || section.wan_cellular1 == "true">
ip route 1.1.1.1 255.255.255.255 ${cell_if1} 99 track 10
ip route 8.8.8.8 255.255.255.255 ${cell_if1} tag 786
</#if>

<#if !section.vpn_primaryheadend?? || section.vpn_primaryheadend == "true">
<#if herIpAddress??>
ip route ${herIpAddress}  255.255.255.255 ${ether_if} dhcp
<#if backupHerIpAddress?has_content>
ip route ${backupHerIpAddress} 255.255.255.255 ${ether_if} dhcp
</#if>
</#if>
</#if>

<#-- ADDED 3 LINES BELOW FOR ADVANCED -->
<#-- User defined static routes with either next hop or egress interface -->
<#if far.staticRoute??>
<#list far.staticRoute as SR>
  <#if SR['destNetwork']?has_content>
      ip route ${SR['destNetwork']} ${SR['destNetMask']} ${SR['nextInterface']}
  </#if>
</#list>
</#if>
!
<#if !section.vpn_primaryheadend?? || section.vpn_primaryheadend == "true">
ip nat inside source route-map RM_Tu2 interface Tunnel2 overload
</#if>
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
<#if primaryHerIpAddress?has_content>
 permit esp host ${herIpAddress} any
</#if>
<#if backupHerIpAddress?has_content>
  permit esp host ${backupHerIpAddress} any
</#if>
!

<#-- ADDED 11 LINES BELOW FOR ADVANCED -->
<#-- OPTIONALLY remove NAT overload config and config and setup routing over FlexVPN S2SVPN -->
<#if !section.vpn_primaryheadend?? || section.vpn_primaryheadend == "true">
no ip nat inside source route-map RM_Tu2 interface Tunnel2 overload
no route-map RM_Tu2 permit 10

interface Tunnel2
 no ip nat outside
!
</#if>

ip access-list standard CLOUD
  permit ${lanNtwk} ${lanWild}

<#if !section.vpn_primaryheadend?? || section.vpn_primaryheadend == "true">
crypto ikev2 authorization policy CVPN
  route set access-list CLOUD
!
</#if>

<#-- ADDED LINES BELOW FOR ADVANCED -->
<#-- Reverse telnet to serial port at TCP port 2050 -->

interface Async0/2/0
  no ip address
  encapsulation relay-line
!
line 0/2/0
  transport input telnet
  transport output none
  databits 8
  parity none
  stopbits 1
  speed 9600

line vty 0 4
    exec-timeout 5 0
    length 0
    transport input ssh

!
<#-- ADDED LINES BELOW FOR ADVANCED -->
<#-- Netflow -->

<#if !section.security_netflow?? || section.security_netflow == "true">
<#if far.netflowCollectorIP??>
 flow record defaultStealthWatch
  match ipv4 protocol
  match ipv4 source address
  match ipv4 destination address
  match transport source-port
  match transport destination-port
  match interface input
  match ipv4 tos
  collect interface output
  collect counter bytes long
  collect counter packets
  collect timestamp sys-uptime first
  collect timestamp sys-uptime last

flow exporter export_Gi0_0_0_-63055531
 destination ${far.netflowCollectorIP}
 source Loopback 1
 transport udp 2055
 template data timeout 60

flow monitor dsw_Gi0_0_0_-63055531
 exporter export_Gi0_0_0_-63055531
 cache timeout active 60
 record defaultStealthWatch
<#-- add logic to use other WAN interfaces -->
interface ${ether_if}
 ip flow monitor dsw_Gi0_0_0_-63055531 input
!
!
</#if>
</#if>

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
<#-- ADDED 5 LINES BELOW FOR ADVANCED -->
event manager applet Cell2-to-eth-failover
 event track 41 state any
 action 0.1 syslog msg "Cell0/3/0 connectivity change. Clearing NAT translations."
 action 0.2 cli command "enable"
 action 1.0 cli command "clear ip nat translation *"

<#-- Set APN -->

<#if APN1?has_content>
event manager applet change_apn
event timer countdown time 10
action 5 syslog msg "Changing APN Profile"
action 10 cli command "enable"
action 15 cli command "${cell_if1} lte profile create 1 ${APN1}" pattern "confirm"
action 20 cli command "y"
</#if>
!
<#-- ADDED 5 LINES BELOW FOR ADVANCED -->
<#if APN2?has_content>
event manager applet change_apn2
event timer countdown time 10
action 5 syslog msg "Changing APN Profile for Cellular0/3/0"
action 10 cli command "enable"
action 15 cli command "Cellular 0/3/0 lte profile create 1 ${APN2}" pattern "confirm"
action 20 cli command "y"
</#if>
!

<#-- ------------------------------ -->

event manager applet ListAllParams
<#assign i = 100>
<#list far as key, value>
  <#if value??>
    <#if value?is_string>
      action ${i} cli command "${key} = ${value}"
      <#assign i = i + 1>
    <#elseif value?is_sequence>
        <#assign subi = 0>
      <#list value as val>
        <#list val as subkey, subvalue>
        action ${i} cli command "${key} [${subi}] ${subkey} = ${subvalue}"
        <#assign i = i + 1>
        </#list>
        <#assign subi = subi + 1>
      </#list>
    </#if>
  <#elseif !value??>
      action ${i} cli command "${key} = *null*"
      <#assign i = i + 1>
  </#if>
</#list>

</#compress>

<#-- End eCVD template -->
