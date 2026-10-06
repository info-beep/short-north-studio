#!/usr/bin/env bash
# Checks that email authentication records are live in public DNS.
# Usage: ./check-dns.sh [sending-domain] [dkim-selector]
#   ./check-dns.sh sunstudiotan.com
#   ./check-dns.sh sunstudiotan.com acumbamail   # selector comes from the Acumbamail panel
set -u

DOMAIN="${1:-sunstudiotan.com}"
SELECTOR="${2:-}"
ROOT="$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')"

if ! command -v dig >/dev/null 2>&1; then
  echo "dig not found. On Mac it's built in; on Linux install dnsutils/bind-utils." >&2
  exit 1
fi

ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m✘\033[0m %s\n' "$1"; }
txt()  { dig +short TXT "$1" @1.1.1.1 | tr -d '"'; }

echo "== SPF ($DOMAIN)"
spf="$(txt "$DOMAIN" | grep -i '^v=spf1' || true)"
count="$(printf '%s' "$spf" | grep -c 'v=spf1' || true)"
if [ -z "$spf" ]; then bad "No SPF record"
elif [ "$count" -gt 1 ]; then bad "Multiple SPF records. Merge into ONE:"; echo "$spf" | sed 's/^/     /'
else ok "$spf"; fi

echo "== DMARC (_dmarc.$DOMAIN)"
dmarc="$(txt "_dmarc.$DOMAIN" | grep '^v=DMARC1' || true)"
[ -n "$dmarc" ] && ok "$dmarc" || bad "No DMARC record on _dmarc.$DOMAIN"

if [ "$ROOT" != "$DOMAIN" ]; then
  echo "== DMARC (_dmarc.$ROOT)"
  rd="$(txt "_dmarc.$ROOT" | grep '^v=DMARC1' || true)"
  [ -n "$rd" ] && ok "$rd" || bad "No DMARC record on _dmarc.$ROOT (recommended)"
fi

echo "== DKIM"
if [ -n "$SELECTOR" ]; then
  d="$(dig +short TXT "$SELECTOR._domainkey.$DOMAIN" @1.1.1.1; dig +short CNAME "$SELECTOR._domainkey.$DOMAIN" @1.1.1.1)"
  [ -n "$d" ] && ok "$SELECTOR._domainkey.$DOMAIN found" || bad "Nothing at $SELECTOR._domainkey.$DOMAIN"
else
  echo "  (pass the DKIM selector from Acumbamail as the 2nd argument to check it)"
fi

echo "== MX ($ROOT), where replies to hello@ go"
mx="$(dig +short MX "$ROOT" @1.1.1.1)"
[ -n "$mx" ] && ok "$(echo "$mx" | tr '\n' ' ')" || bad "No MX on $ROOT. Reply-To inbox won't receive mail"
