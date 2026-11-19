
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
# Download nine SRA sequencing datasets

module load sra-toolkit

# Submit this job from the cloned GitHub repository
WORKDIR="${SLURM_SUBMIT_DIR:-$PWD}"
cd "$WORKDIR"

ACCESSIONS="$WORKDIR/accession_file.txt"

if [[ ! -s "$ACCESSIONS" ]]; then
    echo "ERROR: accession_file.txt is missing or empty."
    exit 1
fi

mkdir -p sra_data fastq_data temp_sra

# Download and convert each SRA run
while IFS= read -r accession || [[ -n "$accession" ]]; do

    accession="${accession//$'\r'/}"
    [[ -z "$accession" ]] && continue

    echo "Processing $accession"

    # Download the SRA run
    prefetch "$accession" \
        --max-size u \
        --output-directory "$WORKDIR/sra_data"

    SRA_PATH="$WORKDIR/sra_data/$accession"

    if [[ ! -d "$SRA_PATH" ]]; then
        echo "ERROR: SRA download not found for $accession"
        exit 1
    fi

    # Convert to FASTQ
    fasterq-dump "$SRA_PATH" \
        --split-files \
        --threads 8 \
        --temp "$WORKDIR/temp_sra" \
        --outdir "$WORKDIR/fastq_data"

    # Check that FASTQ output exists
    shopt -s nullglob
    fastq_files=("$WORKDIR"/fastq_data/"$accession"*.fastq)
    shopt -u nullglob

    if [[ ${#fastq_files[@]} -eq 0 ]]; then
        echo "ERROR: No FASTQ files created for $accession"
        exit 1
    fi

    # Compress FASTQ files
    for file in "${fastq_files[@]}"; do
        gzip -f "$file"
    done

    echo "Finished $accession"

done < "$ACCESSIONS"

echo "SRA download and FASTQ conversion completed."


