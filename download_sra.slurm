
#!/bin/bash
#SBATCH --job-name=download_sra
#SBATCH --partition=RM-shared
#SBATCH --output=download_sra_%j.out
#SBATCH --error=download_sra_%j.err
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G

set -euo pipefail

# BIOL 443 Final Project
# Download 9 SRA sequencing datasets

# Load SRA Toolkit
module load sra-toolkit

# Define working directory

WORKDIR="/ocean/projects/bio260081p/your-username/FinalProject_RiverDolphin"
cd "$WORKDIR"

# Create directories
mkdir -p sra_data fastq_data temp_sra

# Read each SRR accession
while read -r accession; do

    [[ -z "$accession" ]] && continue

    echo "Downloading $accession"

    # Download SRA file
    prefetch "$accession" \
        --max-size u \
        --output-directory "$WORKDIR/sra_data"

    echo "Converting $accession to FASTQ"

    # Convert SRA data to FASTQ
    fasterq-dump \
        "$WORKDIR/sra_data/$accession" \
        --split-files \
        --threads 8 \
        --temp "$WORKDIR/temp_sra" \
        --outdir "$WORKDIR/fastq_data"

    # Compress FASTQ files
    for file in "$WORKDIR"/fastq_data/"$accession"*.fastq; do

        [[ -f "$file" ]] || continue

        gzip "$file"

    done

    echo "Finished processing $accession"

done < accession_file.txt

echo "All nine SRA datasets processed."

