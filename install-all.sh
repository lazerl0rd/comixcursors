#! /bin/bash
#
# install-all.sh
# Part of ComixCursors, a desktop cursor theme.
#
# Copyright © 2010 Ben Finney <ben+gnome@benfinney.id.au>
# Copyright © 2006–2010 Jens Luetkens <j.luetkens@hamburg.de>
#
# This work is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this work. If not, see <http://www.gnu.org/licenses/>.

themename_stem="ComixCursors"
configfile_dir="${themename_stem}Configs"
configfile_template_name="custom"

# Set the ICONSDIR destination to a default (if not already set).
ICONSDIR=${ICONSDIR:-~/.icons}
export ICONSDIR

# argument processing and usage
function usage {
  echo ""
  echo "  $0 [OPTION]"
  echo "  Install the ComixCursors mouse theme."
  echo "  OPTIONS:"
  echo "    -h:    Display this help."
  echo "    -u:    Uninstall the ComixCursors mouse theme."
  echo ""
  exit
}

while getopts ":uh" opt; do
  case $opt in
    h)
      usage
      ;;
    u)
      UNINSTALL=true
      ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
  esac
done

function build_theme {
    # Build the cursors for a particular theme.
    THEMENAME="$1"

    destdir="${ICONSDIR}/${themename_stem}-${THEMENAME}"
    if [ -d "${destdir}" ] ; then
        rm -r "${destdir}"
    fi

    # left-handed cursors
    if [[ "$THEMENAME" == LH-* ]] ; then
	LH="-LH"
    else 
	LH=""
    fi

    export THEMENAME
    export LH

    if [ $UNINSTALL ] ; then
        make uninstall
    else
        printf "\nBuilding \"${THEMENAME}\":\n\n"
        ./build-cursors
        make
        make install
    fi
}

for configfile in "${configfile_dir}"/*.CONFIG ; do
    # Each config file represents a theme to be built.
    configfile_name=$(basename "$configfile")
    themename="${configfile_name%.CONFIG}"
    if [ "$themename" == "$configfile_template_name" ] ; then
        # The template isn't a theme we want to build.
        continue
    fi
    build_theme "$themename"
done
