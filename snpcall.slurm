
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
# Map nine datasets to the human reference genome
# Generate BAM files, alignment statistics, and VCF files

module load bowtie2/2.4.4
module load samtools
module load bcftools

WORKDIR="${SLURM_SUBMIT_DIR:-$PWD}"
cd "$WORKDIR"

REFERENCE="$WORKDIR/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"
BOWTIEREF="$WORKDIR/bowtie2_index/human_genome_reference"
ACCESSIONS="$WORKDIR/accession_file.txt"

mkdir -p results

# Check required inputs
if [[ ! -s "$REFERENCE" || ! -s "$ACCESSIONS" ]]; then
    echo "ERROR: Reference genome or accession list is missing."
    exit 1
fi

if ! bowtie2-inspect -n "$BOWTIEREF" > /dev/null; then
    echo "ERROR: Bowtie2 index is missing or unreadable."
    exit 1
fi

# Index the reference genome if needed
if [[ ! -s "${REFERENCE}.fai" ]]; then
    samtools faidx "$REFERENCE"
fi

# Process each accession
while IFS= read -r accession || [[ -n "$accession" ]]; do

    accession="${accession//$'\r'/}"
    [[ -z "$accession" ]] && continue

    echo "Processing $accession"

    READS_1="$WORKDIR/fastq_data/${accession}_1.fastq.gz"
    READS_2="$WORKDIR/fastq_data/${accession}_2.fastq.gz"
    READS_3="$WORKDIR/fastq_data/${accession}_3.fastq.gz"
    READS_SINGLE="$WORKDIR/fastq_data/${accession}.fastq.gz"

    SORTED_BAM="$WORKDIR/results/${accession}_sorted.bam"
    VCF_OUTPUT="$WORKDIR/results/${accession}.vcf.gz"
    FLAGSTAT_OUTPUT="$WORKDIR/results/${accession}_flagstat.txt"
    ALIGN_LOG="$WORKDIR/results/${accession}_bowtie2.log"

    # Paired-end sequencing
    if [[ -s "$READS_1" && -s "$READS_2" ]]; then

        echo "Running paired-end alignment"

        if [[ -s "$READS_3" ]]; then
            echo "WARNING: Additional unpaired reads found:"
            echo "$READS_3"
            echo "These reads are not included in this alignment."
        fi

        bowtie2 --very-fast -p 8 \
            -x "$BOWTIEREF" \
            --rg-id "$accession" \
            --rg "SM:$accession" \
            -1 "$READS_1" \
            -2 "$READS_2" \
            2> "$ALIGN_LOG" \
            | samtools sort -@ 4 -m 2G \
                -o "$SORTED_BAM" -

    # Single-end reads with _1 suffix
    elif [[ -s "$READS_1" && ! -e "$READS_2" ]]; then

        echo "Running single-end alignment"

        bowtie2 --very-fast -p 8 \
            -x "$BOWTIEREF" \
            --rg-id "$accession" \
            --rg "SM:$accession" \
            -U "$READS_1" \
            2> "$ALIGN_LOG" \
            | samtools sort -@ 4 -m 2G \
                -o "$SORTED_BAM" -

    # Single-end reads without suffix
    elif [[ -s "$READS_SINGLE" ]]; then

        echo "Running single-end alignment"

        bowtie2 --very-fast -p 8 \
            -x "$BOWTIEREF" \
            --rg-id "$accession" \
            --rg "SM:$accession" \
            -U "$READS_SINGLE" \
            2> "$ALIGN_LOG" \
            | samtools sort -@ 4 -m 2G \
                -o "$SORTED_BAM" -

    else

        echo "ERROR: Missing or incomplete FASTQ files for $accession"
        exit 1

    fi

    # Index BAM file
    samtools index "$SORTED_BAM"

    # Save alignment statistics
    samtools flagstat "$SORTED_BAM" \
        > "$FLAGSTAT_OUTPUT"

    # Verify sample identification
    if ! samtools view -H "$SORTED_BAM" \
        | grep -Fq "SM:$accession"; then

        echo "ERROR: Sample identification missing for $accession"
        exit 1
    fi

    # Call variants for this sample
    bcftools mpileup \
        -Ou \
        -f "$REFERENCE" \
        "$SORTED_BAM" \
        | bcftools call \
            -mv \
            -Oz \
            -o "$VCF_OUTPUT"

    # Index VCF
    bcftools index -t "$VCF_OUTPUT"

    echo "Finished $accession"

done < "$ACCESSIONS"

echo "Mapping and individual SNP calling completed."
echo "Review alignment statistics before joint variant calling."

