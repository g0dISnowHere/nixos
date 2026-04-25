# Secret Rotation Checklist

Date: 2026-03-28
Scope: tracked files and live config for currently preserved services

## Rotate Now

- [ ] Rotate `CF_DNS_API_TOKEN` in `public/traefik/.env`
- [ ] Rotate `CROWDSEC_BOUNCER_API_KEY` in `public/traefik/config/traefik-crowdsec-bouncer.env`
- [ ] Rotate CrowdSec local API credentials in `public/traefik/crowdsec/config/local_api_credentials.yaml`
- [ ] Rotate CrowdSec online API credentials in `public/traefik/crowdsec/config/online_api_credentials.yaml`
- [ ] Rotate CrowdSec Console enrollment token in `secrets/services/crowdsec/console-enrollment-token.yaml`
- [ ] Rotate Traefik ACME account material in `public/traefik/traefik/acme_letsencrypt.json`
- [ ] Rotate Cloudflare ACME account material in `public/traefik/traefik/cloudflare-acme.json`
- [ ] Rotate TLS account or certificate material in `public/traefik/traefik/tls_letsencrypt.json`

## Review And Rotate If Needed

- [ ] Review `CF_API_EMAIL` in `public/traefik/.env` while rotating Cloudflare credentials
- [ ] Review `public/perplexica/config.toml` for provider or API tokens, then rotate any found
- [ ] Review `public/perplexica/backend-dbstore/config.json` for embedded credentials, then rotate any found
- [ ] Review `public/openwebui/pipelines/ollama_pipeline/valves.json` for embedded credentials, then rotate any found
- [ ] Review `public/searxng/config/settings.yml` for secrets or private endpoints, then rotate any found

## Likely Config Only

- [ ] Confirm `public/nextcloud_aio/.env` contains only non-secret config toggles
- [ ] Confirm `public/traefik/config/crowdsec.env` contains only non-secret runtime config

## After Rotation

- [ ] Remove old credential values from any tracked files
- [ ] Move rotated secrets out of tracked git files into a managed secret workflow
- [ ] Verify `secrets/services/crowdsec/` contains current CrowdSec-managed secret imports where needed
- [ ] Verify Traefik ACME still works after Cloudflare credential rotation
- [ ] Verify CrowdSec bouncer still authenticates after API key rotation
- [ ] Verify preserved services start cleanly with the new credentials
