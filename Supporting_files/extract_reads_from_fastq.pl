#! /usr/bin/perl
=head
If you need to understand the comments, use Google Translate.

Этот скрипт выписывает из FASTQ-файла с ридами все риды, названия которых приведены в файле $list_filename . Там должны лежать названия целиком без символа @ в начале. Печатает риды в стандартный вывод

Пример: perl /mnt/ssd/Schelkunov/Scripts/extract_reads_from_fastq.pl input_reads.fastq list_of_interesting_reads.txt >sequences_of_interesting_reads.fastq
=cut

$reads_filename=$ARGV[0];
$list_filename=$ARGV[1];

if($reads_filename=~/\.gz$/)
{
	open READS, "gzip --decompress --stdout $reads_filename | ";
}
else
{
	open READS, "< $reads_filename";
}

open LIST, "< $list_filename";

#сначала иду по списку хороших ридов и создаю хэш с их именами, а также упорядоченный массив с именами (чтобы в выходной файл писать в том же порядке, в каком они были во входном списке)
%hash_read_name_to_whether_it_is_good=(); #{"c10062_g1_i1|m.7691"}="yes" (слово "yes" только если он есть в списке)
@array_good_reads_data=(); #Массив идёт от нуля. Значения [номер рида от нуля][0]="имя без @" [номер рида от нуля][1]=последовательность, [номер рида от нуля][2]=строка с плюсиком (и тем, что там есть, кроме плюсика), [номер рида от нуля][3]=строка с качеством .
#и ещё хэш "имя рида" -> "номер рида" (от нуля)
%hash_read_name_to_its_ordinal_number=();
$current_read_number=0;
while(<LIST>)
{
	#если это не пустая строка, значит там название рида
	if($_!~/^\s*$/)
	{
		$read_name=$_;
		chomp($read_name);
		$hash_read_name_to_whether_it_is_good{$read_name}="yes";
		#print "assigned $read_name\n";
		$array_good_reads_data[$current_read_number][0]=$read_name;
		$hash_read_name_to_its_ordinal_number{$read_name}=$current_read_number;
		$current_read_number++;
	}
}

#полное количество ридов, отсчитывая от нуля (то есть, реальное на 1 больше)
$total_number_of_reads_from_zero=$current_read_number-1;

#теперь иду по фаста-файлу и добавляю последовательности хороших ридов в массив, 
$is_this_read_good="no";
while(<READS>)
{
	if((($.-1)%4==0)&&($_=~/^\@(.+)$/))
	{
		$read_name=$1;
		$is_this_read_good="no";
		#print "seeing $read_name\n";
		if($hash_read_name_to_whether_it_is_good{$read_name}=~/yes/)
		{
			#print "good $read_name\n";
			$is_this_read_good="yes";
		}

	}
	
	#если это хороший рид, и строка не с названием рида (то есть, с последовательностью или пустая), то дописываю последовательность из этой строки в массив с именами и последовательностями ридов
	if($is_this_read_good=~/yes/)
	{
		$read_number=$hash_read_name_to_its_ordinal_number{$read_name};
		if(($.-2)%4==0)
		{
			$array_good_reads_data[$read_number][1].=$_;
		}
		if(($.-3)%4==0)
		{
			$array_good_reads_data[$read_number][2].=$_;
		}
		if(($.-4)%4==0)
		{
			$array_good_reads_data[$read_number][3].=$_;
		}
	}
}

close(LIST);
close(READS);

#теперь иду по порядку ридов и печатаю их в fastq-формате
foreach $read_number (0..$total_number_of_reads_from_zero)
{
	#печатаю, только если для этого рида найдена последовательность
	if($array_good_reads_data[$read_number][1]!~/^$/)
	{
		print "@".$array_good_reads_data[$read_number][0]."\n";
		print $array_good_reads_data[$read_number][1];
		print $array_good_reads_data[$read_number][2];
		print $array_good_reads_data[$read_number][3];
	}
}




