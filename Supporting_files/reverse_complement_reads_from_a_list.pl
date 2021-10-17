#! /usr/bin/perl
=head
If you need to understand the comments, use Google Translate.

Этот скрипт берёт на вход FASTQ-файл с ридами и список ридов. Те риды, которые есть в списке, он делает обратно-комплементарными, а те, которых нет, он выписывает, не меняя.
Во входном списке должны лежать названия целиком без символа @ в начале. Печатает риды в файл, который называется так же, как входной, но перед .fastq идёт (__with_some_reads_reverse_complemented)

Пример: perl /mnt/ssd/Schelkunov/Scripts/reverse_complement_reads_from_a_list.pl input_reads.fastq list_of_interesting_reads.txt
=cut

$reads_filename=$ARGV[0];
$list_filename=$ARGV[1];

$outfile_name=$reads_filename;
$outfile_name=~s/^(.+)\..+/$1\__with_some_reads_reverse_complemented.fastq/;

open READS, "< $reads_filename";
open LIST, "< $list_filename";
open READS_OUTFILE, "> $outfile_name";

#сначала иду по списку ридов, которые нужно сделать обратно-комплементарными, и создаю хэш с их именами
%hash_read_name_to_whether_it_should_be_reverse_complemented=(); #{"c10062_g1_i1|m.7691"}="yes" (слово "yes" только если он есть в списке)
while(<LIST>)
{
	#если это не пустая строка, значит там название рида
	if($_!~/^\s*$/)
	{
		$read_name=$_;
		chomp($read_name);
		$hash_read_name_to_whether_it_should_be_reverse_complemented{$read_name}="yes";
		#print "$read_name will be reverse complemented\n";
	}
}


#теперь иду по FASTQ-файлу и печатаю риды, делая те, которые нужно сделать обратно-комплементарными, обратно-комплементарными.
$should_this_read_be_reverse_complemented="no";
while(<READS>)
{
	if((($.-1)%4==0)&&($_=~/^\@(.+)$/))
	{
		$read_name=$1;
		$should_this_read_be_reverse_complemented="no";
		#print "seeing $read_name\n";
		if($hash_read_name_to_whether_it_should_be_reverse_complemented{$read_name}=~/yes/)
		{
			#print "good $read_name\n";
			$should_this_read_be_reverse_complemented="yes";
		}

	}
	
	#если этот рид нужно сделать обратно-комплементарным
	if($should_this_read_be_reverse_complemented=~/yes/)
	{
		if(($.-1)%4==0)
		{
			print READS_OUTFILE "$_";
		}
		elsif(($.-2)%4==0)
		{
			$string=$_;
			chomp($string);
			$string=reverse($string);
			$string=~tr/ATGCatgcNn/TACGtacgNn/;
			print READS_OUTFILE "$string\n";
		}
		elsif($.%4==0) #переворачиваю качество
		{
			$string=$_;
			chomp($string);
			$string=reverse($string);
			print READS_OUTFILE "$string\n";
		}
		else
		{
			print READS_OUTFILE "$_";
		}
	}
	else
	{
		print READS_OUTFILE "$_";
	}
}

close(LIST);
close(READS);
close(READS_OUTFILE);

