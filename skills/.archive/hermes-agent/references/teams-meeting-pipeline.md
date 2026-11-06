# Teams Meeting Pipeline (hermes teams-pipeline)

Operate the Microsoft Teams meeting summary pipeline via Hermes CLI. Covers meeting summary, pipeline status, job replay, and Graph subscription management.

## Prerequisites

Before using the pipeline, verify these are set in `~/.hermes/.env`:
```
MSGRAPH_TENANT_ID=...
MSGRAPH_CLIENT_ID=...
MSGRAPH_CLIENT_SECRET=...
```

If any are missing, the user needs an Azure AD app registration with admin-consented Graph application permissions.

## Status and Inspection

```bash
hermes teams-pipeline validate              # config snapshot — run first after any change
hermes teams-pipeline token-health          # Graph token status
hermes teams-pipeline token-health --force-refresh   # force a fresh token
hermes teams-pipeline list                  # recent meeting jobs
hermes teams-pipeline list --status failed  # only failed jobs
hermes teams-pipeline show <job-id>         # full detail of one job
hermes teams-pipeline subscriptions         # current Graph webhook subscriptions
```

## Re-running / Debugging

```bash
hermes teams-pipeline run <job-id>          # replay a stored job (re-summarize, re-deliver)
hermes teams-pipeline fetch --meeting-id <id>    # dry-run without persisting
hermes teams-pipeline fetch --join-web-url "<url>"  # dry-run by join URL
```

## Subscription Management

```bash
hermes teams-pipeline subscribe \
  --resource communications/onlineMeetings/getAllTranscripts \
  --notification-url https://<your-public-host>/msgraph/webhook \
  --client-state "$MSGRAPH_WEBHOOK_CLIENT_STATE"

hermes teams-pipeline renew-subscription <sub-id> --expiration <iso-8601>
hermes teams-pipeline delete-subscription <sub-id>
hermes teams-pipeline maintain-subscriptions            # renew near-expiry ones
hermes teams-pipeline maintain-subscriptions --dry-run  # show what would be renewed
```

## Critical: Subscriptions Expire in 72 Hours

Microsoft Graph caps webhook subscriptions at 72 hours and will NOT auto-renew them.
Set up automated renewal via `hermes cron add`, systemd timer, or crontab.
12-hour interval is safe (6x headroom against 72h limit).

## Troubleshooting Flow

1. `validate` → `token-health` → `subscriptions` — if all pass, check `list`
2. Job missing entirely → subscriptions may have expired
3. Job exists but failed → `show <job-id>`, then `run <job-id>` to replay
4. Success but no delivery → check `platforms.teams.extra.delivery_mode` in config

Related docs:
- Azure app registration: `/docs/guides/microsoft-graph-app-registration`
- Pipeline setup: `/docs/user-guide/messaging/teams-meetings`
- Operator runbook: `/docs/guides/operate-teams-meeting-pipeline`
