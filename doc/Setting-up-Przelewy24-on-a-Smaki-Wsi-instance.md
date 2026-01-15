# Setting up Przelewy24 on a Smaki Wsi instance

## Table of contents

- [Before you begin](#before-you-begin)
- [Intro to Przelewy24](#intro-to-przelewy24)
- [Instructions](#instructions)
  - [Step 1. Create a Przelewy24 account](#step-1-create-a-przelewy24-account)
  - [Step 2. Collect API credentials](#step-2-collect-api-credentials)
  - [Step 3. Configure callbacks](#step-3-configure-callbacks)
  - [Step 4. Configure your Smaki Wsi instance](#step-4-configure-your-smaki-wsi-instance)
  - [Step 5. Provision and restart](#step-5-provision-and-restart)
  - [Step 6. Verify payment methods in admin](#step-6-verify-payment-methods-in-admin)
  - [Step 7. Assign methods to an enterprise](#step-7-assign-methods-to-an-enterprise)
  - [Step 8. Enable in order cycle](#step-8-enable-in-order-cycle)
  - [Step 9. Place a test order](#step-9-place-a-test-order)
- [Testing on Vagrant (local only)](#testing-on-vagrant-local-only)

## Before you begin
This is a walkthrough for setting up Przelewy24 on a Smaki Wsi instance. You will need access to
the P24 merchant panel, and SSH access to the server (or Vagrant + Ansible for local setup).

## Intro to Przelewy24
The integration uses the Przelewy24 REST API with a redirect flow:

- Smaki Wsi registers a transaction (`/api/v1/transaction/register`).
- The customer is redirected to the P24 payment page.
- P24 sends a server-to-server notification to `urlStatus`.
- Smaki Wsi verifies the transaction using `/api/v1/transaction/verify`.

This matches the existing Smaki Wsi external gateway flow (similar to Stripe redirect).

## Instructions

### Step 1. Create a Przelewy24 account
Create or use an existing P24 merchant account. Make sure you have access to a sandbox account
for testing or production credentials for live usage.

### Step 2. Collect API credentials
From the P24 panel, collect:

- `merchantId`
- `posId`
- `api_key`
- `crc_key`

These must be kept secret.

### Step 3. Configure callbacks
The integration uses:

- `urlReturn` (customer return):  
  `https://YOUR_DOMAIN/payment_gateways/przelewy24/return/ORDER_NUMBER`

- `urlStatus` (server notification):  
  `https://YOUR_DOMAIN/payment_gateways/przelewy24/status`

You do not enter these manually in the Smaki Wsi code. They are sent during registration.
Ensure `SITE_URL` (host) is correct on your server so the generated URLs are valid and public.

### Step 4. Configure your Smaki Wsi instance
All secrets must be stored in `secrets.yml` and excluded from git.

For Vagrant:
`smaki-wsi-install/inventory/host_vars/192.168.56.4/secrets.yml`

Add:

```
p24_merchant_id: "YOUR_MERCHANT_ID"
p24_pos_id: "YOUR_POS_ID"
p24_api_key: "YOUR_API_KEY"
p24_crc_key: "YOUR_CRC_KEY"
```

Non-secret options live in `config.yml`:

```
p24_setup_enabled: true
p24_test_mode: true
p24_language: "pl"
p24_wait_for_result: true
p24_time_limit: 15
p24_assign_all_distributors: true
```

### Step 5. Provision and restart
Provision/deploy the server. The deploy task runs:

```
bundle exec rake ofn:payment_methods:przelewy24
```

This creates or updates `Przelewy24` and `Przelewy24 BLIK` payment methods.

### Step 6. Verify payment methods in admin
Go to `Configuration -> Payment Methods`. You should see:

- Przelewy24
- Przelewy24 BLIK

### Step 7. Assign methods to an enterprise
Go to `Enterprises -> Edit -> Payment Methods` and assign the new methods to your distributor.

### Step 8. Enable in order cycle
Go to `Order Cycles -> Checkout options` and enable Przelewy24 / BLIK for the relevant cycle.

### Step 9. Place a test order
Open the shopfront, choose Przelewy24 or BLIK, and place a test order. If using sandbox, use the
P24 test flow and verify that:

- the customer is redirected to P24,
- `urlStatus` reaches your server,
- the order completes after verification.

If `urlStatus` is not reachable, the payment will stay pending and will not be settled.

## Testing on Vagrant (local only)
Przelewy24 sends `urlStatus` from their servers, so your instance must be publicly reachable.
In local Vagrant without a public URL, the payment will remain pending.

### Option A: use a public tunnel (recommended)
Use a tunnel (ngrok or Cloudflare Tunnel) to expose your local VM:

1) Start the tunnel pointing to your local web port (example for port 8080):
```
ngrok http 8080
```
or
```
cloudflared tunnel --url http://localhost:8080
```
2) Set your `SITE_URL` to the public tunnel URL (without trailing slash).
3) Re-run provision/deploy so `.env` is updated.
4) Retry the payment. Now `urlStatus` can reach your instance.

### Option B: redirect-only test (no status)
You can still verify:
- payment method appears in checkout,
- redirect to P24 works.

But the order will not complete because no `urlStatus` is delivered.
