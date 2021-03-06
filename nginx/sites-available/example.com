# www to non-www redirect -- duplicate content is BAD:
# https://github.com/h5bp/html5-boilerplate/blob/5370479476dceae7cc3ea105946536d6bc0ee468/.htaccess#L362
# Choose between www and non-www, listen on the *wrong* one and redirect to
# the right one -- http://wiki.nginx.org/Pitfalls#Server_Name

# Redirect to non-www
server {
    server_name *.example.com;
    return 301 $scheme://example.com$request_uri;
}

server {

    # Document root
    root /var/www/example.com;

    # Try static files first, then php
    index index.html index.htm index.php;

    # Specific logs for this vhost
    access_log /var/log/nginx/example.com-access.log;
    error_log  /var/log/nginx/example.com-error.log error;

    # Make site accessible from http://localhost/
    server_name example.com;

    # Specify a character set
    charset utf-8;

    # h5bp nginx configs
    include conf/h5bp.conf;

    # Redirect needed to "hide" index.php
    location / {
            try_files $uri $uri/ /index.php?q=$uri&$args;
    }

    # Don't log robots.txt or favicon.ico files
    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    # 404 errors handled by our application, for instance Laravel or CodeIgniter
    error_page 404 /index.php;

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;

            # With php5-cgi alone:
            # fastcgi_pass 127.0.0.1:9000;
            # With php5-fpm:
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
    }

}