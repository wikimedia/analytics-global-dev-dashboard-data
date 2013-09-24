#!/bin/bash

set -e

cd "$(dirname "$0")"

#-----------------------------------------------------------------------------
print_help() {
    cat <<EOF
blend_in_repository.sh [ OPTIONS ] OTHER_REPOSITORY

OPTIONS:
  --help          - prints this page
  --clean-links   - removes links to OTHER_REPOSITORY in the current
                    repository, before creating new ones.
  --no-add-links  - does not add new links. Use this in combination with
                    --clean-links to remove the links.

OTHER_REPOSITORY is the absolute path to the repository, whose
dashboards, grahs,... should get linked into the current repository.
EOF
}

#-----------------------------------------------------------------------------
error() {
    echo "Error: $@" >&2
    exit 1
}

#-----------------------------------------------------------------------------
parse_parameters() {
    while [ $# -gt 0 ]
    do
	local PARAM="$1"
	shift
	case "$PARAM" in
	    "--help" )
		print_help
		exit 1
		;;
	    "--clean-links" )
		CLEAN_LINKS=yes
		;;
	    "--no-add-links" )
		ADD_LINKS=no
		;;
	    * )
		if [ -z "$OTHER_REPOSITORY" ]
		then
		    OTHER_REPOSITORY="$PARAM"
		else
		    error "Unknown parameter $OTHER_REPOSITORY"
		fi
	esac
    done
}

#-----------------------------------------------------------------------------
# Setting up globals
#
ADD_LINKS=yes
CLEAN_LINKS=no
DIRS_TO_LINK=( "dashboards" "datafiles" "datasources" "geo" "graphs" )
OTHER_REPOSITORY=
parse_parameters "$@"

#-----------------------------------------------------------------------------
# Checking whether OTHER_REPOSITORY_DIR_ABS is an absolute directory
#
if [ -z "$OTHER_REPOSITORY" ]
then
    error "No OTHER_REPOSITORY given."
fi
if [ "${OTHER_REPOSITORY:0:1}" != "/" ]
then
    error "$OTHER_REPOSITORY is not given as absolute path."
fi
if [ ! -d "$OTHER_REPOSITORY" ]
then
    error "$OTHER_REPOSITORY is not a directory."
fi
OTHER_REPOSITORY_DIR_ABS="$OTHER_REPOSITORY"


#-----------------------------------------------------------------------------
# Checking whether OTHER_REPOSITORY_DIR_ABS looks like a limn data repository
#
for DIR_TO_LINK in "${DIRS_TO_LINK[@]}"
do
    if [ ! -d "$OTHER_REPOSITORY_DIR_ABS/$DIR_TO_LINK" ]
    then
	error "$OUTER_REPOSITORY_DIR_ABS does not look like a limn data \
repository, as $OTHER_REPOSITORY_DIR_ABS/$DIR_TO_LINK is not a directory"
    fi

    if [ ! -z "$(find "$OTHER_REPOSITORY_DIR_ABS/$DIR_TO_LINK" -mindepth 2 -type f)" ]
    then
	error "$OTHER_REPOSITORY_DIR_ABS/$DIR_TO_LINK contains files in \
subdirectories. This functionality is not yet covered in this script"
    fi
done

#-----------------------------------------------------------------------------
# Cleaning up links from previous runs of this script, if requested
#
if [ "$CLEAN_LINKS" = "yes" ]
then
    for DIR_TO_LINK in "${DIRS_TO_LINK[@]}"
    do
	find "$DIR_TO_LINK" -lname "$OTHER_REPOSITORY_DIR_ABS/$DIR_TO_LINK/*" -delete
    done
fi

#-----------------------------------------------------------------------------
# Adding the links to dashboards, graphs, ... of OTHER_REPOSITORY_DIR_ABS if
# requested
#
if [ "$ADD_LINKS" = "yes" ]
then
    for DIR_TO_LINK in "${DIRS_TO_LINK[@]}"
    do
	find "$OTHER_REPOSITORY_DIR_ABS/$DIR_TO_LINK" \
	    -type f \
	    ! -name ".gitignore" \
	    -exec ln -s {} "$DIR_TO_LINK" \;
    done
fi
