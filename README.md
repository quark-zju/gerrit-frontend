Alternative Gerrit Frontend
===========================

Display all comments, inline comments, patch sets of one change all together, in one page.

Examples
--------
* [OpenStack #70700](http://quark-zju.github.io/gerrit-frontend/examples/review.openstack.org_70700.html) (340K gzipped HTML)
* [OpenStack #64553](http://quark-zju.github.io/gerrit-frontend/examples/review.openstack.org_64553.html) (2.9M gzipped HTML)
* [CyanogenMod #63824](http://quark-zju.github.io/gerrit-frontend/examples/review.cyanogenmod.org_63824.html) (110K gzipped HTML)

Usage
-----
```bash
bundle
rake db:migrate
rake db:seed
./bin/delayed_job start
rails s
```

Then open [localhost:3000](http://localhost:3000), or try to load some changes like:
* [localhost:3000/review.openstack.org/1](http://localhost:3000/review.openstack.org/1)
* [localhost:3000/review.cyanogenmod.org/I97edae55351101046def5058a2459ab88edf2d0d](http://localhost:3000/review.cyanogenmod.org/I97edae55351101046def5058a2459ab88edf2d0d)

FAQ
---
Q: How does it read gerrit data?
A: Data are read via Gerrit API. Gerrit 2.8.4-15 has been tested. Other versions may work fine.

Q: Does it work for gerrit that needs authorization?
A: Yes. Just set HTTP passwords at `/passwords`.

Q: Is there a cache?
A: Yes. Data are stored in database. When a change is fully imported, visit it again won't emit any HTTP request.

Q: How do I force a change to be updated?
A: Append `?update=1` to the URL to fetch new revisions. Use `?update=2` to force reloading more (mostly existing) contents, which is useful to fix a broken import.

Q: I don't need asynchronous importing. What to do?
A: Set related host's `is_local_net` attribute to `true`.

Background Story
----------------
Gerrit 2.8.4 still displays one file per tab and patch sets are collapsed by default.
This makes it extremely difficult to view code changes and inline comments efficiently, especially for changes with a lot of patch sets like [this](https://review.openstack.org/#/c/64553/).
Gerrit is [evolving](https://code.google.com/p/gerrit/issues/detail?id=938). It probably will be easier to use eventually. However, I cannot wait long.

User script can not solve the problem since Gerrit is a GWT project.

License
-------
MIT
