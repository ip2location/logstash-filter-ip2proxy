# IP2Proxy Filter Plugin
This is IP2Proxy filter plugin for Logstash that enables Logstash's users to reverse search of IP address to detect VPN servers, open proxies, web proxies, Tor exit nodes, search engine robots, data center ranges, residential proxies, consumer privacy networks, and enterprise private networks using IP2Proxy BIN database. Other information available includes proxy type, country, state, city, ISP, domain name, usage type, AS number, AS name, threats, last seen date and provider names. The library took the proxy IP address from **IP2Proxy BIN Data** file and **IP2Location.io** data.

For the methods to use IP2Proxy filter plugin with Elastic Stack (Elasticsearch, Filebeat, Logstash, and Kibana), please take a look on this [tutorial](https://blog.ip2location.com/knowledge-base/how-to-use-ip2proxy-filter-plugin-with-elastic-stack).

*Note: This plugin works in Logstash 7, 8 and 9*


## Dependencies (IP2PROXY BIN DATA FILE)
This plugin requires IP2Proxy BIN data file to function. You may download the BIN data file at
* IP2Proxy LITE BIN Data (Free): https://lite.ip2location.com
* IP2Proxy Commercial BIN Data (Commercial): https://www.ip2location.com

## Dependencies (IP2LOCATION.IO DATA)
This plugin requires API key to function. You may sign up for a free API key at https://www.ip2location.io/pricing.


## Installation
Install this plugin by the following code:
```
bin/logstash-plugin install logstash-filter-ip2proxy
```


## Config File Example
```
input {
  beats {
    port => "5043"
  }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}"}
  }
  ip2proxy {
    source => "[source][address]"
  }
}

output {
  elasticsearch {
    hosts => [ "localhost:9200" ]
  }
}
```

## Config File Example using IP2Location.io
```
input {
  beats {
    port => "5043"
  }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}"}
  }
  ip2proxy {
    source => "[source][address]"
    lookup_type => "ws"
    api_key => "YOUR_API_KEY"
  }
}

output {
  elasticsearch {
    hosts => [ "localhost:9200" ]
  }
}
```


## IP2Proxy Filter Configuration
|Setting|Input type|Required|
|---|---|---|
|source|string|Yes|
|database|a valid filesystem path|No|
|use_memory_mapped|boolean|No|
|use_cache|boolean|No|
|lookup_type|string|No|
|api_key|string|No|
|hide_unsupported_fields|boolean|No|

* **source** field is a required setting that containing the IP address or hostname to get the ip information.
* **database** field is an optional setting that containing the path to the IP2Proxy BIN database file.
* **use_memory_mapped** field is an optional setting that used to allow user to enable the use of memory mapped file. Default value is false.
* **use_cache** field is an optional setting that used to allow user to enable the use of cache. Default value is true.
* **lookup_type** field is an optional setting that used to allow user to decide the lookup method either using IP2Proxy BIN database file(db) or IP2Location.io data(ws). Default value is db.
* **api_key** field is an optional setting that used to allow user to set the API Key of the IP2Location.io lookup.
* **hide_unsupported_fields** field is an optional setting that used to allow user to hide unsupported fields. Default value is false.


## Sample Output
|Field|Description|
|---|---|
|ip2proxy.as|the autonomous system (AS) name of proxy's IP address or domain name|
|ip2proxy.asn|the autonomous system number (ASN) of proxy's IP address or domain name|
|ip2proxy.city|the city name of the proxy|
|ip2proxy.country_long|the ISO3166-1 country name of the proxy|
|ip2proxy.country_short|the ISO3166-1 country code (two-characters) of the proxy|
|ip2proxy.domain|the domain name of proxy's IP address or domain name|
|ip2proxy.fraud_score|the potential risk score (0 - 99) associated with IP address. A higher IP2Proxy Fraud Score indicates a greater likelihood of fraudulent activity and a lower reputation|
|ip2proxy.is_proxy|Check whether if an IP address was a proxy. Returned value:<ul><li>-1 : errors</li><li>0 : not a proxy</li><li>1 : a proxy</li><li>2 : a data center IP address</li></ul>|
|ip2proxy.isp|the ISP name of the proxy|
|ip2proxy.last_seen|the last seen days ago value of proxy's IP address or domain name|
|ip2proxy.provider|the VPN service provider name if available|
|ip2proxy.proxy_type|the proxy type. Please visit  <a href="https://www.ip2location.com/database/px11-ip-proxytype-country-region-city-isp-domain-usagetype-asn-lastseen-threat-residential-provider" target="_blank">IP2Location</a> for the list of proxy types supported|
|ip2proxy.region|the ISO3166-2 region name of the proxy. Please visit <a href="https://www.ip2location.com/free/iso3166-2" target="_blank">ISO3166-2 Subdivision Code</a> for the information of ISO3166-2 supported|
|ip2proxy.thread|the threat type of the proxy|
|ip2proxy.usage_type|the usage type classification of the proxy. Please visit <a href="https://www.ip2location.com/database/px11-ip-proxytype-country-region-city-isp-domain-usagetype-asn-lastseen-threat-residential-provider" target="_blank">IP2Location</a> for the list of usage types supported|


## Support
Email: support@ip2location.com

URL: [https://www.ip2location.com](https://www.ip2location.com)
