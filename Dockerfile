FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=ubuntu
ENV HOME=/home/ubuntu
ENV DISPLAY=:1
ENV RESOLUTION=1600x900

# إنشاء مستخدم غير root
RUN useradd -m -s /bin/bash -u 1000 $USER && \
    echo "$USER:$USER" | chpasswd && \
    adduser $USER sudo && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# تثبيت الحزم الأساسية
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    xterm \
    vim \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    software-properties-common \
    && apt clean && rm -rf /var/lib/apt/lists/*

# تثبيت Firefox من PPA
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' | tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox && \
    apt update -y && apt install -y firefox xubuntu-icon-theme && \
    apt clean && rm -rf /var/lib/apt/lists/*

# إعداد الخلفية
RUN mkdir -p /usr/share/backgrounds/xfce /usr/share/xfce4/backdrops && \
    wget --no-check-certificate "https://g.top4top.io/p_3892yo4uu1.jpg" -O /usr/share/backgrounds/custom.jpg && \
    cp /usr/share/backgrounds/custom.jpg /usr/share/backgrounds/xfce/xfce-wallpaper.jpg && \
    cp /usr/share/backgrounds/custom.jpg /usr/share/xfce4/backdrops/xfce-wallpaper.jpg

# تثبيت وتطبيق ثيم Windows 10
RUN git clone https://github.com/B00merang-Project/Windows-10.git /usr/share/themes/Windows-10 && \
    git clone https://github.com/B00merang-Project/Windows-10-Icons.git /usr/share/icons/Windows-10 && \
    mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/ && \
    echo '<?xml version="1.0" encoding="UTF-8"?>' > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml && \
    echo '<channel name="xsettings" version="1.0">' >> /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml && \
    echo '  <property name="Net" type="empty">' >> /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml && \
    echo '    <property name="ThemeName" type="string" value="Windows-10"/>' >> /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml && \
    echo '    <property name="IconThemeName" type="string" value="Windows-10"/>' >> /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml && \
    echo '  </property>' >> /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml && \
    echo '</channel>' >> /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml

# إعداد noVNC للاتصال التلقائي
RUN echo '<meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale">' > /usr/share/novnc/index.html

# إعداد VNC
RUN mkdir -p $HOME/.vnc && \
    echo "$USER" | vncpasswd -f > $HOME/.vnc/passwd && \
    chmod 600 $HOME/.vnc/passwd && \
    chown -R $USER:$USER $HOME/.vnc

# إعداد script بدء التشغيل
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'export HOME=/home/ubuntu' >> /start.sh && \
    echo 'export USER=ubuntu' >> /start.sh && \
    echo 'export DISPLAY=:1' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# بدء VNC server' >> /start.sh && \
    echo 'vncserver :1 -localhost no -SecurityTypes None -geometry $RESOLUTION -depth 24 -fg &' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# توليد شهادة SSL' >> /start.sh && \
    echo 'openssl req -new -x509 -days 365 -nodes -out /tmp/self.pem -keyout /tmp/self.key' >> /start.sh && \
    echo 'cat /tmp/self.key /tmp/self.pem > /tmp/cert.pem' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# بدء websockify' >> /start.sh && \
    echo 'websockify --web=/usr/share/novnc/ --cert=/tmp/cert.pem 6080 localhost:5901' >> /start.sh && \
    chmod +x /start.sh

# تعيين المالك للمجلدات
RUN chown -R $USER:$USER /home/ubuntu

# فتح المنافذ
EXPOSE 5901
EXPOSE 6080

# تشغيل الحاوية
CMD ["/start.sh"]
