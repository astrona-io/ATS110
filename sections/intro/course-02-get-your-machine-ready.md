# Get Your Machine Ready

Every playground and lab in this course runs on your own machine, in a small Kubernetes cluster. A tool called `astrona` builds it for you, sets it up, grades your work and removes it again. This page gets your machine ready: first the tools you need, then the handful of `astrona` commands you will use every day, and last what to do when a start goes wrong.

## What you need

Every section needs the same small set of tools. Install these before you start:

- **A container engine:** Docker or Podman. The cluster runs inside it.
- **`kind`:** runs Kubernetes inside the container engine.
- **`kubectl`:** talks to the cluster. You run every build through `kubectl exec`.
- **The astrona command-line tool.**
- **A web browser:** to look at the embedded app and at Perses through a port-forward.

You do not need Node.js, npm or Go on your machine: every build runs in a pod in the cluster. Each environment also installs **Helm 3.22.1** and **`percli` 0.54.0** on your machine, so their versions always match the course.

The environments need **outbound internet** while they start and while you build. They download Perses from GitHub, container images from Docker Hub, and npm packages from `registry.npmjs.org`. The first `npm install` in an environment downloads several hundred megabytes and takes a few minutes. Give your container engine at least **6 GiB** of memory: a JavaScript build with Vite needs about 2 GiB on its own.

## Reaching Perses and the app

Perses and the example app run inside the cluster, so your browser reaches them through port-forwards. Pages that need them ask you to start them in a second terminal and leave them running:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
kubectl -n embed port-forward svc/embed-app 8081:8081
```

Then Perses answers at `http://perses.localtest.me:8080` and the app at `http://app.localtest.me:8081`. The names under `localtest.me` are public DNS names that point at `127.0.0.1`, your own machine. If your router blocks such answers and the names do not resolve, add this line to `/etc/hosts` on your machine:

```
127.0.0.1 perses.localtest.me app.localtest.me
```

You do not have to check your tools by hand. Let `astrona` look at your machine for you:

```sh
astrona setup
```

`astrona setup` looks at what is missing, shows you each step it would take, and asks before it does anything.

Later, you can check your machine at any time:

```sh
astrona check
```

## The commands you use every day

Once your machine is ready, you need only a handful of `astrona` commands. Each module page and lab page shows the exact command to copy, so you do not need to remember paths. This section walks through them in the order you meet them: sign in, start, pause, submit and clean up.

Labs from the course catalog are tied to your Astrona account, so you sign in first:

```sh
astrona login
```

Next you start a playground or a lab. Each module page and lab page shows the exact `astrona run` command for it. It looks like this:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-010/module-01/playground
```

When the cluster is ready, `kubectl` already points at it.

A chapter that sends you to a lab asks you to pause the playground first. Pausing frees your machine's memory but keeps everything you built:

```sh
astrona stop <name>
```

When the lab is done, start the playground again and carry on where you left off:

```sh
astrona start <name>
```

Inside a lab, you send your work for grading with `astrona submit`. The grader checks the live cluster. It reads the files you built, the Perses API and the app nginx serves, so your fix has to actually work, not only make an error message go away. Each lab page shows the exact command:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

You can submit as often as you like.

When you are done with a playground or a lab, remove it:

```sh
astrona destroy <name>
```

The name is the environment's name, printed by `astrona run` and shown on each page (for example `ats-110-playground-010-01`). It is not the folder path. To see what is on your machine, list it:

```sh
astrona list
```

> [!WARNING]
> **Run one environment at a time.** Each playground and lab is a whole cluster with its own Perses and builder. Two running at once can use up your machine's memory, and it is easy to send a command to the wrong one. Pause or destroy the playground before you start the lab.

## When a start goes wrong

Sometimes a playground or lab does not start cleanly. Ask `astrona` what is wrong before you try anything else:

```sh
astrona doctor
```

It checks your machine, the lab's configuration and the running lab, and tells you how to fix what it finds.

If a start fails while it downloads something, check your network first. If an `npm install` stops after a long time, the builder pod may be short of memory; check `kubectl -n embed describe pod -l app=app-builder` for `OOMKilled`. Remember also that a lab often starts with an app that does not build: the lab's task tells you when that is the case. With your machine ready and these commands at hand, you can start the first module.
