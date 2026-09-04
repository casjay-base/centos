# Security audit — centos/etc (source of truth)

Read-only audit performed via `security-auditor` agent, 2026-08-31. Nothing
fixed yet. Fix `centos/` first, then re-run `sync.sh` and re-check whether
each finding also applies to the derived distros (fedora/debian/ubuntu/
raspbian/arch/alpine) before considering this closed. `pkmgr/min.sh` and
`sync.sh` themselves were NOT reviewed — do that as a follow-up pass.

Logrotate findings below already reflect the finalized policy: `rotate 0`
(no retained backups) + `nocompress` for all logs; security logs (wtmp,
btmp, secure, ssh, maillog) get `maxage 180` + `maxsize 100M` instead of
immediate discard; everything else rotates monthly OR at a size threshold
(10/50/100M by verbosity) whichever comes first.

## CRITICAL

- [x] 1. Real TLS private key committed and trusted by Cockpit —
      `etc/ssl/CA/CasjaysDev/private/localhost.key`,
      `etc/cockpit/ws-certs.d/localhost.key`,
      `etc/cockpit/ws-certs.d/1-my-cert.cert` (contains the key, not just
      the cert) — matches committed cert CN=casjay.net, valid to
      2031-11-18. MUST revoke+regenerate and purge from git history
      (`git filter-repo`) — already permanently burned since public.
      Generate at bootstrap into a gitignored path instead.
      DECISION (user, 2026-09-04): keep the committed self-signed key/cert as
      the shared default — acceptable for a public repo, no per-host rotation
      wanted. Files restored, `.gitignore` no longer excludes them. Kept two
      independent bugs found along the way, unrelated to that decision:
      `__copy_ca_certs()` in `pkmgr/centos/scripts/{min.sh,server.sh}` now
      chmods the generated-if-missing fallback pair 600/644 (was a
      world-readable 664 on the whole `/etc/letsencrypt` tree), and the
      cockpit renewal hook writes the key with `>` instead of an appending
      `>>` that stacked a new key onto the file on every renewal. History
      purge still outstanding (out of scope here — needs `git filter-repo`,
      a destructive/confirm-gated operation).
- [x] 2. Shorewall default policy fully open, both IPv4 and IPv6 —
      `etc/shorewall/policy:4-5`, `etc/shorewall6/policy:4-5` = ACCEPT/
      ACCEPT; `rules` files are empty. No filtering exists at all. Change
      to DROP defaults + explicit per-service ACCEPT rules.
      FIXED (moot via firewalld migration): no `shorewall*` path remains under
      `etc/`; `firewalld/zones/public.xml` has no `target=` so it inherits
      firewalld's default-deny (only ssh/dhcpv6-client/http/https/smtp/smtps/
      smtp-submission are opened) and `docker.xml` is `target="%%REJECT%%"`,
      which is the default-deny posture this finding asked for. Also fixed a
      dangling reference the migration left behind: `fail2ban/jail.conf:17`
      still had `banaction = shorewall` (a now-nonexistent action) — set to
      `firewallcmd-ipset` to match `jail.d/00-firewalld.conf`.
- [x] 3. SNMP: `rwcommunity publicrw` (unauthenticated, any source, full
      MIB write) + `rocommunity public` — `etc/snmp/snmpd.conf:10-13,15,
      23-26`. Remove rw entirely; restrict ro to 127.0.0.1; move to SNMPv3.
      FIXED: `rwuser`/`rwcommunity` gone and `rocommunity public 127.0.0.1`
      (WIP); this pass added `agentAddress udp:127.0.0.1:161,udp6:[::1]:161`
      so snmpd no longer binds 0.0.0.0, and qualified the dangling
      `rouser publicv3ro` with `authPriv` plus a comment giving the exact
      `net-snmp-create-v3-user -ro -A ... -a SHA-512 -X ... -x AES` command to
      run at bootstrap (no createUser credential is committed).
- [x] 4. Samba: `map to guest = Bad User` + `guest ok = yes` + `force
      user = root` + `create mask = 0777` on `[tmp]` and `[backups]` —
      `etc/samba/smb.conf`. Anonymous root-owned writes into the backup
      set and /tmp. Remove guest/public/force-user; add
      `server min protocol = SMB2`, `server signing = mandatory`.
      FIXED: `hosts allow/deny` + `server min protocol = SMB2` +
      `server signing = mandatory` were already in the WIP; this pass set
      `map to guest = Never`, `usershare allow guests = No`, dropped the global
      `guest ok = yes`, and rewrote `[tmp]`/`[backups]` (and the four
      commented-out share templates) to `public = no`, `valid users =
      @sambausers`, no `force user`, `create mask = 0660` /
      `directory mask = 0770`. Fails closed until bootstrap creates the
      `sambausers` group and runs `smbpasswd -a` (noted in a comment above the
      share definitions).
- [x] 5. rsyncd exports `/mnt/backups` anonymously, `uid = root`, no auth
      users/secrets/hosts allow — `etc/rsyncd.conf`,
      `etc/rsync.d/{backup,ftp}.conf`. Add auth + secrets file (0600) +
      hosts allow; drop uid to non-root.
      FIXED: `[backup]` now runs `uid/gid = nobody` with `auth users = backup`,
      `secrets file = /etc/rsyncd.secrets`, `strict modes = yes` on top of the
      WIP's `hosts allow/deny`; `rsyncd.conf` gained safe global defaults
      (`uid/gid = nobody`, `use chroot = yes`, `read only = yes`,
      `max connections = 10`) so a future module inherits them; `[ftp]` left
      anonymous read-only on purpose (public `/var/ftp/pub`, already non-root)
      with a comment saying so. `etc/rsyncd.secrets` is gitignored and
      generated 0600 root:root by a new "Setting up rsyncd" section in
      `pkmgr/centos/scripts/{min.sh,server.sh}`; missing secrets fail closed.
- [x] 6. Tor: SOCKS/HTTP/DNS proxy bound `0.0.0.0`, no SocksPolicy, plus
      `ExitRelay 1` — `etc/tor/torrc:25-31,53-59`. Open proxy + SSRF pivot
      to every loopback service. Bind to 127.0.0.1, add
      `SocksPolicy accept 127.0.0.0/8 / reject *`, drop exit relay.
      FIXED: `ExitRelay 0`, no ORPort/ExitPolicy, and the loopback+RFC1918
      `SocksPolicy` with a trailing `reject *`/`reject6 *` were already in the
      WIP. Verified the HTTPTunnelPort/DNSPort reasoning rather than opening
      anything: 9080/9053 appear in no firewalld zone — `public.xml` is the
      default zone with no `target=` (deny-by-default, only ssh/http/https/
      smtp*/dhcpv6-client opened) and `docker.xml` is `target="%%REJECT%%"` —
      so both ports are unreachable from every network. No firewalld change
      needed; the torrc comment now states this explicitly instead of the
      vague "the host firewall must restrict".
