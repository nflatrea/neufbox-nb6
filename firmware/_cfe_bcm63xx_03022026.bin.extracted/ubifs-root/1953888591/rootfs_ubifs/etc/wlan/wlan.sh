#!/bin/sh
# broadcom wlan config

maxbss=4

wl() {
    local name="$1"
    shift
    debug /usr/sbin/wlctl -i "$name" "$@"
}

wlc() {
    local name=$(phy_name $1)
    local id=$(phy_id $1)
    shift
    local cmd="$1"
    shift
    debug /usr/sbin/wlctl -i $name $cmd -C $id "$@"
}

dhd() {
    local name=$(phy_name $1)
    local id=$(phy_id $1)
    shift
    local cmd="$1"
    shift
    #debug /usr/bin/dhdsetint -i $name -b $id -c $cmd -v "$@"
    dhdctl -i $name $cmd "$@"
}

dhdnv() {
    local name=$1
    local iovar=$2
    local nvram="$3"
    dhd $name $iovar "$(nvram get $nvram)"
}

safe_nvget() {
    local nvram="$1"
    local default="$2"
    local val=""
    if ! val="$(nvram get $nvram)"; then
	val="$default"
	echo "-- /!\ the key $nvram is not in config! using default: $default --" 1>&2
    fi
    echo "$val"
}

wlnv() {
    local name=$1
    local wlcmd=$2
    local nvram="$3"
    local default="$4"
    local val="$(safe_nvget $nvram $default)"
    wl $name $wlcmd "$val"
}

wlcnv() {
    local name=$1
    local wlcmd=$2
    local nvram="$3"
    local default="$4"
    local val="$(safe_nvget $nvram $default)"
    wlc $name $wlcmd "$val"
}

iface_exist() {
    ifconfig $1 > /dev/null 2>&1
}

wlan_5g_is_on(){
    [ "$(wlan active)" = "on" ] && [ "$(nvram get wlan_ac_active)" = "on" ]
}

wlan_guest_5g_is_on() {
    #[ "$(nvram get wlan_guest_ac_active)" = "on" ]
    false
}

wlan_hotspot_5g_is_on() {
    #[ "$(nvram get hotspot_active)" = "on" ]
    false
}

wlan_24g_is_on(){
    [ "$(wlan active)" = "on" ] && [ "$(nvram get wlan_active)" = "on" ]
}

wlan_guest_24g_is_on() {
    wlan_24g_is_on && [ "$(nvram get wlan_guest_active)" = "on" ]
}

wlan_hotspot_24g_is_on() {
    wlan_24g_is_on && [ "$(nvram get hotspot_active)" = "on" ] && [ "$(autoconf get hotspot_enable)" = "true" ]
}

wlan_wps_must_start() {
    [ "$(nvram get wlan_wl0_wps_mode)" = "enabled" ] && ([[ "$(nvram get wlan_wl0_enc|head -c 3)" = "WPA" ]] || [[ "$(nvram get wlan_wl0_ac_enc|head -c 3)" = "WPA" ]])
}


#debug=1
if [ -z $debug]; then
    if [ "$(nvram get wlan_debug)" = "on" ]; then
        debug=1
    else
        debug=0
    fi
fi

debug() {
    if ! "${@}"; then
        echo -e "ERROR: ${@}" | logger -t wlan
        if [ $debug -eq 1 ]; then
            echo -e "ERROR: ${@}"
        fi
    else
        if [ $debug -eq 1 ]; then
            echo -e "SUCCESS: ${@}" | logger -t wlan
            echo -e "SUCCESS: ${@}"
        fi
    fi
}

ipt() {
    debug iptables "$@"
}

phy_id(){
    if [ "$1" = "wl0" ] || [ "$1" = "wl1" ] ; then
        echo 0
    else
        echo $1 | cut -d"." -f2
    fi
}

phy_name(){
    echo $1 | cut -d"." -f1
}
wlifcdown() {
    for i in $(ifconfig -a | awk  "/^$1/ "'{print $1}')
    do
        ifconfig $i down 2> /dev/null
    done
}

