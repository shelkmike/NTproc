=head
If you need to understand the comments, use Google Translate.

Этот скрипт берёт на вход имя входного файла с ридами, имя файла с логами porechop (запущенного с опцией --verbosity 3) и имя выходного файла с ридами, и записывает в выходной только те, в которых PCR_adapter нашёлся на обоих концах.

Пример использования:
perl /mnt/ssd/Schelkunov/Work/Run_diff/MinION_basecalling/Supplementary_scripts/retain_only_reads_that_have_PCR_adapter_on_both_ends.pl input.fastq porechop_logs.txt output.fastq list_of_read_titles_for_reads_with_PCR_adapter_adapters_on_both_ends.txt
=cut

$path_to_the_input_fastq=$ARGV[0];
$path_to_the_porechop_logs=$ARGV[1];
$path_to_the_output_fastq=$ARGV[2];
$path_to_the_output_list=$ARGV[3];

#Загружаю файл в массив, как написано на https://stackoverflow.com/a/8963627
open PORECHOP_LOGS, "< $path_to_the_porechop_logs";
chomp(my @porechop_logs = <PORECHOP_LOGS>);
close PORECHOP_LOGS;

open LIST_OF_READ_TITLES_FOR_READS_WITH_PCR_ADAPTER_ADAPTERS_ON_BOTH_ENDS, "> $path_to_the_output_list";
=head
13236cbb-82d6-4038-b5d2-aa1e75c03a6c runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=32832 ch=218 start_time=2020-07-12T01:24:41Z
  start: GTTGTACTTCGTTCAGTTACGTATTGCTAAACAATTAGTATCAACTGCCAGAGTACGCAGGATGCGGAACTGATTGATGAAACTATCAAGGTTTTTCTGGAAGGTACGCGAACCGAGCTGGAAGACTGTCTCTCATTTAATAAATTAGAG...
    start alignments:
      PCR_adapter, full score=76.923077, partial score=76.923077, read position: 29-54
      SQK-NSK007, full score=92.857143, partial score=92.857143, read position: 2-28
  end:   ...AGTGTTGACTCAAAACTATCTATTTTGTTGCAGTACCTGCAGTGGAAAACATAAGCTGAAGAAAAAAAAAACAAACAAAAAAAAACAGACGGAAAGCTACAAACGGAATCGAGTACTCTGCACGTTATTCACTGCTTAGGCAATACGTAA
    end alignments:
      PCR_adapter, full score=80.0, partial score=80.0, read position: 114-137
      SQK-NSK007, full score=50.0, partial score=100.0, read position: 139-150

0f1f556e-7b16-4c69-9d18-f0326fe8f37a runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=29156 ch=83 start_time=2020-07-12T01:24:02Z
  start: GGTATACTTGAATTCGAGATTACGTATTGCTGGCAAATTAATTTCAGCGCGAGTACGCGGAGGTCGGTCTAAGCTTAAAAAAAAAAAAAAACAAAAAAACAAAAAAAAACAAAAAAAAGCAAAAAAAAAATAAAAAAACAAAAAAGAAAA...
  end:   ...CCACTGTAGCAATACGTAACAGTATGCTTCAGTTCAGTTACGTATTGCTAAGCAGTGGTATCAACGCACAGAGTACTTCTCGCAAAGGCAGAGAAAGTAGTCTTTTCGCTTATTGATATGCTTAAACTCCCCGCGTACTCTGCGTTGATA
    end alignments:
      PCR_adapter, full score=92.0, partial score=92.0, read position: 49-74
      PCR_adapter, full score=60.869565, partial score=100.0, read position: 136-150

=cut

$read_title="";

$line_number = 0; #Номер строки. Считается от 1.

while($line_number < $#porechop_logs)
{
	$line_number += 1;
	
	#Если следующая строка начинается с "  start:", значит эта строка содержит заголовок рида.
	if($porechop_logs[$line_number]=~/^\s+start\:/)
	{
		$previous_read_title=$read_title; #заголовок предыдущего рида.
		
		$read_title = $porechop_logs[$line_number - 1];
		chomp($read_title);
		
		#проверяю, были ли адаптеры PCR_adapter на начале и на конце предыдущего рида. Если "да", то печатаю начало заголовка этого рида в выходной файл.
		if(($does_this_read_have_a_PCR_adapter_adapter_at_the_start=~/^yes$/)&&($does_this_read_have_a_PCR_adapter_adapter_at_the_end=~/^yes$/))
		{
			print LIST_OF_READ_TITLES_FOR_READS_WITH_PCR_ADAPTER_ADAPTERS_ON_BOTH_ENDS "$previous_read_title\n";
		}
		
		
		$does_this_read_have_a_PCR_adapter_adapter_at_the_start="no";
		$does_this_read_have_a_PCR_adapter_adapter_at_the_end="no";
		$are_we_currently_observing_read_start_of_read_end=""; #"start", если в данный момент скрипт читает, что было найдено в начале рида. "end" - если что в конце. "" - если пока скрипт ещё не дошёл до описания ни начала, ни конца рида.
	}
	if($porechop_logs[$line_number - 1]=~/^\s+start:/)
	{
		$are_we_currently_observing_read_start_of_read_end="start";
	}
	
	if($porechop_logs[$line_number - 1]=~/^\s+end:/)
	{
		$are_we_currently_observing_read_start_of_read_end="end";
	}
	
	if(($porechop_logs[$line_number - 1]=~/PCR_adapter/)&&($are_we_currently_observing_read_start_of_read_end=~/^start$/))
	{
		$does_this_read_have_a_PCR_adapter_adapter_at_the_start="yes";
	}
	if(($porechop_logs[$line_number - 1]=~/PCR_adapter/)&&($are_we_currently_observing_read_start_of_read_end=~/^end$/))
	{
		$does_this_read_have_a_PCR_adapter_adapter_at_the_end="yes";
	}	
}
#делаю обработку самого последнего рида.
$previous_read_title=$read_title; #заголовок предыдущего рида.
if(($does_this_read_have_a_PCR_adapter_adapter_at_the_start=~/^yes$/)&&($does_this_read_have_a_PCR_adapter_adapter_at_the_end=~/^yes$/))
{
	print LIST_OF_READ_TITLES_FOR_READS_WITH_PCR_ADAPTER_ADAPTERS_ON_BOTH_ENDS "$previous_read_title\n";
}

#собственно, выписываю в формате fastq риды, у которых были адаптеры PCR_adapter на обоих концах
$path_to_this_script = $0;
$path_to_the_folder_with_this_script = $path_to_this_script;
$path_to_the_folder_with_this_script =~ s/^(.+)\/.+/$1/;
system("perl $path_to_the_folder_with_this_script/extract_reads_from_fastq.pl $path_to_the_input_fastq $path_to_the_output_list >$path_to_the_output_fastq");








