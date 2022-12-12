#!/bin/bash

function usage()
{
   cat << HEREDOC

   >>>    GraffiTE_VCF_convert.sh     <<<
      
   Author: Clément Goubert - goubert.clement@gmail.com
   Last revision: 12/01/2022

   This script converts a VCF file generated by GraffiTE into a .tsv table with header for downstream analysis
   NOTE: for now, it only works with the "pangenome.vcf" file, found in <GraffiTE_outdir>/3_TSD_Search/pangenome.vcf (not for genotyping VCFs)

   ***************************************

   Usage: ./GraffiTE_VCF_convert.sh -V <GraffiTE_outdir/3_TSD_Search/pangenome.vcf> -n <GraffiTE_outdir/1_SV_Search/vcfs.txt>

   mendatory arguments:
    -V, --vcf          VCF produced by GraffiTE, typically <GraffiTE_outdir>/3_TSD_Search/pangenome.vcf
    -n, --vcf-names    Name for each assembly contributing to the VCF

HEREDOC
} 

# if no parameter given, output help and quit
if [[ $# -eq 0 ]] ; then
    echo 'Error! No mandatory argument given'
    usage
    exit 0
fi

# parameters parser
PARAMS=""
while (( "$#" )); do
  case "$1" in
# flags with arguments
    -V|--vcf )
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        VCFin=$2
        shift 2
      else
        echo "Error: missing input VCF (/3_TSD_Search/pangenome.vcf)" >&2
        usage
        exit 1
      fi
      ;;
   -n|--vcf-names)
       if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
         VCFindex=$2
         shift 2
       else
         echo "Error: missing VCF name list (/1_SV_Search/vcfs.txt)" >&2
         usage
         exit 1
       fi
       ;;
   -*|--*=) # unsupported flags
      echo "Error: Unsupported argument $1" >&2
      usage
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;    
  esac # <- end of case
done
# set positional arguments in their proper place
eval set -- "$PARAMS"


# test if we have a mam filter or not vcf
MAM=$(grep -v '#' $VCFin | head -n 1 | grep 'mam_filter' | wc -l | awk '{print $1}')
# extract the relevant columns from the VCF, split the support vector into binary columns for each assembly, pad the TSD column if missing
if [[ $MAM == "0" ]];
then
  grep -v "#" $VCFin | \
    sed 's/=/\t/g;s/;/\t/g' | \
    cut -f 1-5,11,13,15,19,21,29,31,33,35,37,39,41,43,45,47 | \
    awk '{gsub(".","& ", $6); print $0}' | \
    awk '{if ($NF == "1|0") {gsub(/1\|0/, "None", $NF); print $0} else {print $0}}' | \
    sort -k1,1 -k2,2n > body
  # make the header, including each assembly (vcf) name for split support vector
  head_begin=$(echo -e "CHR\tPOS\tID\tREF\tALT")
  head_supp=$(cat "$VCFindex" | awk -v RS='^$' '{gsub(/\n|(,\n$)/,"\t")} 1')
  head_end=$(echo -e "SVLEN\tSVTYPE\tCHR2\tEND\tn_hits\tfrags\thit_lenths\thit_names\thit_classes\thit_strands\thit_IDs\ttotal_match_length\ttotal_match_span\tTSD")
else
  grep -v "#" $VCFin | \
    sed 's/=/\t/g;s/;/\t/g' | \
    cut -f 1-5,11,13,15,19,21,29,31,33,35,37,39,41,43,45,47 | \
    awk '{gsub(".","& ", $6); print $0}' | \
    awk '{if ($NF == "1|0") {gsub(/1\|0/, "None", $NF); print $0} else {print $0}}' | \
    sort -k1,1 -k2,2n > body
  # make the header, including each assembly (vcf) name for split support vector
  head_begin=$(echo -e "CHR\tPOS\tID\tREF\tALT")
  head_supp=$(cat "$VCFindex" | awk -v RS='^$' '{gsub(/\n|(,\n$)/,"\t")} 1')
  head_end=$(echo -e "SVLEN\tSVTYPE\tCHR2\tEND\tn_hits\tfrags\thit_lenths\thit_names\thit_classes\thit_strands\thit_IDs\ttotal_match_length\ttotal_match_span\tmam_filter1\tmam_filter2\tTSD")
fi
cat <(echo -e "$head_begin\t$head_supp\t$head_end") body > $VCFin.tsv
# cleanup
rm body

## next we will need a switch for when we convert a genotype vcf
## I think we can recycle the main awk command but add 49+ in the cut call to get all the genotypes:
# grep -v "#" $VCFin | \
#     sed 's/=/\t/g;s/;/\t/g' | \
#     cut -f 1-5,11,13,15,19,21,29,31,33,35,37,39,41,43,45,47,49+ | \
#     awk '{gsub(".","& ", $6); print $0}' | \
#     awk '{if ($NF == "1|0") {gsub(/1\|0/, "None", $NF); print $0} else {print $0}}' | \
#     sort -k1,1 -k2,2n > body
## Make sure that the 

