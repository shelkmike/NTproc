UPDATE: since the time I made NTproc, Oxford Nanopore has created its own tool for the same task, called Pychopper (https://github.com/epi2me-labs/pychopper). It's probably better to use Pychopper instead of NTproc.<br><br><br>
<b>NTproc</b> is a pipeline for <b>N</b>anopore <b>T</b>ranscriptome reads <b>proc</b>essing. The main function of NTproc is <ins>removal of reads that correspond to fragmented cDNAs</ins>. NTproc supposes that a read corresponds to a fragmented cDNA if the read doesn't have PCR adapter sequences on both ends.<br>
In addition to removal of reads that belong to fragmented cDNAs, NTproc rotates reads such that their poly-A tails become on the right (3') end. Also, NTproc trims adapters and performs demultiplexing.<br><br>

### Installation
Simply download the latest release from https://github.com/shelkmike/NTproc/releases and extract the archive.

### Requirements
* Modified_porechop (https://github.com/shelkmike/Modified_porechop) should be installed and available through $PATH .

### Usage
Ntproc has two mandatory options and one additional option.<br>
The mandatory options are:<br>
1\) --fastq — path to a FASTQ file with reads. This file may be compressed by Gzip. It is mandatory that the input reads should not be trimmed.<br>
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
Files titled like BC01.fastq, BC02.fastq, BC03.fastq contain processed reads with Nanopore barcodes "Barcode 1", "Barcode 2", "Barcode 3", while the file none.fastq contains reads where Modified_porechop wasn't able to find a barcode. NTproc knows standard Nanopore barcodes from "Barcode 1" to "Barcode 96".<br>
<br>
To check whether NTproc works correctly, you can use a test set of 10 000 reads (file 10000_reads.fastq), provided with NTproc. Run a test with a command like<br>
`bash ntproc.sh --fastq ./Test_set/10000_reads.fastq --adapter AAGCAGTGGTATCAACGCAGAGT --output_folder Test_results`<br>

### Questions and answers.
1. How **fast** is NTproc?<br>
NTproc utilizes a single CPU thread and is capable of processing 1 million reads in approximately an hour. If a faster performance is required, you can split the input FASTQ file into batches and run several instances of NTproc independently.
2. How much **RAM** does NTproc need?<br>
Approximately 1 Gb RAM per 1 million reads. If you don't have enough RAM to process all reads at once, you can split the input FASTQ into batches and process them in order (not in parallel).
<br>
If you would like NTproc to have the capability of automatically splitting reads into batches (for speedup or for lowering RAM usage) with subsequent automatic merging of results from different batches, notify me via Issues (https://github.com/shelkmike/NTProc/issues).
