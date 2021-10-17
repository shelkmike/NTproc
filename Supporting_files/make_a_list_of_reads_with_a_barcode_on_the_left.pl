=head
If you need to understand the comments, use Google Translate.

Скрипт идёт по логам porechop, которые тот делал во время демультиплексирования, и составляет список всех ридов, у которых баркод был слева.
Список на выходе будет в виде
cb7c583b-89b7-47f0-9bfa-0ba84187e297 runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=24397 ch=260 start_time=2020-07-12T01:24:57Z
625e25a2-73d7-40ac-9ae7-2f1616c24260 runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=26902 ch=388 start_time=2020-07-12T01:23:42Z
ed089fa3-c124-49c7-b749-06608bec5f67 runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=28335 ch=393 start_time=2020-07-12T01:24:04Z
d6adf636-027e-476c-9dc8-677e979ecca6 runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=26622 ch=412 start_time=2020-07-12T01:24:35Z

То есть, список ридов без символа @ в начале.

Выходной список всегда выдаётся в файл list_of_reads_to_make_reverse_complement.txt

Пример использования:
perl /mnt/ssd/Schelkunov/Work/Run_diff/MinION_basecalling/Supplementary_scripts/make_a_list_of_reads_with_a_barcode_on_the_left.pl demultiplexing_logs.txt list_of_reads_to_make_reverse_complement.txt
=cut


$path_to_porechop_demultiplexing_logs=$ARGV[0];
$path_to_the_output_list=$ARGV[1];

open INFILE, "< $path_to_porechop_demultiplexing_logs";
open OUTFILE, "> $path_to_the_output_list";

$read_title=""; #заголовок рида, рассматриваемого сейчас.
$previous_read_title=""; #заголовок предыдущего рида.
$are_we_currently_observing_read_start_of_read_end=""; #"start", если в данный момент скрипт читает, что было найдено в начале рида. "end" - если что в конце. "" - если пока скрипт ещё не дошёл до описания ни начала, ни конца рида.
$is_top_rated_barcode_at_the_start_or_at_the_end=""; #"nowhere", если для рида не найден вообще ни один баркод. "start", если на левом краю, "end, если на правом краю".
$full_score_of_the_current_top_rated_barcode=0; #full_score того баркода, у которого сейчас самый высокий рейтинг.


