#!/usr/bin/env bash

#See github.com/shelkmike/NTproc
ntproc_version=1.2

#######################################
#Step 0. Getting command line arguments and checking whether all required programs are in $PATH.

#The default values.
number_of_cpu_threads_to_use=1 #Porechop is poorly parallelized, so NTproc always uses one thread (really, there is almost no difference whether is uses one thread or a hundred threads). To parallelize NTproc, it's better for a user to split the input FASTQ file into batches and process them separately. NTproc has a parameter "--threads", but I hide it from a user (it's mentioned neither in --help, nor in Github), because it has almost no effect.
path_to_the_output_folder="NTproc_results"
path_to_the_input_fastq="empty"
pcr_adapter_sequence="empty"

#Parsing the command line arguments. The method is based on a suggestion from https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash .
while [[ $# -gt 0 ]] 
do
	key="$1"

	case $key in
		--fastq)
		path_to_the_input_fastq="$2"
		shift
		shift
		;;
		--adapter)
		pcr_adapter_sequence="$2"
		shift
		shift
		;;
		--threads)
		number_of_cpu_threads_to_use="$2"
		shift
		shift
		;;
		--output_folder)
		path_to_the_output_folder="$2"
		shift
		shift
		;;
		--help)
		print_help="yes"
		shift
		;;
		--version)
		echo "NTproc "$ntproc_version
		exit #If the user needs only the version of NTproc, NTproc prints it and stops.
		shift
		;;
		*)    # unknown option
		list_of_unknown_options+=("$1")
		shift
		;;
	esac
done


#If the user didn't provide some of the required options, NTproc prints help and stops. Also, it stops if the user has used "--help" key or provided an option which NTproc doesn't know.
if [[ $path_to_the_input_fastq =~ ^"empty"$ ]] || [[ $pcr_adapter_sequence =~ ^"empty"$ ]] || [[ $print_help =~ "yes"$ ]] || [[ $list_of_unknown_options =~ .+ ]]; then
	cat << EOF
###########################################
Mandatory options:
1) --fastq - path to a FASTQ file with unprocessed reads.
2) --adapter - sequence of the adapter used for PCR. For details, see https://github.com/shelkmike/NTproc.

###########################################
Additional option:
3) --output_folder - the folder to write results to. The default value is "NTproc_results".

###########################################
Descriptive options:
4) --help - Print this help.
5) --version - Print the version of NTproc.

###########################################
Example:
bash ntproc.sh --fastq unprocessed_nanopore_reads.fastq --adapter AAGCAGTGGTATCAACGCAGAGT

EOF
exit
fi


#If the user has provided relative paths, I convert them to absolute paths (as suggested at https://stackoverflow.com/questions/4175264/how-to-retrieve-absolute-path-given-relative)
path_to_the_input_fastq="$(cd "$(dirname "$path_to_the_input_fastq")"; pwd)/$(basename "$path_to_the_input_fastq")"
path_to_the_output_folder="$(cd "$(dirname "$path_to_the_output_folder")"; pwd)/$(basename "$path_to_the_output_folder")"

#I also determine the path to the current folder.
path_to_the_folder_from_which_NTproc_was_run=$PWD

#Path to the folder where ntproc.sh is located. It is necessary to locate its supporting scripts.
path_to_the_folder_with_NTproc="$(cd "$(dirname "$0")"; pwd)"

#Checking whether all programs required by NTproc are available.
list_of_warnings_about_unavailability_of_dependencies="" #to this list I will add information about unavailable programs. If there are any, I will print the list to the user.
number_of_the_current_problem_with_unavailability=0 #all problems with unavailability of dependencies are enumerated starting with 1.

if ! [ -d $path_to_the_folder_with_NTproc/Supporting_files ] 
then
	number_of_the_current_problem_with_unavailability=$(expr $number_of_the_current_problem_with_unavailability + 1)
	list_of_warnings_about_unavailability_of_dependencies=$list_of_warnings_about_unavailability_of_dependencies"\n\n"$number_of_the_current_problem_with_unavailability") Cannot find the folder /Supporting_files . It should be located in the same folder where ntproc.sh is located. Please, download the full release from https://github.com/shelkmike/NTproc/releases."
