
#!/bin/bash
#SBATCH --job-name=river_dolphin_vcf
#SBATCH --partition=RM-shared
#SBATCH --output=analyze_vcf_%j.out
#SBATCH --error=analyze_vcf_%j.err
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G

set -euo pipefail

# BIOL 443 Final Project
# Joint variant calling and VCF analysis

module load samtools
module load bcftools

WORKDIR="${SLURM_SUBMIT_DIR:-$PWD}"
cd "$WORKDIR"

REFERENCE="$WORKDIR/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"
ACCESSIONS="$WORKDIR/accession_file.txt"

mkdir -p analysis

BAM_LIST="$WORKDIR/analysis/bam_list.txt"
SAMPLE_LIST="$WORKDIR/analysis/sample_names.txt"

if [[ ! -s "$REFERENCE" || ! -s "$ACCESSIONS" ]]; then
    echo "ERROR: Reference genome or accession list is missing."
    exit 1
fi

# Create lists of BAM files and sample names
: > "$BAM_LIST"
: > "$SAMPLE_LIST"

while IFS= read -r accession || [[ -n "$accession" ]]; do

    accession="${accession//$'\r'/}"
    [[ -z "$accession" ]] && continue

    BAM="$WORKDIR/results/${accession}_sorted.bam"

    if [[ ! -s "$BAM" ]]; then
        echo "ERROR: Missing BAM file: $BAM"
        exit 1
    fi

    if [[ ! -s "${BAM}.bai" ]]; then
        echo "ERROR: Missing BAM index for $accession"
        exit 1
    fi

    # Verify that the expected sample name is present
    SAMPLE_NAME=$(samtools view -H "$BAM" \
        | awk -F '\t' '$1=="@RG" {
            for(i=2;i<=NF;i++) {
                if($i ~ /^SM:/) {
                    sub(/^SM:/,"",$i)
                    print $i
                }
            }
        }' | sort -u)

    if [[ "$SAMPLE_NAME" != "$accession" ]]; then
        echo "ERROR: Unexpected sample name in $BAM"
        echo "Expected: $accession"
        echo "Found: $SAMPLE_NAME"
        exit 1
    fi

    echo "$BAM" >> "$BAM_LIST"
    echo "$SAMPLE_NAME" >> "$SAMPLE_LIST"

done < "$ACCESSIONS"

# Confirm nine unique samples
TOTAL=$(wc -l < "$SAMPLE_LIST")
UNIQUE=$(sort -u "$SAMPLE_LIST" | wc -l)

if [[ "$TOTAL" -ne 9 || "$UNIQUE" -ne 9 ]]; then
    echo "ERROR: Expected nine unique samples."
    exit 1
fi

echo "Verified nine BAM files with unique sample names."

# Perform joint variant calling
bcftools mpileup \
    --threads 8 \
    -Ou \
    -f "$REFERENCE" \
    -a FORMAT/DP,FORMAT/AD \
    -b "$BAM_LIST" \
    | bcftools call \
        --threads 8 \
        -mv \
        -Oz \
        -o analysis/combined_variants.vcf.gz

# Index combined VCF
bcftools index -t analysis/combined_variants.vcf.gz

# Confirm nine samples in combined VCF
VCF_SAMPLES=$(bcftools query \
    -l analysis/combined_variants.vcf.gz | wc -l)

if [[ "$VCF_SAMPLES" -ne 9 ]]; then
    echo "ERROR: Combined VCF does not contain nine samples."
    exit 1
fi

# Filter for biallelic SNPs
bcftools view \
    -m2 -M2 \
    -v snps \
    -i 'QUAL>=30' \
    -Oz \
    -o analysis/filtered_snps.vcf.gz \
    analysis/combined_variants.vcf.gz

# Index filtered VCF
bcftools index -t analysis/filtered_snps.vcf.gz

# Generate variant statistics
bcftools stats \
    analysis/filtered_snps.vcf.gz \
    > analysis/variant_stats.txt

# Export genotype information for review
bcftools query \
    -f '[%SAMPLE\t%GT\n]' \
    analysis/filtered_snps.vcf.gz \
    > analysis/genotypes_for_review.txt

echo "VCF analysis completed."
echo "Review variant quality, coverage, and missingness before PCA."