- [x] 7. MySQL: hardcoded `[client] password` in world-readable
      `my.cnf:2-3`, no `bind-address` (defaults to 0.0.0.0 → internet-
      exposed given #2), `general_log = 2` logging cleartext
      CREATE/SET PASSWORD statements forever (no rotation, see #21).
      Remove password line, add `bind-address = 127.0.0.1`,
      `general_log = 0`.
      FIXED: dropped the `[client] password = supersecretpassword` line (with a
      comment pointing at `~/.my.cnf` 0600 / a bootstrap env file), added
      `bind-address = 127.0.0.1` to `[mysqld]`, and set `general_log = 0`.
      Note: this also clears half of finding #25 - the other committed
      placeholder passwords in `munin/plugin-conf.d/munin-node` are untouched.
- [x] 8. PHP `allow_url_include = On` (`php.ini:80`) + empty
      `disable_functions` (`:18`) — turns any include($_GET[]) bug into
      unauthenticated RCE. Set `allow_url_include = Off`, populate
      `disable_functions`.
      FIXED in `etc/php.ini` (the only place either directive is set - there is
      no `php.d/` in this tree and `php-fpm/www.conf` does not override them):
      `allow_url_include = Off` and `disable_functions = exec,passthru,
      shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,
      parse_ini_file,show_source`. NOTE: `curl_exec`/`curl_multi_exec` break
      any app that uses PHP's HTTP client (WordPress, most CMSes) - a comment
      above the directive says to drop just those two rather than emptying the
      list if that bites.

## HIGH

- [x] 9. Daily root cron pipes unauthenticated `curl` output to `bash`,
      unpinned `main` ref, no signature — `cron.d/run-os-update:2`. Pin to
      a commit SHA + verify signature, or drop the fallback.
      FIXED: dropped the `|| bash -c "$(curl ...)"` fallback entirely from
      `etc/cron.d/run-os-update` — `/root/.local/bin/run-os-update` is shipped by
      this same repo, so the remote refetch was a redundant root RCE path, not a
      recovery mechanism. If the script is missing the cron entry now no-ops
      instead of executing whatever `main` happens to hold. Comment above the
      line states this. `cron.d/yum-update`'s separate issue is #38 (LOW),
      untouched here.
- [x] 10. Apache `<Directory />` has no `Require all denied` (stock RHEL
      default removed) with `Options All` + `AllowOverride All` —
      `httpd.conf:123-138`. Restore deny-by-default, `Options None`.
      FIXED in `etc/httpd/conf/httpd.conf`: `<Directory />` is now
      `Options None` + `AllowOverride None` + `Require all denied`, the stock
      RHEL posture. Because 2.4 authorization is inherited, `<Directory
      "/var/www">` and `<Directory "/var/www/html">` each gained an explicit
      `Require all granted` so the real docroot still serves; both also dropped
      the `All` from `Options` (which was silently granting `ExecCGI` and
      `Includes` across the whole docroot) down to
      `MultiViews Indexes FollowSymLinks`. `Indexes` is left in place on
      purpose — that is #32 (LOW), out of scope for this pass.
- [x] 11. `/cgi-bin` executes `.sh .php .js .go` as CGI, world-accessible,
      `AllowOverride All` — `httpd.conf:154-160`,
      `nginx/global.d/cgi-bin.conf`. Strip non-`.cgi/.pl` handlers,
      `AllowOverride None`.
      FIXED in `etc/httpd/conf/httpd.conf`: the `/usr/local/share/httpd/cgi-bin`
      block is now `AllowOverride None` and
      `AddHandler cgi-script .cgi .pl` — `.py .sh .rb .go .js .php` no longer
      execute as CGI (`.php` in particular was handing the PHP handler an
      arbitrary-upload directory). A comment above the `ScriptAlias` says not to
      re-add them. `Require all granted` was deliberately kept: nginx is the
      internet-facing terminator and proxies `/cgi-bin` to Apache from the
      host's own LAN address (`conf.d/default.conf` upstream
      `mycurrentipaddress_4:8443`), so a loopback-only `Require ip` would have
      broken every legitimate request while the exposure is unchanged — the
      execution surface, not the reachability, was the actual defect.
      `nginx/global.d/cgi-bin.conf` needed no change; it is a plain proxy pass
      with no handler logic of its own.
- [x] 12. Munin has zero access control on `/munin` and `/munin-cgi` (both
      Apache and nginx configs) — empty `munin-htpasswd` is never
      referenced anywhere. Add AuthType Basic + AuthUserFile + Require
      valid-user to both vhost configs; generate htpasswd at bootstrap.
      FIXED: `httpd/conf.d/munin.conf` now carries `AuthType Basic` /
      `AuthName "Munin"` / `AuthUserFile /etc/munin/munin-htpasswd` /
      `Require valid-user` on both the `/var/lib/munin/html` directory and the
      `/munin-cgi/` Location, and `nginx/global.d/munin.conf` enforces the same
      credentials at the edge via `auth_basic` / `auth_basic_user_file` on both
      proxied locations (single prompt — nginx forwards `Authorization`
      upstream, and Apache revalidates against the same file). The committed
      `munin/munin-htpasswd` is intentionally left empty, so munin fails closed
      until bootstrap runs `htpasswd -B -c /etc/munin/munin-htpasswd <user>`;
      a comment at the top of each config states that command.
- [x] 13. munin-node runs plugins as root, zero `allow`/`cidr_allow` ACL —
      `munin-node.conf`. Add `cidr_allow 127.0.0.1/32`; drop root where
      plugins allow.
      FIXED: `munin/munin-node.conf` replaced the two commented-out
      `#allow ^.\.0\.0\.0$` / `#allow ^::0$` placeholders with a real ACL —
      `cidr_allow 127.0.0.1/32` + `cidr_allow ::1/128` and the matching
      `allow ^127\.0\.0\.1$` / `allow ^::1$` regexes (munin-node applies both
      lists, so both forms are needed). `host 127.0.0.1` already bound it to
      loopback; the ACL is the second layer. Root drop: the global
      `[*] user root` in `munin/plugin-conf.d/munin-node` is now `user munin` —
      every plugin that genuinely needs privilege (`disk*`, `cps*`, `postfix*`,
      `hddtemp*`, `ip_*`, `fail2ban`, `fw*`, `cup*`, `asterisk_*`, `yum*`)
      already carries its own explicit `user root` section, so only the
      unenumerated default was widened. `user root` on the daemon itself is
      unchanged (upstream default; munin-node needs it to setuid per plugin).
      Also stripped a stray blank line at EOF of `plugin-conf.d/munin-node`.
- [x] 14. sshd_config: `PermitRootLogin yes`, `PasswordAuthentication yes`,
      `MaxSessions 99999`, `LoginGraceTime 300`, `GSSAPIAuthentication
      yes`, no cipher/kex/MAC hardening (client config has it, server
      doesn't) — `sshd_config:12,13,16,21,32`. Harden to match
      `ssh_config`'s crypto pins; `PermitRootLogin prohibit-password`;
      `PasswordAuthentication no`; `MaxSessions 10`; `LoginGraceTime 30`.
      FIXED in `etc/ssh/sshd_config`: `LoginGraceTime 30`,
      `PermitRootLogin prohibit-password`, `MaxSessions 10`,
      `PasswordAuthentication no` (plus explicit `PubkeyAuthentication yes` and
      `KbdInteractiveAuthentication no` so PAM cannot re-open a password path
      behind `UsePAM yes`), and `GSSAPIAuthentication no` /
      `GSSAPICleanupCredentials yes` — no Kerberos realm is configured anywhere
      in this tree, so GSSAPI was pure attack surface. Added the four crypto
      pins (`Ciphers`/`MACs`/`KexAlgorithms`/`HostKeyAlgorithms`) copied
      verbatim from `ssh_config` so client and server now agree, with a comment
      saying to keep the two in sync. NOTE: this is a hard cutover to key-only
      root/user login — bootstrap must install an authorized_keys entry before
      this config is deployed to a host that currently logs in by password.
- [x] 15. ProFTPD: `RootLogin on`, `TLSRequired off` (cleartext root
      password over network), `AllowForeignAddress on` (FTP bounce),
      `TLSProtocol` includes TLSv1/1.1 — `proftpd.conf`,
      `proftpd.d/tls.conf`. `RootLogin off`, `TLSRequired on`,
      `AllowForeignAddress off`, drop TLSv1/1.1.
      FIXED: `proftpd.conf` → `RootLogin off` and `AllowForeignAddress off`
      (closes the FTP-bounce port-scan/relay primitive). `proftpd.d/tls.conf` →
      `TLSRequired on` and `TLSProtocol TLSv1.2 TLSv1.3`. A comment above the
      block flags the behavioral consequence: `TLSRequired on` applies to the
      `<Anonymous ~ftp>` section too, so anonymous clients must now speak
      FTPS (`AUTH TLS`) — plain cleartext FTP is refused outright. Left
      `TLSOptions NoSessionReuseRequired` alone: that is #39 (LOW), out of
      scope for this pass despite being tagged "fix alongside #15".
- [x] 16. fail2ban: stray `banaction = firewallcmd-ipset` in
      `jail.d/00-firewalld.conf` contradicts `action = shorewall` in
      `jail.local` (footgun for any jail added without an explicit
      action); no nginx jail despite nginx being the internet-facing TLS
      terminator (Apache jail bans the proxy, not the real client IP —
      also needs `set_real_ip_from`/`real_ip_header` in nginx); duplicate
      `logpath` in `[proftpd]` silently drops `/var/log/secure`; no
      `recidive` jail. Delete the firewalld banaction file, add nginx +
      recidive jails, fix the duplicate logpath.
      ALREADY FIXED (banaction half): re-read before touching anything, as
      instructed. The shorewall→firewalld migration under #2 already resolved
      the contradiction in the opposite direction from what this finding
      proposed — instead of deleting `jail.d/00-firewalld.conf`, `jail.conf:17`
      was changed from `banaction = shorewall` to
      `banaction = firewallcmd-ipset`, so the two files now agree and every
      `action = %(banaction)s` in `jail.local` resolves to a firewalld action
      that actually exists. Deleting the jail.d file would have been a
      regression; left in place. No `action = shorewall` remains anywhere.
      FIXED (remaining three parts): `jail.local` `[proftpd]` had two
      consecutive `logpath =` lines, the second silently discarding
      `/var/log/secure` — merged into one multi-line `logpath` continuation so
      both files are watched. Added `[nginx-http-auth]`, `[nginx-botsearch]`,
      and `[nginx-limit-req]` jails (all `enabled = true`) against
      `/var/log/nginx/{error,access}.log`, with a comment noting these see the
      real client IP while the `[apache]` jail only ever sees the proxy. Added
      an `[recidive]` jail — 30d ban, 7d window, 3 strikes — watching
      `/var/log/fail2ban.log`. For the real-IP half, `nginx/nginx.conf` gained
      `set_real_ip_from 127.0.0.0/8` + `::1/128`, `real_ip_header
      X-Forwarded-For`, and `real_ip_recursive on` in the `http` block, so a
      request arriving through any loopback hop is attributed to and banned as
      the true source rather than the intermediate.
- [x] 17. Postfix `mynetworks` trusts all of `10/8`, `172.16/12`,
      `192.168/16`, malformed `fd00::/8` (should be `fc00::/7` scope) —
      `postfix/mynetworks:5-9`. Not an open relay to the internet, but any
      device on any of those private ranges can relay authenticated
      onward mail via `relayhost`. Narrow to the actual server subnet.
      FIXED in `etc/postfix/mynetworks`: reduced to `[::1]/128` + `127.0.0.0/8`.
      Dropped `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` and the malformed
      `[fd00::]/8` (which, as written, matched the whole `fd00::/8` prefix
      rather than the intended ULA `fc00::/7` scope) — rather than correcting
      it to `fc00::/7`, which would have kept an entire address class trusted,
      it is removed with the rest. The heading was updated from "loopback and
      private ranges" to "loopback only", and a comment tells the operator to
      add the actual server subnet (a single /24 or the docker bridge) here
      rather than a whole RFC1918 range. Loopback-only is the correct fail-safe
      default for a repo that deploys to unknown networks; hosts that need to
      relay for LAN clients should authenticate via submission instead.
- [x] 18. Apache emits `Access-Control-Allow-Origin: *` (incl. DELETE/PUT)
      on every vhost, a syntactically invalid `Content-Security-Policy
      "*"` (browsers discard it — zero XSS protection despite appearing
      configured), and a malformed `Header always add Header "..."`
      timing-leak line — `httpd.conf:222-227`. Remove all five lines; set
      CORS per-vhost with an explicit allowlist; write a real CSP.
      FIXED in `etc/httpd/conf/httpd.conf`: removed all four global
      `Access-Control-*` headers (the wildcard origin, the 1000s preflight
      cache, the header allowlist, and the `POST, GET, OPTIONS, DELETE, PUT`
      method list) and the malformed `Header always add Header "It took %D
      microseconds for request"` line, which both emitted a literally
      `Header`-named response header and leaked per-request service timing.
      Replaced the placeholder `Content-Security-Policy "*"` — which browsers
      discard as a parse error, so the site had zero CSP while appearing
      configured — with a real policy: `default-src 'self'`, `object-src
      'none'`, `frame-ancestors 'self'`, `base-uri 'self'`, `form-action
      'self'`, `img-src 'self' data:`, `script-src 'self'`, `style-src 'self'
      'unsafe-inline'` (inline styles kept because the shipped default-html
      pages rely on them). Also added the two headers that were simply absent,
      `X-Content-Type-Options nosniff` and `X-Frame-Options SAMEORIGIN`, plus
      `Referrer-Policy strict-origin-when-cross-origin`. `Strict-Transport-
      Security` was already correct and is unchanged. A comment in place of the
      deleted CORS block says to set `Access-Control-*` per vhost in
      `vhosts.d` against an explicit origin allowlist, never a wildcard.
- [x] 19. `ssh_config` sets `ForwardX11Trusted yes` under `Host *` — any
      compromised remote host can keylog/screenshot the local X session.
      Set `ForwardX11 no` globally; enable per-host only, never Trusted.
      FIXED in `etc/ssh/ssh_config`: the `Host *` block is now `ForwardX11 no`
      + `ForwardX11Trusted no` (both stated explicitly rather than relying on
      the compiled-in default, since a later `Host` stanza inherits whatever is
      set first). The existing "Enable X11 forwarding" comment was replaced
      with one explaining the keylog/screenshot risk and directing per-host
      opt-in via `ForwardX11 yes` alone, never `ForwardX11Trusted`. The
      neighboring `ForwardAgent no` was already correct and is unchanged.
      Server-side `X11Forwarding yes` in `sshd_config` is left as-is — it
      governs hosts connecting *in*, is untrusted-mode by default there, and is
      not what this finding describes.

## MEDIUM

- [x] 20. SELinux disabled (`selinux/config`, `sysconfig/selinux`) — set
      `enforcing` (or `permissive` first to collect denials).
      DECISION (user, 2026-09-04): keep `SELINUX=disabled` in both files.
      `pkmgr/centos/scripts/min.sh:337` and `server.sh:282` both run
      `sed -i 's|SELINUX=.*|SELINUX=disabled|g' "/etc/selinux/config"` on every
      bootstrap, forcing this state regardless of what casjay-base ships — a
      `permissive` fix here would have been silently overwritten on every
      deployed host. Given that, the user chose to match the shipped config to
      what bootstrap actually deploys rather than change pkmgr's behavior or
      remove the override. Not a functional change from the pre-audit state.
- [x] 21. Logrotate gaps against policy (rotate 0 / nocompress / monthly-
      or-size / security logs maxage 180 + 100M):
  - `logrotate.conf` global stanza + `/var/log/btmp`: no `maxsize` at
    all (time-only) — btmp is exactly the file that fills fastest under
    the brute-force exposure from #2+#14.
  - `logrotate.d/named`, `logrotate.d/munin`: no `maxsize`, no explicit
    `rotate` (inherits ok, but no size cap).
  - secure/maillog/auth.log/mail.log currently use `maxsize 100M`
    uniformly — per policy these are the security-tier logs and should
    carry `maxage 180` alongside the size cap (add `maxage 180` to
    these stanzas specifically; other logs stay rotate-0/no-maxage).
  - **No logrotate stanza exists at all** for: httpd, nginx, proftpd
    (4 logs), php-fpm, fail2ban, rsyncd, mysql, samba, tor. Add stanzas
    for each, sized 10/50/100M by verbosity, `nocompress`, `rotate 0`
    (or `maxage 180` if it's a security-relevant log per the list above).
  - `logrotate.d/munin:8` — `postrotate` restarts munin/munin-node
    unnecessarily (already using `copytruncate` on line 6); drop the
    restart, it causes a monthly monitoring outage.
  - `cron.daily/logrotate` duplicates RHEL 9's `logrotate.timer` systemd
    unit — risk of double-rotation discarding a log the first run just
    created under `rotate 0`. Pick one mechanism.
      FIXED, all six sub-items. `logrotate.conf`: added a global
      `maxsize 100M` backstop so a log that goes loud mid-month cannot fill the
      disk waiting for the monthly run, and gave `/var/log/btmp` its own
      `maxsize 100M` (it was time-only, and it is the file that fills fastest
      under brute force). The four security-tier files (`secure`, `maillog`,
      `auth.log`, `mail.log`) plus `wtmp`/`btmp` moved off `rotate 0` to
      `rotate 12` + `maxage 180` — `maxage` is a no-op alongside `rotate 0`,
      which discards the rotated copy immediately, so retaining a 180-day
      forensic window required both. `logrotate.d/named` and `logrotate.d/munin`
      gained explicit `monthly` + `maxsize 50M` + `rotate 0` + `nocompress`
      instead of inheriting with no size cap, and munin's `postrotate systemctl
      restart munin munin-node` was dropped — line 6 already sets `copytruncate`,
      so the restart bought nothing and cost a monthly monitoring outage.
      New stanzas added for every service that had none:
      `logrotate.d/{httpd,nginx,proftpd,php-fpm,fail2ban,rsyncd,mysql,samba,tor}`,
      sized 100M (httpd/nginx/mysql), 50M (proftpd/php-fpm/samba) or 10M (tor)
      by verbosity, all `nocompress`. `fail2ban`, `rsyncd` and proftpd's
      `auth.log` are security-relevant, so they take `maxage 180` + `rotate 12`
      like the tier above; the rest are `rotate 0`. Log paths were read out of
      the actual service configs in this tree, not guessed
      (`proftpd.conf:19,28,29,46,47`, `rsyncd.conf:3`, `torrc:59`,
      `samba/smb.conf:18`, `php-fpm.d/www.conf:15,17`, `nginx.conf:7,19`).
      Double-rotation: `cron.daily/logrotate` now exits 0 immediately when
      `systemctl list-unit-files logrotate.timer` succeeds, so the timer owns
      rotation on RHEL 9 and the cron entry survives only as a fallback for a
      host with no timer. Deleting it outright was rejected — on a host where
      the timer is absent that would have left no rotation at all.
      Two further defects found while verifying the above with
      `logrotate --debug`, both of which silently disabled rotation entirely
      and are fixed here rather than left for a later pass:
      (a) The stock `logrotate.d/rsyslog` shipped by the rsyslog package also
      lists `/var/log/maillog` and `/var/log/secure`, which `logrotate.conf`
      defines. logrotate treats a path defined twice as fatal and skips the
      whole second file, so on any deployed host `/var/log/{cron,messages,
      spooler}` were never being rotated at all. This tree now ships its own
      `logrotate.d/rsyslog` covering only those three, with a comment saying not
      to re-add the two that live in `logrotate.conf`.
      (b) The `secure`/`maillog`/`auth.log`/`mail.log` stanzas had no
      `postrotate` HUP, so rsyslog kept writing to the unlinked inode after
      rotation and the newly created file stayed empty — the security logs were
      effectively being discarded, not rotated. They are now one grouped stanza
      with `sharedscripts` + `systemctl -s HUP kill rsyslog.service`.
      Also dropped the `create`/`su` lines naming the `mysql` and `toranon`
      users from the two new stanzas (and did not add one to `nginx`):
      logrotate treats an unknown user as a fatal error and skips the entire
      file, so those lines would have disabled the stanza on any host without
      that service installed. `copytruncate` is used instead.
      Verified: `logrotate --debug` over `logrotate.conf` with `include`
      repointed at this tree's own `logrotate.d` reports zero errors,
      duplicates, or unknown options across all 11 files.
- [x] 22. PHP session/error hardening — `php.ini`: `display_errors = On`
      (`:33`, leaks paths/SQL/stack traces — set Off, log_errors already
      on); `session.cookie_httponly` empty (`:245` — XSS → full session
      theft, set On); no `session.cookie_secure`; `session.use_strict_mode
      = 0` (`:236` — session fixation, set 1); 6-day session lifetime
      never idle-expiring (`:242,249`); `post_max_size = 10G` /
      `upload_max_filesize = 1G` / `max_execution_time = 3600` (`:56,77,
      27` — disk-fill / worker-exhaustion DoS, reduce all three).
      FIXED in `etc/php.ini`: `display_errors = Off`, `session.use_strict_mode
      = 1` (rejects a session ID the server never issued, which is what makes
      session fixation work), `session.cookie_httponly = 1`,
      `session.cookie_secure = 1` (the directive was commented out entirely —
      every vhost in this tree is TLS-only, so there is no plain-HTTP path to
      break), and `session.cookie_samesite = Lax` added alongside as the
      matching CSRF control. Lifetimes: `session.cookie_lifetime` 525600 → `0`
      (browser-session cookie) and `session.gc_maxlifetime` 525600 → `7200`, so
      an idle session actually expires server-side after two hours instead of
      never — the old value was ~6 days on both, meaning a stolen cookie stayed
      valid for a week. Limits: `post_max_size` 10G → `128M`,
      `upload_max_filesize` 1G → `64M` (also fixing the missing space in
      `upload_max_filesize =1G`), `max_execution_time` and `max_input_time`
      3600 → `120`.
      Also fixed one file the finding did not name: `php-fpm.d/www.conf:24`
      carried `php_flag[display_errors] = on`, a per-pool override that would
      have put display_errors straight back on for every FPM request regardless
      of php.ini. Now `off`. `log_errors` was already on in both files and is
      unchanged. Grepped `php-fpm.conf`, `php-fpm.d/` and confirmed there is no
      `php.d/` in this tree, so nothing else overrides any of the above.
      ADMIN NOTE: `max_execution_time 120` and the upload caps are a real
      behavior change for any app doing large uploads or long-running imports —
      raise them per-vhost/per-pool rather than globally; comments above each
      directive say so.
- [x] 23. sysctl.conf: `send_redirects = 1` (should be 0, non-router host),
      `proxy_arp = 1` on all interfaces (ARP hijack risk), `log_martians
      = 0` (disables spoofed-packet logging) — lines 17-27. Missing
      entirely: `rp_filter`, `accept_redirects = 0`, `secure_redirects =
      0`, `accept_source_route = 0`, `net.ipv6.conf.all.accept_ra = 0`,
      `kernel.kptr_restrict`, `kernel.dmesg_restrict`. `ip_forward = 1`
      stays (needed for Docker).
      FIXED in `etc/sysctl.conf`, lines 17-27 rewritten as commented blocks.
      `log_martians` 0 → `1` (all + default), `proxy_arp` 1 → `0` (all +
      default — answering ARP for addresses this host does not own is an
      on-segment traffic-redirection primitive), and every `send_redirects`
      set to `0`. The old block also had `net.ipv4.conf.all.send_redirects = 1`
      written twice on consecutive lines (21, 22); deduplicated. Added the seven
      missing controls: `accept_redirects = 0` and `secure_redirects = 0`
      (v4 all/default, plus v6 `accept_redirects`), `accept_source_route = 0`
      (v4 and v6), `net.ipv6.conf.{all,default}.accept_ra = 0` so a rogue RA
      cannot install a default route on a statically-addressed server,
      `kernel.kptr_restrict = 2` and `kernel.dmesg_restrict = 1`.
      `rp_filter` is set to `2` (loose), not `1` (strict): this host forwards
      for Docker and may be multi-homed, and strict mode drops the return leg
      of any asymmetric path. A comment states that tradeoff. `ip_forward = 1`,
      `conf.default.forwarding = 1` and both `ipv6...forwarding = 1` lines are
      unchanged as the finding requires, and still match the `sed` patterns
      `pkmgr/centos/scripts/min.sh:785,789` rewrites them with, so bootstrap
      does not conflict with this file.
- [x] 24. Cockpit `disallowed-users` is empty (upstream ships `root`) —
      re-enables root login to the Cockpit web UI. Restore `root` to the
      file.
      FIXED: `etc/cockpit/disallowed-users` now contains `root` below the
      existing header comment, restoring the upstream default this tree had
      emptied. A comment says why — an empty file is not "no policy", it
      actively re-enables root login to the web UI — and directs the operator to
      administer as an unprivileged user and escalate. This pairs with #14's
      `PermitRootLogin prohibit-password`: without it, Cockpit was still a
      password-authenticated root entry point on port 9090.
- [x] 25. Committed placeholder passwords that deploy verbatim (not in the
      sed substitution list) — `munin/plugin-conf.d/munin-node` (mysql/
      pgsql/ldap-bindpw/squid/generic — `mysecurepassword`, `amp111`),
      `my.cnf:3` (`supersecretpassword`). Move to a gitignored
      `*.local` generated at bootstrap; add to the placeholder
      substitution list so an unsubstituted deploy fails loudly instead
      of silently shipping a known password.
      ALREADY FIXED (`my.cnf` half): re-read the live file before touching
      anything, as instructed. #7 already removed the `[client] password =
      supersecretpassword` line and replaced it with a comment pointing at a
      0600 `~/.my.cnf` or a bootstrap env file. No password remains anywhere in
      `etc/my.cnf`. Not redone.
      FIXED (munin half): all seven committed credentials in
      `etc/munin/plugin-conf.d/munin-node` — the `[*]` global `env.password`,
      `[mysql*] env.mysqlpassword`, `[postgres*] env.PGPASS`, `[slapd*]
      env.bindpw`, `[squid*] env.squidpassword`, `[asterisk_*] env.secret`
      (`amp111`, the stock FreePBX manager secret) and `[esx_*] env.pass` — are
      now the literal token `CHANGEME_AT_BOOTSTRAP`. A header comment states
      that this is a deliberately non-functional placeholder, not a working
      default, that no real credential may ever be committed to this
      world-readable public repo, and that the plugin reports nothing until the
      operator fills it in or deletes the section for a service they do not
      monitor.
      The non-functional-token route was chosen over a gitignored
      `*.local` generated at bootstrap because these are optional per-service
      monitoring credentials for services that may not be installed — there is
      nothing for bootstrap to generate them *from*, unlike `rsyncd.secrets`
      (`min.sh:1389-1394`), where the secret is self-chosen and `openssl rand`
      is the right answer. The established convention in this repo is followed
      in the half that does apply: bootstrap now says something.
      SECOND REPO TOUCHED — `pkmgr/centos/scripts/min.sh` and
      `scripts/server.sh`, munin-node section of each. Both now grep the
      installed `/etc/munin/plugin-conf.d/munin-node` for the placeholder token
      and print a `printf_yellow` warning naming the file when it is still
      present, which is the "fails loudly instead of silently shipping a known
      password" this finding asks for. Both also `chown root:munin` +
      `chmod 640` that file, since it holds credentials once filled in and was
      being deployed world-readable. `bash -n` passes on both scripts;
      script-lint still needs to run before commit.
      NOT DONE, deliberately: the placeholder was not added to the
      `find ... sed -i` substitution list at `min.sh:1078-1083`. Every entry
      there substitutes a value bootstrap can actually derive (hostname, domain,
      current IP). A password is not derivable, so a sed entry would have had to
      invent one and write it into a world-readable file — strictly worse than
      the loud warning. `snmp_* env.community public` in the same file is a
      separate weak-default issue, not a committed password, and is out of
      scope for this finding.
- [x] 26. Docker: `daemon.json` enables `ipv6`/`ip6tables` but
      `shorewall6/zones` has no `dock` zone (IPv4 has one, with
      `dock $FW REJECT`) and no `fixed-cidr-v6` is set — containers can
      get globally-routable IPv6 reachable directly from the internet,
      bypassing IPv4 port-publishing discipline. Also `"experimental":
      true` on a production host. Mirror the `dock` zone into shorewall6,
      set `fixed-cidr-v6` (ULA), drop `experimental`, add
      `"no-new-privileges": true`, `"icc": false`, `"live-restore": true`.
      ALREADY FIXED (found while closing out the LOW/INFO pass — this checkbox
      was never ticked even though the work landed earlier): `etc/docker/
      daemon.json` sets `fixed-cidr-v6` to a ULA prefix (`fd00:dead:beef::/64`,
      not globally routable), `no-new-privileges`/`icc`/`live-restore` are all
      set as prescribed, and `experimental` is absent. The shorewall6 `dock`
      zone mirror is moot — shorewall was deleted entirely (see #2) and
      replaced by `firewalld/zones/docker.xml`, which is
      `target="%%REJECT%%"` bound to `docker0` — the same default-deny
      posture the finding asked shorewall6 to provide, just via firewalld.
- [x] 27. `login.defs`: `PASS_MAX_DAYS 99999` (never expires),
      `PASS_MIN_DAYS 0`; no `pam_pwquality` config anywhere in the tree,
      so password length/complexity has no real floor given
      `PasswordAuthentication yes` on sshd (#14). Set `PASS_MAX_DAYS
      365`, `PASS_MIN_DAYS 1`, ship `/etc/security/pwquality.conf`.
      FIXED in `etc/login.defs`: `PASS_MAX_DAYS` 99999 → `365`, `PASS_MIN_DAYS`
      0 → `1` (stops a user cycling straight back to the old password to defeat
      history), `PASS_WARN_AGE` 7 → `14`, and `PASS_MIN_LEN` 8 → `14` for
      consistency — with a comment noting PAM ignores `PASS_MIN_LEN` on RHEL, so
      it is the pwquality file below that actually enforces length.
      `ENCRYPT_METHOD SHA512` and `UMASK 077` were already correct and are
      unchanged.
      New file `etc/security/pwquality.conf` (the `etc/security/` directory did
      not exist in this tree at all): `minlen = 14`, one required character from
      each of the four classes (`dcredit`/`ucredit`/`lcredit`/`ocredit = -1`
      plus `minclass = 4`), `maxrepeat`/`maxclassrepeat` to reject runs,
      `usercheck`/`gecoscheck`/`dictcheck` on, `difok = 5`, and
      `enforce_for_root` so a root password set non-interactively during a
      bootstrap run is held to the same floor. Every directive carries a comment
      above it explaining what it buys.
      NOTE on the finding's framing: it justifies this by
      `PasswordAuthentication yes` on sshd, but #14 has since set that to `no`,
      so this no longer guards remote SSH. It still matters — console and
      recovery logins, `su`, Cockpit (now root-blocked by #24 but still password
      auth for other users), proftpd, and samba all authenticate against these
      passwords. Fixed on that basis, not the original one.
      ADMIN NOTE: `PASS_MAX_DAYS 365` only applies to accounts created after
      this deploys; existing accounts keep their current aging until
      `chage -M 365 <user>` is run against them.
- [x] 28. Expired private-CA anchor in system trust store —
      `pki/ca-trust/source/anchors/CasjaysDev.crt`, expired ~2024-04-09.
      Remove; the CA's private key is not in this repo (checked), so no
      compromise, just dead/silently-breaking trust. If a private CA is
      still needed, regenerate fresh and keep the key offline.
      FIXED: deleted `etc/pki/ca-trust/source/anchors/CasjaysDev.crt`. Verified
      against the file rather than the finding text before removing it —
      `openssl x509` confirms a self-signed `CN=Casjays Developments` valid
      `2014-04-12` to `2024-04-09`, so it has been dead for over two years and
      `update-ca-trust` was silently importing an expired anchor on every
      bootstrap. Grepped the whole tree: nothing in `casjay-base/centos`
      referenced it by name, so removing it breaks no config.
      No replacement is needed and none was added. The finding's "if a private
      CA is still needed" is already answered elsewhere in this tree:
      `etc/ssl/CA/CasjaysDev/certs/ca.crt` is a *different*, current CA
      (`CN=casjaysdev.com`, valid to 2031-11-18), and
      `pkmgr/*/scripts/min.sh` already copies that one into
      `/etc/pki/ca-trust/source/anchors/` at bootstrap. The expired file was
      simply a stale leftover from the previous CA generation, not the anchor
      anything actually uses. The `anchors/` directory is now empty in git,
      which is fine — bootstrap recreates and populates it on the host.

## LOW / INFO

- [x] 29. `ServerSignature EMail` leaks an email address on every Apache
      error page, contradicts `ServerTokens Prod` — set `Off`.
      FIXED: `httpd/conf/httpd.conf:114` is now `ServerSignature Off`.
- [x] 30. `/health/apache` uses deprecated `Order Deny,Allow` syntax —
      migrate to `Require ip` (mod_access_compat still works but is
      legacy); note RFC1918 isn't a real trust boundary here given #6.
      FIXED: the `<Location /health/apache>` block now uses a single
      `Require ip 127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16`
      in place of the `Order`/`Deny`/`Allow` trio. Same deprecated 2.2
      syntax in `httpd/conf.d/autoindex.conf` (the `.hta*` `<Files>`
      block, `order allow,deny` + `deny from all`) was converted to
      `Require all denied` in the same pass — identical mechanical fix in
      a file already open for #32. A third instance found by grep,
      `httpd/conf.d/errors.conf:18-19` (`Order allow,deny` +
      `Allow from all` on the `default-error` directory), became
      `Require all granted` — semantically identical, no access change.
      `httpd/conf.d/` is now free of 2.2 `Order`/`Allow`/`Deny` syntax.
      RFC1918-is-not-a-trust-boundary caveat is unchanged and still
      stands.
- [x] 31. `SSLProxyCheckPeerName/CN/Expire off` disables cert validation
      for all outbound mod_proxy HTTPS — low impact today (loopback-ish
      target) but MITM-able for any future proxy target.
      FIXED: all three flipped to `on` in `httpd/conf/httpd.conf`, with a
      comment noting that a vhost needing a self-signed backend overrides
      them per-vhost. BEHAVIOR CHANGE ON DEPLOYED HOSTS: any existing
      `mod_proxy` HTTPS target whose certificate does not validate (self-
      signed, wrong CN, or expired) will now fail instead of silently
      proceeding. The nginx→apache loopback path in `nginx/global.d/*`
      proxies to `https://apache/...`, so if that upstream presents the
      committed self-signed cert under a non-matching name it will need a
      per-vhost `SSLProxyCheckPeerName off` (or a matching cert) after
      this lands.
- [x] 32. `Options Indexes` on shared asset paths + `~/Public/html` —
      directory listing enabled broadly; low value alone but consistent
      with #10's posture problem.
      FIXED: `Indexes` dropped from all seven `/usr/local/share/httpd/
      default-*` blocks in `httpd/conf.d/autoindex.conf`, from
      `/home/*/Public/html` in `httpd/conf.d/userdir.conf`, and from the
      `/var/www` and `/var/www/html` blocks in `httpd/conf/httpd.conf`.
      The mod_autoindex theming (`IndexOptions`, `AddIcon`,
      `IndexStyleSheet`) is left in place — it is inert unless a vhost
      opts back in with `Options +Indexes`, which is now the explicit
      per-vhost decision it should have been. BEHAVIOR CHANGE: paths that
      relied on an implicit directory listing (a `default-*` asset dir or
      a user's `~/Public/html` with no index file) now return 403.
- [x] 33. No `server_tokens off;` in nginx.conf (version disclosure); no
      HSTS observed at the nginx layer specifically (Apache sets one
      behind it — verify it actually reaches the client through the
      double-TLS-termination setup).
      FIXED (tokens) / VERIFIED (HSTS): `server_tokens off;` added to the
      `http` block in `nginx/nginx.conf`. The HSTS half was a false alarm
      — `nginx/global.d/nginx-defaults.conf:96` already sets
      `add_header Strict-Transport-Security "max-age=31536000;
      includeSubDomains" always;` and every vhost includes `global.d/*`,
      so nginx emits its own HSTS to the client and does not depend on
      Apache's header surviving the double termination.
- [x] 34. `named.conf` uses `dnssec-enable`/`dnssec-lookaside`/
      `bindkeys-file`, all removed in BIND 9.16+ (RHEL 9 ships 9.16) —
      named will fail to start. Access controls (`listen-on 127.0.0.1`,
      `allow-query localhost`) are correct — not an open resolver.
      FIXED: `named/named.conf` drops `dnssec-enable`,
      `dnssec-lookaside` and `bindkeys-file`, keeping
      `dnssec-validation yes` (backed by the existing
      `include "/etc/named/root.key"`) and `managed-keys-directory`,
      both still valid in 9.16+. Access controls untouched.
- [x] 35. `dnf.conf`: `skip_if_unavailable=True` can silently skip
      security updates from a failing repo; `localpkg_gpgcheck` unset
      (defaults off) — locally-installed RPMs bypass signature checks.
      FIXED: `skip_if_unavailable=False` and `localpkg_gpgcheck=1` in
      `dnf/dnf.conf`. BEHAVIOR CHANGE ON DEPLOYED HOSTS: a transiently
      unreachable or broken repo now makes the whole dnf transaction fail
      loudly instead of quietly proceeding without it, and an unsigned or
      wrongly-signed local `.rpm` installed with `dnf install ./foo.rpm`
      is now refused — both intended, but both will surface as new
      failures on hosts that were relying on the silent path.
- [x] 36. `resolv.conf` hardcodes a specific third-party resolver IP
      (`82.29.128.43`) alongside 1.1.1.1/8.8.8.8 — baked into a public
      repo; will silently become someone else's server if reassigned.
      FIXED: `82.29.128.43` removed; `resolv.conf` now ships only
      1.1.1.1 and 8.8.8.8. A stray blank line at EOF was cleaned up at
      the same time (single trailing newline). Note `cron.d/
      update-resolver` runs `update-resolv.sh` from `root/.local/bin/`,
      which is in the unreviewed set below — if that script re-adds a
      hardcoded resolver at runtime this fix is cosmetic until that
      script is reviewed too.
- [x] 37. `profile`/`bashrc` set `umask 002` (UPG convention) vs
      `login.defs UMASK 077` — standard RHEL behavior but worth a
      conscious decision; 002 means group-writable files by default.
      DECISION: keep as-is. Re-read of `profile:51-55` and
      `bashrc:56-60` shows both use the stock RHEL user-private-group
      conditional — `if [ $UID -gt 199 ] && [ "$(id -gn)" = "$(id -un)" ]`
      — so `002` applies only when the user's primary group is their own
      private group (group-writable to nobody but themselves); every
      other account, including system accounts and any user in a shared
      primary group, gets `022`. That is the upstream `setup` package
      behavior verbatim, not a local weakening, and `login.defs UMASK
      077` governs `useradd` home-directory creation, a different code
      path. No change made; tightening to 077 here would diverge from
      stock RHEL and break UPG collaboration without a real gain.
- [x] 38. `cron.d/yum-update` unattended daily `yum update -y` gated on
      `ping google.com` — availability risk (unreviewed updates), and the
      ping-as-connectivity-check fails closed on ICMP-blocking networks.
      FIXED: `cron.d/yum-update` is now
      `0 2 * * * root dnf -y --security upgrade >/dev/null 2>&1`. The
      ICMP gate is gone (dnf fails on its own when repos are
      unreachable, and ping is blocked on plenty of otherwise-online
      networks). BEHAVIOR CHANGE ON DEPLOYED HOSTS: the nightly job now
      applies only security errata instead of every available update —
      deliberately narrower, since a full unattended `update -y` was the
      availability risk this finding names. Non-security updates are
      still covered by the separate `cron.d/run-os-update` job at 4am.
- [x] 39. `proftpd.d/tls.conf`: `TLSOptions NoSessionReuseRequired`
      weakens control/data-channel binding — fix alongside #15.
      FIXED: re-read the current file after #15's `TLSRequired on` /
      `TLSProtocol TLSv1.2 TLSv1.3` changes — the `TLSOptions
      NoSessionReuseRequired` line was still present and untouched by
      that pass. The line is now removed entirely, restoring proftpd's
      default requirement that the data connection reuse the control
      connection's TLS session. BEHAVIOR CHANGE ON DEPLOYED HOSTS: FTPS
      clients that open the data channel with a fresh TLS session (some
      older or load-balanced clients) will be rejected; that rejection is
      the control this finding asks for, so the fix is a tighten, not a
      workaround.
- [x] 40. Committed 1024-bit DH param file (`ssl/dhparam/1024.pem`) —
      unused (4096-bit one is referenced instead) but should be deleted;
      1024-bit DH is within reach of precomputation attacks (Logjam).
      FIXED: confirmed with `openssl dhparam -text -noout` that the file
      really was 1024-bit, and that nothing in the repo references it
      (`httpd.conf:217` uses `/etc/ssl/dhparam/httpd.pem`, itself 4096-
      bit). `etc/ssl/dhparam/1024.pem` deleted. No regeneration needed —
      2048.pem and 4096.pem already ship. Deleting the committed file
      alone was not sufficient: `root/.local/bin/root_dhparams.sh:33`
      regenerated a fresh `1024.pem` into `$DHDIR` every Tuesday via
      `cron.d/dhparam`, so that generation line was removed too (this is
      a `.sh` change — run script-lint before committing). NOTE, not
      fixed, needs a decision: the same script's last line collapses
      `apache/nginx/postfix/proftpd/httpd.pem` to a copy of the 2048-bit
      params, so a deployed host ends up with 2048-bit `httpd.pem` while
      this repo ships a 4096-bit one. Not a Logjam-class weakness and out
      of scope for #40, but the repo and the host disagree.
- [x] 41. php-fpm `www.conf` is mostly correct (loopback-bound, allowed
      clients restricted, clear_env yes) — only `display_errors = on`
      needs to flip per #22; `pm.status_path`/`ping.path` aren't
      currently exposed by any vhost.
      ALREADY FIXED by #22: `php-fpm.d/www.conf:26` is
      `php_flag[display_errors] = off` with the explanatory comment from
      that pass above it, and `php.ini:41` is `display_errors = Off`.
      Re-confirmed `pm.status_path = /status` / `ping.path = /ping` are
      still not routed by any vhost or `global.d` location. No change
      needed this pass.
- [x] 42. `certbot/dns.conf` `dns_rfc2136_secret` is empty (no committed
      secret) — flag only that deployed file mode should be 0600; repo/
      rsync overlay doesn't appear to enforce per-file modes.
      DECISION: confirmed safe, documented rather than changed. The
      committed value really is empty (`dns_rfc2136_secret =` with no
      value) — a template, not a leaked credential, so
      `sensitive_data.md` is satisfied as-is and this repo needs no
      plaintext-credential exception. The 0600 concern is also already
      handled outside this repo: `pkmgr/centos/scripts/min.sh:1283-1284`,
      `server.sh:1104-1105` and `scripts/template:366` all
      `chmod 600 /etc/certbot/dns.conf` at bootstrap, and min.sh:1026 /
      server.sh:891 drop the file from the overlay temp dir so a host's
      filled-in secret is never overwritten by the empty template. Only
      change made here: trailing whitespace stripped and a comment added
      stating the empty secret is deliberate and that pkmgr enforces the
      mode.

## Not reviewed — follow-up needed

- `root/`, `usr/`, `var/` in this same repo — `usr/` and
  `root/.local/bin/` hold the actual scripts invoked by every `cron.d`
  entry (`run-os-update`, `process-check.sh`, `clean-system`,
  `update-resolv.sh`, `root_certbot.sh`), all running as root. Unreviewed;
  this is where finding #9's actual downloaded payload lives.
- `pkmgr/centos/scripts/min.sh` and `casjay-base/sync.sh` — not read for
  this pass; `sync.sh` decides how every finding above gets rewritten for
  the other 6 distros, so a per-distro re-check is needed after fixes land.
- File modes/ownership on deploy — this repo can't express them; several
  findings (#1 key files, #7 my.cnf, #25 plugin-conf.d, #42 certbot)
  depend on deployed permissions the repo alone can't guarantee.
- The other six distro trees were assumed to mirror these findings but
  were not independently checked — in particular whether the committed
  private key (#1) exists in all seven trees.
- Git history was not audited beyond confirming the key's commit
  (`42a5ace3f005`) — run `gitleaks --log-opts=--all` before remediation
  since the repo is public and history already leaked once.
- Not individually examined: `httpd/conf.modules.d/*`, `httpd/conf/magic`,
  most `shorewall*/` non-policy files, `postfix/` map files (canonical/
  transport/virtual/relocated/mydomains*), `skel/.config/bash/**` beyond
  umask, `ntp.conf`/`chrony.conf`, `webalizer.conf`, `vnstat.conf`,
  `uptimed.conf`, `tmpfiles.d/*`, `fail2ban/action.d/shorewall*.conf`,
  `fail2ban/filter.d/fail2ban.conf`, `fail2ban/ips.txt`.
- No runtime host was inspected — all findings are static-config only.
