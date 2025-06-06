#!/bin/bash -login
### This script was modified from https://github.com/mcstitzer/maize_v4_TE_annotation/blob/master/helitron/run_helitron_scanner.sh
### Original author: Michelle Stitzer, Apr 11, 2018
### Modifier: Shujun Ou (shujun.ou.1@gmail.com), May 1, 2019
### Revised: Tianyu Lu (tianyu@lu.fm), July 26, 2024

### specify the genome file
GENOME=$1

### the base path of this script
path=$(dirname "$0")

## where to find HelitronScanner.jar
#HSDIR=$path/../bin/HelitronScanner

# Find original directory of bash script, resolving symlinks
# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in/246128#246128
SOURCE=$3
echo $SOURCE
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
HSDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

### preset CPU and max memory
CPU=4
MEMGB=150 #Gb

### allow user to specify CPU number to run HelitronScanner
if [ ! -z "$2" ];
	then CPU=$2
fi

###########################
##   DIRECT ORIENTATION  ##
###########################

### only run command if output does not exist

if [ ! -f ${GENOME}.HelitronScanner.head.done ]; then

##find helitron heads
### will load each chromosome into memory, without splitting into 1Mb batches (-buffer_size option ==0) 
java -Xmx${MEMGB}g -jar ${HSDIR}/HelitronScanner.jar scanHead -lcv_filepath ${HSDIR}/TrainingSet/head.lcvs -g $GENOME -buffer_size 0 -output ${GENOME}.HelitronScanner.head

touch ${GENOME}.HelitronScanner.head.done

fi

if [ ! -f ${GENOME}.HelitronScanner.tail.done ]; then

## helitron tails
java -Xmx${MEMGB}g -jar ${HSDIR}/HelitronScanner.jar scanTail -lcv_filepath ${HSDIR}/TrainingSet/tail.lcvs -g $GENOME -buffer_size 0 -output ${GENOME}.HelitronScanner.tail

touch  ${GENOME}.HelitronScanner.tail.done
fi

if [ ! -f ${GENOME}.HelitronScanner.pairends.done ]; then

## pair the ends to generate possible helitrons
java -Xmx${MEMGB}g -jar ${HSDIR}/HelitronScanner.jar pairends -head_score ${GENOME}.HelitronScanner.head -tail_score ${GENOME}.HelitronScanner.tail -output ${GENOME}.HelitronScanner.pairends
touch ${GENOME}.HelitronScanner.pairends.done
fi

if [ ! -f ${GENOME}.HelitronScanner.draw.done ]; then

## draw the helitrons into fastas
java -Xmx${MEMGB}g -jar ${HSDIR}/HelitronScanner.jar draw -pscore ${GENOME}.HelitronScanner.pairends -g $GENOME -output ${GENOME}.HelitronScanner.draw -pure_helitron
touch ${GENOME}.HelitronScanner.draw.done
fi

############################
##    REVERSE COMPLEMENT  ##
############################

if [ ! -f  ${GENOME}.HelitronScanner.rc.head.done ]; then

##find helitron heads
### will load each chromosome into memory, without splitting into 1Mb batches (-buffer_size option ==0) 
java -Xmx${MEMGB}g -jar ${HSDIR}/HelitronScanner.jar scanHead -lcv_filepath ${HSDIR}/TrainingSet/head.lcvs -g $GENOME -buffer_size 0 --rc -output ${GENOME}.HelitronScanner.rc.head
touch ${GENOME}.HelitronScanner.rc.head.done
fi

if [ ! -f  ${GENOME}.HelitronScanner.rc.tail.done ]; then

## helitron tails
java -Xmx${MEMGB}g -jar ${HSDIR}/HelitronScanner.jar scanTail -lcv_filepath ${HSDIR}/TrainingSet/tail.lcvs -g $GENOME -buffer_size 0 --rc -output ${GENOME}.HelitronScanner.rc.tail
touch ${GENOME}.HelitronScanner.rc.tail.done
fi

if [ ! -f  ${GENOME}.HelitronScanner.rc.pairends.done ]; then

## pair the ends to generate possible helitrons
java -Xmx${MEMGB}g -jar ${HSDIR}/HelitronScanner.jar pairends -head_score ${GENOME}.HelitronScanner.rc.head -tail_score ${GENOME}.HelitronScanner.rc.tail --rc -output ${GENOME}.HelitronScanner.rc.pairends
touch ${GENOME}.HelitronScanner.rc.pairends.done
fi

if [ ! -f  ${GENOME}.HelitronScanner.draw.rc.done ]; then

## draw the helitrons
java -Xmx${MEMGB}g -jar ${HSDIR}/HelitronScanner.jar draw -pscore ${GENOME}.HelitronScanner.rc.pairends -g $GENOME -output ${GENOME}.HelitronScanner.draw.rc -pure_helitron
touch ${GENOME}.HelitronScanner.draw.rc.done
fi

rm *.done
#########################
##   tab format output ##
######################### 

### will read in both $GENOME.HelitronScanner.draw.hel.fa $GENOME.HelitronScanner.draw.rc.hel.fa and filter out candidates based on prediction scores (min = 12) and target site (AT or TT).
perl $path/format_helitronscanner_out.pl -genome $GENOME -sitefilter 1 -minscore 12 -keepshorter 1 -extout 0




