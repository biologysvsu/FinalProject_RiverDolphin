
# Comparative Genomics of Amazon River Dolphins, Arapaima, and Humans

## Objective

The objective of this project is to compare whole-genome sequencing data from three different species: Amazon river dolphins (*Inia geoffrensis*), arapaima fish (*Arapaima gigas*), and humans (*Homo sapiens*). We will use nine sequencing datasets, with three from each species, to investigate their genetic similarities, differences, and evolutionary relationships.

This workflow will explain how to download sequencing data from NCBI, map the sequences to the human reference genome using Bowtie2, identify genetic variants, and create a PCA plot to visualize genetic differences among the samples.

## Software and Resources

The following programs and resources will be used:

1. **NCBI SRA:** Source of the whole-genome sequencing datasets.
2. **SRA Toolkit:** Used to download sequencing reads from NCBI.
3. **PSC Bridges2:** High-performance computing system used to run the analysis.
4. **Bowtie2:** Used to align sequencing reads to the human reference genome.
5. **SAMtools:** Used to process and organize alignment files.
6. **BCFtools:** Used to identify and analyze genetic variants.
7. **PLINK 2:** Used to perform principal component analysis (PCA).
8. **GitHub:** Used to organize the workflow and scripts.

### Useful Links

- [NCBI SRA](https://www.ncbi.nlm.nih.gov/sra)
- [SRA Toolkit](https://github.com/ncbi/sra-tools)
- [PSC Bridges2](https://www.psc.edu/resources/bridges-2/)
- [Bowtie2 Manual](https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml)
- [SAMtools](http://www.htslib.org/)
- [BCFtools](https://samtools.github.io/bcftools/)
- [PLINK 2](https://www.cog-genomics.org/plink/2.0)

---

## Step 1: List of SRA Accessions

For this project, we selected nine sequencing datasets from the NCBI Sequence Read Archive (SRA). Three datasets were selected for each species.

The SRX accession numbers identify the sequencing experiments, while the SRR accession numbers identify the sequencing runs that will be used to download the data.

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

### Creating the Accession File

The nine SRR accession numbers will be saved in a text file named `accession_file.txt`.

The file will contain the following:

```text
SRR35768626
SRR35768627
SRR35768629
SRR14593737
SRR23574201
SRR23574205
SRR39117445
SRR39117444
SRR39117443
```

This file will be used in the next step to download the sequencing data.

Before downloading, the NCBI metadata should be checked to confirm that each run contains suitable whole-genome DNA sequencing data and represents the intended sample.

---

## Step 2: Download SRA Sequences

The next step is to download the nine whole-genome sequencing datasets from NCBI using the SRA Toolkit.

We will create a SLURM script named `download_sra.slurm` to download the sequencing runs onto PSC Bridges2.

### Preparing the Download Script

The script will:

1. Read the nine SRR accession numbers from `accession_file.txt`.
2. Use `prefetch` to retrieve each sequencing run from NCBI.
3. Use `fasterq-dump` to convert the downloaded data into FASTQ files.
4. Compress the FASTQ files to reduce storage requirements.
5. Save the sequencing files in the `fastq_data` directory.

The script is available here:

[Download SRA Script](download_sra.slurm)

### Running the Script

Once access to PSC Bridges2 is available, the script can be submitted using:

```bash
sbatch download_sra.slurm
```

To check the status of the job:

```bash
squeue -u $USER
```

### Expected Output

The script is intended to create two directories:

- `sra_data/` — Original downloaded SRA data.
- `fastq_data/` — Converted and compressed FASTQ files.

The FASTQ files will be used in the next steps to map the sequencing reads to the human reference genome.

**Note:** This script has been prepared for the workflow but has not yet been executed or validated on PSC Bridges2.

---

## Step 3: Obtain the Human Reference Genome

The human reference genome will be used as the reference for mapping the sequencing reads from all nine datasets.

We will use the GRCh38 human reference genome, which can be obtained from NCBI.

Reference genome link:

[NCBI Human Reference Genome](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.40/)

The reference genome will be downloaded in FASTA format and used to build the Bowtie2 database.

---

## Step 4: Build the Bowtie2 Database

After obtaining the human reference genome, we will use Bowtie2 to build an index of the reference sequence.

The Bowtie2 database allows sequencing reads to be aligned to the human reference genome.

The command will follow this format:

```bash
bowtie2-build human_reference.fna human_index
```

The FASTA filename will be replaced with the actual downloaded reference genome filename.

---

## Step 5: Map the Nine Sequencing Datasets to the Human Reference Genome

Bowtie2 will be used to align the sequencing reads from all nine datasets to the human reference genome.

The analysis will include three Amazon river dolphin datasets, three arapaima datasets, and three human datasets.

Because whole-genome sequencing datasets can be large, the mapping process may take several hours.

The Bowtie2 alignment output will be processed using SAMtools to create sorted and indexed BAM files.

A separate variant-calling step using BCFtools will then be used to generate VCF files containing genetic variants.

---

## Step 6: Analyze the VCF Files

The VCF files will be examined to identify genetic variation among the nine samples.

The analysis will include:

1. Checking the quality of the variant calls.
2. Filtering low-quality variants.
3. Identifying genomic positions that can be reliably compared across samples.
4. Preparing a combined dataset for PCA analysis.

---

## Step 7: Create a PCA Plot

Principal component analysis (PCA) will be used to visualize patterns of genetic variation among the nine sequencing datasets.

We will use PLINK 2 to calculate the principal components and create a PCA plot.

The plot will display the samples according to their genetic variation, with each species labeled separately.

We will examine whether the river dolphin and human samples show greater genetic similarity compared to the arapaima samples.

Because arapaima is evolutionarily distant from humans, mapping its reads to the human reference genome may produce limited or biased results. Mapping quality and the number of reliable shared variants will need to be evaluated before interpreting the PCA.

---

## Expected Results

We expect river dolphins and humans to share a more recent common ancestor with each other than either does with arapaima fish because both river dolphins and humans are mammals.

The PCA will be used to explore patterns of genetic variation, although it may not reliably reconstruct evolutionary relationships across these distantly related species.

This workflow is a proposed analysis plan. The sequencing data have not yet been downloaded or analyzed, and no results have been generated.
