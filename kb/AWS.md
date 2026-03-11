# AWS Gotchas

## RDS

### Replication privilege

RDS does not support `ALTER ROLE ... REPLICATION` — only `rdsadmin` can set that
attribute. To grant replication privilege to a user, use:

```sql
GRANT rds_replication TO username;
```

This applies to both the replication user on the source and any admin user that
needs to start a walsender. `ALTER ROLE username REPLICATION` will fail with
`ERROR: permission denied to alter role`.
