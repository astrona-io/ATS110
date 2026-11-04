# Solution: Make The Install Reproducible

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: exact versions in `package.json` and `save-exact=true` in `.npmrc`, a lockfile that matches `package.json` with one copy of each core Perses package, and a fresh build served by nginx.

## Step 1: Look at the starting point

Define a helper for the builder and read the dependency lines:

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder "grep -E '\"(@perses-dev|react|echarts)' package.json"
builder "ls -a"
```

Every version starts with `^`. There is no `package-lock.json` and no `.npmrc`. Under a `^` range on a `0.x` version, npm accepts the same minor version only: `^0.54.0` means `>=0.54.0 <0.55.0`. A `^18.3.1` range accepts any 18.x from 18.3.1 on.

## Step 2: Make every version exact

Remove the `^` from every entry. One `sed` command removes a leading `^` or `~` from every version string. The lines in `package.json` have the form `"name": "^1.2.3"`, so the pattern matches the quote, the colon and the symbol:

```sh
builder "sed -i -E 's/\": \"[~^]/\": \"/' package.json"
builder "grep -c '\\^' package.json"
```

The second command counts the lines that still contain `^`; it prints `0` when none are left. `grep -c` exits with 1 when the count is zero, which is expected here.

## Step 3: Tell npm to save exact versions

Create the project `.npmrc`:

```sh
builder "echo 'save-exact=true' > .npmrc"
```

From now on `npm install some-package` writes `"some-package": "1.2.3"` and not `"^1.2.3"`.

## Step 4: Create the lockfile and prove it

```sh
builder npm install --no-audit --no-fund
builder "rm -rf node_modules && npm ci --no-audit --no-fund"
```

The first command creates `package-lock.json`. The second removes the installed packages and rebuilds them from the lockfile alone. `npm ci` stops with an error when `package.json` and `package-lock.json` disagree, so a successful run is the proof that they match.

Check the tree and the core packages:

```sh
builder npm ls @perses-dev/client @perses-dev/components @perses-dev/plugin-system @perses-dev/dashboards @perses-dev/explore
```

## Step 5: Build and deploy

```sh
builder "npm run build && npm run deploy"
```

Open `http://app.localtest.me:8081` after starting a port-forward with `kubectl -n embed port-forward svc/embed-app 8081:8081`. The panel appears as before.

## Reference script

The file `solution/apply.sh` does the same work by writing the final `package.json` and `.npmrc`. If a check still fails, run `astrona submit` and read which of the three checks does not pass.
