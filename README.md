<b>NTproc</b> is a pipeline for <b>N</b>anopore <b>T</b>ranscriptome reads <b>proc</b>essing. It was created to increase the proportion of reads that correspond to entire (non-fragmented) cDNAs and also to rotate reads such that their poly-A tails become on the right (3') end of reads. In addition, NTproc trims adapters and performs demultiplexing.<br><br>
<b>[a more detailed description including a diagram will be added after the corresponding paper is published]</b>


### Installation
Simply download the files using the command<br>
`git clone https://github.com/shelkmike/NTproc`

### Requirements
* Modified_porechop (https://github.com/shelkmike/Modified_porechop) should be installed and available through $PATH .

### Usage
Ntproc has two mandatory options and one additional option.<br>
The mandatory options are:<br>
1\) --fastq — path to a FASTQ file with unprocessed reads.<br>
2\) --adapter — a full or partial sequence of a PCR adapter used for cDNA amplification.<br>

The additional option is<br>
3\) --output_folder — the folder to write results to. The default value is "NTproc_results".<br>
<br>
An example of how to run NTproc:<br>
`bash ntproc.sh --fastq unprocessed_nanopore_reads.fastq --adapter AAGCAGTGGTATCAACGCAGAGT`<br>
<br>
In the output folder of NTproc, aside from some intermediate files and folders, you'll see the folder "Demultiplexed" with a content like this:<br>
BC01.fastq<br>
BC02.fastq<br>
BC03.fastq<br>
none.fastq<br>
<br>
Files titled like BC01.fastq, BC02.fastq, BC03.fastq contain processed reads with Nanopore barcodes "Barcode 1", "Barcode 2", "Barcode 3", while the file none.fastq contain reads where Modified_porechop wasn't able to find a barcode. NTproc knows standard Nanopore barcodes from "Barcode 1" to "Barcode 96".<br>
<br>
To check whether NTproc works correctly, you can use a test set of 10 000 reads (file 10000_reads.fastq), provided with NTproc. Run a test with a command like<br>
`bash ntproc.sh --fastq ./Test_set/10000_reads.fastq --adapter AAGCAGTGGTATCAACGCAGAGT --output_folder Test_results`<br>

### Performance
NTproc utilizes a single CPU thread and is capable of processing 1 000 000 reads in approximately an hour. If a faster performance is required, a user can split the input FASTQ file into batches and run several instances of NTproc independently. If you would like NTproc to have integrated parallelization, notify me via Issues (https://github.com/shelkmike/NTProc/issues).