wlifcup() {
    for i in $(ifconfig -a | awk  "/^$1/ "'{print $1}')
    do
        ifconfig $i up 2> /dev/null
    done
}
wlconf_setaspm() {
    wl wl0 aspm 0x102
}

wlconf_setupTPs() {
    taskset -p 2 $(pidof wfd1-thrd)
    wl wl1 tp_id 0

    taskset -p 1 $(pidof dhd0_dpc)
    taskset -p 2 $(pidof wfd0-thrd)
}

wl_down() {
    local name="$1"

    echo wlconf_down $name
    wl $name down

    wl ${name} bss down
    for i in $(seq 1 $((maxbss-1))); do
        wl ${name}.$i bss down
    done

}

get_24ghz_nmode() {
    if [ "$(nvram get wlan_mode)" = "11g" ]
    then
        echo 0
    else
        echo -1
    fi
}

get_5ghz_bwcap() {
    case $(nvram get wlan_ac_bwcap) in
        80)
            echo 0x7
            ;;
        40)
            echo 0x3
            ;;
        20)
            echo 0x1
            ;;
    esac
}

get_24ghz_bwcap() {
    if [ "$(nvram get wlan_ht40)" = "on" ]
    then
        echo 0x3
    else
        echo 0x1
    fi
}

get_5ghz_chanspec() {
    local bw_cap=$(nvram get wlan_ac_bwcap)
    local channel=$(nvram get wlan_ac_channel)
    if [ "$channel" = "auto" ];then
        channel=36
    fi
    case $bw_cap in
        20)
            echo $channel
            ;;
        40)
            if [ $((channel%8)) -eq 0 ];then
                echo ${channel}u
            else
                echo ${channel}l
            fi
            ;;
        80)
            echo ${channel}/80
            ;;
    esac

}
get_24ghz_chanspec() {
    local channel=$(nvram get wlan_channel)
    if [ "$(nvram get wlan_ht40)" = "on" ]
    then
        if [ $channel -gt 6 ];then
            echo ${channel}u
        else
            echo ${channel}l
        fi
    else
        echo $channel
    fi
}


get_gmode() {
    if [ "$(nvram get wlan_mode)" = "11g" ]; then
        echo 2
    else
        echo 1
    fi
}

bcm_reset_WDS() {
    wlctl -i $1 wdswsec 0
    wlctl -i $1 wdswsec_enable 0
    for i in $(seq 0 3)
    do
        wlctl -i $1 rmwep $i
    done
}

wl_set_ssid() {
    local name="$1"
    local ssid="$2"

    #ssid="$(echo $ssid|sed 's/#beer/🍺/g')"
    #ssid="$(echo $ssid|sed 's/#pizza/🍕/g')"
    #ssid="$(echo $ssid|sed 's/#tv/📺/g')"
    #ssid="$(echo $ssid|sed -'s/#smoke/🚬/g')"

    ssid="$(echo $ssid| \
sed -e 's/#smoke/🚬/g' \
-e 's/#tv/📺/g' \
-e 's/#love/❤️/g' \
-e 's/#smile/😃/g' \
-e 's/#sad/😞/g' \
-e 's/#pizza/🍕/g' \
-e 's/#beer/🍺/g')"

    if [ "$name" = "wl0" ]; then
        status set wlan_rawssid5g "$ssid"
    elif [ "$name" = "wl1" ]; then
        status set wlan_rawssid "$ssid"
    fi

    wl $name ssid "$ssid"
}

wl_configure_common() {
    local name=$1

    wl $name radio on
    wl $name up
    wl $name msglevel 0
    wl $name down

    wl ${name} bss down
    for i in $(seq 1 $((maxbss-1)));do
        iface_exist ${name}.$i && wl ${name}.$i bss down
    done

    wl $name infra 1

    wl $name mpc 0


    wl $name chanim_mode 2
}


