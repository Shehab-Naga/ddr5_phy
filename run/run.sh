#!/bin/sh

##########################
# Tool Related
##########################
TESTCASE="ddr_sanity_test"
SEED="1"
UVM_VERBOSITY="+UVM_VERBOSITY=UVM_LOW"
GUI_ARG=""
UVM_TO="10000000"
COMPILE_ONLY="FALSE" 	#Use it when just compiling 
COV="FALSE"		#Use it for coverage collection enabling
COVERAGE_OPITONS=""		#Complements $COV
NUM_RUNS=1

###########################
# Paths
###########################
LOGS="./log"
DUMP="./waves"
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
# Env definitions
###########################
ratio="ratio_1_to_1"
ASSERTIONS_DEF=""

###################################
# Help
###################################
usage_txt=$'\nUsage:run.sh [options]



------- Debug and Help and Etc -------

-help          	Print help/usage

-verbos_debug	Set UVM_VERBOSITY="+UVM_VERBOSITY=UVM_DEBUG +UVM_PHASE_TRACE +UVM_OBJECTION_TRACE +UVM_CONFIG_DB_TRACE"
            
-verbos_hi	Set UVM_VERBOSITY="+UVM_VERBOSITY=UVM_HIGH +UVM_CONFIG_DB_TRACE"
           
-gui		Open DVE for running and debugging



------- Build and Run control -------

-cln_bld  	Clean the work area before running.

-cov_en		Enable coverage generation.

-comp_only	Compile only, Do not run the simulation

-timeout      	Time in ns for timeout

-runs		Specify the number of runs (with different seeds) for the specified test.


------- Defines -------

-ratio		Decide the frequency ratio used thoughout the simulation.

-assert_en	Define flag to bind and use ddr assertions.



------- Dump control -------

-nosave       No dump

-wavst        Waves dump start time in "us"

-wavnm        Waves dump name

-wavdp        Waves dump depth in hierarchy from tb_top



------- Required args -------

-extra        	Extra Arguments passed
'

#

####################################

###################################
# Switches 
###################################
#Note: a "shift" is done when the option is followed by arguments
while test $# -gt 0
do
    case "$1" in
        -test)
            echo "$0: ********> Setting testcase to '$2'"
            TESTCASE="$2"
            LOG="$2.log"
            shift
            ;;
        -seed)
            echo "$0: ********> Setting seed to $2"
            SEED="$2"
            shift
            ;;
        -wavst)
            echo "$0: ********> Waves: dump start from $2 us"
            WAVE_START="$2"
            shift
            ;;
        -wavnm)
            echo "$0: ********> Waves: dump name $2"
            WAVE_NAME="$2"
            shift
            ;;
        -wavdp)
            echo "$0: ********> Waves: dump depth $2"
            WAVE_DEPTH="$2"
            shift
            ;;
        -timeout)
            echo "$0: ********> UVM Timeout : $2 ns"
            UVM_TO="$2"
            shift
            ;;
        -extra)
            echo "$0: ********> Setting extra commands $2"
            EXTRA_CMD="$2"
            shift
            ;;
        -cln_bld)
            echo "$0: ********> Clean build"
            CLN_BUILD="TRUE"
            ;;
	-gui)
            echo "$0: ********> Open GUI"
            GUI_ARG="-gui"
            ;;
        -comp_only)
            echo "$0: ********> not running"
            COMPILE_ONLY="TRUE"
            ;;
        -verbos_debug)
            UVM_VERBOSITY="+UVM_VERBOSITY=UVM_DEBUG +UVM_PHASE_TRACE +UVM_OBJECTION_TRACE +UVM_CONFIG_DB_TRACE"
            echo "$0: ********> Add $UVM_VERBOSITY to simv."
            ;;
        -verbos_hi)
            UVM_VERBOSITY="+UVM_VERBOSITY=UVM_HIGH +UVM_CONFIG_DB_TRACE"
            echo "$0: ********> Add $UVM_VERBOSITY to simv."
            ;;
        -ratio)
            echo "$0: ********> Using frequincy ratio: 1 to $2"
            ratio="ratio_1_to_$2"
            shift
            ;;
        -cov_en)
            echo "$0: ********> Enabling coverage collection"
            COV="TRUE"
	    COVERAGE_OPITONS="-lca -cm line+cond+tgl+fsm+branch+assert -cm_hier cm_hier.file"
            ;;
	-assert_en)
            echo "$0: ********> Enabling Assertions"
            ASSERTIONS_DEF="assert_en"
            ;;
	-runs)
            echo "$0: ********> Running the test $2 times with different seeds"
            NUM_RUNS=$2
            shift
            ;;
        -help)
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
			$COVERAGE_OPITONS -sverilog -timescale=1ps/1ps -ntb_opts uvm-1.2 -debug_acc+all \
			+define+$ratio +define+$ASSERTIONS_DEF \
			+libext+.sv+ \
			+incdir+$TESTBENCH \
			+incdir+$UVM_SEQUENCES \
			+incdir+$UVM_TESTS \
			+incdir+$RTL \
			$TESTBENCH/top_testbench.sv \
			-assert svaext +lint=TFIPC-L
			#-q is to Make VCS quiet -- -assert svaext is for property local variable  support 
			#-y $RTL \
			#Removed the -y option and used `include for RTL to measure code coverage
}


####################################
# Handling some input options
####################################
if [ "$CLN_BUILD" == "TRUE" ]
then
	rm -rf simv* csrc* *.xml *.vdb .tmp *.vpd *.key urgReport *.h temp ./log/*.log .vcs .txt .hvp urg .inter.vpd.uvm .restart* .synopsys* novas.* .dat *.fsdb verdi work* vlog* DVEfiles .fsm.sch.verilog.xml *.log
fi

if [ "$SEED" == "Z" ]
then
    SEED=`perl -e 'printf "%d\n", rand(2**31-1);'`
fi

if [ "$COMPILE_ONLY" == "FALSE" ]
then
    printf "\n\n$0: ********> Compiling...<********\n"
    vcs_cmd -l $LOGS/comp.log 
    printf "\n\n$0: ********> Running, with the following UVM verbosity option: $UVM_VERBOSITY <********\n"
	for i in $(seq $NUM_RUNS)
	do
		SEED=$i 
		./simv 	$GUI_ARG \
    		+UVM_TESTNAME=$TESTCASE +UVM_TIMEOUT=$UVM_TO +ntb_random_seed=$SEED \
    		+UVM_NO_RELNOTES $UVM_VERBOSITY \
    		-cm_dir "${TESTCASE}_${ratio}_${SEED}" -l $LOGS/run.log $COVERAGE_OPITONS \
    		#+UVM_TR_RECORD +UVM_LOG_RECORD \
	done

   
    
    printf "\n\n$0: ********> Sim is done <********.\n"
else
    printf "\n\n$0: ********> Compiling...<********\n"
    vcs_cmd -l $LOGS/comp.log 
fi

if [ "$COV" == "TRUE" ]
then
    printf "\n\n$0: ********> Creating Coverage Reports...<********\n\n"
    urg -lca -dir ./*.vdb
fi
#
