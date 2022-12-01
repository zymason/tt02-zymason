#!/bin/csh -f

cd /afs/andrew.cmu.edu/usr6/zymason/private/18341/tt02-zymason/src

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/afs/ece.cmu.edu/support/synopsys/synopsys.release/T-Foundation/vcs/T-2022.06/linux64/bin/vcselab $* \
    -o \
    simv \
    -nobanner \

cd -

