# Linux test harness

Use `test/run-linux-docker` to build a Linux image containing your dotfiles and drop into an interactive shell.

- Requires Docker on the host.
- Builds an image (`dotfiles-test:latest` by default) using `test/Dockerfile`, installs `curl` (for the bootstrap fetch), copies the repo into `/root/dotfiles`, and drops you into an interactive shell; you can `cd /root/dotfiles` and run `./.bootstrap` manually.
- Environment knobs:
  - `IMAGE=mytag ./test/run-linux-docker` to change the image tag.
  - `NO_CACHE=1 ./test/run-linux-docker` to force a clean rebuild.
