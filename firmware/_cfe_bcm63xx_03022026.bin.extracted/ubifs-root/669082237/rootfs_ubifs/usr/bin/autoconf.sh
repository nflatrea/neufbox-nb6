#!/bin/sh

fetch_file() {
	local service=$1
	local operator_domain=$(status get operator_domain)
	local file=$(autoconf get ${service}_file)
	local uri="$(autoconf get ${service}_url)/${file}"

	logger -p daemon.info -t "[autoconf::${service}]" "get ${uri}"

	if ! sed -e "s/%OPERATOR_DOMAIN%/${operator_domain}/g" ${uri} > /tmp/autoconf/${file}; then
		return 1
	fi

	return 0
}

fetch_http() {
	local service=$1
	local timeout=$(nvram get autoconf_wget-timeout)
	local file=$(autoconf get ${service}_file)
	local uri="http://$(autoconf get ${service}_url)/${file}"
	local uri="${uri}?ip_data=$(status get net_data_ipaddr)"
	if [ "$(autoconf get option)" != "3" ]; then
		local uri="${uri}&ip_voip=$(status get net_voip_ipaddr)"
		local uri="${uri}&ip_tv=$(status get net_tv_ipaddr)"
	fi
	local uri="${uri}&mac=$(mac_addr -p)"
	if test -d /etc/adsl; then
		local uri="${uri}&mac_ppp=$(mac_addr -p 3)"
		local uri="${uri}&login_ppp=$(nvram get ppp_login)"
	fi
	local uri="${uri}&genrel=$(autoconf get general_timestamp)"
	local uri="${uri}&hw=$(cat /sys/devices/platform/mcu/nvram/pid)"
	local uri="${uri}&sw=$(cat /etc/efixo_release)"
	if [ "$(status get hotspot_status)" = "up" ]; then
		local uri="${uri}&hotspot_status=on"
	else
		local uri="${uri}&hotspot_status=off"
	fi

	logger -p daemon.info -t "[autoconf::${service}]" "get ${uri}"

	if ! wget -q -T ${timeout} -O /tmp/autoconf/${file} "${uri}"; then
		return 1
	fi

	return 0
}

request_general_default() {
	local general=$1
	local service=$2

	autoconf set ${service}_request "0"

	# invalidate and delete conf
	autoconf set ${service}_status ko
	rm -f /tmp/autoconf/$(autoconf get ${service}_file)

	# fill autoconf info
	autoconf set ${service}_proto "file"
	autoconf set ${service}_url "/etc/default/autoconf"
	autoconf set ${service}_file "general.xml"

	return 0
}

request_general() {
	local general=$1
	local service=$2

	local access=$(status get net_autoconf_access|sed -e 's/ftth/thd/' -e 's/adsl/dsl/' -e 's/gprs/3g/')
	local operator_domain=$(status get operator_domain)

	# always fetch general
	autoconf set ${service}_request $(autoconf get ${service}_timestamp)

	# invalidate and delete conf
	autoconf set ${service}_status ko
	rm -f /tmp/autoconf/$(autoconf get ${service}_file)

	# fill autoconf info
	autoconf set ${service}_proto "$(nvram get autoconf_proto)"
	autoconf set ${service}_url "general.${operator_domain}"
	autoconf set ${service}_file "general.xml"

	return 0
}

request_service() {
	local general=$1
	local name=$2
	local service=$3

	# enable ?
	local enable=$(roxml -q ${general} "/conf/service[name=\"${name}\"]/@enable")
	autoconf set ${service}_enable ${enable}
	if [ "${enable}" != "true" ]; then
		return 1
	fi

	# new conf ?
	local version=$(roxml -q ${general} "/conf/service[name=\"${name}\"]/name/@version")
	autoconf set ${service}_request ${version}
	if [ "$(autoconf get ${service}_timestamp)" = "${version}" ]; then
		return 1
	fi

	# invalidate and delete conf
	autoconf set ${service}_status ko
	rm -f /tmp/autoconf/$(autoconf get ${service}_file)

	# fill autoconf info
	eval $(roxml -o ${general} "/conf/service[name=\"${name}\"]")
	autoconf set ${service}_proto ${protocole}
	autoconf set ${service}_url ${url}
	autoconf set ${service}_file ${file}

	return 0
}

