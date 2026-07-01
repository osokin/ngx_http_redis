# NGINX HTTP Redis module

NGINX HTTP Redis module is a dynamic module for [NGINX](https://nginx.org/en/download.html)
that enables basic caching function with [Redis](https://redis.io/downloads/).


# Support

Commercial support and professional services is available from [tipi.work](https://tipi.work).


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
| Syntax:  | *redis_socket_keepalive on \| off* |
| Default: | `redis_socket_keepalive off;` |
| Context: | *http, server, location* |

Configures the “TCP keepalive” behavior for outgoing connections to a
redis server. By default, the operating system's settings are in effect
for the socket.  If the directive is set to the value " `on` ", the
`SO_KEEPALIVE` socket option is turned on for the socket.


The following set of directives requires the [OpenSSL](https://www.openssl.org/) library.

The following set of directives is available as part of a *commercial subscription*.

### `redis_ssl_session_reuse`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_session_reuse on \| off* |
| Default: | `redis_ssl_session_reuse on;` |
| Context: | *http, server, location* |

Determines whether SSL sessions can be reused when working with the proxied server.
If the errors `SSL3_GET_FINISHED:digest check failed` appear in the logs, try
disabling session reuse.

### `redis_ssl_protocols`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_protocols [SSLv2] [SSLv3] [TLSv1] [TLSv1.1] [TLSv1.2] [TLSv1.3]* |
| Default: | `redis_ssl_protocols [TLSv1] [TLSv1.1] [TLSv1.2] [TLSv1.3];` |
| Context: | *http, server, location* |

Enables the specified protocols for requests to a proxied Redis server.

### `redis_ssl_ciphers`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_ciphers ciphers* |
| Default: | `redis_ssl_ciphers DEFAULT;` |
| Context: | *http, server, location* |

Specifies the enabled ciphers for requests to a proxied Redis server.  The
ciphers are specified in the format understood by the OpenSSL library.

The full list can be viewed using the `openssl ciphers` command.

### `redis_ssl_name`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_name name* |
| Default: | `redis_ssl_name $redis_host;` |
| Context: | *http, server, location* |

Allows overriding the server name used to verify the certificate of the proxied
Redis server and to be passed through SNI when establishing a connection with
the proxied Redis server.

By default, the host part of the `redis_pass` URL is used.

### `redis_ssl_server_name`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_server_name on \| off* |
| Default: | `redis_ssl_server_name off;` |
| Context: | *http, server, location* |

Enables or disables passing of the server name through [TLS Server Name
Indication extension](http://en.wikipedia.org/wiki/Server_Name_Indication)
(SNI, RFC 6066) when establishing a connection with the proxied Redis server.

### `redis_ssl_verify`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_verify on \| off* |
| Default: | `redis_ssl_verify off;` |
| Context: | *http, server, location* |

Enables or disables verification of the proxied Redis server certificate.

### `redis_ssl_verify_depth`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_verify_depth number* |
| Default: | `redis_ssl_verify_depth 1;` |
| Context: | *http, server, location* |

Sets the verification depth in the proxied Redis server certificates chain.

### `redis_ssl_trusted_certificate`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_trusted_certificate file* |
| Default: | - |
| Context: | *http, server, location* |

Specifies a file with trusted CA certificates in the PEM format used to verify
the certificate of the proxied Redis server.

### `redis_ssl_crl`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_crl file* |
| Default: | - |
| Context: | *http, server, location* |

Specifies a file with revoked certificates (CRL) in the PEM format used to verify
the certificate of the proxied Redis server.

### `redis_ssl_certificate`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_certificate file* |
| Default: | - |
| Context: | *http, server, location* |

Specifies a file with the certificate in the PEM format used for authentication
to a proxied Redis server.

The value store:uri can be specified instead of the file, which loads a certificate
with a specified uri from an OpenSSL store.

### `redis_ssl_certificate_key`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_certificate_key file* |
| Default: | - |
| Context: | *http, server, location* |

Specifies a file with the secret key in the PEM format used for authentication to
a proxied Redis server.

The value `engine:name:id` can be specified instead of the file, which loads a
secret key with a specified id from the OpenSSL engine name.

The value `store:uri` can be specified instead of the file (1.29.3), which loads
a secret key with a specified `uri` from an OpenSSL store.

### `redis_ssl_password_file`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_password_file file* |
| Default: | - |
| Context: | *http, server, location* |

Specifies a file with passphrases for secret keys where each passphrase is specified
on a separate line.  Passphrases are tried in turn when loading the key.

### `redis_ssl_conf_command`

| | |
|--------- | ------------------------ |
| Syntax:  | *redis_ssl_conf_command name value* |
| Default: | - |
| Context: | *http, server, location* |

Sets arbitrary OpenSSL configuration commands when establishing a connection with the
proxied Redis server.

The directive is supported when using OpenSSL 1.0.2 or higher.

Several `redis_ssl_conf_command` directives can be specified on the same level.
These directives are inherited from the previous configuration level if and only if
there are no `redis_ssl_conf_command` directives defined on the current level.


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

[Eval module](https://github.com/vkholodkov/nginx-eval-module) is required.

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
                set $redis_key "$http_user_agent";
                redis_pass     redis;
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
