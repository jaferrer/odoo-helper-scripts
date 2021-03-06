# Odoo helper scripts collection

Master: 
[![Build Status](https://travis-ci.org/katyukha/odoo-helper-scripts.svg?branch=master)](https://travis-ci.org/katyukha/odoo-helper-scripts)
[![Coverage Status](https://codecov.io/gh/katyukha/odoo-helper-scripts/branch/master/graph/badge.svg)](https://codecov.io/gh/katyukha/odoo-helper-scripts)

Dev:
[![Build Status](https://travis-ci.org/katyukha/odoo-helper-scripts.svg?branch=dev)](https://travis-ci.org/katyukha/odoo-helper-scripts)
[![Coverage Status](https://codecov.io/gh/katyukha/odoo-helper-scripts/branch/dev/graph/badge.svg)](https://codecov.io/gh/katyukha/odoo-helper-scripts/branch/dev)


## Features

- Easily manage few instances of odoo that ran on same machine
- High usage of [virtualenv](https://virtualenv.pypa.io/en/stable/) for isolation purpose
- Easy addons installation
    - Automatiacly resolve and fetch dependencies
        - oca\_dependencies.txt ([sample](https://github.com/OCA/maintainer-quality-tools/blob/master/sample_files/oca_dependencies.txt), [mqt tool code](https://github.com/OCA/maintainer-quality-tools/blob/master/sample_files/oca_dependencies.txt))
        - [requirements.txt](https://pip.readthedocs.io/en/stable/user_guide/#requirements-files)
    - Specific file format to track addon dependencies: [odoo\_requirements.txt](#syntax-of-odoo_requirementstxt)
    - installation from *git* repositories
    - installation from *Mercurial* repositories (**experimental**)
    - installation of python dependencies from [PyPI](pypi.python.org/pypi) or any [vcs supported by setuptools](https://setuptools.readthedocs.io/en/latest/setuptools.html?highlight=develop%20mode#dependencies-that-aren-t-in-pypi)
    - shortcuts that simplifies fetching addons from [OCA](https://github.com/OCA) or [github](https://github.com)
    - works good with long recursive dependencies.
      One of the reasons for this script collection development was,
      ability to automaticaly install more that 50 addons,
      that depend on each other, and where each addon have it's own git repo.
- Supported odoo versions:
    - *7.0* (some functionality may not work),
    - *8.0*
    - *9.0*
    - *10.0*
    - *11.0* (experimental, *python3* and *python2*)
- OS support:
    - On *Ubuntu* should work nice
    - Also should work on *Debian* based systems, but some troubles may happen with installation of system dependencies.
    - Other linux systems - in most cases should work, but system dependecies must be installed manualy.


## Documentation note

Documentaion in this readme, or in other sources, may not be up to date!!!
So use *--help* option, which is available for most of commands.


## Usage note

This script collection is designed to simplify life of addons developer.
This project ***is not*** designed, to install and configure production ready Odoo instances!!!
To install Odoo in production read [Odoo official installation doc](https://www.odoo.com/documentation/10.0/setup/install.html) first.
Also, it is possible to manage almost any Odoo intance with this project, if it will be configured right.


## Install (user space)

To install (in user home) just do folowing:

```bash
wget -O - https://raw.githubusercontent.com/katyukha/odoo-helper-scripts/master/install-user.bash | bash -s
```

After instalation You will have ```odoo-helper-scripts``` directory inside your home directory
(also it will be added to PATH environment variable through ```~/.bash-profile``` file).
And ```$HOME/odoo-helper.conf``` file will be generated with path to odoo-helper-scripts install dir.

## Install (system-wide)

To install (system-wide) just do folowing:

```bash
wget -O - https://raw.githubusercontent.com/katyukha/odoo-helper-scripts/master/install-system.bash | sudo bash -s
```

or more explicit way:

```bash
wget -O /tmp/odoo-helper-install.bash https://raw.githubusercontent.com/katyukha/odoo-helper-scripts/master/install-system.bash;
sudo bash /tmp/odoo-helper-install.bash;
```

After instalation You will have ```odoo-helper-scripts``` directory under ```/opt/``` directory.
(also ```odoo-helper``` and ```odoo-install``` scripts will be linked to ```/usr/local/bin/``` dir).
And ```/etc/odoo-helper.conf``` file will be generated with path to odoo-helper-scripts install dir.

If you wish to install from *dev* branch, you can use following command:

```bash
wget -O - https://raw.githubusercontent.com/katyukha/odoo-helper-scripts/master/install-system.bash | sudo bash -s - dev
```

## Test your OS support

It is possible to run basic tests via docker. For this task, odoo-helper-scripts repo
contains script ```run_docker_test.bash```. Run ```bash run_docker_test.bash --help``` to
see all available options for that script.

For example to test, how odoo-helper-scripts will work on debian:stretch, do following:
```cd $ODOO_HELPER_ROOT; bash run_docker_test.bash --docker-ti --docker-image debian:stretch```


## Usage

And after install you will have available folowing scripts in your path:

    - odoo-install
    - odoo-helper

Each script have ```-h``` or ```--help``` option which display most relevant information
about script and all possible options and subcommands of script

Look at [complete example](#complete-example)

### odoo-install

Install Odoo in specified directory in (using virtualenv)

```bash
odoo-install
```

After this You wil have odoo and it's dependencies installed into *MyOdoo* directory.
Note that installation is done only with PIP, with out need of super-user rights, but thus
system dependencies, such as libraries, compilers, \*-dev packages, etc cannot be installed.
You should install them manualy.

This installation also creates *odoo-helper.conf* file inside project, which allows to use
*odoo-helper* script to simplify interaction with this odoo installation.

Also, in case that this is source installation, you may install more than one odoo installation
on machine, thus you can use it for development of multiple addon sets, which may not work good on same odoo installation.

### odoo-helper

This script simlify interaction with odoo installs (mostly done by *odoo-install* script)

Note, that this script becomes useful when there is *odoo-helper.conf* config file could be found.
Config will be searched in folowing paths:

- `/etc/default/odoo-helper.conf`  - System wide config file. May be usefule if
                                     You have only one Odoo instalation in system
- `<user home dir>/odoo-helper.conf`   - User specific config.
- *Project specific* - this config is searched in working directory and up. first one found will be used.
                     This feature allows to use *odoo-helper* with multiple odoo instances in one system

Core functionality is:

- *fetch* - which makes available to fetch module from git repository and
            install it in this installation.
            Also it may automatically fetch dependencise of module been fetched,
            if it have *odoo_requirements.txt* file inside.
- *generate_requirements* - Generates *odoo_requirements.txt* file, with list of modules
                            installed from git repositories. It checks all modules placed in
                            addons directory, which is passed as argument to this command or
                            got from odoo-helper.conf. Resulting file is suitable for *fetch_requirements command
- *server* - Contorlls odoo server of current project. run with *--help* option for more info.
- *test* - Test set of modules (```-m <module>``` option, which could be passed multiple times)
           Depending on options, may create new clean test daatabase.
           For depatis run this command with --help option$A
- *link* - link specified module directory to current addons dir. mostly used internaly
- *db* - manage database (create, drop, dump, restore, etc)
- *addons* - manage addons (install, update, check for updates in git repos, etc)
- *tr* - translation utils
- *postgres* - manage local postgres (create pg user, etc)

For details use *--help* option

### Syntax of odoo\_requirements.txt

*odoo_requirements.txt* parsed line by line, and each line
must be just set of options for ```odoo-helper fetch``` command:

```
-r|--repo <git repository>  [-b|--branch <git branch>] [-m|--module <odoo module name>] [-n|--name <repo name>]
--requirements <requirements file>
-p|--python <python module>

```

Also there are shorter syntax for specific repository sources:

- ```--github user/repository``` for github repositories
- ```--oca repository``` of Odoo Comunity Assiciation repositories

Fore example:

```
--github katyukha/base_tags --module base_tags -b master
--oca project-service -m project_sla
```

For details run ```odoo-helper fetch --help```


## Complete example

```bash
# Install odoo-helper scripts pre-requirements.
# This step should be usualy ran one time, and is required to ensure that
# all odoo-helper dependencies installed.
odoo-helper install pre-requirements

# Install system dependencies for odoo version 10.0
# This option requires sudo.
odoo-helper install sys-deps 10.0;

# Install postgres and create there user with name='odoo' and password='odoo'
odoo-helper install postgres odoo odoo

# Install odoo 10.0 into 'odoo-10.0' directory
odoo-install -i odoo-10.0 --odoo-version 10.0
cd odoo-10.0

# Now You have odoo-10.0 installed in this directory.
# Note, that this odoo installation uses virtual env (venv dir)
# Also You will find there odoo-helper.conf config file

# So now You may run local odoo server (i.e openerp-server script).
# Note that this command run's server in foreground.
odoo-helper server run  # This will automaticaly use config file: conf/odoo.conf

# Press Ctrl+C to stop seerver

# To run server in backgroud use following command
odoo-helper server start

# there are also few additional server related commands:
odoo-helper server status
odoo-helper server log
odoo-helper server ps
odoo-helper server restart
odoo-helper server stop

# Also there are shourtcuts for these commands:
odoo-helper status
odoo-helper log
odoo-helper restart
odoo-helper stop

# Let's install fetch module contract from OCA repository 'contract'
# Here branch will be detected automatically
odoo-helper fetch --oca contract

# Or alternatively
odoo-helper fetch --github OCA/contract --branch 10.0

# Now look at custom_addons/ dir, there will be placed links to addons
# from https://github.com/OCA/contract repository
# But repository itself is placed in repositories/ directory

# Now let's run tests for these just installed modules
odoo-helper test --create-test-db -m contract

# this will create test database (it will be dropt after test finished) and 
# run tests for modules 'base_tags' and 'product_tags'

# Or we can run tests of whole directory, odoo-helper-scripts
# will automaticaly detect installable addons and test it
odoo-helper test -d ./repositories/contract

# This will use standard test database, that will not be dropt after tests,
# so we do not need to recreate database on each test run, which saves time

# If You need color output from Odoo, you may use '--use-unbuffer' option,
# but it depends on 'expect-dev' package.
odoo-helper --use-unbuffer test -m contract

# The one cool thing of odoo-helper script, you may not remeber paths to odoo instalation,
# and if you change directory to another inside your odoo project, everything will continue to work.
cd custom_addons
odoo-helper server status
dooo-helper server restart

# So... let's install one more odoo version
# go back to directory containing our projects (that one, where odoo-10.0 project is placed)
cd ../../

# Let's install odoo of version 8.0 here too.
# First, install system dependencies for odoo version 8.0
odoo-helper install sys-deps 8.0;

# And when system dependencies installed, install odoo itself
odoo-install --install-dir odoo-8.0 --odoo-version 8.0
cd odoo-8.0

# and install there for example addon 'project_sla' for 'project' Odoo Comutinty repository
# Note  that odoo-helper script will automaticaly fetch branch named as server version in current install,
# if another branch was not specified
odoo-helper fetch --oca project -m project_sla

# and run tests for it
odoo-helper test --create-test-db -m project_sla


# also if you want to install python packages in current installation environment, you may use command:
odoo-helper fetch -p suds  # this installs 'suds' python package

# and as one more example, let's install aeroo-reports with dependancy to aeroolib in odoo 10.0
cd ../odoo-10.0
odoo-helper fetch --github gisce/aeroo -n aeroo
odoo-helper fetch -p git+https://github.com/jamotion/aeroolib#egg=aeroolib

```
