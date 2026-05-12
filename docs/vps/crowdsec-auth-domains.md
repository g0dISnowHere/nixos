# CrowdSec Auth Domains

This page explains the 3 different CrowdSec remote auth paths used in this
repo. They are separate on purpose.

## 1. CrowdSec Console Enrollment

What it is:

- one-time or revocable enrollment / attachment token
- used to attach the machine to the CrowdSec Console

Repo input:

- `secrets/services/crowdsec/console-enrollment-token.yaml`
- YAML key: `token`

Runtime use:

- consumed by `crowdsec-console-enroll.service`
- runs `cscli console enroll ...`

What it is not:

- not the CTI API key
- not the runtime Central API machine credential

## 2. CrowdSec Central API Runtime Credentials

What they are:

- machine-specific runtime credentials for CrowdSec Central API
- normal online creds used after registration
- stored as `url`, `login`, `password`

Default model in this repo:

- generated on-host by `crowdsec-capi-register.service`
- written to `/var/lib/crowdsec/online_api_credentials.yaml`

Optional import model:

- if `secrets/services/crowdsec/online-api-credentials.yaml` exists, the repo
  imports it instead of generating fresh runtime creds

What they do:

- allow ongoing CAPI auth after the machine is registered
- feed online blocklists and other Central API runtime behavior

What they are not:

- not the Console enrollment token
- not the CTI API key

## 3. CrowdSec CTI API Key

What it is:

- API key for CrowdSec CTI enrichment
- separate from Console and separate from Central API runtime auth

Repo input:

- `secrets/services/crowdsec/cti-api-key.yaml`
- YAML key: `key`

Runtime use:

- rendered into `/run/secrets/rendered/crowdsec-config.yaml`
- injected as `api.cti.key`

What it is not:

- not used for `cscli console enroll`
- not used as `/var/lib/crowdsec/online_api_credentials.yaml`

## Quick Map

Use this when confused:

- want Console attachment -> `console-enrollment-token.yaml`
- want Central API runtime auth -> `/var/lib/crowdsec/online_api_credentials.yaml`
- want CTI enrichment -> `cti-api-key.yaml`

## Operator Notes

- keeping all 3 is correct if you want all CrowdSec features
- only Console token is expected to be one-time / revocable
- generated CAPI runtime creds are normal, not redundant
- if a secret file under `secrets/services/crowdsec/` is edited or replaced,
  rekey it with the repo SOPS workflow before deploy
