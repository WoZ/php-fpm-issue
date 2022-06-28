## PHP-FPM issue 8855

> Demo for the https://github.com/php/php-src/issues/8885

Run `docker-compose up --build`.

php-fpm and nginx will start.

Run helper `./run.sh log.php-fpm` in a separate terminal process.

Make a curl request from your host machine

`curl -I http://localhost:8085/phpinfo.php`

Check an output of the `docker-compose` command. You may see that `access.log = /proc/self/fd/2` setting works and
access log record was added to the stderr output.

```shell
php-fpm_1  | 172.16.2.3 - 28/Jun/2022:12:07:45 +0000 "HEAD /phpinfo.php" 200 /var/www/html/public/phpinfo.php 0.003 2097152 0.00
```

Reload php-fpm daemon with a command `./run.sh reload.php-fpm`.

In the shell with a `./run.sh log.php-fpm` you will see that daemon restarted.

```shell
[28-Jun-2022 12:11:31.567445] DEBUG: pid 1, fpm_got_signal(), line 123: received SIGUSR2
[28-Jun-2022 12:11:31.567465] NOTICE: pid 1, fpm_got_signal(), line 124: Reloading in progress ...
[28-Jun-2022 12:11:31.567473] DEBUG: pid 1, fpm_pctl(), line 233: switching to 'reloading' state
[28-Jun-2022 12:11:31.567494] DEBUG: pid 1, fpm_pctl_kill_all(), line 159: [pool www] sending signal 3 SIGQUIT to child 7
[28-Jun-2022 12:11:31.567519] DEBUG: pid 1, fpm_pctl_kill_all(), line 170: 1 child(ren) still alive
[28-Jun-2022 12:11:31.567525] DEBUG: pid 1, fpm_event_loop(), line 430: event module triggered 1 events
[28-Jun-2022 12:11:31.567531] DEBUG: pid 1, fpm_pctl_kill_all(), line 159: [pool www] sending signal 15 SIGTERM to child 7
[28-Jun-2022 12:11:31.567550] DEBUG: pid 1, fpm_pctl_kill_all(), line 170: 1 child(ren) still alive
[28-Jun-2022 12:11:31.568056] DEBUG: pid 1, fpm_event_loop(), line 430: event module triggered 2 events
[28-Jun-2022 12:11:31.568069] DEBUG: pid 1, fpm_got_signal(), line 82: received SIGCHLD
[28-Jun-2022 12:11:31.568114] DEBUG: pid 1, fpm_event_loop(), line 430: event module triggered 1 events
[28-Jun-2022 12:11:31.568125] DEBUG: pid 1, fpm_children_bury(), line 259: [pool www] child 7 exited on signal 15 (SIGTERM) after 431.810648 seconds from start
[28-Jun-2022 12:11:31.568131] DEBUG: pid 1, fpm_pctl_exec(), line 80: Blocking some signals before reexec
[28-Jun-2022 12:11:31.568135] NOTICE: pid 1, fpm_pctl_exec(), line 85: reloading: execvp("php-fpm", {"php-fpm"})
[28-Jun-2022 12:11:31.585004] DEBUG: pid 1, fpm_log_open(), line 48: open access log (/proc/self/fd/2)
[28-Jun-2022 12:11:31.585060] DEBUG: pid 1, fpm_scoreboard_init_main(), line 38: got clock tick '100'
[28-Jun-2022 12:11:31.585099] DEBUG: pid 1, fpm_signals_init_main(), line 219: Unblocking all signals
[28-Jun-2022 12:11:31.585107] NOTICE: pid 1, fpm_sockets_init_main(), line 421: using inherited socket fd=7, ":::9000"
[28-Jun-2022 12:11:31.585107] NOTICE: pid 1, fpm_sockets_init_main(), line 421: using inherited socket fd=7, ":::9000"
[28-Jun-2022 12:11:31.585127] DEBUG: pid 1, fpm_event_init_main(), line 348: event module is epoll and 3 fds have been reserved
[28-Jun-2022 12:11:31.585333] NOTICE: pid 1, fpm_init(), line 83: fpm is running, pid 1
[28-Jun-2022 12:11:31.585349] DEBUG: pid 1, fpm_children_make(), line 407: blocking signals before child birth
[28-Jun-2022 12:11:31.585551] DEBUG: pid 1, fpm_children_make(), line 431: unblocking signals, child born
[28-Jun-2022 12:11:31.585587] DEBUG: pid 1, fpm_children_make(), line 437: [pool www] child 21 started
[28-Jun-2022 12:11:31.585597] DEBUG: pid 1, fpm_pctl_heartbeat(), line 463: heartbeat have been set up with a timeout of 333ms
[28-Jun-2022 12:11:31.585612] DEBUG: pid 1, fpm_event_loop(), line 377: 1288 bytes have been reserved in SHM
[28-Jun-2022 12:11:31.585617] NOTICE: pid 1, fpm_event_loop(), line 378: ready to handle connections
```

