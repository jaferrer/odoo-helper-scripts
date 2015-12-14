
set -e; # fail on errors

# Odoo-helper mark that common module is imported
ODOO_HELPER_COMMON_IMPORTED=1;

declare -A ODOO_HELPER_IMPORTED_MODULES;
ODOO_HELPER_IMPORTED_MODULES[common]=1

# Define version number
ODOO_HELPER_VERSION="0.0.3"

# predefined filenames
CONF_FILE_NAME="odoo-helper.conf";

# Color related definitions
function allow_colors {
    NC='\e[0m';
    REDC='\e[31m';
    GREENC='\e[32m';
    YELLOWC='\e[33m';
    BLUEC='\e[34m';
    LBLUEC='\e[94m';
}

# could be used to hide colors in output
function deny_colors {
    NC='';
    REDC='';
    GREENC='';
    YELLOWC='';
    BLUEC='';
    LBLUEC='';
}

# Allow colors by default
allow_colors;
# -------------------------

# Simplify import controll
# oh_require <module_name>
function ohelper_require {
    local mod_name=$1;
    if [ -z ${ODOO_HELPER_IMPORTED_MODULES[$mod_name]} ]; then
        source $ODOO_HELPER_LIB/$mod_name.bash;
        ODOO_HELPER_IMPORTED_MODULES[$mod_name]=1;
    fi
}


# simply pass all args to exec or unbuffer
# depending on 'USE_UNBUFFER variable
# Also take in account virtualenv
function execu {
    if [ ! -z $VENV_DIR ]; then
        source $VENV_DIR/bin/activate;
    fi

    # Check unbuffer option
    if [ ! -z $USE_UNBUFFER ] && ! command -v unbuffer >/dev/null 2>&1; then
        echo -e "${REDC}Command 'unbuffer' not found. Install it to use --use-unbuffer option";
        echo -e "It could be installed by installing package expect-dev";
        echo -e "Using standard behavior${NC}";
        USE_UNBUFFER=;
    fi

    if [ -z $USE_UNBUFFER ]; then
        eval "$@";
        local res=$?;
    else
        eval unbuffer "$@";
        local res=$?;
    fi

    if [ ! -z $VENV_DIR ]; then
        deactivate;
    fi
    return $res
}


# Simple function to create directories passed as arguments
# create_dirs [dir1] [dir2] ... [dir_n]
function create_dirs {
    for dir in $@; do
        if [ ! -d $dir ]; then
            mkdir -p "$dir";
        fi
    done;
}


# Simple function to check if at least one command exists.
# Returns first existing command
function check_command {
    for test_cmd in $@; do
        if execu command -v "$test_cmd" >/dev/null 2>&1; then
            echo "$test_cmd";
            return 0;
        fi;
    done
    return -1;
}


# echov $@
# echo if verbose is on
function echov {
    if [ ! -z "$VERBOSE" ]; then
        echo "$@";
    fi
}

# check if process is running
# is_process_running <pid>
function is_process_running {
    kill -0 $1 >/dev/null 2>&1;
    return $?;
}

# random_string [length]
# default length = 8
function random_string {
    < /dev/urandom tr -dc _A-Za-z0-9 | head -c${1:-8};
}

# search_file_up <start path> <file name>
function search_file_up {
    local path=$1;
    while [[ "$path" != "/" ]];
    do
        if [ -e "$path/$2" ]; then
            echo "$path/$2";
            return 0;
        fi
        path=`dirname $path`;
    done
}

# function to print odoo-helper config
function print_helper_config {
    echo "ODOO_BRANCH=$ODOO_BRANCH;";
    echo "PROJECT_ROOT_DIR=$PROJECT_ROOT_DIR;";
    echo "CONF_DIR=$CONF_DIR;";
    echo "LOG_DIR=$LOG_DIR;";
    echo "LOG_FILE=$LOG_FILE;";
    echo "LIBS_DIR=$LIBS_DIR;";
    echo "DOWNLOADS_DIR=$DOWNLOADS_DIR;";
    echo "ADDONS_DIR=$ADDONS_DIR;";
    echo "DATA_DIR=$DATA_DIR;";
    echo "BIN_DIR=$BIN_DIR;";
    echo "VENV_DIR=$VENV_DIR;";
    echo "ODOO_PATH=$ODOO_PATH;";
    echo "ODOO_CONF_FILE=$ODOO_CONF_FILE;";
    echo "ODOO_TEST_CONF_FILE=$ODOO_TEST_CONF_FILE;";
    echo "ODOO_PID_FILE=$ODOO_PID_FILE;";
    echo "BACKUP_DIR=$BACKUP_DIR;";
}


# Function to configure default variables
function config_default_vars {
    if [ -z $PROJECT_ROOT_DIR ]; then
        echo -e "${REDC}There is no PROJECT_ROOT_DIR set!${NC}";
        return 1;
    fi
    CONF_DIR=${CONF_DIR:-$PROJECT_ROOT_DIR/conf};
    ODOO_CONF_FILE=${ODOO_CONF_FILE:-$CONF_DIR/odoo.conf};
    ODOO_TEST_CONF_FILE=${ODOO_TEST_CONF_FILE:-$CONF_DIR/odoo.test.conf};
    LOG_DIR=${LOG_DIR:-$PROJECT_ROOT_DIR/logs};
    LOG_FILE=${LOG_FILE:-$LOG_DIR/odoo.log};
    LIBS_DIR=${LIBS_DIR:-$PROJECT_ROOT_DIR/libs};
    DOWNLOADS_DIR=${DOWNLOADS_DIR:-$PROJECT_ROOT_DIR/downloads};
    ADDONS_DIR=${ADDONS_DIR:-$PROJECT_ROOT_DIR/custom_addons};
    DATA_DIR=${DATA_DIR:-$PROJECT_ROOT_DIR/data_dir};
    BIN_DIR=${BIN_DIR:-$PROJECT_ROOT_DIR/bin};
    VENV_DIR=${VENV_DIR:-$PROJECT_ROOT_DIR/venv};
    ODOO_PID_FILE=${ODOO_PID_FILE:-$PROJECT_ROOT_DIR/odoo.pid};
    ODOO_PATH=${ODOO_PATH:-$PROJECT_ROOT_DIR/odoo};
    BACKUP_DIR=${BACKUP_DIR:-$PROJECT_ROOT_DIR/backups};
}


# is_odoo_module <module_path>
function is_odoo_module {
    if [ ! -d $1 ]; then
       return 1;
    elif [ -f "$1/__openerp__.py" ] || [ -f "$1/__odoo__.py" ] || [ -f "$1/__terp__.py" ]; then
        return 0;
    else
        return 1;
    fi
}


# Load project configuration. No args prowided
function load_project_conf {
    local project_conf=`search_file_up $WORKDIR $CONF_FILE_NAME`;
    if [ -f "$project_conf" ] && [ ! "$project_conf" == "$HOME/odoo-helper.conf" ]; then
        echov -e "${LBLUEC}Loading conf${NC}: $project_conf";
        source $project_conf;
    fi

    if [ -z $PROJECT_ROOT_DIR ]; then
        echo -e "${REDC}WARNING: no project config file found${NC}";
    fi
}