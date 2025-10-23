###
### Dockerfile migration of https://github.com/EnergyCube/cowfc_installer
### 
### `docker-compose up`
### 
### Open ports listed below
### TCP: 53, 80, 443, 8000, 9000, 9001, 9009, 9002, 9003, 9998, 27500, 27900, 27901, 28910, 29900, 29901, 29920
### UDP: 53
### 
### Admin URL: http://$IP/?page=admin&section=Dashboard
###

ARG ADMIN_USERNAME
ARG ADMIN_PASSWORD

ARG VERSION_OPENSSL="OpenSSL_1_1_1m"
ARG VERSION_OPENSSL1="openssl-1.1.1m"
ARG VERSION_HTTPD="httpd-2.4.52"

###
### Build OpenSSL with SSLv3
### info: https://qiita.com/keys/items/61eb02bd7396cda0d548
###
FROM debian:11 AS builder_openssl
ARG VERSION_OPENSSL
ARG VERSION_HTTPD
WORKDIR /
RUN apt update
RUN apt -y install build-essential curl libapr1-dev libaprutil1-dev libpcre3-dev
WORKDIR /
RUN curl -L https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1m/openssl-1.1.1m.tar.gz -o openssl-1.1.1m.tar.gz
RUN tar xvf openssl-1.1.1m.tar.gz
RUN rm openssl-1.1.1m.tar.gz
WORKDIR /openssl-1.1.1m
RUN ./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl shared enable-ssl3 enable-ssl3-method enable-weak-ssl-ciphers
RUN make install_sw
RUN make install_ssldirs
WORKDIR /
RUN curl -L https://github.com/apache/httpd/archive/refs/tags/2.4.52.tar.gz -o httpd-2.4.52.tar.gz
RUN tar xvf httpd-2.4.52.tar.gz
RUN rm httpd-2.4.52.tar.gz
WORKDIR /httpd-2.4.52
# apr
RUN curl -L https://github.com/apache/apr/archive/refs/tags/1.7.0.tar.gz -o apr-1.7.0.tar.gz
RUN tar xvf apr-1.7.0.tar.gz
RUN rm apr-1.7.0.tar.gz
# apr-util
RUN curl -L https://github.com/apache/apr-util/archive/refs/heads/1.7.x.tar.gz -o apr-util-1.7.x.tar.gz
RUN tar xvf apr-util-1.7.x.tar.gz
RUN rm apr-util-1.7.x.tar.gz

#buildconfに必要なモジュールをダウンロード
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    libapr1-dev \
    libaprutil1-dev \
    libpcre3-dev \
    autoconf \
    libtool \
    libtool-bin \
    pkg-config \
    perl \
    python3

RUN mv apr-1.7.0 srclib/apr \
    && mv apr-util-1.7.x srclib/apr-util

# with this command, you can switch openssl libraries
RUN echo "/usr/local/openssl/lib" > /etc/ld.so.conf.d/usr.local.openssl.lib.conf
RUN ldconfig
RUN ./buildconf
RUN ./configure --enable-ssl --with-ssl=/usr/local/openssl/
RUN make
WORKDIR /

###
### Create dummy certificate files
### info: https://flewkey.com/blog/2020-07-12-nds-constraint.html
###
FROM debian:11 AS builder_dummy-certs
RUN mkdir /dummy-certs
WORKDIR /dummy-certs
RUN apt update
RUN apt -y install curl openssl
RUN curl https://larsenv.github.io/NintendoCerts/WII_NWC_1_CERT.p12 -LO
RUN openssl pkcs12 -in WII_NWC_1_CERT.p12 -passin pass:alpine -passout pass:alpine -out keys.txt
RUN sed -n '7,29p' keys.txt > nwc.crt
RUN sed -n '33,50p' keys.txt > nwc.key
RUN openssl genrsa -out server.key 1024
RUN echo "US\nWashington\nRedmond\nNintendo of America Inc.\nNintendo Wifi Network\n*.*.*\nca@noa.nintendo.com\n\n\n" | openssl req -new -key server.key -out server.csr
RUN openssl x509 -req -in server.csr -CA nwc.crt -CAkey nwc.key -CAcreateserial -out server.crt -days 3650 -sha1 -passin pass:alpine
RUN rm WII_NWC_1_CERT.p12 keys.txt nwc.key nwc.srl server.csr
WORKDIR /