wl_configure_24ghz() {
    local name=$1

    wlnv $name country wlan_country "E0/856"
    wlnv $name maxassoc wlan_maxassoc
    wlnv $name bss_maxassoc wlan_wl0_maxassoc
    wl $name radio on
    wl $name band b
    
    wl $name spect 0
    wl $name radar 0
    #wl $name dfs_preism -1
    #wl $name dfs_postism -1
    #wl $name tpc_db ??
    local nmode=-1
    local gmode=1
    if [ "$(nvram get wlan_mode)" = "11g" ]; then
        nmode=0
        gmode=2
        wl $name ampdu 0
    else
        wl $name ampdu 1
    fi

    wl $name nmode $nmode
    wl $name nmode_protection_override -1
    wl $name protection_control 2

    wl $name gmode $gmode
    wl $name gmode_protection_override -1
    wl $name gmode_protection_control 2


    local bw_cap=1
    local mimo_bw_cap=0
    if [ "$(nvram get wlan_ht40)" = "on" ]; then
        bw_cap=3
        mimo_bw_cap=1
    fi

    wl $name bw_cap 2g $bw_cap
    wl $name mimo_bw_cap $mimo_bw_cap
    wl $name mimo_preamble -1

    if [ "$(nvram get wlan_channel)" != "auto" ]; then
        wl $name chanspec $(get_24ghz_chanspec)
    #else
    #    acs_cli -i $name autochannel
    fi

    wl $name rifs $(nvram get wlan_rifs)
    rifs_mode=$(nvram get wlan_rifsmode)
    wlan_mode=$(nvram get wlan_mode)
    if [ "$wlan_mode" = "$rifs_mode" ] || ([ "$wlan_mode" = "11n" ] && [ "$wlan_rifs" = "11ng" ]); then
        wl $name rifs_advert $(nvram get wlan_rifsadvert)
    else
        wl $name rifs_advert 0
    fi

    wlnv $name obss_coex wlan_obsscoex

    wl $name vlan_mode 0
    wl $name btc_mode 0

    wlnv $name rxchain_pwrsave_enable wlan_rxchainpwrsaveenable
    wlnv $name rxchain_pwrsave_quiet_time  wlan_rxchainpwrsavequiettime 
    wlnv $name rxchain_pwrsave_pps  wlan_rxchainpwrsavepps

    wlnv $name radio_pwrsave_enable  wlan_radiopwrsaveenable
    wlnv $name radio_pwrsave_quiet_time  wlan_radiopwrsavequiettime
    wlnv $name radio_pwrsave_pps  wlan_radiopwrsavepps
    wlnv $name radio_pwrsave_level  wlan_radiopwrsavelevel

    wlnv $name stbc_rx  wlan_stbcrx
    wlnv $name stbc_tx  wlan_stbctx

    wlnv $name dtim wlan_dtim

    wl $name antdiv 3
    wl $name txant 3

    wl $name mimo_ss_stf 1
    
    wlnv $name wme wlan_wme
    wlnv $name wme_noack wlan_wmenoack
    wlnv $name wme_apsd wlan_wmeapsd
    
    wlnv $name closed wlan_closed

    wl $name rateset default

    if [ "$(nvram get wlan_frameburst)" = "on" ]; then
        wl $name frameburst 1
    fi

    wl $name pwr_percent 100


    case $(nvram get wlan_wl0_enc) in
        WPA2-PSK|WPA-PSK|WPA-WPA2-PSK)
            wl_setup_wpa $name \
                         $(nvram get wlan_wl0_enc) \
                         $(nvram get wlan_wl0_enctype)
            ;;
        OPEN)
            wl_setup_open $name
            ;;
    esac

    wl $name pspretend_retry_limit 5
    wl $name bss down
    wl $name up

    # Some parameters need the interface to be up :
    wl_set_ssid "$name" "$(nvram get wlan_wl0_ssid)"
    
    wlnv $name interference_override wlan_interferenceoverride -1

    #wl $name interference 0
    wlnv $name interference wlan_interference -1

    #wlnv $name fcache wlan_fcache
    wl $name fcache 0
    wlnv $name phycal_tempdelta wlan_phycaltempdelta
    wlnv $name wmf_bss_enable wlan_wmfbss
    wl $name bss down

    if [ "$(nvram get wlan_wl0_enc)" = "WEP" ]; then
        wl_setup_wep "$name" "$(nvram get wlan_wl0_wepkeys_n0)"
    fi
    return 0
}