Make a new `curl` request `curl -I http://localhost:8085/phpinfo.php`.

**Expected result**: access log record appears in the stderr

**Actual result**: access log record appears in the `error_log` file (`/usr/local/var/log/php-fpm.log`).

```shell
172.16.2.3 - 28/Jun/2022:12:13:28 +0000 "HEAD /phpinfo.php" 200 /var/www/html/public/phpinfo.php 0.004 2097152 0.00
[28-Jun-2022 12:13:28.683913] DEBUG: pid 1, fpm_event_loop(), line 430: event module triggered 1 events
```

### An extra details.

You may replace `command: php-fpm` with the
`command: strace -tt -f -s 200 --decode-fds=all -e trace=execve,open,fcntl,read,write,close,dup,dup2,pipe php-fpm` in the
`docker-compose.yml`.

Relaunch containers and check output of strace.

Some findings.

```shell
# this is an error_log settings, php-fpm master process
12:33:29.003325 open("/usr/local/var/log/php-fpm.log", O_WRONLY|O_CREAT|O_APPEND|O_LARGEFILE, 0600) = 3</usr/local/var/log/php-fpm.log>

12:33:29.004759 open("/dev/stderr", O_WRONLY|O_CREAT|O_APPEND|O_LARGEFILE, 0600) = 4<pipe:[47154]>
12:33:29.005140 close(4<pipe:[47154]>)  = 0

# this is an access.log settings, php-fpm master process
12:33:29.005341 open("/proc/self/fd/2", O_WRONLY|O_CREAT|O_APPEND|O_LARGEFILE, 0600) = 4<pipe:[47154]>
12:33:29.005848 write(3</usr/local/var/log/php-fpm.log>, "[28-Jun-2022 12:33:29.005606] DEBUG: pid 9, fpm_log_open(), line 48: open access log (/proc/self/fd/2)\n", 103) = 103
12:33:29.006094 fcntl(4<pipe:[47154]>, F_GETFD) = 0
12:33:29.006284 fcntl(4<pipe:[47154]>, F_SETFD, FD_CLOEXEC) = 0

# Block with an issue
12:33:29.014762 open("/usr/local/var/run/php-fpm.pid", O_WRONLY|O_CREAT|O_TRUNC|O_LARGEFILE, 0644) = 9</usr/local/var/run/php-fpm.pid>
12:33:29.015091 write(9</usr/local/var/run/php-fpm.pid>, "9", 1) = 1
12:33:29.015323 close(9</usr/local/var/run/php-fpm.pid>) = 0
# dup2 closes fd=2 (/proc/self/fd/2) and reopens it. This call breaks expected behaviour.
# https://stackoverflow.com/questions/24538470/what-does-dup2-do-in-c
12:33:29.015667 dup2(3</usr/local/var/log/php-fpm.log>, 2<pipe:[47154]>) = 2</usr/local/var/log/php-fpm.log>
12:33:29.016162 write(3</usr/local/var/log/php-fpm.log>, "[28-Jun-2022 12:33:29.015948] NOTICE: pid 9, fpm_init(), line 83: fpm is running, pid 9\n", 88) = 88
12:33:29.016365 pipe([9<pipe:[42549]>, 10<pipe:[42549]>]) = 0

# after child born... curl request before reload, writes to fd=4 that points to (/proc/self/fd/2)
[pid    10] 12:39:44.504798 read(3<TCPv6:[[::ffff:172.16.2.2]:9000->[::ffff:172.16.2.3]:34100]>, "\1\4\0\1\0\0\0\0", 8) = 8
[pid    10] 12:39:44.511915 open("/var/www/html/public/phpinfo.php", O_RDONLY|O_LARGEFILE) = 5</var/www/html/public/phpinfo.php>
[pid    10] 12:39:44.513938 read(5</var/www/html/public/phpinfo.php>, "<?php\nphpinfo();", 16) = 16
[pid    10] 12:39:44.515274 close(5</var/www/html/public/phpinfo.php>) = 0
[pid    10] 12:39:44.517943 write(4<pipe:[47154]>, "172.16.2.3 - 28/Jun/2022:12:39:44 +0000 \"HEAD /phpinfo.php\" 200 /var/www/html/public/phpinfo.php 0.014 2097152 0.00\n", 116172.16.2.3 - 28/Jun/2022:12:39:44 +0000 "HEAD /phpinfo.php" 200 /var/www/html/public/phpinfo.php 0.014 2097152 0.00
) = 116
[pid    10] 12:39:44.518439 write(3<TCPv6:[[::ffff:172.16.2.2]:9000->[::ffff:172.16.2.3]:34100]>, "\1\6\0\1\0D\4\0X-Powered-By: PHP/7.4.29\r\nContent-type: text/html; charset=UTF-8\r\n\r\n\0\0\0\0\1\3\0\1\0\10\0\0\0\0\0\0\0\0\0\0", 96) = 96

# reload...
[pid     9] 12:49:25.770552 write(3</usr/local/var/log/php-fpm.log>, "[28-Jun-2022 12:49:25.770507] DEBUG: pid 9, fpm_got_signal(), line 123: received SIGUSR2\n", 89) = 89
...
[pid    10] 12:49:25.776421 +++ killed by SIGTERM +++
...
12:49:25.786318 execve("/usr/local/sbin/php-fpm", ["php-fpm"], 0x7f87eeed6d60 /* 16 vars */) = 0
...
12:49:25.860843 open("/usr/local/var/log/php-fpm.log", O_WRONLY|O_CREAT|O_APPEND|O_LARGEFILE, 0600) = 3</usr/local/var/log/php-fpm.log>
...
# here we see that /dev/stderr is relinked to /usr/local/var/log/php-fpm.log
12:49:25.860995 open("/dev/stderr", O_WRONLY|O_CREAT|O_APPEND|O_LARGEFILE, 0600) = 4</usr/local/var/log/php-fpm.log>
12:49:25.861057 close(4</usr/local/var/log/php-fpm.log>) = 0

# now /proc/self/fd/2 points to /usr/local/var/log/php-fpm.log
12:49:25.861091 open("/proc/self/fd/2", O_WRONLY|O_CREAT|O_APPEND|O_LARGEFILE, 0600) = 4</usr/local/var/log/php-fpm.log>
12:49:25.861169 write(3</usr/local/var/log/php-fpm.log>, "[28-Jun-2022 12:49:25.861140] DEBUG: pid 9, fpm_log_open(), line 48: open access log (/proc/self/fd/2)\n", 103) = 103
...
[pid    18] 13:22:13.000553 write(4</usr/local/var/log/php-fpm.log>, "172.16.2.3 - 28/Jun/2022:13:22:12 +0000 \"HEAD /phpinfo.php\" 200 /var/www/html/public/phpinfo.php 0.009 2097152 0.00\n", 116) = 116
```

As I see, the method that does `dup2` is `fpm_stdio_init_final` and it's called from `fpm_init`.


```
int fpm_stdio_init_final() /* {{{ */
{
        if (fpm_use_error_log()) {
                /* prevent duping if logging to syslog */
                if (fpm_globals.error_log_fd > 0 && fpm_globals.error_log_fd != STDERR_FILENO) {

                        /* there might be messages to stderr from other parts of the code, we need to log them all */
                        if (0 > dup2(fpm_globals.error_log_fd, STDERR_FILENO)) {
                                zlog(ZLOG_SYSERROR, "failed to init stdio: dup2()");
                                return -1;
                        }
                }
#ifdef HAVE_SYSLOG_H
                else if (fpm_globals.error_log_fd == ZLOG_SYSLOG) {
                        /* dup to /dev/null when using syslog */
                        dup2(STDOUT_FILENO, STDERR_FILENO);
                }
#endif
        }
        zlog_set_launched();
        return 0;
}
```