# ###
# ### Build pkmn-classic-framework and dump the gts database
# ###
# FROM debian:11 AS builder_pkmn-classic-framework
# ENV WINE_MONO_VERSION="7.4.0"
# WORKDIR /
# #
# # Install dependencies
# #
# RUN apt update
# RUN apt -y install curl git gnupg gnupg1 gnupg2 mariadb-server mono-complete nuget sqlite3 xz-utils
# #
# # Install Wine
# # info: https://wiki.winehq.org/Debian
# #
# RUN dpkg --add-architecture i386
# RUN curl https://dl.winehq.org/wine-builds/winehq.key -O
# RUN apt-key add winehq.key
# RUN echo "deb https://dl.winehq.org/wine-builds/debian/ bullseye main" >> /etc/apt/sources.list
# RUN apt update
# RUN apt -y install --install-recommends winehq-stable
# RUN rm winehq.key
# #
# # Install Wine Mono
# # info: https://wiki.winehq.org/Mono
# #
# RUN curl -L -o wine-mono.msi https://dl.winehq.org/wine/wine-mono/7.4.0/wine-mono-7.4.0-x86.msi
# RUN wineboot --init && wine msiexec /i wine-mono.msi

###
### Isolate pip from runner
###
FROM python:2.7.18 AS builder_twisted
RUN pip install twisted

###
### pkmn-server
###
FROM debian:11
ARG ADMIN_USERNAME
ARG ADMIN_PASSWORD
ARG VERSION_OPENSSL
ARG VERSION_HTTPD
COPY --from=builder_openssl /openssl-1.1.1m /openssl-1.1.1m
COPY --from=builder_openssl /httpd-2.4.52 /httpd-2.4.52
COPY --from=builder_dummy-certs /dummy-certs /dummy-certs
COPY --from=builder_twisted /usr/local/lib/python2.7/site-packages /usr/local/lib/python2.7/dist-packages
WORKDIR /
#
# Install requirements
#
RUN apt update
RUN apt -y --no-install-recommends install apache2 apt-transport-https ca-certificates curl git libapache2-mod-mono lsb-release mono-xsp net-tools python2.7 python3-software-properties software-properties-common vim
RUN ln -s /usr/bin/python2.7 /usr/bin/python
# Install php7.4
RUN curl https://packages.sury.org/php/apt.gpg -o /etc/apt/trusted.gpg.d/php.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
RUN apt update
RUN apt -y --no-install-recommends install mariadb-server php7.4 php7.4-mysql php7.4-sqlite3 sqlite3
#
# Install custom OpenSSL(mod_ssl)
#
RUN apt update
RUN apt -y --no-install-recommends install build-essential
WORKDIR /openssl-1.1.1m
RUN make install_sw
RUN make install_ssldirs
WORKDIR /httpd-2.4.52
RUN cp modules/ssl/.libs/mod_ssl.so /usr/lib/apache2/modules/
RUN rm -rf /openssl-1.1.1m
RUN rm -rf /httpd-2.4.52
# Switch openssl libraries
# see build section
RUN echo "/usr/local/openssl/lib" > /etc/ld.so.conf.d/usr.local.openssl.lib.conf
RUN ldconfig
# Remove build dependencies
RUN apt purge -y build-essential
#
# Install dummy certificates
#
RUN mkdir /etc/apache2/certs
RUN cp /dummy-certs/server.crt /etc/apache2/certs/
RUN cp /dummy-certs/server.key /etc/apache2/certs/
RUN cp /dummy-certs/nwc.crt /etc/apache2/certs/
RUN rm -rf /dummy-certs
#
# Clone CoWFC repositories and install
#
WORKDIR /var/www
RUN git clone --depth 1 https://github.com/EnergyCube/CoWFC.git
RUN git clone --depth 1 https://github.com/EnergyCube/dwc_network_server_emulator.git
# slightly edit config
RUN sed -i -e "s/db_user = root/db_user = cowfc/g" CoWFC/Web/config.ini
RUN sed -i -e "s/db_pass = passwordhere/db_pass = cowfc/g" CoWFC/Web/config.ini
RUN sed -i -e "s/recaptcha_enabled = 1/recaptcha_enabled = 0/g" CoWFC/Web/config.ini
RUN chmod 777 CoWFC/Web/bans.log
RUN touch dwc_network_server_emulator/gpcm.db
RUN chmod 777 dwc_network_server_emulator/ -R
RUN echo "\npokemondpds\t2\tRwBpAHIAYQBmAGYAZQA_" >> dwc_network_server_emulator/gamestats.cfg
# CoWFC admin page setting
RUN service mariadb start && \
    sleep 5 && \
    echo "CREATE DATABASE cowfc; CREATE USER 'cowfc'@'localhost' IDENTIFIED BY 'cowfc'; GRANT ALL PRIVILEGES ON *.* TO 'cowfc'@'localhost'; FLUSH PRIVILEGES;" | mysql --user=root && \
    mysql --user=root --password= --database=cowfc < CoWFC/SQL/cowfc.sql && \
    echo "INSERT INTO users (Username, Password, Rank) VALUES ('$ADMIN_USERNAME','`/var/www/CoWFC/SQL/bcrypt-hash "$ADMIN_PASSWORD"`','1');" | mysql --user=root --database=cowfc

    # Install Websites
