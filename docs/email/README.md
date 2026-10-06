# Sun Studio Tan — Email Comeback Runbook

Four phases, in order. **Don't skip ahead.** Each phase ends with a go/no-go gate. If you fail a gate, fix it before moving on. Sending to a dirty list from a domain that isn't authenticated is what caused the "horrible" results in the first place.

| Phase | What | Time | Gate to pass |
|---|---|---|---|
| 1 | Authenticate the domain (SPF, DKIM, DMARC) | ~30 min + up to 48h DNS wait | Acumbamail shows the domain as verified |
| 2 | Test before sending | ~20 min | mail-tester ≥ 9/10, no spam folder at Gmail/Outlook/Yahoo |
| 3 | Clean the list | ~1 hr + verification run | Invalid/risky addresses removed |
| 4 | Send to 500 Active contacts | 1 send + 7 days of tracking | Bounces < 2%, complaints < 0.1% |

---

## Phase 1 — Authenticate the domain

### Decision: root domain or subdomain?

| Option | From address | Pros | Cons |
|---|---|---|---|
| A. Subdomain | `hello@mail.sunstudiotan.com` | If marketing email ever gets a bad reputation, your everyday mail (receipts, Vagaro, 1:1 replies) on `sunstudiotan.com` isn't affected | The address looks slightly less clean |
| **B. Root domain (recommended)** | `hello@sunstudiotan.com` | Cleanest look, and it's already verified in Acumbamail | Marketing reputation and business mail share one domain |

**Go with B.** `sunstudiotan.com` is already verified in Acumbamail. At your sending volume, the reputation protection a subdomain gives you isn't worth the setup.

> ⚠️ **Why the subdomain stalls:** Acumbamail verifies a sender by emailing it. `mail.sunstudiotan.com` has no inbox (no MX record), so that verification email has nowhere to land and never arrives. If you ever want a subdomain anyway, it needs its own MX records or forwarding first.

### Step 1.1 — Find your DNS host

DNS lives wherever your domain's **nameservers** point. That isn't always where you bought the domain.
- Bought or connected through **Wix** with Wix nameservers → **Wix → Domains → ⋯ → Manage DNS Records**
- Otherwise check the registrar (GoDaddy, Porkbun, Squarespace, etc.), or Cloudflare if nameservers point there.
- Not sure? Look up `sunstudiotan.com` at https://lookup.icann.org. The "Name Servers" line tells you where DNS is hosted.

### Step 1.2 — Add the domain in Acumbamail

1. Acumbamail → **Account / Settings → Sender domains** (also listed as *Authenticate domain* / *Dominios*).
2. Use `sunstudiotan.com` (already verified). Make sure its SPF/DKIM authentication shows as passing, not just the sender verification.
3. Acumbamail will show you the exact **SPF** and **DKIM** records. **Copy them exactly from the panel.** Don't copy values from blog posts or old screenshots. They're account-specific and they change.

### Step 1.3 — Add the records at your DNS host

Use the values Acumbamail gave you. The general shape:

