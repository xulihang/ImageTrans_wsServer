The certificate is issued by ZeroSSL.

How the certificate is generated:

1. `openssl pkcs12 -export -in certificate.crt -inkey private.key -out abc.p12`
2. `keytool -importkeystore -srckeystore abc.p12 -srcstoretype PKCS12 -destkeystore certificate.jks -deststoretype JKS`