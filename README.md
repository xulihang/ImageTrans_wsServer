The certificate is issued by ZeroSSL using acme.sh.

How the certificate is issued using acme.sh:

1. `acme.sh --issue --dns -d local.basiccat.org \
 --yes-I-know-dns-manual-mode-enough-go-ahead-please`
2. Add the txt dns record with the values provided in the previous step.
3. `acme.sh --renew -d local.basiccat.org \
  --yes-I-know-dns-manual-mode-enough-go-ahead-please
`

How the certificate is converted:

1. `openssl pkcs12 -export -in fullchain.cer -inkey local.basiccat.org.key -out abc.p12`
2. `keytool -importkeystore -srckeystore abc.p12 -srcstoretype PKCS12 -destkeystore certificate.jks -deststoretype JKS`