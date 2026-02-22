nginx_pkg:
  pkg.installed:
    - name: nginx

nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - require:
      - pkg: nginx_pkg

nginx_index:
  file.managed:
    - name: /usr/share/nginx/html/index.html
    - contents: "Hello from Salt!\n"
    - require:
      - pkg: nginx_pkg
