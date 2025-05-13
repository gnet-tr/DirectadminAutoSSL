#!/bin/sh
VERSION=1.5
WELLKNOWN_PATH="/var/www/html/.well-known/acme-challenge"
TIMESTAMP=`date +%s`
CURL=/usr/local/bin/curl
if [ ! -x ${CURL} ]; then
        CURL=/usr/bin/curl
fi

if ! /usr/local/directadmin/directadmin c | grep -m1 -q '^letsencrypt=1$'; then
	echo "Let's encrypt hasn't been enabled on the system, exiting..."
	exit 1
else
	LETSENCRYPT_LIST_SELECTED="`/usr/local/directadmin/directadmin c | grep '^letsencrypt_list_selected=' | cut -d= -f2 | tr ':' ' '`"
fi

challenge_check() {
    if [ ! -d ${WELLKNOWN_PATH} ]; then
        mkdir -p ${WELLKNOWN_PATH}
    fi

    touch ${WELLKNOWN_PATH}/letsencrypt_${TIMESTAMP}

    # HTTP isteği yap, sadece 200 OK ise başarı say
    HTTP_STATUS=$(${CURL} -s -o /dev/null -w "%{http_code}" http://${1}/.well-known/acme-challenge/letsencrypt_${TIMESTAMP})

    if [ "$HTTP_STATUS" = "200" ]; then
        rm -f ${WELLKNOWN_PATH}/letsencrypt_${TIMESTAMP}
        echo 0
        return
    fi

    # Eğer HTTP 301/302 yönlendirmeyse, zorunlu yönlendirme olabilir
    if [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
        echo "Warning: $1 redirects HTTP to HTTPS (code $HTTP_STATUS)" >&2
        # HTTPS ile şansını dene, ama -k ile sertifikayı umursamadan
        HTTPS_STATUS=$(${CURL} -k -s -o /dev/null -w "%{http_code}" https://${1}/.well-known/acme-challenge/letsencrypt_${TIMESTAMP})

        if [ "$HTTPS_STATUS" = "200" ]; then
            rm -f ${WELLKNOWN_PATH}/letsencrypt_${TIMESTAMP}
            echo 0
            return
        fi
    fi

    rm -f ${WELLKNOWN_PATH}/letsencrypt_${TIMESTAMP}
    echo 1
}


for u in `ls /usr/local/directadmin/data/users`; do
{
	  for d in `cat /usr/local/directadmin/data/users/$u/domains.list`; do
	  {
			if [ ! -e /usr/local/directadmin/data/users/$u/domains/$d.cert ] && [ -s /usr/local/directadmin/data/users/$u/domains/$d.conf ]; then
				DOMAIN_LIST="${d}"
				CHALLENGE_TEST=`challenge_check $d`
				if [ ${CHALLENGE_TEST} -ne 1 ]; then
					for A in ${LETSENCRYPT_LIST_SELECTED}; do
					{
						H=${A}.${d}
						CHALLENGE_TEST=`challenge_check ${H}`
						if [ ${CHALLENGE_TEST} -ne 1 ]; then
							DOMAIN_LIST="${DOMAIN_LIST},${H}"
						fi
					};
					done;
					CHALLENGE_TEST=`challenge_check $d`
					if echo "${DOMAIN_LIST}" | grep -m1 -q ','; then
						/usr/local/directadmin/scripts/letsencrypt.sh request ${DOMAIN_LIST} 4096
					else
						/usr/local/directadmin/scripts/letsencrypt.sh request_single ${d} 4096
					fi
				fi
			fi
			if [ -e /usr/local/directadmin/data/users/$u/domains/$d.cert ]; then
				REWRITE=false
				if ! grep -m1 -q '^ssl=ON' /usr/local/directadmin/data/users/$u/domains/$d.conf; then
					perl -pi -e 's|^ssl\=.*|ssl=ON|g' /usr/local/directadmin/data/users/$u/domains/$d.conf								
					REWRITE=true
				fi
				if ! grep -m1 -q '^ssl=ON' /usr/local/directadmin/data/users/$u/domains/$d.conf; then
					echo 'ssl=ON' >> /usr/local/directadmin/data/users/$u/domains/$d.conf
				fi
				if ! grep -m1 -q '^SSLCACertificateFile=' /usr/local/directadmin/data/users/$u/domains/$d.conf && ! grep -m1 -q '^SSLCertificateFile=' /usr/local/directadmin/data/users/$u/domains/$d.conf && ! grep -m1 -q '^SSLCertificateKeyFile=' /usr/local/directadmin/data/users/$u/domains/$d.conf; then
					perl -pi -e "s|^UseCanonicalName=|SSLCACertificateFile=/usr/local/directadmin/data/users/$u/domains/$d.cacert\nSSLCertificateFile=/usr/local/directadmin/data/users/$u/domains/$d.cert\nSSLCertificateKeyFile=/usr/local/directadmin/data/users/$u/domains/$d.key\nUseCanonicalName=|g" /usr/local/directadmin/data/users/$u/domains/$d.conf
					REWRITE=true
				fi
				if ${REWRITE}; then
					echo "action=rewrite&value=httpd&user=$u" >> /usr/local/directadmin/data/task.queue
					echo "action=rewrite&value=mail_sni&domain=$d" >> /usr/local/directadmin/data/task.queue
				fi
			fi
	  }
	  done;
}
done;

#we don't want unconditional writes every minute or so
#echo "action=rewrite&value=mail_sni" >> /usr/local/directadmin/data/task.queue

exit 0
