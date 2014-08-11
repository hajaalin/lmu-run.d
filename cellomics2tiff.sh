#/bin/bash

INPUT=/mnt/lmu-active/LMU-active2/user/FROM_CELLINSIGHT
STAGING=/home/hajaalin/staging
OUTPUT=/mnt/lmu-active/LMU-active2/user/FROM_CSC_LMU/CellInsight

# if testing:
#INPUT=/mnt/lmu-active/LMU-active2/Harri/Data/testsets/cellomics2tiff
#OUTPUT=/home/hajaalin/tmp/FROM_CSC_LMU

IMAGE=hajaalin/cellomics2tiff
docker pull $IMAGE
docker run -v $INPUT:/input -v $STAGING:/staging -v $OUTPUT:/output $IMAGE -h
