
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
# Run only after checking data quality


WORKDIR="/ocean/projects/bio260081p/your-username/FinalProject_RiverDolphin"
cd "$WORKDIR"

# PLINK 2 must be available in PATH.
# Verify installation or load the PSC module first.
command -v plink2

mkdir -p pca_results

# Convert filtered VCF to PLINK 2 format
plink2 \
    --vcf analysis/filtered_snps.vcf.gz \
    --allow-extra-chr \
    --make-pgen \
    --out pca_results/river_dolphin

# Identify SNPs for LD pruning
plink2 \
    --pfile pca_results/river_dolphin \
    --allow-extra-chr \
    --indep-pairwise 50 5 0.2 \
    --out pca_results/pruned

# Calculate the first two principal components
plink2 \
    --pfile pca_results/river_dolphin \
    --allow-extra-chr \
    --extract pca_results/pruned.prune.in \
    --pca 2 \
    --out pca_results/river_dolphin_pca

echo "PCA completed."
