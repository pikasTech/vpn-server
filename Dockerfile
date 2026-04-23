FROM ubuntu:22.04

RUN apt update && apt install -y shadowsocks-libev wget python3 nginx && apt clean

COPY v2ray-plugin /usr/local/bin/v2ray-plugin
RUN chmod +x /usr/local/bin/v2ray-plugin

RUN mkdir -p /etc/shadowsocks-libev /var/www/html

COPY config/ss.json /etc/shadowsocks-libev/config.json
COPY clash-config.yaml /var/www/html/clash.yaml

RUN chmod 644 /var/www/html/clash.yaml

RUN echo 'server { listen 8080; server_name _; location /clash.yaml { alias /var/www/html/clash.yaml; default_type text/plain; } location / { return 404; } }' > /etc/nginx/sites-available/clash

RUN ln -sf /etc/nginx/sites-available/clash /etc/nginx/sites-enabled/clash \
    && sed -i 's/#server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf \
    && rm /etc/nginx/sites-enabled/default 2>/dev/null || true \
    && nginx -t

RUN mkdir -p /run/nginx

ENTRYPOINT ["sh", "-c", "nginx && ss-server -c /etc/shadowsocks-libev/config.json"]