wl_setup_24ghz() {
    local name=$1

    ifconfig $name up
    wl $name bss up
}


wl_configure_5ghz() {
    local name=$1
    
    wlnv $name country wlan_ac_country "E0/837"
    wlnv $name maxassoc wlan_ac_maxassoc 12
    wlnv $name bss_maxassoc wlan_wl0_ac_maxassoc 12
    wl $name apsta 0
    wl $name radio on
    wl $name band a

    wl $name regulatory 0
    wl $name radar 1
    wl $name spect 1
    # dfs_*ism are for test only
    #wl $name dfs_preism -1
    #wl $name dfs_postism -1
    #wl $name tpc_db ??
    wl $name nmode -1
    wl $name nmode_protection_override -1
    wl $name protection_control 2

    
    if [ "$(nvram get wlan_ac_mode)" = "11n" ]; then
        wl $name vhtmode 0
        wl $name mode_reqd 2
    elif [ "$(nvram get wlan_ac_mode)" = "11ac" ]; then
        wl $name mode_reqd 3
    fi

    wl $name bw_cap 5g $(get_5ghz_bwcap)
    if [ "$(nvram get wlan_ac_channel)" != "auto" ]; then
        wl $name chanspec $(get_5ghz_chanspec)
    else
        if [ "$(nvram get wlan_ac_dfsoverride)" != "on" ]; then
            local bw=$(nvram get wlan_ac_bwcap)
            local rand=$(cat /dev/urandom | tr -dc '0-9'| head -c 2)
            local chan=$(((rand%4)*4+36))
            if [ "$bw" = "80" ]; then
		wl $name chanspec ${chan}/80
            elif [ "$bw" = "40" ]; then
		wl $name chanspec ${chan}l
            else
		wl $name chanspec $chan
            fi
        fi
    fi

    wl $name vlan_mode 0
    wl $name btc_mode 0


    case $(nvram get wlan_wl0_ac_enc) in
        WPA2-PSK|WPA-PSK|WPA-WPA2-PSK)
            wl_setup_wpa $name \
                         $(nvram get wlan_wl0_ac_enc) \
                         $(nvram get wlan_wl0_ac_enctype)
            ;;
        OPEN)
            wl_setup_open $name
            ;;
    esac

    wl $name pspretend_retry_limit 5
    #wl $name frameburst 1
    #wl $name amsdu 0
    #wl $name rx_amsdu_in_ampdu 0
    #wl $name psta_inact 0
    #wl $name phycal_tempdelta 5

    wl $name txbf_bfr_cap 1
    wl $name txbf_bfe_cap 1
    wl $name txbf_imp 1

    wlnv $name closed wlan_ac_closed
    wl $name bss down
    wl $name up
    # Some parameters need the interface to be up
    wl_set_ssid "$name" "$(nvram get wlan_wl0_ac_ssid)"
    wlnv $name interference_override wlan_ac_interferenceoverride -1
    wl $name radarthrs 0x6a0 0x18 0x6a0 0x18 0x688 0x30 0x6a0 0x18 0x6a0 0x18 0x688 0x30
    
    dhdnv $name wmf_bss_enable wlan_wmfbss
    dhd $name wmf_ucast_igmp 1
    dhd $name wmf_ucast_upnp 1
    wl $name bss down
}

wl_setup_5ghz() {
    
    local name=$1

    ifconfig $name up
    wl $name bss up    
}


wl_setdown_wepcrypto() {
    local name="$1"
    for i in $(seq 0 3); do
        wlc $name rmwep $i
    done
}

wl_setup_wpa() {
    local name="$1"
    local mode="$2"
    local type="$3"

   # wl_setdown_wepcrypto "$name"

    if [ "$mode" = "WPA-PSK" ]; then
        wpa_auth=4
    elif [ "$mode" = "WPA2-PSK" ]; then
        wpa_auth=128
    else # WPA-WPA2-PSK
        wpa_auth=132
    fi

    if [ "$type" = "tkip" ]; then
        wsec=2
    elif [ "$type" = "aes" ]; then
        wsec=4
    else
        wsec=6
    fi

    wl $name wsec $wsec
    wl $name wsec_restrict 1
    wl $name wpa_auth $wpa_auth
    wl $name eap_restrict 1
    wl $name auth 0
}

