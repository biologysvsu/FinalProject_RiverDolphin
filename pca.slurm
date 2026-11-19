
#!/bin/bash
#SBATCH --job-name=river_dolphin_pca
#SBATCH --partition=RM-shared
#SBATCH --output=pca_%j.out
#SBATCH --error=pca_%j.err
#SBATCH --time=04:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

set -euo pipefail

# BIOL 443 Final Project
# Exploratory PCA using PLINK 2

WORKDIR="${SLURM_SUBMIT_DIR:-$PWD}"
cd "$WORKDIR"

INPUT_VCF="$WORKDIR/analysis/filtered_snps.vcf.gz"
OUTPUT_DIR="$WORKDIR/pca_results"

# Check that PLINK 2 is available
if ! command -v plink2 > /dev/null 2>&1; then
    echo "ERROR: PLINK 2 is not available."
    echo "Load or activate PLINK 2 before running this script."
    exit 1
fi

# Check input file
if [[ ! -s "$INPUT_VCF" ]]; then
    echo "ERROR: Filtered VCF file not found."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Import VCF into PLINK 2 format
plink2 \
    --vcf "$INPUT_VCF" \
    --allow-extra-chr \
    --make-pgen \
    --out "$OUTPUT_DIR/river_dolphin"

# Calculate missing genotype statistics
plink2 \
    --pfile "$OUTPUT_DIR/river_dolphin" \
    --allow-extra-chr \
    --missing \
    --out "$OUTPUT_DIR/missingness"

echo "Missingness reports generated."

# Require manual approval before PCA
if [[ "${REVIEWED_DATA:-NO}" != "YES" ]]; then
    echo "PCA has not been performed."
    echo "Review sample missingness, genotype quality,"
    echo "chromosome identifiers, and alignment statistics."
    echo "After approval, rerun with REVIEWED_DATA=YES."
    exit 0
fi

# Filter samples and variants with high missingness
plink2 \
    --pfile "$OUTPUT_DIR/river_dolphin" \
    --allow-extra-chr \
    --mind 0.1 \
    --geno 0.1 \
    --make-pgen \
    --out "$OUTPUT_DIR/quality_filtered"

# Identify SNPs for LD pruning
plink2 \
    --pfile "$OUTPUT_DIR/quality_filtered" \
    --allow-extra-chr \
    --indep-pairwise 50 5 0.2 \
    --out "$OUTPUT_DIR/pruned"

# Calculate first two principal components
plink2 \
    --pfile "$OUTPUT_DIR/quality_filtered" \
    --allow-extra-chr \
    --extract "$OUTPUT_DIR/pruned.prune.in" \
    --pca 2 \
    --out "$OUTPUT_DIR/river_dolphin_pca"

echo "PCA calculations completed."
echo "Review PCA results before interpreting them."
