#!/usr/bin/env bash
# Checks that email authentication records are live in public DNS.
# Usage: ./check-dns.sh [sending-domain] [dkim-selector] [root-domain]
#   ./check-dns.sh sunstudiotan.com
#   ./check-dns.sh sunstudiotan.com acumbamail   # selector comes from the Acumbamail panel
# root-domain defaults to the last two labels; pass it for domains like example.co.uk
set -u

DOMAIN="${1:-sunstudiotan.com}"
SELECTOR="${2:-}"
ROOT="${3:-$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')}"

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
rd=""
if [ "$ROOT" != "$DOMAIN" ]; then
  rd="$(txt "_dmarc.$ROOT" | grep '^v=DMARC1' || true)"
fi
if [ -n "$dmarc" ]; then ok "$dmarc"
elif [ -n "$rd" ]; then ok "None on $DOMAIN; inherits _dmarc.$ROOT: $rd"
else bad "No DMARC record on _dmarc.$DOMAIN$( [ "$ROOT" != "$DOMAIN" ] && echo " or _dmarc.$ROOT")"; fi

echo "== DKIM"
if [ -n "$SELECTOR" ]; then
  # dig follows a CNAME and prints the target's TXT; long keys come back as several quoted chunks
  d="$(dig +short TXT "$SELECTOR._domainkey.$DOMAIN" @1.1.1.1 | tr -d '"' | tr '\n' ' ')"
  if printf '%s' "$d" | grep -Eq '(^|[; ])p=[^; ]+'; then ok "$SELECTOR._domainkey.$DOMAIN has a DKIM key"
  else bad "No usable DKIM key (non-empty p=) at $SELECTOR._domainkey.$DOMAIN"; fi
else
  echo "  (pass the DKIM selector from Acumbamail as the 2nd argument to check it)"
fi

echo "== MX ($DOMAIN), where replies to hello@$DOMAIN go"
mx="$(dig +short MX "$DOMAIN" @1.1.1.1)"
[ -n "$mx" ] && ok "$(echo "$mx" | tr '\n' ' ')" || bad "No MX on $DOMAIN. An inbox at this domain can't receive mail"
