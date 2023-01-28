# Compiled-In Runtime Plugin (CIRP)

## Introduction

So. You have a V module or application, some V source, that you want to
allow users to be able to "hook on to", extend or customize at certain key points.

You can not have all these extensions and customization in
the application's source repository, maybe your resources are limited,
you can not maintain all of them, some extensions may not fit the goal or
problem your application is trying to solve, etc.

A classic approach to solving such things is using *runtime* plugins, where you
build a plugin as a dynamic/shared library (`.so`/`.dll`) - and then
load it at run time and "glue together" the plugin with the rest of the
application all happening at run time. In V this can be done with the [`dl`](https://modules.vlang.io/dl.html) module.
This approach works fine and is being used to successfully develop dynamic
extensible applications.

It's just that this approach also has some downsides, it comes with a prize, so to speak.

Examples of downsides when using dynamic loaded plugins:

* Plugins need to be build separately from the host application, giving a need for
  a separate build system/setup and often special build flags.
* Plugin authors have to build their plugins for each platform they want to support,
  this can result in plugins that only work on selected platforms giving a bad user
  experience and a fragmented ecosystem.
* The separate build process often needs special compiler flags and some flags
  can prevent the plugin from working properly or result in crashes at run time.
* The dynamic nature of this type of plugins leads to many errors that need to be
  handled at run time. Ranging over things like loading of missing plugins/files, state
  corruptions in the host application's plugin configuration, crashes when plugins
  are not compiled with the correct flags.

I'm sure there's plenty of other headaches with the run time approach.

One way to have less headaches in this regard is to use what I call:
"Compiled-In Runtime Plugins" (I call them "CIRPs", which is a ridiculous bend on "chips").

I can't imagine this approach is a new thing - it's just that I haven't heard or
read about this exact approach before, so what I present here might be naive
or solved better by other people/languages. I just thought it would be nice to share
and see where it goes.

My solution is based on V since I happen to like it and because it's compile time and
reflection capabilities has improved a lot lately, at the time of writing my V version is:
`V version: V 0.3.2 d3e4058, timestamp: 2023-01-28 10:15:28 +0200`

## How It Works

The idea is fairly simple:

Let plugin authors write plugins in a way so anyone can simply drop it into an application's
code base and rebuild the application with a `-d` flag - and *BOOM* the application has magic
new capabilities. Done.

No run time loading, no ghost calls to functions or methods that are missing, no crashes,
no separate build processes or weird compiler flags, everything is evaluated and predictable
at compile time like any other V source code, making sure everything works and nothing
is missing - resulting in a rock solid application run.

For application developers this means they can expose a normal plugin API with which
anyone can expand on their work. Plugin authors can write, build and distribute plugins for
the application in a really easy and predictable way.

Sounds great, right? Well - it _is_ great and it even works, at least in V!

## Caveats

There is a few (known) things about the current solution that is not optimal, though,
which I hope can be improved over time:

* Since plugins are compiled-in you can not simply delete a library file to disable
  functionality (it can be solved via config files that can be evaluated at run time).
* The whole application needs to be rebuilt when plugins are enabled/disabled.
* Deleting active plugin source code *before* disabling plugins can result in compile
  errors that can be hard to deal with when the application is rebuilt.
  If you're not experienced with how the approach works, this can be painful.
  This is especially a point I hope we can solve over time. In 90% of the time the issue
  can be fixed by simply deleting the auto-generated plugin boilerplate glue code file,
  and rebuilding the application with a flag.
* Dynamically generated plugin glue code. Unfortunately the approach needs to generate
  a file with necessary glue code in order for everything to work. This makes it harder
  to integrate with systems like `git` since this glue file always need to be present in
  the project *but then changes over time* when plugins are enabled/disabled.
  This is complicating the VCS process greatly. It's hopefully also something that can
  be solved over time.
* The host app needs to be `run` whenever plugins are configured via enable/disable
  since the `v.reflection` module need access to inspect the code at run time before
  changes can be detected and boilerplate code (re)written.
* Some operations may need two successive runs with different `-d` flags set.
* Problems I have not thought about.

The above things are something I'm willing to put up with, over having to deal with plugins
at run time. Your opinion might be different, in which case this approach is not for you.
I think good conventions or maybe with the help of a makefile or similar, the major pain
points of the approach can be minimized or eliminated.

The good thing is that the approach can be implemented (and branded) as an independent
module that is controlled by the host application and the whole enable/disable process
is controlled by V compiler `-d` flags, in this example the plugin module is called
`cirp` and the host application is called `pluggable` and the two example plugins `Foo`
and `Bar`.
Also notice how the plugins *does not* implement the whole API, only the methods
they "operate" on. See [foo.v.plugin](foo.v.plugin) and [bar.v.plugin](bar.v.plugin).

## Install

```bash
git clone https://github.com/Larpon/pluggable.git
cd pluggable
```

## Usage

On first run, as a demo, try running the following commands and observe the output:

1. `v run .` (should be no output)
2. `v -d cirp_enable run . && v -d cirp_make run .`
3. `v run .` (should have output from the plugins)

The control commands/flags are:

* `v -d cirp_make run .` (re-)generates plugin boilerplate code from present plugin code.
* `v -d cirp_template run .` output a V source code template for *writing* a host app plugin.
* `v -d cirp_enable run .` enables all present plugins in code base (via file name conventions).
* `v -d cirp_disable run .` disables all present plugins in code base (via file name conventions).
* `v -d cirp_api run .` show a simple version of the available plugin API.
* `v -d no_cirp run .` disables running any plugin code at run time.

The flags `v -d cirp_enable run .` and `v -d cirp_disable run .` often needs to be followed by
`v -d cirp_make run .` to (re-)generate the glue code.

When plugins are configured you can build, develop and/or run your application like you would
normally:
`v run .`, `v -o app . && ./app` etc.

Happy plug'n'play to all of you!

# FAQ

* Q: Help the app/plugin is in a broken state!
* A: Try `rm -f plugins.auto.v && v -d cirp_make run . && v run .`
