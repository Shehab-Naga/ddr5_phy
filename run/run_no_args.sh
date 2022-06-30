#!/bin/sh

##########################
# Tool Related
##########################
TESTCASE="ddr_sanity_test"
SEED="1"
UVM_DEBUG="+UVM_VERBOSITY=UVM_MEDIUM"
GUI_ARG="-c"
UVM_TO="5000000"
COMPILE_ONLY="FALSE" 	#Use it when just compiling 
COV="FALSE"	#Use it for coverage collection enabling
COVERAGE=""	#Complements $COV

###########################
# Paths
###########################
LOGS="../logs"
DUMP="../waves"
RTL="../rtl"
TESTBENCH="../testbench"
UVM_COMPONENTS="$TESTBENCH/components"
UVM_TRANSACTIONS="$TESTBENCH/transactions"
UVM_TESTS="$TESTBENCH/tests"
UVM_SEQUENCES="$TESTBENCH/sequences"
UVM_INTERFACES="$TESTBENCH/interfaces"
UVM_DRAM_AGENT="$TESTBENCH/$UVM_COMPONENTS/dram_agent"
UVM_MC_AGENT="$TESTBENCH/$UVM_COMPONENTS/mc_agent"


###########################
# Env variables
###########################
ratio_1_to_2=""
ratio_1_to_4=""


###################################
# Switches 
###################################
while test $# -gt 0
do
    case "$1" in
        -test)
            echo "$0: ---> Setting testcase to '$2'"
            TESTCASE="$2"
            LOG="$2.log"
            shift
            ;;
        -seed)
            echo "$0: ---> Setting seed to $2"
            SEED="$2"
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
        -extra)
            echo "$0: ---> Setting extra commands $2"
            EXTRA_CMD="$2"
            shift
            ;;
        -cln)
            echo "$0: ---> Clean build"
            CLN_BUILD="TRUE"
            ;;
        -comp_only)
            echo "$0: ---> not running"
            COMPILE_ONLY="TRUE"
            ;;
        -uvm_verbos_debug)
            UVM_DEBUG="+UVM_VERBOSITY=UVM_DEBUG +UVM_PHASE_TRACE +UVM_OBJECTION_TRACE +UVM_CONFIG_DB_TRACE"
            echo "$0: ---> Add $UVM_DEBUG to vsim."
            ;;
        -uvm_verbos_hi)
            UVM_DEBUG="+UVM_VERBOSITY=UVM_HIGH +UVM_CONFIG_DB_TRACE"
            echo "$0: ---> Add $UVM_DEBUG to vsim."
            ;;
        -ratio_1_to_2)
            echo "$0: ---> Using frequincy ratio of 1 to 2"
            ratio_1_to_2="+define+ratio_1_to_2"
            ;;
	-ratio_1_to_4)
            echo "$0: ---> Using frequincy ratio of 1 to 4"
            ratio_1_to_4="+define+ratio_1_to_4"
            ;;
        -cov_en)
            echo "$0: ---> Enabling coverage collection"
            COV="TRUE"
            ;;
        -h)
            echo "$0: $usage_txt"
            exit 0
            ;;
        *)
            echo "$0: Unsupported argument '$1'"
            exit 1
            ;;
    esac
    shift
done



###########################
# VCS - Compilation
###########################

function vcs_cmd 
{
		vcs 	$* \
			-sverilog -timescale=1ns/1ns -ntb_opts uvm-1.2 \
			-y $RTL \
			+libext+.sv+ \
			+incdir+$TESTBENCH \
			+incdir+$UVM_SEQUENCES \
			+incdir+$UVM_TESTS \
			+incdir+$RTL \
			$TESTBENCH/top_testbench.sv 
}


####################################
# Handling some input options
####################################
if [ "$SEED" == "Z" ]
then
    SEED=`perl -e 'printf "%d\n", rand(2**31-1);'`
fi

if [ "$COMPILE_ONLY" == "FALSE" ]
then
    printf "\n\n$0: ---> Compiling & Running...\n"
    vcs_cmd -l $LOGS/comp.log 
    ./simv +UVM_TESTNAME=$TESTCASE +UVM_NO_RELNOTES +UVM_TESTNAME=$TESTCASE +UVM_TR_RECORD +UVM_LOG_RECORD -l $LOGS/run.log  
    printf "\n\n$0: ---> Sim is done.\n"
else
    printf "\n\n$0: ---> Compiling...\n"
    vcs_cmd -l $LOGS/comp.log 
fi

if [ "$COV" == "TRUE" ]
then
    #COVERAGE="-coverage all -covtest $TESTCASE$SEED -covdut ddr_phy_1x32"
    urg -report $LOGS/
fi


