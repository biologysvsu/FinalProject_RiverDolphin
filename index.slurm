
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
# Build Bowtie2 index for human reference genome

# Load Bowtie2
module load bowtie2/2.4.4

# Define working directory
WORKDIR="/ocean/projects/bio260081p/your-username"
cd "$WORKDIR"

# Define human reference genome
REFERENCE="$WORKDIR/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"

# Create directory for index files
mkdir -p bowtie2_index

# Build Bowtie2 index
bowtie2-build --threads 16 \
    "$REFERENCE" \
    "$WORKDIR/bowtie2_index/human_genome_reference"

echo "Bowtie2 index completed."
