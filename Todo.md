* Documentation
* YouTube tutorial videos for Linux, mac OS and Windows
* Curses menuconfig?
* Helm chart to run in Kubernetes?
* Add ports on worldserver and authserver for master brach also
* Remove old/ directory (put in another protected branch?)
* Fix healthchecks to not inject login failures into mysql logs
* Fix Makefile to dynamically build worldserver.conf and authserver.conf again like the old Makefile did?
* Take a look at the most popular other TrinityCore container https://github.com/fred-drake/TrinityCoreDocker/tree/3.3.5 and see how I can simplify
* https://github.com/fred-drake/TrinityCoreDocker/blob/3.3.5/Dockerfile
* Setup automatic CI pipeline to make a nightly build and publish to DockerHub.
* Add `command_not_found_handle()` to intercept tcadmin SOAP commands.
* Document how to make database backups and how to use the `sql/custom/`.
* Document how to make use of `sql/docker-entrypoint-initdb.d/` for easy pre-populated databases.
