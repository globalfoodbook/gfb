#!/bin/sh

# /opt/letsencrypt/letsencrypt-auto --config /etc/letsencrypt/configs/globalfoodbook.com.conf certonly

for conf in $(ls /etc/letsencrypt/configs/*.conf); do
  /opt/letsencrypt/letsencrypt-auto --renew --config "$conf" certonly
done

if [ $? -ne 0 ]
then
  ERRORLOG=`tail /var/log/letsencrypt/letsencrypt.log`
  echo -e "The Let's Encrypt cert has not been renewed! \n \n" \
    $ERRORLOG
 else
   sudo service nginx -s reload #> /dev/null 2>&1 &
fi

exit 0
