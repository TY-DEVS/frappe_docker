# syntax=docker/dockerfile:1

ARG FRAPPE_BRANCH=version-16
ARG FRAPPE_IMAGE_PREFIX=frappe

FROM ${FRAPPE_IMAGE_PREFIX}/build:${FRAPPE_BRANCH} AS builder

ARG FRAPPE_BRANCH=version-16
ARG FRAPPE_PATH=https://github.com/frappe/frappe
ARG CACHE_BUST=""

USER frappe

COPY --chown=frappe:0 apps.json /home/frappe/apps.json

RUN : "${CACHE_BUST}" && \
  bench init --apps_path=/home/frappe/apps.json \
    --frappe-branch=${FRAPPE_BRANCH} \
    --frappe-path=${FRAPPE_PATH} \
    --no-procfile \
    --no-backups \
    --skip-redis-config-generation \
    --verbose \
    /home/frappe/frappe-bench && \
  cd /home/frappe/frappe-bench && \
  echo "{}" > sites/common_site_config.json && \
  find apps -mindepth 1 -path "*/.git" | xargs rm -fr && \
  chmod -R g=u /home/frappe/frappe-bench

FROM ${FRAPPE_IMAGE_PREFIX}/base:${FRAPPE_BRANCH} AS backend

USER frappe

COPY --from=builder --chown=frappe:0 /home/frappe/frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

# Keep the COPY destination group-writable and move assets to image-layer storage
RUN chmod g=u /home/frappe/frappe-bench && \
  cp -r /home/frappe/frappe-bench/sites/assets /home/frappe/frappe-bench/assets && \
  rm -rf /home/frappe/frappe-bench/sites/assets

VOLUME [ \
  "/home/frappe/frappe-bench/sites", \
  "/home/frappe/frappe-bench/logs" \
]

USER root
# Entrypoint and startup scripts
COPY resources/core/main-entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

COPY resources/core/start.sh /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh

# Ensure nginx templates and entrypoint are present for the frontend container
COPY resources/core/nginx/nginx-template.conf /templates/nginx/frappe.conf.template
COPY resources/core/nginx/nginx-entrypoint.sh /usr/local/bin/nginx-entrypoint.sh
COPY resources/core/nginx/security_headers.conf /etc/nginx/snippets/security_headers.conf
RUN chmod 755 /usr/local/bin/nginx-entrypoint.sh

USER frappe
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["start.sh"]
