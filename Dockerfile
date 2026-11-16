# syntax=docker/dockerfile:1
FROM frappe/erpnext:v16.55.0

USER frappe
WORKDIR /home/frappe/frappe-bench

RUN set -e; \
    yarn config set network-concurrency 1; \
    yarn config set network-timeout 600000; \
    bench get-app --branch=main --resolve-deps --skip-assets crm https://github.com/frappe/crm; \
    (cd apps/crm/frontend && yarn install --network-concurrency 1 --network-timeout 600000 && yarn build); \
    bench build --app crm; \
    ln -sf /home/frappe/frappe-bench/apps/crm/crm/public /home/frappe/frappe-bench/assets/crm; \
    bench get-app --branch=version-16 --resolve-deps --skip-assets helpdesk https://github.com/frappe/helpdesk; \
    (cd apps/helpdesk/desk && yarn install --network-concurrency 1 --network-timeout 600000 && yarn build); \
    bench build --app helpdesk; \
    ln -sf /home/frappe/frappe-bench/apps/helpdesk/helpdesk/public /home/frappe/frappe-bench/assets/helpdesk; \
    find apps -mindepth 1 -path "*/.git" | xargs --no-run-if-empty rm -fr; \
    (cp -r /home/frappe/frappe-bench/sites/assets/* /home/frappe/frappe-bench/assets/ 2>/dev/null || true); \
    rm -rf /home/frappe/frappe-bench/sites/assets

USER frappe
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["start.sh"]
