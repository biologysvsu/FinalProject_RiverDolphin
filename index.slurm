
#!/bin/bash
#SBATCH --job-name=bowtie2_build
#SBATCH --partition=RM-shared
#SBATCH --output=bowtie2_build_%j.out
#SBATCH --error=bowtie2_build_%j.err
#SBATCH --time=03:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=31G

set -euo pipefail

# BIOL 443 Final Project
# Build Bowtie2 index for the human reference genome

module load bowtie2/2.4.4

WORKDIR="${SLURM_SUBMIT_DIR:-$PWD}"
cd "$WORKDIR"

REFERENCE="$WORKDIR/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"

INDEX_DIR="$WORKDIR/bowtie2_index"
INDEX_PREFIX="$INDEX_DIR/human_genome_reference"

# Check that the reference genome exists
if [[ ! -s "$REFERENCE" ]]; then
    echo "ERROR: Human reference genome not found."
    echo "$REFERENCE"
    exit 1
fi

mkdir -p "$INDEX_DIR"

echo "Building Bowtie2 index..."

bowtie2-build \
    --threads 16 \
    "$REFERENCE" \
    "$INDEX_PREFIX"

echo "Bowtie2 index completed."