while(<INFILE>)
{
=head
04a37e1c-00ee-47ae-8939-fcc0022726a9 runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=28342 ch=193 start_time=2020-07-12T01:24:52Z
  start: GCGGGGACACAAAACCTGCTAATAACAATCTCCAAATGGCTAAATCATTTGTACCTCATCTTTGTGTTATGCGTTTGGTTCTCCGCACGTGGCGGTTGGAACGCCATTCCACGATGAAGGAAGTGTTTACTGCGACACTTGCCGCTTTGG...
    start alignments:
      Barcode 3 (reverse), full score=52.0, partial score=76.470588, read position: 0-16
  end:   ...AGTTTATTTAGAGTTTTATTTATTTCTATTTTATTGTATTGTTGAGTCTCTAAAGATGGTGAGACTATTTGAACTATCTAAGATAAACCATATAAAATAAAGTATTTGCAACCTTCGAAAAAAAAAAGAAGACAAAGGTTTCAGCTTAGC
    end alignments:
      Barcode 11 (reverse), full score=40.0, partial score=76.923077, read position: 137-150
      Barcode 10 (forward), full score=83.333333, partial score=83.333333, read position: 127-147
  Barcodes:
    start barcodes:        BC01 (62.1%), BC02 (46.7%), BC03 (4.2%), BC04 (16.7%), BC05 (50.0%), BC06 (64.0%), BC07 (60.0%), BC08 (59.3%), BC09 (53.3%), BC10 (69.0%), BC11 (24.0%), BC12 (25.0%)
    end barcodes:          BC01 (62.1%), BC02 (4.2%), BC03 (4.2%), BC04 (12.0%), BC05 (8.3%), BC06 (59.3%), BC07 (39.3%), BC08 (53.6%), BC09 (16.7%), BC10 (83.3%), BC11 (58.3%), BC12 (34.6%)
    best start barcode:    BC10 (69.0%)
    best end barcode:      BC10 (83.3%)
    final barcode call:    BC10

2ddc7239-025b-4553-9bb2-3803ce5c88f2 runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=25834 ch=389 start_time=2020-07-12T01:24:50Z
  start: GCGGGATGTGGGAAGAAGGGGGAAAGAGGACCTTTCACCAGCTAGCTCCCCTGTTTTTTTATGTTTAACCCTCATCAGTTTGGTTGGTGATGTATACTATCAACCGTTTCAATATCAGAAATAATTTGAATATTTAGCCGAAAAAAAAAA...
  end:   ...GAGGACCTTTCACCAGCTAGCTCCCCTGTTTTTTTATGTTTAACCCTCATCAGTTTGGTTGGTGATGTATACTATCAACCGTTTCAATATCAGAAATAATTTGAATATTTAGCCGAAAAAAAAAAAACAGACGACTACAAACGGAATCGA
    end alignments:
      Barcode 2 (reverse), full score=16.666667, partial score=100.0, read position: 146-150
      Barcode 2 (forward), full score=100.0, partial score=100.0, read position: 126-150
  Barcodes:
    start barcodes:        BC01 (20.8%), BC02 (62.5%), BC03 (4.2%), BC04 (59.3%), BC05 (57.6%), BC06 (64.0%), BC07 (59.3%), BC08 (48.0%), BC09 (61.5%), BC10 (8.3%), BC11 (66.7%), BC12 (25.0%)
    end barcodes:          BC01 (44.4%), BC02 (100.0%), BC03 (39.4%), BC04 (58.3%), BC05 (54.8%), BC06 (16.7%), BC07 (30.8%), BC08 (4.2%), BC09 (59.3%), BC10 (60.0%), BC11 (12.5%), BC12 (62.5%)
    best start barcode:    BC11 (66.7%)
    best end barcode:      BC02 (100.0%)
    final barcode call:    BC02

=cut
	#по-видимому, самый простой способ определить, какой именно баркод есть в риде по результатам porechop, это выбрать тот баркод, у которого самый высокий full_score.
	
	
	
	if($_=~/^(\S+ runid=.+)$/)
	{
		$previous_read_title=$read_title; #заголовок предыдущего рида.
		$read_title=$1;
		chomp($read_title);
		
		#если у прошлого рида баркод был слева, то записываю заголовок рид в файл, в котором заголовки тех ридов, которые нужно будет сделать обратно-комплементарными.
		if($is_top_rated_barcode_at_the_start_or_at_the_end=~/start/)
		{
			print OUTFILE "$previous_read_title\n";
			#print "For $previous_read_title the top barcode has the full score of $full_score_of_the_current_top_rated_barcode and was at $is_top_rated_barcode_at_the_start_or_at_the_end\n";
		}
		
		$are_we_currently_observing_read_start_of_read_end=""; #"start", если в данный момент скрипт читает, что было найдено в начале рида. "end" - если что в конце. "" - если пока скрипт ещё не дошёл до описания ни начала, ни конца рида.
		$is_top_rated_barcode_at_the_start_or_at_the_end="nowhere"; #"nowhere", если для рида не найден вообще ни один баркод. "start", если на левом краю, "end, если на правом краю".
		$full_score_of_the_current_top_rated_barcode=0; #full_score того баркода, у которого сейчас самый высокий рейтинг.
		
	}
	if($_=~/^\s+start:/)
	{
		$are_we_currently_observing_read_start_of_read_end="start";
	}
	
	if($_=~/^\s+end:/)
	{
		$are_we_currently_observing_read_start_of_read_end="end";
	}
	
	if($_=~/full score=([\d\.]+)/)
	{
		$full_score_in_this_string=$1;
		if($full_score_in_this_string>$full_score_of_the_current_top_rated_barcode)
		{
			$is_top_rated_barcode_at_the_start_or_at_the_end=$are_we_currently_observing_read_start_of_read_end;
			$full_score_of_the_current_top_rated_barcode=$full_score_in_this_string;
		}
	}
}

#обрабатываю последний рид
$previous_read_title=$read_title; #заголовок предыдущего рида.
if($is_top_rated_barcode_at_the_start_or_at_the_end=~/start/)
{
	print OUTFILE "$previous_read_title\n";
}



close(INFILE);
close(OUTFILE);












