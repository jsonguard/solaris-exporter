solaris-exporter
==================

SPARC solaris exporter for Prometheus. 

Original docs moved to: [docs/README.md](docs/README.md)

Building
---------

Requirenments:

- Python 3.x (for working with poetry and pyenv)
- Poetry ([link](https://github.com/python-poetry/poetry))
- Pyenv ([link](https://github.com/pyenv/pyenv))
- GNU Make (just ordinary `make`)
- `tar`, `unzip`

How to build this project:

1. Install correct version of Python locally
    `pyenv install`

1. Install project dependencies
    `poetry install`

1. Build project distributions
    `make`

Done! You have these results:

- `*.whl` file - this is only a source of this project without dependencies. Use it if you undestand what you do.

- `*.tag.gz` file - this is distribution that binary-compabilible with any solaris sparc machines. Just untar it and run `run.sh` script for start solaris exporter.

Builds are available in `dist/` directory.

Additional make commands:

- `make wheel` - build `*.whl` file only.
- `make tarball` - the same of simple `make` run.
- `make clean` - cleaning up build root and `dist/` directories.

Also the make supports a direct platform specifing. Just add a `PLATFORM=foo-bar` option as shown here:

```bash
make tarball PLATFORM=solaris-2.11-sun4v
```

If you are behind a company proxy you should do a few tricks:

1. For Poetry you should specify an env variable with http proxy:

    ```bash
    export http_proxy=http://hostname:3128/
    ```

1. For Make add an additiona pip option:

    ```bash
    make tarball PIP_EXTRA_OPTIONS='--proxy http://hostname:3128/'
    ```

You may add username and password (for basic auth) to both. Just use this format:

`http://username:password@hostname:3128/`

If you want to use Make with PyPI mirror placed on company Nexus just add:

`PIP_EXTRA_OPTIONS='--index-url http://nexus.example.com/nexus/repository/pypi/simple --trusted-host nexus.example.com'`
