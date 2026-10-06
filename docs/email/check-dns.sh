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
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m✘\033[0m %s\n' "$1"; }

# One TXT record per line, with multi-string chunks ("abc" "def") joined back together.
# CNAME targets that dig prints along the way are dropped (they aren't quoted).
txt() { dig +short TXT "$1" @1.1.1.1 | grep '^"' | sed -E 's/"[[:space:]]+"//g; s/"//g'; }
# Strip whitespace around tag separators so "v = DMARC1 ; p = none" reads as "v=DMARC1;p=none".
norm() { sed -E 's/[[:space:]]*([=;])[[:space:]]*/\1/g; s/^[[:space:]]+//'; }
lines() { [ -z "$1" ] && echo 0 || printf '%s\n' "$1" | wc -l | tr -d ' '; }

echo "== SPF ($DOMAIN)"
spf="$(txt "$DOMAIN" | grep -iE '^v=spf1([[:space:]]|$)' || true)"
case "$(lines "$spf")" in
  0) bad "No SPF record" ;;
  1) ok "$spf" ;;
  *) bad "Multiple SPF records. Receivers treat this as an error. Merge into ONE:"; echo "$spf" | sed 's/^/     /' ;;
esac

# Exactly one v=DMARC1 record counts; zero or several means no usable policy at that name.
dmarc_at() { txt "_dmarc.$1" | norm | grep -E '^v=DMARC1(;|$)' || true; }
echo "== DMARC (_dmarc.$DOMAIN)"
dmarc="$(dmarc_at "$DOMAIN")"
case "$(lines "$dmarc")" in
  1) ok "$dmarc" ;;
  0)
    if [ "$ROOT" = "$DOMAIN" ]; then bad "No DMARC record on _dmarc.$DOMAIN"
    else
      rd="$(dmarc_at "$ROOT")"
      case "$(lines "$rd")" in
        1) ok "None on $DOMAIN; inherits _dmarc.$ROOT: $rd" ;;
        0) bad "No DMARC record on _dmarc.$DOMAIN or _dmarc.$ROOT" ;;
        *) bad "Multiple DMARC records on _dmarc.$ROOT. Receivers ignore all of them. Keep ONE" ;;
      esac
    fi ;;
  *) bad "Multiple DMARC records on _dmarc.$DOMAIN. Receivers ignore all of them. Keep ONE:"; echo "$dmarc" | sed 's/^/     /' ;;
esac

echo "== DKIM"
if [ -n "$SELECTOR" ]; then
  # dig follows a CNAME on its own; the key's p= value may contain folding whitespace.
  key="$(txt "$SELECTOR._domainkey.$DOMAIN" | norm | grep -oE '(^|;)p=[^;]*' | head -1 | sed -E 's/^;?p=//' | tr -d '[:space:]')"
  if [ -z "$key" ]; then bad "No usable DKIM key (non-empty p=) at $SELECTOR._domainkey.$DOMAIN"
  elif printf '%s' "$key" | grep -Eq '^[A-Za-z0-9+/]+={0,2}$'; then ok "$SELECTOR._domainkey.$DOMAIN has a DKIM key"
  else bad "DKIM key at $SELECTOR._domainkey.$DOMAIN isn't valid base64. Re-copy it from Acumbamail"; fi
else
  echo "  (pass the DKIM selector from Acumbamail as the 2nd argument to check it)"
fi

echo "== MX ($DOMAIN), where replies to hello@$DOMAIN go"
mx="$(dig +short MX "$DOMAIN" @1.1.1.1)"
if [ -n "$mx" ]; then ok "$(echo "$mx" | tr '\n' ' ')"
elif [ -n "$(dig +short A "$DOMAIN" @1.1.1.1; dig +short AAAA "$DOMAIN" @1.1.1.1)" ]; then
  warn "No MX on $DOMAIN. Mail falls back to its A/AAAA address, which usually isn't a mail server. Add MX records for your inbox"
else bad "No MX, A, or AAAA record on $DOMAIN. An inbox at this domain can't receive mail"; fi
