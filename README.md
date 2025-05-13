# autoletsencrypt.sh – DirectAdmin için Toplu SSL Kurulumu (Let's Encrypt)

Bu betik, DirectAdmin kontrol panelinde barındırılan tüm domainler için otomatik olarak Let's Encrypt SSL sertifikası alır.
Yeni domainler eklendiğinde veya daha önce sertifika almamış siteler varsa, betik bunları otomatik olarak tespit eder ve işlem yapar.
Yönlendirme engellerine karşı HTTPS fallback desteklidir.

---

## 🔧 Kurulum

```bash
cd /root
wget -O autoletsencrypt.sh https://raw.githubusercontent.com/gnet-tr/DirectadminAutoSSL/main/autoletsencrypt.sh
chmod 755 autoletsencrypt.sh
./autoletsencrypt.sh
```

> Yukarıdaki link, scriptin doğrudan indirilebileceği GitHub RAW linkidir.

---

## 📌 Ön Koşullar

SSL özelliğinin tüm kullanıcılar, reseller hesapları ve hosting paketlerinde aktif hale getirilmesi gerekir.
Aşağıdaki komutlarla bu işlemi topluca yapabilirsiniz:

```bash
cd /usr/local/directadmin/data
perl -pi -e 's/^ssl=OFF/ssl=ON/' users/*/user.conf
perl -pi -e 's/^ssl=OFF/ssl=ON/' users/*/domains/*.conf
perl -pi -e 's/^ssl=OFF/ssl=ON/' users/*/reseller.conf
perl -pi -e 's/^ssl=OFF/ssl=ON/' admin/packages/*.pkg
perl -pi -e 's/^ssl=OFF/ssl=ON/' users/*/packages/*.pkg
```

Web sunucu yapılandırmalarını yeniden oluşturun:

```bash
cd /usr/local/directadmin/custombuild
./build rewrite_confs
```

---

## 🚀 Betik Ne Yapar?

* Tüm kullanıcıların domainlerini tarar
* Daha önce SSL alınmamış domainleri tespit eder
* `www.`, `mail.`, `webmail.` gibi yaygın subdomainleri de kontrol eder
* HTTP doğrulaması yapılamazsa HTTPS fallback ile yeniden dener
* Sertifikaları aldıktan sonra:

  * Web server (Apache/Nginx)
  * Mail server (Exim, Dovecot)
  * FTP (Pure-FTPd) yapılandırmalarını otomatik olarak günceller

---

## 🔁 Önerilen Cron Yapılandırması

Günlük olarak süresi yaklaşan sertifikaları yenilemek için:

```bash
0 3 * * * /usr/local/directadmin/scripts/letsencrypt.sh renew >> /var/log/letsencrypt-renew.log 2>&1
```

Haftalık olarak yeni eklenen veya eksik kalan domainleri denetlemek için:

```bash
0 4 * * 0 /root/autoletsencrypt.sh >> /var/log/autoletsencrypt.log 2>&1
```

---

## ⚠️ HTTPS Zorlaması Olan Siteler İçin

Bu betik, `.well-known/acme-challenge/` dizinine yapılan yönlendirmeleri tespit eder.
HTTP → HTTPS zorlaması olan durumlarda, HTTPS ile tekrar test yapılır.
Ancak hem HTTP hem HTTPS erişimi engelleniyorsa, sertifika talebi atlanır.

---

## 💬 Geri Bildirim

Herhangi bir hata, öneri veya katkı için GitHub üzerinden [issue](https://github.com/gnet-tr/DirectadminAutoSSL/issues) veya pull request gönderebilirsiniz.

---

## 📄 Lisans

Bu proje, **GNU Genel Kamu Lisansı (GPL)** altında lisanslanmıştır.
Detaylar için lütfen [LICENSE](./LICENSE) dosyasına göz atın.

---

## 🔗 Gnet Hakkında

Bu betik, [Gnet](https://www.gnet.tr) tarafından geliştirilen açık kaynak çözümlerden biridir.
Daha fazla teknik içerik, komut dosyası ve sistem yöneticilerine yönelik diğer projeler için [GitHub hesabımıza](https://github.com/gnet-tr) göz atabilirsiniz.

---

> 🚧 **Sorumluluk Reddi:**
> Bu script, genel senaryolar dikkate alınarak hazırlanmıştır.
> Her sunucu ortamı farklılık gösterebileceğinden, doğabilecek veri kaybı, kesinti veya yapılandırma sorunlarında **Gnet sorumluluk kabul etmez.**
> İşlem öncesinde sunucunuzun tam yedeğini veya bir snapshot yedeği almanız önemle tavsiye edilir.
