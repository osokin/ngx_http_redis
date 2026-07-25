#!/usr/bin/perl

# (C) Sergey A. Osokin

# Tests for http redis module with client certificate to ssl backend.
# The redis_ssl_certificate and redis_ssl_password_file directives.

###############################################################################

use warnings;
use strict;

use Test::More;

BEGIN { use FindBin; chdir($FindBin::Bin); }

use lib 'lib';
use Test::Nginx;

###############################################################################

select STDERR; $| = 1;
select STDOUT; $| = 1;

eval { require Redis; };
plan(skip_all => 'Redis not installed') if $@;


my $t = Test::Nginx->new()->has(qw/http http_ssl/)
	->has_daemon('redis-server')->plan(3)
	->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

daemon         off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    upstream redisbackend {
        server 127.0.0.1:8081;
    }

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        redis_ssl_session_reuse off;

        location /verify {
            set $redis_key $uri;
            redis_pass rediss://redisbackend;
            redis_ssl_certificate 1.example.com.crt;
            redis_ssl_certificate_key 1.example.com.key;
        }

        location /fail {
            set $redis_key $uri;
            redis_pass rediss://redisbackend;
            redis_ssl_certificate 2.example.com.crt;
            redis_ssl_certificate_key 2.example.com.key;
        }

        location /encrypted {
            set $redis_key $uri;
            redis_pass rediss://redisbackend;
            redis_ssl_certificate 3.example.com.crt;
            redis_ssl_certificate_key 3.example.com.key;
            redis_ssl_password_file password;
        }
    }
}

EOF

$t->write_file('openssl.conf', <<EOF);
[ req ]
default_bits = 2048
encrypt_key = no
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
EOF

my $d = $t->testdir();

foreach my $name ('example.com') {
	system('openssl genrsa '
		. "-out $d/$name.key 4096 "
                . ">>$d/openssl.out 2>&1") == 0
                or die "Can't create CA key for $name: $!\n";
	system('openssl req -x509 -new '
		. '-nodes -sha256 '
		. "-key $d/$name.key "
		. "-days 1 -subj /CN=$name/ "
		. "-out $d/$name.crt "
                . ">>$d/openssl.out 2>&1") == 0
                or die "Can't create CA certificate for $name: $!\n";
}

foreach my $name ('1.example.com', '2.example.com') {
        system('openssl req -x509 -new '
                . "-config $d/openssl.conf -subj /CN=$name/ "
                . "-CA $d/example.com.crt "
                . "-CAkey $d/example.com.key "
                . "-out $d/$name.crt -keyout $d/$name.key "
                . ">>$d/openssl.out 2>&1") == 0
                or die "Can't create certificate for $name: $!\n";
}

foreach my $name ('3.example.com') {
        system('openssl req -x509 -new '
                . "-config $d/openssl.conf -subj /CN=$name/ "
                . "-CA $d/example.com.crt "
                . "-CAkey $d/example.com.key "
                . "-out $d/$name.crt -keyout $d/$name.key "
                . ">>$d/openssl.out 2>&1") == 0
                or die "Can't create certificate for $name: $!\n";
}

sleep 1 if $^O eq 'MSWin32';

$t->write_file('password', '3.example.com');

my $crt1 = "$d/1.example.com.crt";
my $key1 = "$d/1.example.com.key";
my $crt3 = "$d/3.example.com.crt";
my $key3 = "$d/3.example.com.key";
my $cacrt = "$d/example.com.crt";

$t->write_file('redis.conf', <<EOF);

daemonize no
pidfile $d/redis.pid
port 8082
tls-port 8081
tls-cert-file $crt1
tls-key-file $key1
tls-client-cert-file $crt3
tls-client-key-file $key3
tls-ca-cert-file $cacrt
tls-auth-clients yes
bind 127.0.0.1
timeout 300
loglevel debug
logfile $d/redis.log
databases 16
save ""
rdbcompression yes
dbfilename dump.rdb
dir ./
appendonly no
appendfsync always

EOF

$t->run_daemon('redis-server', $d . '/redis.conf');
$t->run();

$t->waitforsocket('127.0.0.1:8082')
	or die "Can't start redis";

###############################################################################

my $r = Redis->new(server => '127.0.0.1:8082');
$r->set('/verify/' => 'SEE-THIS0') or die "can't put value into redis: $!";
$r->set('/fail/' => 'SEE-THIS1') or die "can't put value into redis: $!";
$r->set('/encrypted/' => 'SEE-THIS2') or die "can't put value into redis: $!";

like(http_get('/verify/'), qr/SEE-THIS0/, 'verify certificate');
like(http_get('/fail/'), qr/SEE-THIS1/, 'fail certificate');
like(http_get('/encrypted/'), qr/SEE-THIS2/, 'verify certificate');

###############################################################################
