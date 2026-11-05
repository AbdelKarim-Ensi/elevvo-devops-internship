# Task 3 - Automated Scripting & Secrets Hygiene

```bash
cp .env.example .env        # edit LOG_DIR, WEBHOOK_URL
bash backup.sh              # manual test
bash demo.sh                # demo with fake logs
```

## Cron
```bash
crontab -e
# demo: every 2 minutes
*/2 * * * * /FULL/PATH/task-03-backup-automation/backup.sh >> /FULL/PATH/task-03-backup-automation/cron.log 2>&1
# real: every day at 02:00
# 0 2 * * * /FULL/PATH/task-03-backup-automation/backup.sh >> /FULL/PATH/task-03-backup-automation/cron.log 2>&1
crontab -l && tail -f cron.log
```

## Secrets hygiene
`.env` is in `.gitignore` (root). Check: `git ls-files | grep -x .env` prints nothing.
