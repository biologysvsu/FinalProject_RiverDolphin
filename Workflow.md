
# Comparative Genomics of Amazon River Dolphin, Arapaima, and Human

## Project Overview

For our BIOL 443 final project, we will compare whole-genome sequencing data from three different species: Amazon river dolphin (*Inia geoffrensis*), arapaima (*Arapaima gigas*), and human (*Homo sapiens*).

We selected three SRA sequencing runs from each species, giving us nine datasets total.

Our goal is to use bioinformatics tools to download sequencing reads, align them to the human reference genome, identify genetic variants, and explore the results using principal component analysis (PCA).

This repository contains the commands and scripts for completing the project using PSC Bridges2.

## Software and Resources

The programs used in this workflow include:

- NCBI SRA Toolkit — download sequencing data
- Bowtie2 — align sequencing reads to a reference genome
- SAMtools — sort and index alignment files
- BCFtools — identify and analyze genetic variants
- PLINK 2 — prepare genetic data for PCA
- PSC Bridges2 — high-performance computing system
- GitHub — store scripts and document the workflow

Useful resources:

- [NCBI Sequence Read Archive](https://www.ncbi.nlm.nih.gov/sra)
- [Human Reference Genome GRCh38](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.40/)
- [Bowtie2 Manual](https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml)
- [SAMtools](https://www.htslib.org/)
- [BCFtools](https://samtools.github.io/bcftools/)
- [PLINK 2](https://www.cog-genomics.org/plink/2.0/)

## Step 1: List of SRA Accessions

We selected three whole-genome sequencing runs from each species.

### Amazon River Dolphin (*Inia geoffrensis*)

| SRA Experiment | SRA Run |
|---|---|
| SRX30817921 | SRR35768626 |
| SRX30817920 | SRR35768627 |
| SRX30817918 | SRR35768629 |

### Arapaima (*Arapaima gigas*)

| SRA Experiment | SRA Run |
|---|---|
| SRX10940963 | SRR14593737 |
| SRX19461007 | SRR23574201 |
| SRX19461003 | SRR23574205 |

### Human (*Homo sapiens*)

| SRA Experiment | SRA Run |
|---|---|
| SRX33863759 | SRR39117445 |
| SRX33863758 | SRR39117444 |
| SRX33863757 | SRR39117443 |

We created a file named `accession_file.txt` containing the nine SRR accession numbers. This file will be used by our download and mapping scripts.

Before running the analysis, we will confirm that these datasets contain whole-genome sequencing reads and check their sequencing layouts.

## Step 2: Download SRA Sequences

The next step is to download the nine sequencing datasets from NCBI using the SRA Toolkit.

We will use PSC Bridges2 to download the data and convert the SRA files into FASTQ format.

### Log Into PSC Bridges2

Open a terminal, Git Bash, or PowerShell and connect to PSC:

```bash
ssh your-psc-username@bridges2.psc.edu
```

Navigate to the project directory:

```bash
cd /ocean/projects/bio260081p/your-username
```

Replace `your-username` with your actual PSC username.

### Download Script

We created a SLURM script named `download_sra.slurm`.

The script will:

1. Read the nine SRR accessions from `accession_file.txt`.
2. Download the sequencing runs using `prefetch`.
3. Convert SRA files into FASTQ files using `fasterq-dump`.
4. Compress the FASTQ files to save storage space.
5. Save the files in a directory named `fastq_data`.

The download script is available here:

[download_sra.slurm](download_sra.slurm)

### Submit the Download Job

Once PSC access is available, submit the script:

```bash
sbatch download_sra.slurm
```

Check the job status:

```bash
squeue -u $USER
```

### Expected Output

The download process should create:

- `sra_data/` — downloaded SRA files
- `fastq_data/` — sequencing reads in compressed FASTQ format

These FASTQ files will be used for alignment in Step 5.

## Step 3: Obtain the Human Reference Genome

We will use the human reference genome GRCh38.p14 to align all nine sequencing datasets.

### Reference Genome Information

- Organism: *Homo sapiens*
- Reference assembly: GRCh38.p14
- NCBI accession: GCF_000001405.40
- File format: FASTA
- Reference filename: `GCF_000001405.40_GRCh38.p14_genomic.fna`

The reference genome is available from NCBI:

[NCBI Human Reference Genome](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.40/)

### Download the Reference Genome

First, create a directory for the reference genome:

```bash
mkdir -p reference
```

Download the genomic FASTA file:

```bash
wget -P reference \
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_genomic.fna.gz
```

Uncompress the downloaded file:

```bash
gunzip reference/GCF_000001405.40_GRCh38.p14_genomic.fna.gz
```

### Expected Output

The reference genome will be saved as:

`reference/GCF_000001405.40_GRCh38.p14_genomic.fna`

This FASTA file will be used to build the Bowtie2 database.

## Step 4: Build the Bowtie2 Database

After downloading the human reference genome, we will build a Bowtie2 index.

Bowtie2 uses this index to align sequencing reads to the reference genome.

### Load Bowtie2

On PSC Bridges2, the software can be loaded using:

```bash
module load bowtie2/2.4.4
```

### Build the Bowtie2 Index

We created a SLURM script named `index.slurm` to build the index.

The script is available here:

[index.slurm](index.slurm)

The main indexing command is:

```bash
bowtie2-build --threads 16 \
reference/GCF_000001405.40_GRCh38.p14_genomic.fna \
bowtie2_index/human_genome_reference
```

The first path identifies the human reference genome.

The second path specifies the location and prefix of the Bowtie2 index files.

### Submit the Indexing Job

```bash
sbatch index.slurm
```

Check the job status:

```bash
squeue -u $USER
```

### Expected Output

Bowtie2 should create six index files in the `bowtie2_index` directory.

These files will have `.bt2` or `.bt2l` extensions, depending on the index format.

The completed index will be used in Step 5.

## Step 5: Map the Nine Sequencing Datasets to the Human Reference Genome

Once the FASTQ files and Bowtie2 index are available, we will map the sequencing reads to the human reference genome.

We will use three programs:

- Bowtie2 to align the sequencing reads
- SAMtools to sort and index the alignment files
- BCFtools to identify genetic variants and create VCF files

### Required Input Files

Before starting, we will need:

1. The nine sequencing datasets in FASTQ format
2. The GRCh38.p14 human reference genome FASTA file
3. The Bowtie2 index files
4. The accession list in `accession_file.txt`

### SNP Calling Script

We created a SLURM script named `snpcall.slurm` based on the Bowtie2 and SNP-calling tutorial used in class.

The script processes each SRR accession separately.

[snpcall.slurm](snpcall.slurm)

### Submit the SNP Calling Job

```bash
sbatch snpcall.slurm
```

Check the job status:

```bash
squeue -u $USER
```

### Expected Output

For each sequencing dataset, we expect to generate:

- A sorted BAM file containing aligned reads
- A BAM index file
- A compressed VCF file containing called variants
- A VCF index file

For example, the first Amazon river dolphin sequencing run should generate:

```text
results/SRR35768626_sorted.bam
results/SRR35768626_sorted.bam.bai
results/SRR35768626.vcf.gz
results/SRR35768626.vcf.gz.tbi
```

This process will be repeated for all nine datasets.

### Important Considerations

The sequencing layout must be confirmed before running the mapping script.

Mapping Amazon river dolphin and arapaima reads to a human reference genome may produce low alignment rates, especially for arapaima.

This can affect variant detection and make comparisons between species difficult.

The mapping and SNP-calling process may take many hours and require substantial computing resources.

## Step 6: Analyze the VCF Files

After generating the VCF files, we will examine the genetic variants identified in the sequencing datasets.

We plan to use BCFtools to review variant counts, quality, and filtering.

For PCA, the samples will need to be represented at comparable genomic positions in a shared genotype dataset. Separately called variant-only VCF files cannot simply be combined without accounting for missing and reference genotypes.

We will document the analysis commands and results in this section after developing the next part of the workflow.

## Step 7: Create a PCA Plot

The final step will be to create a principal component analysis (PCA) plot using the genetic data.

We plan to use PLINK 2 to calculate principal components and visualize the samples.

The PCA plot will help us explore patterns in the genetic data.

However, because these species are very different and all reads are being mapped to a human reference genome, the PCA results may be strongly affected by reference bias and missing data. The plot should not be interpreted as a reliable evolutionary tree.

We will add the PCA commands and results after developing this step.

## Project Status

This repository currently documents the proposed bioinformatics workflow.

The scripts have been prepared but have not yet been executed on PSC Bridges2.

The software environment, dataset metadata, resource requirements, and input file layouts must be verified before running the analysis.

