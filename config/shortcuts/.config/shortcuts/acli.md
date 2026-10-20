# Atlassian CLI

## List unfinished Jira tickets created by me

```bash
acli jira workitem search --jql 'creator = currentUser() AND statusCategory != Done ORDER BY created DESC' --paginate
```

Lists all tickets you created outside the Done status category, newest first.
To find tickets you reported instead, replace `creator` with `reporter`.
