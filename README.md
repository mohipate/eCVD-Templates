
# eCVD-Templates

This repository contains eCVD templates for Cisco IoT Operations Dashboard (IoT OD). These templates are based on user feedback and testing performed by the Cisco Validated Design (CVD) team, and are meant to used with Cisco IoT OD.

# How it works

IoT OC will present the user with a graphical configuration template that is build based on `userPropertyTypes.xml`. Based on user input and preference, a data model is fed to the appropriate template that will generate an IOS configuration file.

![flow.png](images/flow.png)

# UPT

Written in XML with JSON payload. Make sure to validate full syntax is correct before moving to production with https://github.com/etychon/iotoc-userPropertyTypes-validator
The UPT is part of the core product and cannot be changed by the user. It is provided here under the `UPT` directory as a reference for all variable names and types.

# Templates

IoT OD templates are written using Apache [FreeMarker](https://freemarker.apache.org/). As you write your own template and include user options (such as Cellular APN), IoT OD user interface will provide a graphical view to enter data fields. IoT OD will only present variables that are part of the template so that you can make very simple, or very complicated templates.

The templates provided here can be used as they are, or as a basis for your own template.

The ultimate output of a template is a Cisco IOS configuration that will be pushed to the gateway.

# Templates provided her

This repo contains templates for IR829, IR1101, and IR829's access point (AP803). They are two versions of the templates: Basic (B) and Advanced (A).

The table below lists what's supported by each template type, either `A` for Advanced, `B` for Basic, and `A+B` for both:

| Feature                                         | IR829 | IR1101 |
|-------------------------------------------------|:----------:|:------:|
| Interface routing priority                            | A+B | A+B |
| LTE Support                                           | A+B | A+B |
| Second LTE Support                                    | A   |  A  |
| Cellular custom APN configuration                     | A+B | A+B |
| Enable/Disable Subtended ports                        | A+B| A+B |
| Subtended network IP configuration                    | A+B | A+B |
| Subtended network DHCP exclusion range                | A+B | A+B |
| Configurable ICMP destination for IP SLA reachability | A | A |
| Workgroup Bridge (Wifi client)                        | A | - |
| Wifi AP with pre-shared key                           | A | - |
| Cisco Umbrella Token                                  | - | A |
| Cisco Umbrella Exclusion RegExp                       | - | A |
| Netflow                                               | A | A |
| Custom Firewall Rules                                 | A | A |
| VPN Headend primary and backup                        | A+B | A+B |
| VPN Interface Source Selection                        | A+B | A+B |
| NTP                                                   | A+B | A+B |
| QoS for Cellular upstream                             | A | A |
| Port Forwarding rules                                 | A+B | A+B |
| Additional static routes                              | A | A |
| Local user configuration                              | A+B | A+B |
| Interface failover using IP SLAs                      | A+B | A+B |

Note:
* IR829s have two templates: one for the gateway, one for the Access Point.
* The default upstream ethernet port is Gig0/0/0 for IR1101 and Gig1 for IR829.
