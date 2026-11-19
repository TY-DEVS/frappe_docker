FROM frappe/erpnext:v16.55.0

USER root
RUN set -e; \
    apt-get update; \
    apt-get install -y --no-install-recommends gcc python3-dev build-essential; \
    rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe/frappe-bench

RUN set -e; \
    bench get-app --branch=main --resolve-deps --skip-assets https://github.com/frappe/crm; \
    (cd apps/crm/frontend && yarn install); \
    bench build --app crm; \
    ln -sf /home/frappe/frappe-bench/apps/crm/crm/public /home/frappe/frappe-bench/assets/crm

RUN set -e; \
    bench set-config -gp socketio_port 9000; \
    bench get-app --branch=version-16 --resolve-deps --skip-assets https://github.com/frappe/helpdesk; \
    (cd apps/helpdesk/desk && yarn install); \
    bench build --app helpdesk; \
    ln -sf /home/frappe/frappe-bench/apps/helpdesk/helpdesk/public /home/frappe/frappe-bench/assets/helpdesk

RUN set -e; \
    yarn config set ignore-scripts true; \
    bench get-app --branch=version-16 --skip-assets https://github.com/frappe/hrms; \
    yarn config set ignore-scripts false; \
    npm --prefix apps/hrms pkg delete scripts.build scripts.postinstall; \
    bench build --app hrms; \
    ln -sf /home/frappe/frappe-bench/apps/hrms/hrms/public /home/frappe/frappe-bench/assets/hrms

RUN set -e; \
    bench get-app --branch=main --resolve-deps --skip-assets https://github.com/frappe/raven; \
    (cd apps/raven && yarn install); \
    bench build --app raven; \
    ln -sf /home/frappe/frappe-bench/apps/raven/raven/public /home/frappe/frappe-bench/assets/raven

RUN set -e; \
    bench get-app --branch=version-3 --resolve-deps --skip-assets https://github.com/frappe/wiki; \
    (cd apps/wiki && yarn install); \
    bench build --app wiki; \
    ln -sf /home/frappe/frappe-bench/apps/wiki/wiki/public /home/frappe/frappe-bench/assets/wiki

RUN set -e; \
    bench get-app --branch=version-3 --resolve-deps --skip-assets https://github.com/frappe/insights; \
    (cd apps/insights && yarn install); \
    bench build --app insights; \
    ln -sf /home/frappe/frappe-bench/apps/insights/insights/public /home/frappe/frappe-bench/assets/insights

RUN set -e; \
    python3 -c '\
path = "apps/frappe/frappe/auth.py"; \
with open(path) as f: c = f.read(); \
target = "def flush_cookies(self, response: Response):"; \
replacement = "def flush_cookies(self, response: Response):\n\t\tdomain = frappe.conf.get(\"cookie_domain\") or None"; \
if target in c and "domain = frappe.conf.get" not in c: \
    c = c.replace(target, replacement); \
    c = c.replace("max_age=opts.get(\"max_age\"),", "max_age=opts.get(\"max_age\"),\n\t\t\t\tdomain=domain,"); \
    c = c.replace("response.set_cookie(key, \"\", expires=expires)", "response.set_cookie(key, \"\", expires=expires, domain=domain)"); \
    with open(path, "w") as f: f.write(c); \
    print("Patched auth.py for cross-subdomain cookie_domain SSO."); \
'

RUN set -e; \
    find apps -mindepth 1 -path "*/.git" | xargs --no-run-if-empty rm -fr; \
    bench build --using-cached; \
    (cp -r /home/frappe/frappe-bench/sites/assets/* /home/frappe/frappe-bench/assets/ 2>/dev/null || true); \
    rm -rf /home/frappe/frappe-bench/sites/assets

USER frappe
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["start.sh"]