RUN rm -rf html/*
RUN mv CoWFC/Web/* html/
RUN mv html/config.ini ./
# Finish CoWFC installation
RUN touch /etc/.dwc_installed
#
# Install pkmn-classic-framework
#
RUN mkdir gamestats2.gs.nintendowifi.net
# Disable capital-case sensitivity
RUN echo "[mysqld]\nlower_case_table_names=1" >> /etc/mysql/my.cnf
#
# Apache2 config
#
WORKDIR /etc/apache2
# tweaks for suppressing warnings
RUN echo "ServerName localhost\nHttpProtocolOptions Unsafe LenientMethods Allow0.9" >> apache2.conf
# Enable SSLv3 and week cipher
RUN sed -i -e "s/SSLCipherSuite HIGH:!aNULL/SSLCipherSuite @SECLEVEL=0:RC4-SHA:RC4-MD5/g" mods-available/ssl.conf
RUN sed -i -e "s/SSLProtocol all -SSLv3/SSLProtocol SSLv3/g" mods-available/ssl.conf
# virtualhost conf from dwc_network_server_emulator
RUN mv /var/www/dwc_network_server_emulator/tools/apache-hosts/* sites-available/
RUN sed -i -e 's/ServerAlias "nas.nintendowifi.net"//g' sites-available/nas-naswii-dls1-conntest.nintendowifi.net.conf
RUN sed -i -e 's/ServerAlias "nas.nintendowifi.net, nas.nintendowifi.net"//g' sites-available/nas-naswii-dls1-conntest.nintendowifi.net.conf
# generate custom virtualhost conf
RUN echo "<VirtualHost *:80>\n        ServerAdmin webmaster@localhost\n        ServerName gamestats2.gs.nintendowifi.net\n        ServerAlias \"gamestats2.gs.nintendowifi.net, gamestats2.gs.nintendowifi.net\"\n        DocumentRoot /var/www/gamestats2.gs.nintendowifi.net\n        MonoAutoApplication disabled\n        MonoServerPath \"/usr/bin/mod-mono-server4\"\n        MonoApplications default \"/:/var/www/gamestats2.gs.nintendowifi.net\"\n        <Location />\n                SetHandler mono\n                MonoSetServerAlias default\n        </Location>\n</VirtualHost>" > sites-available/gamestats2.gs.nintendowifi.net.conf
RUN echo "<VirtualHost *:443>\n        ServerAdmin webmaster@localhost\n        ServerName nas.nintendowifi.net\n        ServerAlias \"nas.nintendowifi.net\"\n        ServerAlias \"nas.nintendowifi.net, nas.nintendowifi.net\"\n        ProxyPreserveHost On\n        ProxyPass / http://127.0.0.1:9000/\n        ProxyPassReverse / http://127.0.0.1:9000/\n        SSLEngine on\n        SSLCertificateFile /etc/apache2/certs/server.crt\n        SSLCertificateKeyFile /etc/apache2/certs/server.key\n        SSLCertificateChainFile /etc/apache2/certs/nwc.crt\n</VirtualHost>" > sites-available/nas.nintendowifi.net.conf
# Apply settings above
RUN a2dismod mpm_event mod_mono_auto
RUN a2enmod proxy proxy_http "php7.4" ssl
RUN a2ensite *.nintendowifi.net.conf

#
# Install scapy for packet capture
#
RUN apt update && apt install -y python3-pip libpcap-dev tcpdump && \
pip install scapy

RUN 

#
# Create entry point script
#
RUN echo "#!/bin/sh -eu\n\nservice mariadb start\napachectl start\ncd /var/www/dwc_network_server_emulator && git apply /var/www/dwc_network_server_emulator/dlc/YDQJ/patch.diff\ncd /var/www/dwc_network_server_emulator && python master_server.py" > /entrypoint.sh
RUN chmod +x /entrypoint.sh
#
# Remove packages
#
RUN apt purge -y apt-transport-https lsb-release net-tools python3-software-properties software-properties-common vim
RUN apt autoremove -y

WORKDIR /var/www/dwc_network_server_emulator

CMD ["/bin/sh", "/entrypoint.sh"]