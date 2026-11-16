# syntax=docker/dockerfile:1
FROM frappe/erpnext:v16.55.0

USER frappe
WORKDIR /home/frappe/frappe-bench

RUN set -e; \
    yarn config set network-concurrency 2; \
    yarn config set network-timeout 300000; \
    bench get-app --branch=main --resolve-deps --skip-assets crm https://github.com/frappe/crm; \
    bench get-app --branch=version-16 --resolve-deps --skip-assets helpdesk https://github.com/frappe/helpdesk

RUN set -e; \
    (cd apps/crm/frontend && yarn install --network-concurrency 2 --network-timeout 300000); \
    (cd apps/helpdesk/desk && yarn install --network-concurrency 2 --network-timeout 300000)

RUN set -e; \
    bench build --app crm; \
    ln -sf /home/frappe/frappe-bench/apps/crm/crm/public /home/frappe/frappe-bench/assets/crm

RUN set -e; \
    bench set-config -gp socketio_port 9000; \
    bench build --app helpdesk; \
    ln -sf /home/frappe/frappe-bench/apps/helpdesk/helpdesk/public /home/frappe/frappe-bench/assets/helpdesk

RUN set -e; \
    find apps -mindepth 1 -path "*/.git" | xargs --no-run-if-empty rm -fr; \
    (cp -r /home/frappe/frappe-bench/sites/assets/* /home/frappe/frappe-bench/assets/ 2>/dev/null || true); \
    rm -rf /home/frappe/frappe-bench/sites/assets

USER frappe
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["start.sh"]
