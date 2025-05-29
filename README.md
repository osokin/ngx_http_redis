# NGINX HTTP Redis module

NGINX HTTP Redis module is a dynamic module for [NGINX](https://nginx.org/en/download.html)
that enables basic caching function with [Redis](https://redis.io/downloads/).

# Description

The [Redis protocol](https://redis.io/topics/protocol),
not yet fully implemented with the module, but `AUTH`, `GET`, and
`SELECT` commands only.

# Directives

### `redis_bind`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_bind [addr]* |
| Default: | \- |
| Context: | *http, server, localtion* |

Use the following IP address as the source address for redis connections.

### `redis_buffer_size`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_buffer_size [size]* |
| Default: | see `getpagesize(2)` |
| Context: | *http, server, location* |

The recv/send buffer size, in bytes.

### `redis_connect_timeout`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_connect_timeout [time]* |
| Default: | `redis_connect_timeout 60000ms;` |
| Context: | *http, server, location* |

The timeout for connecting to redis, in milliseconds.

### `redis_gzip_flag`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_gzip_flag [number]* |
| Default: | `redis_gzip_flag unset;` |
| Context: | *location* |

Reimplementation of [memcached_gzip_flag](http://nginx.org/en/docs/http/ngx_http_memcached_module.html#memcached_gzip_flag).

### `redis_next_upstream`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_next_upstream [error] [timeout] [invalid_response] [not_found] [off]* |
| Default: | `redis_next_upstream error timeout;` |
| Context: | *http, server, location* |

Which failure conditions should cause the request to be forwarded to another upstream
server?  Applies only when the value in `redis_pass_` is an upstream with two or more servers.

### `redis_next_upstream_timeout`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_next_upstream_timeout [time]* |
| Default: | `redis_next_upstream_timeout 0;` |
| Context: | *http, server, location* |

Limits the time during which a request can be passed to the next server.
The `0` value turns off this limitation.

### `redis_next_upstream_tries`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_next_upstream_tries [number]* |
| Default: | `redis_next_upstream_tries 0;` |
| Context: | *http, server, location* |

Limits the number of possible tries for passing a request to the next server.
The `0` value turns off this limitation.

### `redis_pass`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_pass [name:port]* |
| Default: | \- |
| Context: | *http, server, location* |

The backend should set the data in redis. The redis key is `/uri?args`.

### `redis_read_timeout`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_read_timeout [time]* |
| Default: | `redis_read_timeout 60000ms;` |
| Context: | *http, server, location* |

The timeout for reading from redis, in milliseconds.

### `redis_send_timeout`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_send_timeout [time]* |
| Default: | `redis_send_timeout 60000ms;` |
| Context: | *http, server, location* |

The timeout for sending to redis, in milliseconds.

### `redis_socket_keepalive`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_socket_keepalive on | off* |
| Default: | `redis_socket_keepalive off;` |
| Context: | *http, server, location* |

Configures the “TCP keepalive” behavior for outgoing connections to a
redis server. By default, the operating system's settings are in effect
for the socket.  If the directive is set to the value " `on` ", the
`SO_KEEPALIVE` socket option is turned on for the socket.


# Variables

### `$redis_auth`

The `PASSWORD` value for the redis `AUTH` command (since 0.3.9).

### `$redis_db`

The number of redis database; default value is `0` if not defined.

### `$redis_key`

The value of the redis key.


# Installation

You'll need to re-compile Nginx from source to include this module.
Modify your compile of Nginx by adding the following directive
(modified to suit your path of course):

```
./configure --add-module=/absolute/path/to/ngx_http_redis
make
make install
```

Alternatively, it's possible to compile the dynamic `ngx_http_redis`
module.  The nginx source is required.

```
./configure --compat --add-dynamic-module=/absolute/path/to/ngx_http_redis
make modules
```


# Usage

### Example 1


```
http
{
 ...
    server {
        location / {
            set $redis_key  "$uri?$args";
            redis_pass      127.0.0.1:6379;
            error_page      404 502 504 = @fallback;
        }

        location @fallback {
            proxy_pass      backend;
        }
    }
}
```

### Example 2

Capture the `User-Agent` `HTTP` header, query to redis database
for lookup appropriate backend.

[Eval module](http://www.grid.net.ru/nginx/eval.en.html) is required.

```
http
{
 ...
    upstream redis {
        server  127.0.0.1:6379;
    }

    server {
     ...
        location / {

	    eval_escalate on;

	    eval $answer {
		set $redis_key	"$http_user_agent";
		redis_pass	redis;
	    }

            proxy_pass $answer;
        }
        ...
     }
}
```


### Example 3

Compile nginx with [ngx_http_redis](https://github.com/osokin/ngx_http_redis/)
and [ngx_http_gunzip](https://nginx.org/en/docs/http/ngx_http_gunzip_module.html)
modules.
Gzip content and put it into a redis database.

```
% cat index.html
<html><body>Hello from redis!</body></html>
% gzip index.html
% cat index.html.gz | redis-cli -x set /index.html
OK
% cat index.html.gz | redis-cli -x set /
OK
%
```

Follow the next configuration, nginx:
- gets a gzipped content from the redis database;
- unzips it;
- reply with the gunzipped content.

```
http
{
 ...
    upstream redis {
        server  127.0.0.1:6379;
    }

    server {
     ...
        location / {
                gunzip on;
                redis_gzip_flag 1;
                set $redis_key "$uri";
                redis_pass redis;
        }
    }
}
```

### Example 4

The same as Example 1 but with `AUTH`.

```
http
{
 ...
    server {
        location / {
            set $redis_auth somepasswd;
            set $redis_key  "$uri?$args";
            redis_pass      127.0.0.1:6379;
            error_page      404 502 504 = @fallback;
        }
    }
}

```

### Development and testing

1. Clone the [nginx-tests](https://github.com/nginx/nginx-test) repository.
```
   % git clone https://github.com/nginx/nginx-tests.git
```

2. Build [and install] nginx

   Installation of nginx is the optional step.
   Also, install:
   - redis server;
   - perl;
   - perl module for redis.
 

   For FreeBSD ports tree:
```
   % cd /usr/ports/www/nginx-devel && make [ && make install ]
   % ASSUME_ALWAYS_YES=true pkg install redis p5-Redis
```


3. Run the following command

```
   % PERL5LIB=/path/to/nginx-tests/dir \
   TEST_NGINX_VERBOSE=1 \
   TEST_NGINX_LEAVE=1 \
   TEST_NGINX_BINARY=/path/to/nginx/binary \
   TEST_NGINX_MODULES=/path/to/nginx/modules/directory \
   TEST_NGINX_GLOBALS="load_module /path/to/nginx/modules/directory/ngx_http_redis_module.so;" \
   prove
```

   Here's the example, when nginx built from the FreeBSD ports tree
```
   % PERL5LIB=/home/nginx/github/nginx-tests/lib:${PERL5LIB} \
   TEST_NGINX_VERBOSE=1 \
   TEST_NGINX_LEAVE=1 \
   TEST_NGINX_BINARY=/usr/local/sbin/nginx \
   TEST_NGINX_MODULES=/usr/local/libexec/nginx \
   TEST_NGINX_GLOBALS="load_module /usr/local/libexec/nginx/ngx_http_redis_module.so;" \
   prove -prvv
```

# Thanks to

- [Maxim Dounin](https://mdounin.ru/)
- [Vsevolod Stakhov](https://github.com/vstakhov)
- [Ezra Zygmuntowicz](https://github.com/ezmobius)


# Special thanks to

- [Evan Miller](https://github.com/evanmiller) for his
  [Guide To Nginx Module Development](https://www.evanmiller.org/nginx-modules-guide.html)
  and [Advanced Topics In Nginx Module Development](https://www.evanmiller.org/nginx-modules-guide-advanced.html)
- [Valery Kholodkov](https://github.com/vkholodkov) for his
  [Nginx modules development](http://antoine.bonavita.free.fr/nginx_mod_dev_en.html),
  English translation
