server {
        listen 80;
        listen [::]:80;

        root /var/www/example.lavenderbison.com/html;
        index index.html;

        server_name example.lavenderbison.com;

        location / {
                try_files $uri $uri/ =404;
        }
}