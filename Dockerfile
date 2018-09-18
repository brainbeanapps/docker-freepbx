ARG ASTERISK_VERSION=latest-lts
FROM brainbeanapps/asterisk:${ASTERISK_VERSION}

ARG FREEPBX_VERSION=14.0
ARG FREEPBX_DBENGINE=mysql
ARG FREEPBX_DBNAME=asterisk
ARG FREEPBX_CDRDBNAME=asteriskcdrdb
ARG FREEPBX_DBUSER=root
ARG FREEPBX_DBPASS=
ARG FREEPBX_USER=asterisk
ARG FREEPBX_GROUP=asterisk
ARG FREEPBX_WEBROOT=/var/www/html
ARG FREEPBX_ASTETCDIR=/etc/asterisk
ARG FREEPBX_ASTMODDIR=/usr/lib/asterisk/modules
ARG FREEPBX_ASTVARLIBDIR=/var/lib/asterisk
ARG FREEPBX_ASTAGIDIR=/var/lib/asterisk/agi-bin
ARG FREEPBX_ASTSPOOLDIR=/var/spool/asterisk
ARG FREEPBX_ASTRUNDIR=/var/run/asterisk
ARG FREEPBX_ASTLOGDIR=/var/log/asterisk
ARG FREEPBX_AMPBIN=/var/lib/asterisk/bin
ARG FREEPBX_AMPSBIN=/usr/sbin
ARG FREEPBX_AMPCGIBIN=/var/www/cgi-bin
ARG FREEPBX_AMPPLAYBACK=/var/lib/asterisk/playback

# Install updates, enable EPEL, install dependencies
RUN yum -y update && \
  yum -y install epel-release && \
  yum -y install bash && \
  yum clean all && \
  rm -rf /var/cache/yum

# Install PHP
RUN yum -y install https://mirror.webtatic.com/yum/el7/webtatic-release.rpm && \
  yum -y install php56w php56w-pdo php56w-mysql php56w-mbstring php56w-pear php56w-process php56w-xml php56w-opcache \
    php56w-ldap php56w-intl php56w-soap php56w-gd \
    && \
  yum clean all && \
  rm -rf /var/cache/yum && \
  sed -i 's/\(^upload_max_filesize = \).*/\1128M/' /etc/php.ini && \
  sed -i 's/\(^memory_limit = \).*/\1256M/' /etc/php.ini

# Install Node.js
RUN curl -sL https://rpm.nodesource.com/setup_8.x | bash - && \
  yum install -y nodejs && \
  yum clean all && \
  rm -rf /var/cache/yum

# Install MariaDB
RUN yum -y install mariadb-server && \
  yum clean all && \
  rm -rf /var/cache/yum && \
  chown -R mysql:mysql /var/lib/mysql && \
  mysql_install_db --user=mysql && \
  (mysqld_safe > /dev/null 2>&1 &) && sleep 5 && \
  mysql -e "DELETE FROM mysql.user WHERE User='';" && \
  mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" && \
  mysql -e "DROP DATABASE IF EXISTS test;" && \
  mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" && \
  mysql -e "FLUSH PRIVILEGES;" && \
  mysqladmin --socket=/var/lib/mysql/mysql.sock shutdown

# Install Apache2
RUN yum -y install httpd && \
  yum clean all && \
  rm -rf /var/cache/yum && \
  sed -i "s/^\(User\).*/\1 ${FREEPBX_USER}/" /etc/httpd/conf/httpd.conf && \
  sed -i "s/^\(Group\).*/\1 ${FREEPBX_GROUP}/" /etc/httpd/conf/httpd.conf && \
  sed -i "s/AllowOverride None/AllowOverride All/" /etc/httpd/conf/httpd.conf

# Create user and fix the permissions
RUN groupadd "${FREEPBX_GROUP}" && \
  adduser "${FREEPBX_USER}" -g "${FREEPBX_GROUP}" -G "mysql" -m -c "Asterisk User" && \
  chown -R "${FREEPBX_USER}:${FREEPBX_GROUP}" "${FREEPBX_ASTETCDIR}" && \
  chown -R "${FREEPBX_USER}:${FREEPBX_GROUP}" "${FREEPBX_ASTVARLIBDIR}" && \
  chown -R "${FREEPBX_USER}:${FREEPBX_GROUP}" "${FREEPBX_ASTSPOOLDIR}" && \
  chown -R "${FREEPBX_USER}:${FREEPBX_GROUP}" "${FREEPBX_ASTLOGDIR}" && \
  chown "${FREEPBX_USER}:${FREEPBX_GROUP}" "${FREEPBX_ASTRUNDIR}"

# Compile & install FreePBX
WORKDIR /tmp/freepbx
RUN curl -fsSLo /tmp/freepbx.tar.gz http://mirror.freepbx.org/modules/packages/freepbx/freepbx-${FREEPBX_VERSION}-latest.tgz && \
  yum -y install net-tools crontabs sox lame openssl gcc-c++ icu libicu-devel && \
  yum clean all && \
  rm -rf /var/cache/yum && \
  tar -xzf /tmp/freepbx.tar.gz -C . --strip-components=1 && \
  sed -i "s/-U asterisk/-U ${FREEPBX_USER}/" ./start_asterisk && \
  sed -i "s/-G asterisk/-G ${FREEPBX_GROUP}/" ./start_asterisk && \
  ./start_asterisk start && \
  (mysqld_safe > /dev/null 2>&1 &) && sleep 5 && \
  ./install -vv \
    --dbengine="${FREEPBX_DBENGINE}" \
    --dbname="${FREEPBX_DBNAME}" \
    --cdrdbname="${FREEPBX_CDRDBNAME}" \
    --dbuser="${FREEPBX_DBUSER}" \
    --dbpass="${FREEPBX_DBPASS}" \
    --user="${FREEPBX_USER}" \
    --group="${FREEPBX_GROUP}" \
    --webroot="${FREEPBX_WEBROOT}" \
    --astetcdir="${FREEPBX_ASTETCDIR}" \
    --astmoddir="${FREEPBX_ASTMODDIR}" \
    --astvarlibdir="${FREEPBX_ASTVARLIBDIR}" \
    --astagidir="${FREEPBX_ASTAGIDIR}" \
    --astspooldir="${FREEPBX_ASTSPOOLDIR}" \
    --astrundir="${FREEPBX_ASTRUNDIR}" \
    --astlogdir="${FREEPBX_ASTLOGDIR}" \
    --ampbin="${FREEPBX_AMPBIN}" \
    --ampsbin="${FREEPBX_AMPSBIN}" \
    --ampcgibin="${FREEPBX_AMPCGIBIN}" \
    --ampplayback="${FREEPBX_AMPPLAYBACK}" \
    && \
  rm -rf /tmp/freepbx && \
  rm -rf /tmp/freepbx.tar.gz && \
  fwconsole stop --immediate --maxwait=60 --no-interaction -vv && \
  mysqladmin --socket=/var/lib/mysql/mysql.sock shutdown

# Entrypoint
WORKDIR /
COPY docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
