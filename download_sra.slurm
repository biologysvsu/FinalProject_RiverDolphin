
#!/bin/bash
#SBATCH --job-name=download_sra
#SBATCH --output=download_sra_%j.out
#SBATCH --error=download_sra_%j.err
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G

# River Dolphin Comparative Genomics Project
# Download 9 whole-genome sequencing datasets
# 3 Amazon river dolphin, 3 arapaima, 3 human

set -euo pipefail

# Run this script from the project directory.
# Load SRA Toolkit using the PSC module system.
module load sra-toolkit

# Create directories for downloaded data
mkdir -p sra_data fastq_data

# Read each accession from accession_file.txt
while read -r accession; do

    # Skip empty lines
    [[ -z "$accession" ]] && continue

    echo "Downloading $accession"

    # Download the SRA sequencing run
    prefetch "$accession" \
        --output-directory sra_data

    # Convert SRA data to FASTQ
    fasterq-dump \
        "sra_data/$accession" \
        --split-files \
        --threads 8 \
        --outdir fastq_data

    # Compress FASTQ files
    for file in fastq_data/"$accession"*.fastq; do
        [[ -f "$file" ]] || continue
        gzip "$file"
    done

    echo "Finished $accession"

done < accession_file.txt

echo "All nine sequencing runs processed."