fi

if ! [ $(type -P perl 2>/dev/null) ] 
then
	number_of_the_current_problem_with_unavailability=$(expr $number_of_the_current_problem_with_unavailability + 1)
	list_of_warnings_about_unavailability_of_dependencies=$list_of_warnings_about_unavailability_of_dependencies"\n\n"$number_of_the_current_problem_with_unavailability") Cannot find 'perl' in \$PATH."
fi

if ! [ $(type -P modified_porechop 2>/dev/null) ] 
then
	number_of_the_current_problem_with_unavailability=$(expr $number_of_the_current_problem_with_unavailability + 1)
	list_of_warnings_about_unavailability_of_dependencies=$list_of_warnings_about_unavailability_of_dependencies"\n\n"$number_of_the_current_problem_with_unavailability") Cannot find 'modified_porechop' in \$PATH. Please install it from https://github.com/shelkmike/Modified_porechop ."
fi

#if there are unavailable programs or scripts, NTproc writes this and exits.
if [[ $list_of_warnings_about_unavailability_of_dependencies =~ .+ ]];then
	echo -e "\n###########################################"
	echo -e "Unfortunately, NTproc cannot find some programs: "$list_of_warnings_about_unavailability_of_dependencies
	exit
fi

#Creating the output folder.
mkdir --parents $path_to_the_output_folder


#Printing the user-provided parameters to the logfile.
#current_date_and_time=`date`
#echo "At "$current_date_and_time" NTproc was run with the following options:" >$path_to_the_output_folder/logfile.txt
#echo "1) Path to input FASTQ: "$path_to_the_input_fastq >>$path_to_the_output_folder/logfile.txt
#echo "2) PCR adapter: "$pcr_adapter_sequence >>$path_to_the_output_folder/logfile.txt
#echo "3) Number of CPU threads to use: "$number_of_cpu_threads_to_use >>$path_to_the_output_folder/logfile.txt
#echo "4) Path to the output folder: "$path_to_the_output_folder >>$path_to_the_output_folder/logfile.txt

#Creating a FASTA file with the PCR adapter sequence and its reverse complement.
#If such a file already exists, I remove it first.
if [ -f "$path_to_the_output_folder/adapters_without_barcodes.fasta" ]; then
    rm $path_to_the_output_folder/adapters_without_barcodes.fasta
fi

cp $path_to_the_folder_with_NTproc/Supporting_files/standard_nanopore_adapters_without_barcodes.fasta $path_to_the_output_folder/adapters_without_barcodes.fasta
echo "" >>$path_to_the_output_folder/adapters_without_barcodes.fasta #empty line, because standard_nanopore_adapters_without_barcodes.fasta doesn't have a linebreak at the end.
echo ">PCR_adapter|left" >>$path_to_the_output_folder/adapters_without_barcodes.fasta
echo $pcr_adapter_sequence >>$path_to_the_output_folder/adapters_without_barcodes.fasta

pcr_adapter_sequence__reverse_complement=`echo $pcr_adapter_sequence | tr ACGTacgt TGCAtgca | rev` #making a reverse complement as suggested at https://bioinformatics.stackexchange.com/questions/7458/what-is-a-quick-way-to-find-the-reverse-complement-in-bash
echo ">PCR_adapter|right" >>$path_to_the_output_folder/adapters_without_barcodes.fasta
echo $pcr_adapter_sequence__reverse_complement >>$path_to_the_output_folder/adapters_without_barcodes.fasta

#Trimming the PCR Adapter
modified_porechop -i $path_to_the_input_fastq -o $path_to_the_output_folder/reads_from_pass_concatenated__PCR_adapter_trimmed.fastq --threads $number_of_cpu_threads_to_use --verbosity 3 --adapters $path_to_the_output_folder/adapters_without_barcodes.fasta >$path_to_the_output_folder/pcr_adapter_trimming_logs.txt


