FROM jc21/nginx-proxy-manager:2.9.14

RUN apt-get update && apt-get upgrade -y && \
  pip install --upgrade cloudflare==2.19.* && \
  pip install --upgrade pip