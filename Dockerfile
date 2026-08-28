FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ==============================
# Basic packages
# ==============================
RUN apt update -y && \
    apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    xterm \
    init \
    systemd \
    snapd \
    vim \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    openssl \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    software-properties-common && \
    rm -rf /var/lib/apt/lists/*

# ==============================
# Firefox repository
# ==============================
RUN add-apt-repository ppa:mozillateam/ppa -y

RUN echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox

RUN echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' \
    > /etc/apt/apt.conf.d/51unattended-upgrades-firefox

RUN apt update -y && \
    apt install -y firefox && \
    apt install -y xubuntu-icon-theme && \
    rm -rf /var/lib/apt/lists/*

# ==============================
# Firefox - Railway / Container fix
# ==============================
#
# Railway's container environment does not allow
# creating user namespaces. Firefox normally tries
# to use them for its Linux sandbox.
#
# These variables disable the affected Firefox
# sandbox components.
#

ENV MOZ_DISABLE_CONTENT_SANDBOX=1
ENV MOZ_DISABLE_GMP_SANDBOX=1
ENV MOZ_DISABLE_RDD_SANDBOX=1
ENV MOZ_DISABLE_SOCKET_PROCESS_SANDBOX=1

# Disable Firefox multi-process mode as an additional
# compatibility fallback for restricted containers.
ENV MOZ_FORCE_DISABLE_E10S=1

# ==============================
# Firefox launcher
# ==============================
RUN mkdir -p /usr/local/bin && \
    cat > /usr/local/bin/firefox-rdp <<'EOF'
#!/bin/bash

export MOZ_DISABLE_CONTENT_SANDBOX=1
export MOZ_DISABLE_GMP_SANDBOX=1
export MOZ_DISABLE_RDD_SANDBOX=1
export MOZ_DISABLE_SOCKET_PROCESS_SANDBOX=1
export MOZ_FORCE_DISABLE_E10S=1

exec /usr/bin/firefox "$@"
EOF

RUN chmod +x /usr/local/bin/firefox-rdp

# Replace the normal firefox command with our launcher
RUN mv /usr/bin/firefox /usr/bin/firefox-real && \
    ln -s /usr/local/bin/firefox-rdp /usr/bin/firefox

# ==============================
# Background
# ==============================
RUN mkdir -p \
    /usr/share/backgrounds/xfce \
    /usr/share/xfce4/backdrops

RUN wget --no-check-certificate \
    "https://g.top4top.io/p_3892yo4uu1.jpg" \
    -O /usr/share/backgrounds/custom.jpg

RUN find /usr/share/backgrounds/ /usr/share/xfce4/backdrops/ \
    -type f \
    \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.svg" \) \
    -exec cp /usr/share/backgrounds/custom.jpg {} \;

# ==============================
# Windows 10 theme
# ==============================
RUN git clone \
    https://github.com/B00merang-Project/Windows-10.git \
    /usr/share/themes/Windows-10

RUN git clone \
    https://github.com/B00merang-Project/Windows-10-Icons.git \
    /usr/share/icons/Windows-10

# ==============================
# XFCE theme autostart
# ==============================
RUN mkdir -p /etc/xdg/autostart && \
    echo "[Desktop Entry]" > /etc/xdg/autostart/set-win-theme.desktop && \
    echo "Type=Application" >> /etc/xdg/autostart/set-win-theme.desktop && \
    echo "Exec=sh -c 'xfconf-query -c xsettings -p /Net/ThemeName -s Windows-10; xfconf-query -c xsettings -p /Net/IconThemeName -s Windows-10; xfconf-query -c xfwm4 -p /general/theme -s Windows-10'" >> /etc/xdg/autostart/set-win-theme.desktop && \
    echo "Name=Set Win Theme" >> /etc/xdg/autostart/set-win-theme.desktop

# ==============================
# noVNC
# ==============================
RUN echo '<meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale">' \
    > /usr/share/novnc/index.html

RUN echo '<meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale">' \
    > /usr/share/novnc/vnc_lite.html

# ==============================
# Xauthority
# ==============================
RUN touch /root/.Xauthority

# ==============================
# Ports
# ==============================
EXPOSE 5901
EXPOSE 6080

# ==============================
# Start VNC + noVNC
# ==============================
CMD ["bash", "-lc", "vncserver -localhost no -SecurityTypes None -geometry 1920x1080 --I-KNOW-THIS-IS-INSECURE && openssl req -new -subj '/C=JP' -x509 -days 365 -nodes -out /tmp/self.pem -keyout /tmp/self.pem && websockify -D --web=/usr/share/novnc/ --cert=/tmp/self.pem 6080 localhost:5901 && tail -f /dev/null"]