#Retaining only the reads that had PCR adapter on both ends
perl $path_to_the_folder_with_NTproc/Supporting_files/retain_only_reads_that_have_PCR_adapter_on_both_ends.pl $path_to_the_output_folder/reads_from_pass_concatenated__PCR_adapter_trimmed.fastq $path_to_the_output_folder/pcr_adapter_trimming_logs.txt $path_to_the_output_folder/reads_from_pass_concatenated__PCR_adapter_trimmed__only_reads_with_PCR_adapter_at_both_ends.fastq $path_to_the_output_folder/list_of_read_titles_for_reads_with_PCR_adapter_adapters_on_both_ends.txt

#Making a folder with demultiplexing results
mkdir $path_to_the_output_folder/Demultiplexed

#Demultiplexing
modified_porechop -i $path_to_the_output_folder/reads_from_pass_concatenated__PCR_adapter_trimmed__only_reads_with_PCR_adapter_at_both_ends.fastq -b $path_to_the_output_folder/Demultiplexed --threads $number_of_cpu_threads_to_use --verbosity 3 --adapters $path_to_the_folder_with_NTproc/Supporting_files/standard_nanopore_barcodes.fasta >$path_to_the_output_folder/demultiplexing_logs.txt

#Removing reads that have barcodes on both ends
#First, making a list of such reads
perl $path_to_the_folder_with_NTproc/Supporting_files/make_a_list_of_reads_with_a_barcode_on_both_ends.pl $path_to_the_output_folder/demultiplexing_logs.txt $path_to_the_output_folder/list_of_reads_that_have_the_same_barcode_on_both_ends.txt
#Removing reads
find $path_to_the_output_folder/Demultiplexed/ -type f -name "*.fastq" -exec perl $path_to_the_folder_with_NTproc/Supporting_files/drop_reads_from_a_list.pl {} $path_to_the_output_folder/list_of_reads_that_have_the_same_barcode_on_both_ends.txt \;
#Moving reads before the removal to a separate folder. They may be useful for comparison with final reads.
mkdir $path_to_the_output_folder/Demultiplexed__before_dropping_of_reads_with_barcodes_on_both_ends/
mv $path_to_the_output_folder/Demultiplexed/*[0-9].fastq $path_to_the_output_folder/Demultiplexed/none.fastq $path_to_the_output_folder/Demultiplexed__before_dropping_of_reads_with_barcodes_on_both_ends/

#Rotating the reads that have barcodes on the left, such that it becomes on the right.
#First, making a list with barcodes on the left.
perl $path_to_the_folder_with_NTproc/Supporting_files/make_a_list_of_reads_with_a_barcode_on_the_left.pl $path_to_the_output_folder/demultiplexing_logs.txt $path_to_the_output_folder/list_of_reads_to_make_reverse_complement.txt
#Rotating the reads
find $path_to_the_output_folder/Demultiplexed/ -type f -name "*.fastq" -exec perl $path_to_the_folder_with_NTproc/Supporting_files/reverse_complement_reads_from_a_list.pl {} $path_to_the_output_folder/list_of_reads_to_make_reverse_complement.txt \;

#Moving reads before the rotation to a separate folder. They may be useful for comparison with final reads.
mkdir $path_to_the_output_folder/Demultiplexed__before_reverse_complementing/
mv $path_to_the_output_folder/Demultiplexed/*__with_some_reads_omitted.fastq $path_to_the_output_folder/Demultiplexed__before_reverse_complementing/

#Renaming FASTQ files so they have better names as suggested at https://stackoverflow.com/questions/21691864/bash-removing-part-of-a-file-name.
for fname in $path_to_the_output_folder/Demultiplexed__before_reverse_complementing/*__with_some_reads_omitted.fastq ; do mv "$fname" "$(echo "$fname" | sed -r 's/__with_some_reads_omitted//')" ; done
for fname in $path_to_the_output_folder/Demultiplexed/*__with_some_reads_omitted__with_some_reads_reverse_complemented.fastq ; do mv "$fname" "$(echo "$fname" | sed -r 's/__with_some_reads_omitted__with_some_reads_reverse_complemented//')" ; done

