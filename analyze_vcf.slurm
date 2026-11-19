
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
# Joint variant calling and SNP analysis

module load samtools
module load bcftools

WORKDIR="/ocean/projects/bio260081p/your-username"
cd "$WORKDIR"

REFERENCE="$WORKDIR/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"

mkdir -p analysis

# Create a list of the nine BAM files
: > analysis/bam_list.txt

while read -r accession; do

    [[ -z "$accession" ]] && continue

    BAM="$WORKDIR/results/${accession}_sorted.bam"

    if [[ ! -f "$BAM" ]]; then
        echo "Missing BAM file: $BAM" >&2
        exit 1
    fi

    echo "$BAM" >> analysis/bam_list.txt

done < accession_file.txt

# Joint variant calling across nine samples
# -a FORMAT/DP,FORMAT/AD records depth information

bcftools mpileup \
    --threads 8 \
    -Ou \
    -f "$REFERENCE" \
    -a FORMAT/DP,FORMAT/AD \
    -b analysis/bam_list.txt \
    | bcftools call \
        --threads 8 \
        -mv \
        -Oz \
        -o analysis/combined_variants.vcf.gz

# Index combined VCF
bcftools index -t analysis/combined_variants.vcf.gz

# Keep biallelic SNPs with adequate site quality
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

# Calculate missing genotype statistics
bcftools query \
    -f '[%SAMPLE\t%GT\n]' \
    analysis/filtered_snps.vcf.gz \
    > analysis/genotypes_for_review.txt

echo "VCF analysis completed."
echo "Review mapping and missingness before PCA."
