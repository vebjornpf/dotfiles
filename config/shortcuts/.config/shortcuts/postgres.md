# PostgreSQL

## Connect from outside Docker

```bash
psql -h localhost -p 5432 -U <user> -d <database>
```

Replace `<user>` and `<database>` with the PostgreSQL username and database. `psql` prompts for the password if needed. This works when the container publishes PostgreSQL on host port `5432`.

## Inspect tables and constraints

At the `psql` prompt, list schemas:

```sql
\dn
```

At the `psql` prompt, list tables in a schema:

```sql
\dt auth_v1.*
```

List all matching relations, including views and sequences:

```sql
\d auth_v1.*
```

Show a table's columns, types, and constraints:

```sql
\d <schema>.<table>
```

Include extra details such as column storage and comments:

```sql
\d+ <schema>.<table>
```

Show detailed descriptions of all matching relations, including columns, indexes, and constraints:

```sql
\pset pager off
\d+ auth_v1.*
```

Replace `auth_v1` with the schema name. Turn the pager back on with `\pset pager on`; while the pager is open, press `q` to exit.

## Export a schema-only SQL dump

Run this from the shell, not from inside `psql`:

```bash
pg_dump -h localhost -p 5432 -U <user> -d <database> \
  --schema-only --schema=auth_v1 > auth_v1_schema.sql
```

This writes the schema definition to `auth_v1_schema.sql` without dumping table data. Replace `auth_v1` with the schema name.
