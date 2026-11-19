
#!/bin/bash
#SBATCH --job-name=river_dolphin_snps
#SBATCH --partition=RM-shared
#SBATCH --output=snpcall_%j.out
#SBATCH --error=snpcall_%j.err
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=64G

set -euo pipefail

# BIOL 443 Final Project
# Map 9 sequencing datasets to the human genome
# Generate sorted BAM files, VCF files, and alignment statistics

# Load required software
module load bowtie2/2.4.4
module load samtools
module load bcftools

# Define working directory

WORKDIR="/ocean/projects/bio260081p/your-username/FinalProject_RiverDolphin"
cd "$WORKDIR"

# Define reference genome
REFERENCE="$WORKDIR/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"

# Define Bowtie2 index
BOWTIEREF="$WORKDIR/bowtie2_index/human_genome_reference"

# Create output directory
mkdir -p results

# Index the reference FASTA if needed
if [[ ! -f "${REFERENCE}.fai" ]]; then
    samtools faidx "$REFERENCE"
fi

# Process each SRA accession
while read -r accession; do

    [[ -z "$accession" ]] && continue

    echo "Processing $accession"

    # Define input FASTQ files
    READS_1="$WORKDIR/fastq_data/${accession}_1.fastq.gz"
    READS_2="$WORKDIR/fastq_data/${accession}_2.fastq.gz"
    READS_SINGLE="$WORKDIR/fastq_data/${accession}.fastq.gz"

    # Define output files
    SORTED_BAM="$WORKDIR/results/${accession}_sorted.bam"
    VCF_OUTPUT="$WORKDIR/results/${accession}.vcf.gz"
    FLAGSTAT_OUTPUT="$WORKDIR/results/${accession}_flagstat.txt"

    # Align paired-end sequencing reads
    if [[ -f "$READS_1" && -f "$READS_2" ]]; then

        echo "Running paired-end Bowtie2 alignment"

        bowtie2 --very-fast -p 8 \
            -x "$BOWTIEREF" \
            --rg-id "$accession" \
            --rg "SM:$accession" \
            -1 "$READS_1" \
            -2 "$READS_2" \
            | samtools sort -@ 4 -m 2G \
                -o "$SORTED_BAM" -

    # Align single-end sequencing reads
    elif [[ -f "$READS_1" && ! -f "$READS_2" ]]; then

        echo "Running single-end Bowtie2 alignment"

        bowtie2 --very-fast -p 8 \
            -x "$BOWTIEREF" \
            --rg-id "$accession" \
            --rg "SM:$accession" \
            -U "$READS_1" \
            | samtools sort -@ 4 -m 2G \
                -o "$SORTED_BAM" -

    elif [[ -f "$READS_SINGLE" ]]; then

        echo "Running single-end Bowtie2 alignment"

        bowtie2 --very-fast -p 8 \
            -x "$BOWTIEREF" \
            --rg-id "$accession" \
            --rg "SM:$accession" \
            -U "$READS_SINGLE" \
            | samtools sort -@ 4 -m 2G \
                -o "$SORTED_BAM" -

    else

        echo "Missing FASTQ files for $accession" >&2
        exit 1

    fi

    # Index sorted BAM file
    echo "Indexing BAM file"

    samtools index "$SORTED_BAM"

    # Calculate and save alignment statistics
    echo "Calculating alignment statistics"

    samtools flagstat "$SORTED_BAM" \
        > "$FLAGSTAT_OUTPUT"

    # Call genetic variants
    echo "Calling variants with BCFtools"

    bcftools mpileup -Ou \
        -f "$REFERENCE" \
        "$SORTED_BAM" \
        | bcftools call -mv -Oz \
            -o "$VCF_OUTPUT"

    # Index compressed VCF file
    echo "Indexing VCF file"

    bcftools index -t "$VCF_OUTPUT"

    echo "Finished $accession"

done < accession_file.txt

echo "All nine datasets processed."

echo "All nine datasets processed."
