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

If you get something like this:

```
FATAL:  logical replication slot "koyo_repl_test" exists, but wal_level < logical
HINT:  Change wal_level to be logical or higher.
```

... and you've changed the conf file you might have run `alter system` which
sets another conf file ... so search for 

`find / -type f -name postgresql.auto.conf 2> /dev/null` 

and check those wal_levels

YOU NEED TO RESTART POSTGRES when you change wal_level

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

# Specs

I just put in a super basic example of how to spec this - it's by no means
complete and I kind of cheated by turning transactions off (which isn't the
default in Rspec).

# Relevent files

In `app/services`

* `repl_config`: Very simple config settings for replication
* `repl_data`: Used to parse data from the replication slot into ReplDataRows
* `repl_data_row`: Parses a row from the replication slot
* `repl_log`: Manages logging/output
* `repl_server`: Server that monitors the replication slot. 
   Run with `rake repl:repl_server`
* `repl_user`: Class that handles users table changes
* `repl_utils`: Simple SQL commands to deal with the replication slot

In `lib/tasks`

* `repl.rake`: runs the server

In `spec/services`

* `repl_server_spec.rb`: extremely basic smoke test

# Speeding things up

Speed really matters monitoring replication slots on high traffic apps. For
example - if you're calling an API to update external data-sources you don't
want to put that in-line. There are a bunch of ways to do this. You can use the
traditional Sidekiq method - but, that can get complicated/messy if you're
using Sidekiq for a ton of other things as well... you'll need to create a
seperate Sidekiq instance, or dedicated queue, etc. Kind of messy. 

I like to just use a dead simple Redis queue. I haven't included the code to do
this here as it over complicates this "simple" example but it's not hard to do,
and should be done if you have a really busy app.

# Not covered here

Monitoring: You definitely want to monitor this in production. There are a
zillion ways to do this (like DataDog, manually write something, etc) but you
want to do it. If something goes wrong, or someone runs some insane SQL update
the replication slot can grow in size to the point where you won't be able to
read from it, it'll use up all your disk space and everything will suck. So -
Google your prefered method. This article hits on the basics
[https://severalnines.com/blog/using-postgresql-replication-slots/](https://severalnines.com/blog/using-postgresql-replication-slots/)

[Good article on replication slots in postgres](https://hevodata.com/learn/postgresql-replication-slots/)
[Postgres Replication Settings](https://www.postgresql.org/docs/current/runtime-config-replication.html)