| Type | Host / Name | Value | Notes |
|---|---|---|---|
| TXT | `@` | `v=spf1 include:<acumbamail-spf-host> ~all` | SPF. Exact include comes from Acumbamail |
| TXT or CNAME | `<selector>._domainkey` | *(DKIM key/target from Acumbamail)* | DKIM. Paste exactly, no spaces or line breaks added |
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc@sunstudiotan.com; fo=1` | DMARC. Add only if one doesn't already exist |

**SPF rules that trip people up:**
- **Only ONE SPF record per hostname.** If `sunstudiotan.com` already has `v=spf1 ...` (e.g. for Google Workspace), *don't add a second one*. Merge them into one record: `v=spf1 include:_spf.google.com include:<acumbamail-spf-host> ~all`. 
- Max 10 DNS lookups per SPF record. If you're stacking 5+ `include:`s, ask before adding more.

**DNS panel quirks:**
- Most panels (Wix, GoDaddy) automatically add the domain to the end of the Host field. Enter `_dmarc`, not `_dmarc.sunstudiotan.com.sunstudiotan.com`.
- Create `dmarc@sunstudiotan.com` as a mailbox or alias, or use a free DMARC report reader (e.g. Postmark's free DMARC digests, dmarcian, EasyDMARC). They give you an address to use in `rua=` instead. Raw DMARC reports are unreadable XML attachments.

### Step 1.4 — Verify

- Wait 15 min to 48 h, then click **Verify** in Acumbamail.
- Run `./check-dns.sh sunstudiotan.com` from this folder (needs `dig`, built into Mac). It confirms SPF and DMARC are live.
- Set the sender in Acumbamail: **From name** `Sun Studio Tan` · **From** `hello@sunstudiotan.com` · **Reply-To** `hello@sunstudiotan.com`.
- **Never** send from Acumbamail's shared default address or from a `@gmail.com` address.

### DMARC: the road to enforcement (later, not now)

`p=none` = monitor only. Nothing gets blocked. After **4–6 weeks** of reports showing your real senders (Acumbamail, Google/Outlook, Vagaro if it sends as you) all passing:
1. `p=quarantine; pct=25` → then `pct=100`
2. Eventually `p=reject`

Skipping to `reject` before reviewing reports is how your Vagaro confirmations quietly vanish.

✅ **Gate 1:** Acumbamail shows the domain as **verified** (SPF ✓, DKIM ✓) and the DMARC record resolves.

---

## Phase 2 — Test before sending anything

### Step 2.1 — mail-tester.com
1. Go to https://www.mail-tester.com. It gives you a one-time address.
2. In Acumbamail, send the **actual comeback email** (`comeback-email.md`) to that address as a test. Use the real template, not a "test 123."
3. Click **Then check your score**.

| Score | Action |
|---|---|
| **9–10** | ✅ Go |
| 7–8.9 | Fix what it flags (usually: missing DKIM, an image-only email, a broken link, or a blacklisted link shortener) |
| < 7 | Stop. Authentication is broken. Back to Phase 1 |

The free tier allows about 3 tests a day, so fix everything before retesting.

### Step 2.2 — Seed inbox test
Send the same test to your own:

| Inbox | Where it landed | OK? |
|---|---|---|
| Gmail | Primary / Promotions / Spam | Primary or **Promotions** = fine. Spam = fail |
| Outlook / Hotmail | Inbox / Other / Junk | Inbox or Other = fine. Junk = fail |
| Yahoo / AOL | Inbox / Spam | Inbox = fine |
| iPhone Mail (any) | Check on a phone | Images load? Button tappable? |

In Gmail, open the message → **⋮ → Show original**. You want `SPF: PASS`, `DKIM: PASS`, `DMARC: PASS`. Anything else means Phase 1 isn't done.

### Step 2.3 — Compliance must-haves (Gmail/Yahoo/Microsoft bulk-sender rules)
- [ ] One-click unsubscribe enabled (Acumbamail adds this to campaigns; confirm the link works)
- [ ] Physical address in the footer: **612 N High St, Columbus, OH 43215**
- [ ] Every link works and points to the right page
- [ ] Mostly text, not one giant image
- [ ] No link shorteners (bit.ly etc.). They're spam-filter catnip

✅ **Gate 2:** mail-tester ≥ 9, no spam/junk placement at Gmail, Outlook, or Yahoo, and all three auth checks PASS.

---

## Phase 3 — Clean the list

### Step 3.1 — Export and pre-clean
1. Export contacts from Acumbamail (and Vagaro if that's the source) to CSV.
2. Remove anyone who **unsubscribed** or **hard-bounced** on previous sends. They never come back in.
3. Remove obvious junk: duplicates, `test@`, typos like `@gmial.com`, and blanks.

### Step 3.2 — Verify with NeverBounce or ZeroBounce
- Pick one. Both charge per email checked, with bulk discounts. **Check their pricing pages for current rates.** ZeroBounce has historically offered a small batch of free monthly credits, so test it with a sample first.
- Upload the CSV and run the bulk verification.

### Step 3.3 — What to do with each result

| Result (NeverBounce / ZeroBounce label) | Action |
|---|---|
| Valid | ✅ Keep |
| Invalid | ❌ Delete |
| Disposable | ❌ Delete |
| Spamtrap / Abuse / Do-not-mail | ❌ Delete. These wreck your reputation |
| Catch-all / Accept-all | ⏸️ Hold. Not in the first sends. Add them after the domain has 3+ clean sends |
| Unknown | ⏸️ Hold (same as catch-all) |
| Role-based (`info@`, `office@`) | ⏸️ Hold. Low value, higher complaint risk |

### Step 3.4 — Bucket the cleaned list
Using Vagaro visit history:
- **Active**: visited in the last 12 months (← Phase 4 starts here)
- **Lapsed**: 12–24 months
- **Cold**: 24+ months or never booked. Consider never emailing these. Their engagement is closer to a coin flip on spam reports

Re-import into Acumbamail as separate lists or tagged segments.

✅ **Gate 3:** Invalid, disposable, and spamtrap addresses are gone, and the Active bucket is built from **Valid** results only.

---

## Phase 4 — Send the comeback to 500 Active contacts

### Step 4.1 — Build the slice
- Pick **500 random** contacts from the Active (Valid) bucket. Sort by a random column in Sheets (`=RAND()`), take the top 500. Don't just pick your "best" clients. You want an honest read.
- Optional A/B: 250 get subject A, 250 get subject B (see `comeback-email.md`).

### Step 4.2 — Set up tracking (this is how you judge it)
**Opens are not the metric.** Apple Mail Privacy Protection pre-loads images, so many iPhone users "open" without ever reading. Judge on:

| Metric | How to get it | What "good" looks like for a comeback send |
|---|---|---|
| **Click rate** (clicks ÷ delivered) | Acumbamail report | 2–5%+ is solid for a win-back |
| **Bookings** | Unique promo code `COMEBACK` in Vagaro + bookings from people on the 500 list within 7 days | The number that matters. Even 5–10 bookings from 500 is a real win |
| **Bounce rate** | Acumbamail report | < 2%. Over that means the list still isn't clean |
| **Spam complaint rate** | Acumbamail report | < 0.1%. Over 0.3% and Gmail starts filtering you |
| **Unsubscribe rate** | Acumbamail report | < 0.5% is fine. Unsubscribes are healthy; complaints are not |

- Add UTM tags to every link: `?utm_source=acumbamail&utm_medium=email&utm_campaign=comeback_2026`
- Vagaro may not carry UTMs into its booking reports, so **the promo code is your source of truth.** Create it in Vagaro *before* sending.
- After 7 days: export Vagaro bookings, match the emails against the 500-person slice, and count them. That's your real conversion.

### Step 4.3 — Send timing
- Tuesday–Thursday, around 10 am or 7 pm ET.
- Send from Acumbamail at the scheduled time. Don't resend to non-openers (the open data is unreliable anyway).

### Step 4.4 — Ramp-up rules (after the 500 send)

| If the 500 send shows… | Next move |
|---|---|
| Bounces < 2%, complaints < 0.1% | Next send: ~1,000 more Active. Then roughly double each send, 2–3 days apart, until Active is fully covered |
| Bounces 2–5% | Pause. Re-verify the list and check that Hold buckets didn't leak in |
| Complaints ≥ 0.1% | Pause. The audience is too cold or the email reads like spam. Tighten to the last 6 months |
| mail-tester score drops / Gmail starts hitting spam | Stop. Recheck auth (`check-dns.sh`, Gmail "Show original") |

Lapsed goes **after** all Active contacts are sent cleanly, starting with a slice of 500 again.

✅ **Gate 4:** Clean metrics on the 500, with bookings counted from the promo code. Ramp up.

---

## Files in this folder
- `README.md`: this runbook
- `comeback-email.md`: ready-to-paste comeback email (subjects, preheader, body, plain-text version)
- `check-dns.sh`: one-command check that SPF/DMARC/MX are live