wl_setup_wep() {
    local name="$1"
    local key="$2"


    wl $name wsec 1
    wl $name wsec_restrict 1
    wl $name wpa_auth 0
    wl $name eap_restrict 0
    wl $name auth 0
    wl $name addwep 0 $key
}

wl_setup_open() {
    local name="$1"

    #wl_setdown_wepcrypto "$name"

    wl $name wsec 0
    wl $name wsec_restrict 0
    wl $name wpa_auth 0
    wl $name eap_restrict 0
    wl $name auth 0
}


wl_setup_hotspot() {
    local name="$1"


    #wl_setdown_wepcrypto $name

    wl $name closed 0
    wl $name bss_maxassoc 16
    wl $name wme_bss_disable 1
    wl $name ap_isolate 1
    #wl $name wmf_bss_enable 0
    #wl_setdown_wepcrypto $name

    return
}
wl_setup_eapsim(){
    local name="$1"

    #wl_setdown_wepcrypto "$name"

    wl $name closed 0
    wlc $name wpa_cap
    wlc $name wpa_cap 0 2
    wl $name bss_maxassoc 16
    wl $name wme_bss_disable 1
    wl $name ap_isolate 1
    #wl $name wmf_bss_enable 0

    #wl_setdown_wepcrypto "$name"

    wl $name eap_restrict 1
    wlc $name wsec 4
    wlc $name wsec_restrict 1
    wlc $name wpa_auth 64
    wlc $name auth 0

    #wl $name bss up
    #ifconfig $name up

}

wl_configure_guest(){
    local name="$1"

    #wl_setdown_wepcrypto "$name"

    wl $name closed 0
    wl $name bss_maxassoc 16

    wlnv $name ap_isolate wlan_guest_isolate
    wlnv $name closednet wlan_guest_closed

    case $(nvram get wlan_guest_enc) in
        WPA2-PSK|WPA-PSK|WPA-WPA2-PSK)
            wl_setup_wpa $name $(nvram get wlan_guest_enc) $(nvram get wlan_guest_enctype)
            ;;
        OPEN)
            wl_setup_open $name
            ;;
    esac

    wl $name bss down    
}

wl_setup_guest() {
    local name="$1"

    wl $name up
    wlnv $name ssid wlan_guest_ssid
    wl $name bss up
    ifconfig $name up
}

wl_setdown_bss() {
    local name="$1"

    wl $name bss down
    ifconfig $name down
}

wl_autochannel_24ghz(){
    if [ "$(nvram get wlan_active)" = "on" ] && [ "$(status get wlan_wlan0_interrupter)" = "on" ] && [ "$(nvram get wlan_channel)" = "auto" ]; then
        debug acs_cli -i wl1 mode 2
        debug acs_cli -i wl1 autochannel
    fi
}

wl_autochannel_5ghz(){
    if [ "$(nvram get wlan_ac_active)" = "on" ] && [ "$(status get wlan_wlan0_interrupter)" = "on" ] && [ "$(nvram get wlan_ac_channel)" = "auto" ]; then
        debug acs_cli -i wl0 mode 2
        debug acs_cli -i wl0 autochannel
    fi
}

acs_reload_24ghz() {
    if [ "$(nvram get wlan_active)" = "on" ] && [ "$(status get wlan_wlan0_interrupter)" = "on" ]; then
       if [ "$(nvram get wlan_channel)" = "auto" ]; then
           debug acs_cli -i wl1 mode 2
           debug acs_cli -i wl1 autochannel
       else
	   debug acs_cli -i wl1 mode 1
       fi
    fi
}
acs_reload_5ghz(){
    echo "acs_reload"
    if [ "$(nvram get wlan_ac_active)" = "on" ] && [ "$(status get wlan_wlan0_interrupter)" = "on" ]; then
	if [ "$(nvram get wlan_ac_channel)" = "auto" ]; then
	    echo "setting mode 2"
            debug acs_cli -i wl0 mode 2
	else
	    echo "setting mode 1"
	    debug acs_cli -i wl0 mode 1
	fi
    fi
}
