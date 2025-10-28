Content-Type: multipart/mixed; boundary="12345"
MIME-Version: 1.0

--12345
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

config system sdn-connector
edit AzureSDN
set type azure
next
end
config router static
 edit 1
 set gateway ${var_sn1_gateway}
 set device port1
 next
 edit 2
 set dst ${var_vnet_address_prefix}
 set gateway ${var_sn2_gateway}
 set device port2
 next
 edit 3
set dst ${var_azure_metadata_ip} 255.255.255.255
set device port2
 set gateway ${var_sn2_gateway}
 next
edit 4
set dst ${var_azure_metadata_ip} 255.255.255.255
set device port1
 set gateway ${var_sn1_gateway}
 next
 end
 config system probe-response
 set http-probe-value OK
 set mode http-probe
 end
 config system interface
 edit port1
 set mode static
 set ip ${var_port1_ip} ${var_port1_netmask}
 set description external
 set alias ${var_subnet1_name}
 set allowaccess probe-response
 next
 edit port2
 set mode static
 set ip ${var_port2_ip} ${var_port2_netmask}
 set description internal
 set alias ${var_subnet2_name}
 set allowaccess probe-response
 next
 edit port3
 set mode static
 set ip ${var_port3_ip} ${var_port3_netmask}
 set description hasyncport
 set alias ${var_subnet3_name}
 next
 edit port4
 set mode static
 set ip ${var_port4_ip} ${var_port4_netmask}
 set description management
 set alias ${var_subnet4_name}
 set allowaccess ping https ssh ftm
 next
 end
 config system ha
 set group-name AzureHA
 set mode a-p
 set hbdev port3 100
 set session-pickup enable
 set session-pickup-connectionless enable
 set ha-mgmt-status enable
 config ha-mgmt-interfaces
 edit 1
 set interface port4
 set gateway ${var_sn4_gateway}
 next
 end
 set override disable
 set priority ${var_ha_priority}
 set unicast-hb enable
 set unicast-hb-peerip ${var_ha_peer_ip}
 set password ${var_admin_password}
 end
%{ if var_deploy_dvwa ~}
config firewall vip
edit "workload-SSH-VIP"
set extip ${var_fgt_external_ipaddress}
set mappedip "${var_dvwa_vm_ip}"
set extintf "any"
set portforward enable
set extport 2222
set mappedport 22
next
edit "workload-HTTP-DVWA-VIP"
set extip ${var_fgt_external_ipaddress}
set mappedip "${var_dvwa_vm_ip}"
set extintf "any"
set portforward enable
set extport 8001
set mappedport 1000
next
edit "workload-HTTP-BANK-VIP"
set extip ${var_fgt_external_ipaddress}
set mappedip "${var_dvwa_vm_ip}"
set extintf "any"
set portforward enable
set extport 8002
set mappedport 2000
next
edit "workload-HTTP-JUICE-VIP"
set extip ${var_fgt_external_ipaddress}
set mappedip "${var_dvwa_vm_ip}"
set extintf "any"
set portforward enable
set extport 8003
set mappedport 3000
next
edit "workload-HTTP-PETSTORE-VIP"
set extip ${var_fgt_external_ipaddress}
set mappedip "${var_dvwa_vm_ip}"
set extintf "any"
set portforward enable
set extport 8004
set mappedport 4000
next
end
config firewall policy
    edit 1
        set name "workload-SSH-Inbound_Access"
        set srcintf "port1"
        set dstintf "port2"
        set action accept
        set srcaddr "all"
        set dstaddr "workload-SSH-VIP"
        set schedule "always"
        set service "SSH"
        set utm-status enable
        set inspection-mode proxy
        set ssl-ssh-profile "certificate-inspection"
        set av-profile "default"
        set webfilter-profile "default"
        set dnsfilter-profile "default"
        set ips-sensor "default"
        set application-list "default"
    next
    edit 2
        set name "workload-HTTP-DVWA-Inbound_Access"
        set srcintf "port1"
        set dstintf "port2"
        set action accept
        set srcaddr "all"
        set dstaddr "workload-HTTP-DVWA-VIP"
        set schedule "always"
        set service "ALL"
        set utm-status enable
        set inspection-mode proxy
        set ssl-ssh-profile "certificate-inspection"
        set av-profile "default"
        set webfilter-profile "default"
        set dnsfilter-profile "default"
        set ips-sensor "default"
        set application-list "default"
    next
    edit 3
        set name "workload-HTTP-BANK-Inbound_Access"
        set srcintf "port1"
        set dstintf "port2"
        set action accept
        set srcaddr "all"
        set dstaddr "workload-HTTP-BANK-VIP"
        set schedule "always"
        set service "ALL"
        set utm-status enable
        set inspection-mode proxy
        set ssl-ssh-profile "certificate-inspection"
        set av-profile "default"
        set webfilter-profile "default"
        set dnsfilter-profile "default"
        set ips-sensor "default"
        set application-list "default"
    next
    edit 4
        set name "workload-HTTP-JUICE-Inbound_Access"
        set srcintf "port1"
        set dstintf "port2"
        set action accept
        set srcaddr "all"
        set dstaddr "workload-HTTP-JUICE-VIP"
        set schedule "always"
        set service "ALL"
        set utm-status enable
        set inspection-mode proxy
        set ssl-ssh-profile "certificate-inspection"
        set av-profile "default"
        set webfilter-profile "default"
        set dnsfilter-profile "default"
        set ips-sensor "default"
        set application-list "default"
    next
    edit 5
        set name "workload-HTTP-PETSTORE-Inbound_Access"
        set srcintf "port1"
        set dstintf "port2"
        set action accept
        set srcaddr "all"
        set dstaddr "workload-HTTP-PETSTORE-VIP"
        set schedule "always"
        set service "ALL"
        set utm-status enable
        set inspection-mode proxy
        set ssl-ssh-profile "certificate-inspection"
        set av-profile "default"
        set webfilter-profile "default"
        set dnsfilter-profile "default"
        set ips-sensor "default"
        set application-list "default"
    next
    edit 6
        set name "Outbound_Access"
        set srcintf "port2"
        set dstintf "port1"
        set action accept
        set srcaddr "all"
        set dstaddr "all"
        set schedule "always"
        set service "ALL"
        set nat enable
    next
end
%{ else ~}
config firewall policy
    edit 1
        set name "Outbound_Access"
        set srcintf "port2"
        set dstintf "port1"
        set action accept
        set srcaddr "all"
        set dstaddr "all"
        set schedule "always"
        set service "ALL"
        set nat enable
    next
end
%{ endif ~}
%{ if var_fortimanager ~}
config system central-management
set type fortimanager
 set fmg ${var_fortimanager_ip}
set serial-number ${var_fortimanager_serial}
end
 config system interface
 edit port1
 append allowaccess fgfm
 end
 config system interface
 edit port2
 append allowaccess fgfm
 end
%{ endif ~}
${var_fortigate_additional_config}
--12345
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="license"

%{ if var_fortigate_license_flexvm != "" ~}
LICENSE-TOKEN:${var_fortigate_license_flexvm}
%{ endif ~}
%{ if var_fortigate_license_byol != "" ~}
${var_fortigate_license_byol}
%{ endif ~}

--12345--
