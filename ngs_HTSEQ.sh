#!/bin/bash

# Copyright (c) 2012,2013, Stephen Fisher and Junhyong Kim, University of
# Pennsylvania.  All Rights Reserved.
#
# You may not use this file except in compliance with the Kim Lab License
# located at
#
#     http://kim.bio.upenn.edu/software/LICENSE
#
# Unless required by applicable law or agreed to in writing, this
# software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License
# for the specific language governing permissions and limitations
# under the License.

##########################################################################################
# INPUT: $SAMPLE/rum.trim/RUM_Unique.sorted.bam
# OUTPUT: $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt, $SAMPLE/htseq/$SAMPLE.htseq.log.txt, $SAMPLE/htseq/$SAMPLE.htseq.err.txt
# REQUIRES: HTSeq, runHTSeq.py
##########################################################################################

##########################################################################################
# USAGE
##########################################################################################

ngsUsage_HTSEQ="Usage: `basename $0` htseq OPTIONS sampleID    --  run HTSeq on unique mappers from RUM\n"

##########################################################################################
# HELP TEXT
##########################################################################################

ngsHelp_HTSEQ="Usage:\n\t`basename $0` htseq -s species sampleID\n"
ngsHelp_HTSEQ+="Input:\n\tsampleID/rum.trim/RUM_Unique.sorted.bam\n"
ngsHelp_HTSEQ+="Output:\n\tsampleID/htseq/sampleID.htseq.cnts.txt\n\tsampleID/htseq/sampleID.htseq.log.txt\n\tsampleID/htseq/sampleID.htseq.err.txt\n"
ngsHelp_HTSEQ+="Requires:\n\tHTSeq ( http://www-huber.embl.de/users/anders/HTSeq/ )\n\trunHTSeq.py ( https://github.com/safisher/ngs )\n"
ngsHelp_HTSEQ+="Options:\n"
ngsHelp_HTSEQ+="\t-s species - species files 'dmel5.49' and 'zv9' are located in $HTSEQ_REPO.\n"
ngsHelp_HTSEQ+="Run HTSeq using runHTSeq.py script. This requires the sorted BAM file containing unique reads that is generated by 'post'.\n"
ngsHelp_HTSEQ+="The following HTSeq parameter values are used: --mode=intersection-nonempty --stranded=no --type=exon --idattr=gene_id\n"
ngsHelp_HTSEQ+="For a description of the HTSeq parameters see http://www-huber.embl.de/users/anders/HTSeq/doc/count.html#count"


##########################################################################################
# PROCESSING COMMAND LINE ARGUMENTS
# HTSEQ args: -s value, -g value, sampleID
##########################################################################################

ngsArgs_HTSEQ() {
	if [ $# -lt 3 ]; then
		printHelp $COMMAND
		exit 0
	fi
	
	while getopts "s:g:" opt; do
		case $opt in
			s) SPECIES=$OPTARG
				;;
			?) printf "Illegal option: '%s'\n" "$OPTARG"
				printHelp $COMMAND
				exit 0
				;;
		esac
	done
	shift $((OPTIND - 1))   # remove options from argument list
	
	SAMPLE=$1
}

##########################################################################################
# RUNNING COMMAND ACTION
# Run HTSeq on uniqely mapped RUM output and sorted by the POST command.
##########################################################################################

ngsCmd_HTSEQ() {
	prnCmd "# BEGIN: RUNNING HTSEQ"
	
	# make relevant directory
	if [ ! -d $SAMPLE/htseq ]; then 
		prnCmd "mkdir $SAMPLE/htseq"
		if ! $DEBUG; then mkdir $SAMPLE/htseq; fi
	fi
	
	# We assume that RUM worked and 'post' has completed.
	prnCmd "runHTSeq.py $SAMPLE/rum.trim/RUM_Unique.sorted.bam $SAMPLE/htseq/$SAMPLE $HTSEQ_REPO/$SPECIES/$SPECIES.gz"
	if ! $DEBUG; then 
		runHTSeq.py $SAMPLE/rum.trim/RUM_Unique.sorted.bam $SAMPLE/htseq/$SAMPLE $HTSEQ_REPO/$SPECIES/$SPECIES.gz
	fi
	
	# parse output into three files: gene counts ($SAMPLE.htseq.cnts.txt), 
	# warnings ($SAMPLE.htseq.err.txt), log ($SAMPLE.htseq.log.txt)
	prnCmd "grep 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.out > $SAMPLE/htseq/$SAMPLE.htseq.err.txt"
	prnCmd "grep -v 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.out > $SAMPLE/htseq/tmp.txt"
	prnCmd "echo -e 'gene\tcount' > $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt"
	prnCmd "grep -P '\t' $SAMPLE/htseq/tmp.txt | grep -P -v 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' >> $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt"
	prnCmd "grep -P -v '\t' $SAMPLE/htseq/tmp.txt > $SAMPLE/htseq/$SAMPLE.htseq.log.txt"
	prnCmd "grep -P 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' $SAMPLE/htseq/tmp.txt >> $SAMPLE/htseq/$SAMPLE.htseq.log.txt"
	prnCmd "rm $SAMPLE/htseq/$SAMPLE.htseq.out $SAMPLE/htseq/tmp.txt"
	if ! $DEBUG; then 
		grep 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.out > $SAMPLE/htseq/$SAMPLE.htseq.err.txt
		grep -v 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.out > $SAMPLE/htseq/tmp.txt
		echo -e 'gene\tcount' > $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt
		grep -P '\t' $SAMPLE/htseq/tmp.txt | grep -P -v 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' >> $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt
		grep -P -v '\t' $SAMPLE/htseq/tmp.txt > $SAMPLE/htseq/$SAMPLE.htseq.log.txt
		grep -P 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' $SAMPLE/htseq/tmp.txt >> $SAMPLE/htseq/$SAMPLE.htseq.log.txt

		rm $SAMPLE/htseq/$SAMPLE.htseq.out $SAMPLE/htseq/tmp.txt
	fi
	
	prnCmd "# FINISHED: RUNNING HTSEQ"
}