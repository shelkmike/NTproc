=head
If you need to understand the comments, use Google Translate.

ВАЖНО: скрипт работает только для баркодов, которые имеют название вида BC\d+

Скрипт идёт по логам porechop, которые тот делал во время демультиплексирования, и составляет список всех ридов, у которых один и тот же баркод находится на обоих концах.
Под "находится" я понимаю, что какой-то баркод:
1) Является топовым.
2) Находится на обоих концах со score выше 75. 
Я не очень понимаю, что в логах porechop означает full score, но подозреваю, что это на самом деле не alignment score, а identity, потому что эта величина порой достигает 100, но никогда не превышает 100. Порог в 75% я взял, потому что такой порог использует porechop при поиске адаптеров.

Список на выходе будет в виде
cb7c583b-89b7-47f0-9bfa-0ba84187e297 runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=24397 ch=260 start_time=2020-07-12T01:24:57Z
625e25a2-73d7-40ac-9ae7-2f1616c24260 runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=26902 ch=388 start_time=2020-07-12T01:23:42Z
ed089fa3-c124-49c7-b749-06608bec5f67 runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=28335 ch=393 start_time=2020-07-12T01:24:04Z
d6adf636-027e-476c-9dc8-677e979ecca6 runid=9351569d7a88b8016456af9ed9aeb03617c83014 sampleid=Arabidopsis_splice_map read=26622 ch=412 start_time=2020-07-12T01:24:35Z

То есть, список ридов без символа @ в начале.

Выходной список всегда выдаётся в файл list_of_reads_that_have_the_same_barcode_on_both_ends.txt

Пример использования:
perl /mnt/ssd/Schelkunov/Work/Run_diff/MinION_basecalling/Supplementary_scripts/make_a_list_of_reads_with_a_barcode_on_both_ends.pl demultiplexing_logs.txt list_of_reads_that_have_the_same_barcode_on_both_ends.txt
=cut


$path_to_porechop_demultiplexing_logs=$ARGV[0];
$path_to_the_output_list=$ARGV[1];

#Загружаю файл в массив, как написано на https://stackoverflow.com/a/8963627
open INFILE, "< $path_to_porechop_demultiplexing_logs";
chomp(my @infile = <INFILE>);
close INFILE;

open OUTFILE, "> $path_to_the_output_list";

$read_title=""; #заголовок рида, рассматриваемого сейчас.
$are_we_currently_observing_read_start_of_read_end=""; #"start", если в данный момент скрипт читает, что было найдено в начале рида. "end" - если что в конце. "" - если пока скрипт ещё не дошёл до описания ни начала, ни конца рида.
%hash_barcode_found_at_the_start_to_its_full_score=(); #ключ - название баркода, который был найден на левом конце, значение - его full score. При переходом к каждому новому риду этот хэш обнуляется.
%hash_barcode_found_at_the_end_to_its_full_score=(); #ключ - название баркода, который был найден на правом конце, значение - его full score. При переходом к каждому новому риду этот хэш обнуляется.

$line_number = 0; #Номер строки. Считается от 1.

while($line_number < $#infile)
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
	
	$line_number += 1;
	
	#Если следующая строка начинается с "  start:", значит эта строка содержит заголовок рида.
	if($infile[$line_number]=~/^\s+start\:/)
	{
		$read_title = $infile[$line_number - 1];
		chomp($read_title);
		
		%hash_barcode_found_at_the_start_to_its_full_score=(); #ключ - название баркода, который был найден на левом конце, значение - его full score. При переходом к каждому новому риду этот хэш обнуляется.
		%hash_barcode_found_at_the_end_to_its_full_score=(); #ключ - название баркода, который был найден на правом конце, значение - его full score. При переходом к каждому новому риду этот хэш обнуляется.
		$are_we_currently_observing_read_start_of_read_end=""; #"start", если в данный момент скрипт читает, что было найдено в начале рида. "end" - если что в конце. "" - если пока скрипт ещё не дошёл до описания ни начала, ни конца рида.
		
	}
	if($infile[$line_number - 1]=~/^\s+start:/)
	{
		$are_we_currently_observing_read_start_of_read_end="start";
	}
	
	if($infile[$line_number - 1]=~/^\s+end:/)
	{
		$are_we_currently_observing_read_start_of_read_end="end";
	}
	
	if($infile[$line_number - 1]=~/\s*Barcode (\d+).+full score=([\d\.]+)/)
	{
		$barcode_number=$1;
		$full_score_in_this_string=$2;
		#если номер баркода <10, то перед номером нужно вставить 0, чтобы, например, из 2 стало 02
		if($barcode_number<10)
		{
			$barcode_title="BC0".$1;
		}
		else
		{
			$barcode_title="BC".$1;
		}
		
		if($are_we_currently_observing_read_start_of_read_end=~/start/)
		{
			#иногда porechop находит два баркода одного типа на одном конце. Добавляю значение в хэш только если там ещё нет ни одного значения, либо если там сейчас значение меньше, чем нынешнее.
			if(($hash_barcode_found_at_the_start_to_its_full_score{$barcode_title}=~/^$/)||($full_score_in_this_string>$hash_barcode_found_at_the_start_to_its_full_score{$barcode_title}))
			{
				$hash_barcode_found_at_the_start_to_its_full_score{$barcode_title}=$full_score_in_this_string;
			}
		}
		if($are_we_currently_observing_read_start_of_read_end=~/end/)
		{
			#иногда porechop находит два баркода одного типа на одном конце. Добавляю значение в хэш только если там ещё нет ни одного значения, либо если там сейчас значение меньше, чем нынешнее.
			if(($hash_barcode_found_at_the_end_to_its_full_score{$barcode_title}=~/^$/)||($full_score_in_this_string>$hash_barcode_found_at_the_end_to_its_full_score{$barcode_title}))
			{
				$hash_barcode_found_at_the_end_to_its_full_score{$barcode_title}=$full_score_in_this_string;
			}
		}
	}
	
	if($infile[$line_number - 1]=~/^\s*final barcode call\:\s+(BC\d+)/)
	{
		$final_barcode_call=$1;
		#если и в начале рида и в конце со сходством выше 75 оказался тот баркод, про который porechop решил, что именно он - баркод этого рида.
		if(($hash_barcode_found_at_the_start_to_its_full_score{$final_barcode_call}>=75)&&($hash_barcode_found_at_the_end_to_its_full_score{$final_barcode_call}>=75))
		{
			print OUTFILE "$read_title\n";
		}		
	}
}


close(INFILE);
close(OUTFILE);












