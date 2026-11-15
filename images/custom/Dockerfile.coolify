# syntax=docker/dockerfile:1
FROM frappe/erpnext:v16.55.0

USER frappe
WORKDIR /home/frappe/frappe-bench

RUN bench get-app --branch=main --resolve-deps crm https://github.com/frappe/crm \
    && bench build --app crm \
    && find apps -mindepth 1 -path "*/.git" | xargs --no-run-if-empty rm -fr \
    && cp -r /home/frappe/frappe-bench/sites/assets/* /home/frappe/frappe-bench/assets/ 2>/dev/null || true \
    && rm -rf /home/frappe/frappe-bench/sites/assets

USER frappe
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["start.sh"]
