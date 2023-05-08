# Postgres Replication Slot Monitoring Example

例 Rei: Japanes for Example

This gives you a starting point for monitoring replication slots in postgres.

This can be helpful for doing things like keeping a no-sql or elasticsearch
datastore in sync. You can of course do this in other ways (like hooks in
models, services, etc) but I found doing this was simplest and most repliable.
It also works well if you share your database with other teams and they're
doing stuff like changing things in other code bases or running straight SQL.
This will catch all of that.

Downsides of this are you need to run 1 (or two - if you use the redis method)
servers and you need to monitor the replication slot size. So it adds some
deployment complexity/expense depending on how you have production set up.

## Quick Start

### Grab code, setup

```
git clone https://github.com/wiseleyb/rei-replication
cd rei-replication
bundle install
bundle exec rake db:create
```

### Change wal_level

The default install of postgres doesn't enable logical replication. To do this
you need to edit your `postgresql.conf` file and change

`wal_level = logical`

Finding this file can be tricky and depends on how you installed postgres. The
easiest way is probably:

`find / -type f -name postgresql.conf 2> /dev/null`

`AFTER CHANGING THIS FILE YOU NEED TO RESTART POSTGRES` (which also depends on
how you installed it)

Now you can create the slot. In `bundle exec rails c` console:

```
ReplUtils.create_replication_slot!
```

Next - start the replication server in a new terminal window:

```
rake repl:repl_server
```

Then go back to console:

```
User.create(name: 'bob', email: 'bob@bob.com')
```

And you should see action in the server.

`ReplLog: source=Replication message=process-insert users`

# Advanced stuff

Monitoring: You definitely want to monitor this in production. There are a
zillion ways to do this (like DataDog, manually write something, etc) but you
want to do it. If something goes wrong, or someone runs some insane SQL update
the replication slot can grow in size to the point where you won't be able to
read from it, it'll use up all your disk space and everything will suck. So -
Google your prefered method. This article hits on the basics
[https://severalnines.com/blog/using-postgresql-replication-slots/](https://severalnines.com/blog/using-postgresql-replication-slots/)


