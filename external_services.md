DevOps
-----

## SFTPGo

~~~
docker run \
  -p 8080:443 \
  -p 2022:2022 \
  -v "/mnt/c/ssl_certificates:/ssl_certificates" \
  --mount type=bind,source=/mnt/g/ftp/data,target=/srv/sftpgo \
  --mount type=bind,source=/mnt/g/ftp/home,target=/var/lib/sftpgo \
  -e SFTPGO_HTTPD__BINDINGS__0__PORT=443 \
  -e SFTPGO_HTTPD__BINDINGS__0__ADDRESS=0.0.0.0 \
  -e SFTPGO_HTTPD__BINDINGS__0__ENABLE_HTTPS=1 \
  -e SFTPGO_HTTPD__BINDINGS__0__CERTIFICATE_FILE=/ssl_certificates/certificate.crt \
  -e SFTPGO_HTTPD__BINDINGS__0__CERTIFICATE_KEY_FILE=/ssl_certificates/certificate.key \
  -d drakkan/sftpgo:latest
~~~
