Alternative Gerrit Frontend
===========================

Display all comments, inline comments, patch sets of one change all together, in one page.

Notes
-----
* WORKING-IN-PROGRESS
* This project uses Gerrit API to read data and doesn't not support write operations.

Usage
-----
```bash
bundle
rake db:migrate
rake db:seed
./bin/delayed_job start
rails s
```

Then open [localhost:3000](http://localhost:3000), or try to load some change like [localhost:3000/review.openstack.org/64553](http://localhost:3000/review.openstack.org/64553).

Background Story
----------------
Gerrit 2.8.4 still displays one file per tab and patch sets are collapsed by default.
This makes it extremely difficult to view code changes and inline comments efficiently, especially for changes with a lot of patch sets like [this](https://review.openstack.org/#/c/64553/).
Gerrit is [evolving](https://code.google.com/p/gerrit/issues/detail?id=938). It probably will be easier to use eventually. However, I cannot wait long.

User script can not solve the problem since Gerrit is a GWT project.

License
-------
MIT
