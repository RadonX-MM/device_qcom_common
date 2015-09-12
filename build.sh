#!/bin/bash

## AOSParadox Build Script ##

# Display Script Usage
usage()
{
  echo ""
  echo "${txtbld}Usage:${txtrst}"
  echo "  bash build.sh [options] [device] [variant]"
  echo ""
  echo "${txtbld}  Options:${txtrst}"
  echo "    -c# Cleaning options before build:"
  echo "        1 - make clobber"
  echo "        2 - make dirty"
  echo "        3 - make magic"
  echo "        4 - make kernelclean"
  echo "    -j# Set jobs"
  echo "    -l#  Save output in log"
  echo "	 2 - make"
  echo "    -s  Sync before build"
  echo ""
  echo "${txtbld}  Variants:${txtrst}"
  echo "    -userdebug (default)"
  echo "    -user"
  echo ""
  echo "${txtbld}  Example:${txtrst}"
  echo "    bash build.sh -c1 -j18 bacon userdebug"
  echo ""
  exit 1
}

yn_check()
{
 until [[ $yorn = y || $yorn = n ]]; do
   echo ""
   read -p "${bldred}Please enter [y/n]: ${txtrst}" yorn
 done
}

cmmnd_check()
{
 if [[ $? -ne 0 ]]; then
   echo ""
   echo "${bldred}ERROR:${txtrst} '$cmmnd' failed"
   exit 1
 fi
}

# Prepare output colouring commands
red=$(tput setaf 1) # Red
grn=$(tput setaf 2) # Green
blu=$(tput setaf 4) # Blue
txtbld=$(tput bold) # Bold
bldred=${txtbld}${red} # Bold Red
bldgrn=${txtbld}${grn} # Green
bldblu=${txtbld}${blu} # Blue
txtrst=$(tput sgr0) # Reset

if [[ ! -d .repo ]]; then
  echo ""
  echo "${bldred}ERROR:${txtrst} No .repo directory found."
  echo "Is this an Android build tree?"
  exit 2
fi

if [[ ! -d vendor/aosparadox ]]; then
  echo ""
  echo "${bldred}ERROR:${txtrst} No vendor/aosparadox directory found.  Is this an AOSParadox build tree?"
  exit 3
fi

# Find the output directories
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
thisSRCDIR="${PWD##*/}"

if [[ -z $OUT_DIR_COMMON_BASE ]]; then
  export OUTDIR="$DIR/out"
  echo ""
  echo "${bldblu}WARNING:${txtrst} No external out, using default ($OUTDIR)"
else
  export OUTDIR="$OUT_DIR_COMMON_BASE"
  echo ""
  echo "${bldblu}WARNING:${txtrst} External out DIR is set ($OUTDIR)"
fi

# Get OS (Linux / Mac OS X)
IS_DARWIN=$(uname -a | grep Darwin)

if [[ -n "$IS_DARWIN" ]]; then
  CPUS=$(sysctl hw.ncpu | awk '{print $2}')
  DATE=gdate
else
  CPUS=$(grep "^processor" /proc/cpuinfo | wc -l)
  DATE=date
fi

export OPT_CPUS=$(bc <<< "($CPUS-1)*2")
opt_clean=0
opt_jobs="$OPT_CPUS"
opt_sync=0
opt_log=0

while getopts "c:hj:lsu" opt; do
  case "$opt" in
      c) opt_clean="$OPTARG" ;;
      h) usage ;;
      j) opt_jobs="$OPTARG" ;;
      l) opt_log=1 ;;
      s) opt_sync=1 ;;
      u) usage ;;
      *) echo "" && echo "${bldred}ERROR:${txtrst} Incorrect parameter"
	 usage ;;
  esac
done
shift $((OPTIND-1))

device="$1"
variant="$2"

if [[ -z $device ]]; then
  echo ""
  echo "${bldred}ERROR:${txtrst} No device specified"
  usage

elif [[ $device -ne bacon || $device -ne falcon || $device -ne titan ]]; then
  echo ""
  echo "${bldred}ERROR:${txtrst} Invalid device specified (if you're trying to build AOSParadox for other devices, add it on line 126)"
  echo ""
  echo "Supported devices:"
  echo "		     - bacon (OnePlus One)"
  echo "		     - falcon (Motorola Moto G 2014)"
  echo "		     - titan (Motorola Moto G 2013)"
  exit 4
