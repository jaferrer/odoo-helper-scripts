if [ -z $ODOO_HELPER_LIB ]; then
    echo "Odoo-helper-scripts seems not been installed correctly.";
    echo "Reinstall it (see Readme on https://github.com/katyukha/odoo-helper-scripts/)";
    exit 1;
fi

if [ -z $ODOO_HELPER_COMMON_IMPORTED ]; then
    source $ODOO_HELPER_LIB/common.bash;
fi

# Require libs
ohelper_require 'git';
ohelper_require 'recursion';
ohelper_require 'addons';
ohelper_require 'fetch';
# ----------------------------------------------------------------------------------------

set -e; # fail on errors

# Define veriables
REQUIREMENTS_FILE_NAME="odoo_requirements.txt";
PIP_REQUIREMENTS_FILE_NAME="requirements.txt";
OCA_REQUIREMENTS_FILE_NAME="oca_dependencies.txt";


# link_module_impl <source_path> <dest_path> <force: on|off>
function link_module_impl {
    local SOURCE=`readlink -f $1`;
    local DEST="$2";
    local force=$3;

    if [ $force == "on" ] && ([ -e $DEST ] || [ -L $DEST ]); then
        echov "Rewriting module $DEST...";
        rm -rf $DEST;
    fi

    if [ ! -d $DEST ]; then
        if [ -z $USE_COPY ]; then
            if [ -h $DEST ] && [ ! -e $DEST ]; then
                # If it is broken link, remove it
                rm $DEST;
            fi
            ln -s $SOURCE $DEST ;
        else
            cp -r $SOURCE $DEST;
        fi
    else
        echov "Module $SOURCE already linked to $DEST";
    fi
    fetch_requirements $DEST;
    fetch_pip_requirements $DEST/$PIP_REQUIREMENTS_FILE_NAME;
    fetch_oca_requirements $DEST/$OCA_REQUIREMENTS_FILE_NAME;
}

# link_module <force: on|off> <repo_path> [<module_name>]
function link_module {
    local force=$1;
    local REPO_PATH=$2;
    local MODULE_NAME=$3

    if [ -z $REPO_PATH ]; then
        echo -e "${REDC}Bad repo path fot link: $REPO_PATH${NC}";
        return 2;
    fi

    REPO_PATH=$(readlink -f $2);

    local recursion_key="link_module";
    if ! recursion_protection_easy_check $recursion_key "${REPO_PATH}__${MODULE_NAME:-all}"; then
        echo -e "${YELLOWC}WARN${NC}: REPO__MODULE ${REPO_PATH}__${MODULE_NAME:-all} already had been processed. skipping...";
        return 0
    fi

    echov "Linking module $REPO_PATH [$MODULE_NAME] ...";

    # Guess repository type
    if is_odoo_module $REPO_PATH; then
        # single module repo
        link_module_impl $REPO_PATH $ADDONS_DIR/${MODULE_NAME:-`basename $REPO_PATH`} $force;
    else
        # multi module repo
        if [ -z $MODULE_NAME ]; then
            # Check for requirements files in repository root dir
            fetch_requirements $REPO_PATH;
            fetch_pip_requirements $REPO_PATH/$PIP_REQUIREMENTS_FILE_NAME;
            fetch_oca_requirements $REPO_PATH/$OCA_REQUIREMENTS_FILE_NAME;

            # No module name specified, then all modules in repository should be linked
            for file in "$REPO_PATH"/*; do
                if is_odoo_module $file && addons_is_installable $file; then
                    # link module
                    link_module_impl $file $ADDONS_DIR/`basename $file` $force;
                elif [ -d $file ] && ! is_odoo_module $file && [ $(basename $file) != 'setup' ]; then
                    # if it is directory but not odoo module, recursively look for addons there
                    link_module $force $file;
                fi
            done
        else
            # Module name specified, then only single module should be linked
            link_module_impl $REPO_PATH/$MODULE_NAME $ADDONS_DIR/$MODULE_NAME $force;
        fi
    fi
}


function link_command {
    local usage="
    Usage: 

        $SCRIPT_NAME link [-f|--force] <repo_path> [<module_name>]
    ";

    local force=off;

    # Parse command line options and run commands
    if [[ $# -lt 1 ]]; then
        echo "No options supplied $#: $@";
        echo "";
        echo "$usage";
        exit 0;
    fi

    # Process all args that starts with '-' (ie. options)
    while [[ $1 == -* ]]
    do
        key="$1";
        case $key in
            -h|--help)
                echo "$usage";
                exit 0;
            ;;
            -f|--force)
                force=on;
            ;;
            *)
                echo "Unknown option $key";
                exit 1;
            ;;
        esac
        shift
    done

    link_module $force "$@"
}
