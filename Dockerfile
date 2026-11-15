# syntax=docker/dockerfile:1
FROM frappe/erpnext:v16.55.0 AS builder

USER root
RUN apt-get update && apt-get install --no-install-recommends -y \
    gcc \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe/frappe-bench

RUN bench get-app --branch=main --resolve-deps crm https://github.com/frappe/crm \
    && bench build --app crm \
    && find apps -mindepth 1 -path "*/.git" | xargs --no-run-if-empty rm -fr \
    && cp -r /home/frappe/frappe-bench/sites/assets/* /home/frappe/frappe-bench/assets/ 2>/dev/null || true \
    && rm -rf /home/frappe/frappe-bench/sites/assets

FROM frappe/erpnext:v16.55.0 AS final

USER frappe
COPY --from=builder --chown=frappe:0 /home/frappe/frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

USER frappe
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["start.sh"]