fi

if [[ -z $variant ]]; then
  echo "${blu}WARNING:${txtrst} No build variant specified, 'userdebug' will be used"
  variant=userdebug
fi

if [[ $device = bacon ]]; then
  f_device="OnePlus One"

elif [[ $device = falcon ]]; then
  f_device="Motorola Moto G (2014)"

elif [[ $device = titan ]]; then
  f_device="Motorola Moto G (2013)"
fi

if [[ $opt_clean -eq 1 ]]; then
  echo ""
  echo "${bldblu}Cleaning out directory...${txtrst}"
  cmmnd="make clobber"
  make clobber &>/dev/null
  cmmnd_check
  echo "${bldgrn}SUCCES: ${txtrst}Out is clean"

elif [[ $opt_clean -eq 2 ]]; then
  echo ""
  echo "${bldblu}Preparing for dirty...${txtrst}"
  cmmnd="make dirty"
  make dirty &>/dev/null
  cmmnd_check
  echo "${bldgrn}SUCCES:${txtrst} Out is ready for dirty-building"

elif [[ $opt_clean -eq 3 ]]; then
  echo ""
  echo "${bldblu}Preparing your magical adventures...${txtrst}"
  cmmnd="make magic"
  make magic &>/dev/null
  cmmnd_check
  echo "${bldgrn}SUCCES:${txtrst} Enjoy your magical adventure"

elif [[ $opt_clean -eq 4 ]]; then
  echo ""
  echo "${bldblu}Cleaning the kernel components....${txtrst}"
  cmmnd="make kernelclean"
  make kernelclean &>/dev/null
  cmmnd_check
  echo "${bldgrn}SUCCES:${txtrst} All kernel components have been removed"
fi

# Sync with latest sources
if [[ $opt_sync -ne 0 ]]; then
  echo ""
  echo "${bldblu}Syncing repository...${txtrst}"
  cmmnd="repo sync -j$opt_jobs"
  repo sync -j$opt_jobs
  cmmnd_check
  echo "${bldgrn}SUCCES:${txtrst} Repository synced"
fi
rm -f "$OUTDIR/target/product/$device/obj/KERNEL_OBJ/.version"

# Get time of startup
t1=$($DATE +%s)

# Setup environment
echo ""
echo "${bldblu}Setting up environment${txtrst}"
. build/envsetup.sh &>/dev/null

if [[ $? -eq 126 ]]; then
chmod a+x build/envsetup.sh
  . build/envsetup.sh &>/dev/null
fi
cmmnd="lunch \"full_${device}-$variant\""
lunch "full_${device}-$variant"
cmmnd_check
echo "${bldgrn}SUCCES:${txtrst} Environment setup succesfully"

# Remove system folder (this will create a new build.prop with updated build time and date)
rm -f "$OUTDIR/target/product/$device/system/build.prop"
rm -f "$OUTDIR/target/product/$device/system/app/*.odex"
rm -f "$OUTDIR/target/product/$device/system/framework/*.odex"

# Start compiling
echo ""

if [[ $opt_log -eq 2 || $opt_log -eq 3 ]]; then
  echo "${bldblu}Compiling AOSParadox for the $f_device with log ($HOME/make_${device}.log)${txtrst}"
  cmmnd="make -j$opt_jobs otapackage > $HOME/make_$device.log"
  make -j$opt_jobs otapackage > "$HOME/make_$device.log"
  cmmnd_check
  echo "${bldgrn}SUCCES:${txtrst} Build completed"
else
  echo "${bldblu}Compiling AOSParadox for the $f_device ${txtrst}"
  cmmnd="make -j$opt_jobs otapackage"
  make -j$opt_jobs otapackage
  cmmnd_check
  echo "${bldgrn}SUCCES:${txtrst} Build completed"
fi

# Finished? Get elapsed time
t2=$($DATE +%s)

tmin=$(( (t2-t1)/60 ))
tsec=$(( (t2-t1)%60 ))

echo ""
echo "${bldgrn}Total time elapsed:${txtrst} $tmin minutes $tsec seconds"
exit 0