request() {
	local general=$1
	local name=$2
	local service=$3

	case "${service}" in
	"general")
		if [ "${general}" = "/etc/default/autoconf/general.xml" ]; then
			if ! request_general_default ${general} ${service}; then
				return 0
			fi
		else
			if ! request_general ${general} ${service}; then
				return 0
			fi
		fi
		;;
	*)
		if ! request_service ${general} ${name} ${service}; then
			return 0
		fi
		;;
	esac

	# fetch conf
	local file=$(autoconf get ${service}_file)
	if ! fetch_$(autoconf get ${service}_proto) ${service}; then
		logger -p daemon.info -t "[autoconf::${service}]" "failed to fetch ${file}"
		return 1
	fi

	if [ "${service}" != "general" ]; then
		local request=$(autoconf get ${service}_request)
		local timestamp=$(roxml -q /tmp/autoconf/${file} '//@version')
		if [ "${request}" != "${timestamp}" ]; then
			logger -p daemon.info -t "[autoconf::${service}]" "mismatch version [${request}] requested, [${timestamp}] provided"
			return 1
		fi
	else
		local timestamp=$(roxml -q /tmp/autoconf/${file} '//name=general/@version')
		autoconf set firmware_delay $(roxml -q /tmp/autoconf/${file} '//upgrade-delay')
		if test -e /tmp/autoconf/firmware-delay; then
			local uptime=$(awk -F\. '{print $1}' /proc/uptime)
			local date=$(cat /tmp/autoconf/firmware-delay)
			if [ "${uptime}" -ge "${date}" ]; then
				rm -f /tmp/autoconf/firmware-delay
				/etc/init.d/firmware reload
			else
				logger -p daemon.info -t "[autoconf::${service}]" "firmware delay active: date:${date} (now:${uptime})"
			fi
		fi
	fi

	autoconf set ${service}_timestamp ${timestamp}
	autoconf set ${service}_status ok

	if [ "${service}" = "firmware" ]; then
		local delay=$(autoconf get firmware_delay)
		if [ "${delay}" != "0" ] && [ ! -e /tmp/autoconf/firmware-delay ]; then
			local uptime=$(awk -F\. '{print $1}' /proc/uptime)
			local date=$(( ${uptime} + ${delay} ))
			echo ${date} > /tmp/autoconf/firmware-delay
			logger -p daemon.info -t "[autoconf::${service}]" "delay:${delay} date:${date} (now:${uptime})"
			return 0
		fi
	fi

	if [ "${service}" = "general" ]; then
		local general=/tmp/autoconf/${file}
		for name in $(roxml -q ${general} '/conf/service/name'); do
			autoconf.sh request ${name}&
		done
	else
		/etc/init.d/${service} reload
	fi
	return 0
}

invalidate() {
	local name=$1
	local service=$2

	autoconf set general_timestamp "0"
	autoconf set ${service}_status "ko"
	autoconf set ${service}_timestamp "0"
}

reset() {
	local general=$1

	logger -t "autoconf::general" "reset"

	autoconf set option ""
	autoconf set general_timestamp "0"
	for name in $(roxml -q ${general} '/conf/service/name'); do
		local service=$(echo ${name}|sed 's/tvservices/iptv/')
		invalidate ${name} ${service}
	done
}


case "$1" in
"request")
	local general=/tmp/autoconf/$(autoconf get general_file)
	local name=$2
	local service=$(echo $2|sed 's/tvservices/iptv/')
	request ${general} ${name} ${service}
	;;
"default")
	local general=/etc/default/autoconf/general.xml
	local name=$2
	local service=$(echo $2|sed 's/tvservices/iptv/')
	logger -p daemon.info -t "[autoconf::${service}]" "default"
	request ${general} ${name} ${service}
	;;
"invalidate")
	local name=$2
	local service=$(echo $2|sed 's/tvservices/iptv/')
	invalidate ${name} ${name} ${service} 
	;;
"reset")
	local general=/etc/default/autoconf/general.xml
	reset ${general}
	;;
*)
	echo "usage: $0 <request|default|invalidate|reset> [service]"
	exit 1
	;;
esac
