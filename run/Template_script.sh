###################################

# Tool Related

###################################

#

#DUMP="/simulation2/${USER}/sims/"

DUMP="./"

LOCAL="FALSE"

#

ROOTDIR=".."

export RTL="$ROOTDIR/rtl"

testbench="$ROOTDIR/testbench"

#

#---PKG

PKG="${testbench}/tb_pkg.sv"

#

#

###################################

# Paths/Env variables

###################################

TESTCASE="NONE"

#SEED="1"

SEED="Z" #Why use a random seed?

PROBE=""

CLN_BUILD="FALSE"

NO_BUILD="FALSE"

NO_RUN="FALSE"

UVM_DEBUG="+UVM_VERBOSITY=UVM_MEDIUM"

GUI_ARG="-c"

BUILDCMN="FALSE"

COV="FALSE"

COVERAGE=""

LOGS_DIR=${testbench}/run

EXTRA_CMD=""

WORK_LIB_vcs=""

SIMULATOR="vcs"

NO_BUILD_vcs=""

LOG=""

WAVE_START="0"

WAVE_NAME="waves_wddr"

WAVE_DEPTH="all"

UVM_TO="5000000"

#

#

###################################

# Help

###################################

usage_txt=$'\nUsage:simulate.sh [options]



------- Debug and Help and Etc -------

-v            Enable coverage generation.

-h            Print help/usage



------- Required args -------

-e            Extra Arguments passed



------- Build control -------

-c            Clean the work area, do not run sim

-nb           Do not build model



------- Run control -------

-nr           Do not run the simulation

-timeout      time in ns for timeout



------- Dump control -------

-nosave       No dump

-wavst        waves dump start time in "us"

-wavnm        waves dump name

-wavdp        waves dump depth in hierarchy from tb_top



------- Logging -------

-log         log name

-local       save log/shm in local dir



------- Defines -------

-mm            Wavious Memory Model driver added to environment



'

#

####################################

# RTL files

###################################

RTL_FILES="-f ${ROOTDIR}/testbench/rtl.f"

#

###################################

# Switches 

###################################
while test $# -gt 0

do

    case "$1" in

        -t)

            echo "$0: ---> Setting testcase to '$2'"

            TESTCASE="$2"

            LOG="$2.log"

            shift

            ;;

        -x)

            echo "$0: ---> Setting seed to $2"

            SEED="$2"

            shift

            ;;

        -local)

            echo "$0: ---> Dumping log/shm in local directory"

            DUMP=""

            LOCAL="TRUE"

            ;;

        -log)

            echo "$0: ---> Saving log to $2.log"

            LOG="$2.log"

            shift

            ;;

        -wavst)

            echo "$0: ---> Waves: dump start from $2 us"

            WAVE_START="$2"

            shift

            ;;

        -wavnm)

            echo "$0: ---> Waves: dump name $2"

            WAVE_NAME="$2"

            shift

            ;;

        -wavdp)

            echo "$0: ---> Waves: dump depth $2"

            WAVE_DEPTH="$2"

            shift

            ;;

        -timeout)

            echo "$0: ---> UVM Timeout : $2 ns"

            UVM_TO="$2"

            shift

            ;;

        -e)

            echo "$0: ---> Setting extra commands $2"

            EXTRA_CMD="$2"

            shift

            ;;

        -c)

            echo "$0: ---> Clean build"

            CLN_BUILD="TRUE"

            ;;

        -nb)

            echo "$0: ---> not building"

            NO_BUILD="TRUE"

            DUMP=""

            ;;

        -nr)

            echo "$0: ---> not running"

            NO_RUN="TRUE"

            ;;

        -ud)

            UVM_DEBUG="+UVM_VERBOSITY=UVM_DEBUG +UVM_PHASE_TRACE +UVM_OBJECTION_TRACE +UVM_CONFIG_DB_TRACE"

            echo "$0: ---> Add $UVM_DEBUG to vsim."

            ;;

        -uh)

            UVM_DEBUG="+UVM_VERBOSITY=UVM_HIGH +UVM_CONFIG_DB_TRACE"

            echo "$0: ---> Add $UVM_DEBUG to vsim."

            ;;

        -v)

            echo "$0: ---> Enabling coverage collection"

            COV="TRUE"

            ;;

        -h)

            echo "$0: $usage_txt"

            exit 0

            ;;

        -worklib)

            WORK_LIB_vcs="-r work_wddr -xmlibdirname $2"

            shift

            ;;

        -s)

            echo "$0: ---> blah"

            SIMULATOR="$2"

            shift

            ;;

        *)

            echo "$0: Unsupported argument '$1'"

            exit 1

            ;;

    esac

    shift

done



if [ "$CLN_BUILD" == "TRUE" ]

then

    printf "\n\n$0: ---> Cleaning...\n"

    vcs -clean

    exit 0

fi

#

#

###########################################

# RUN

###########################################

if [ "$NO_BUILD" == "TRUE" -a "$NO_RUN" == "TRUE" ] 

then 

    printf "\n\n$0: **** HELP ****  Both build and run were turned off.\n\n"

    echo "$usage_txt"

    exit 0

fi



if [ "$SEED" == "Z" ]

then

    SEED=`perl -e 'printf "%d\n", rand(2**31-1);'`

fi



if [ "$COV" == "TRUE" ]

then

    COVERAGE="-coverage "

fi

#

###########################

# VCS

###########################

EDA_PLAYGND_COMMAND_OPTIONS="-timescale=1ns/1ns +vcs+flush+all +warn=all -sverilog +vcs+vcdpluson"

EDA_PLAYGND_RUN_OPTIONS="simpleadder_test"

#

old='vcs -full64 -R -timescale=1ns/1ns +vcs+flush+all +warn=all -sverilog 				\

    -top top_testbench +vcs+vcdpluson -ntb_opts uvm-1.2				  			\

    $EXTRA_CMD                                                                    \

    $RTL_FILES                                                                    	\

    $PKG                                                                     \

    ${testbench}/top_testbench.sv'

vcs -full64 -timescale=1ns/1ns +vcs+flush+all +warn=all -sverilog 				\

    +vcs+vcdpluson -ntb_opts uvm-1.2				  			\

    $EXTRA_CMD                                                                    \

    $RTL_FILES                                                                    	\

    $PKG                                                                     \

    ${testbench}/top_testbench.sv
	
#EOF
