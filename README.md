solaris-exporter
==================

SPARC solaris exporter for Prometheus.

Original docs moved to: [docs/README.md](docs/README.md)

Requires for work:

- Python 2.7

After installation just start `bin/init.sh` script.

Building
---------

Requirements:

- Linux machine
- Python 2.7
- Python 3.x (for working with poetry) with pip module
    Probably you need to install `python3-pip` package
- Poetry ([link](https://github.com/python-poetry/poetry))
- GNU Make (just ordinary `make`)
- `tar`
- `unzip`

For building IPS package:

- `envsubst`
- `solaris-ips` distribution ([source](https://github.com/oracle/solaris-ips))
    a.k.a Update Center Toolkit

How to build this project:

1. Build project distributions

    ```bash
    make PLATFORM=solaris-2.10-sun4v
    ```

    Available platforms:

    - `solaris-2.10-sun4v`
    - `solaris-2.11-sun4v`

1. (optionally) Create and publish IPS package

    By default package place exporter to `/pub/site/solaris-exporter`. `/pub` and `/pub/site` are not created.

    If you want to set a custom location, define `PREFIX=` in a `make` command.

    ```bash
    export PKG_REPO=http://pkg.example.com/

    make ips-publish \
        PLATFORM=solaris-2.10-sun4v \
        IPS_FILES_OWNER=root        \
        IPS_FILES_GROUP=bin
    ```

    Currently only `PLATFORM=solaris-2.10-sun4v` is supported.

Done! You have these results:

- `*.whl` file - this is only a source of this project without dependencies. Use it if you understand what you do.

- `*.tag.gz` file - this is distribution that binary-compabilible with any solaris sparc machines. Just untar it and run `bin/init.sh start` script to start solaris exporter.

Builds are available in `dist/` directory.

Additional make commands:

- `make wheel` - build `*.whl` file only.
- `make tarball` - the same of empty `make` run.
- `make clean` - cleaning up build root and `dist/` directories.

Also the make supports a direct platform specifying. Just add a `PLATFORM=foo-bar` option as shown here:

```bash
make tarball PLATFORM=solaris-2.11-sun4v
```

If you are behind a company proxy you should do a few tricks:

1. For Poetry you should specify an env variable with http proxy:

    ```bash
    export http_proxy=http://hostname:3128/
    ```

1. For Make add an additional pip option:

    ```bash
    make tarball PIP_EXTRA_OPTIONS='--proxy http://hostname:3128/'
    ```

You may add username and password (for basic auth) to both. Just use this format:

`http://username:password@hostname:3128/`

If you want to use Make with PyPI mirror placed on company Nexus just add:

`PIP_EXTRA_OPTIONS='--index-url http://nexus.example.com/repository/pypi/simple --trusted-host nexus.example.com'`
