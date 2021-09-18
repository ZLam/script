#!/bin/bash

projectRootDir=`pwd`

masterSrcBranchName="master"
devSrcBranchName="dev_xxx"

masterConfigBranchName="master"
devConfigBranchName="dev_xxx"

originSrcBranchName=""

update()
{
    local originBranchName=${1}
    local masterBranchName=${2}
    local devBranchName=${3}
    local bCleanOriginBranch=0
    local bCleanDevBranch=0

    if [ $originBranchName == $devBranchName ]
    then
        bCleanDevBranch=0
        if [[ -n $(git diff --stat) ]]     ## 判断当前仓库干不干净
        then
            bCleanDevBranch=0
        else
            bCleanDevBranch=1
        fi
        if [[ $bCleanDevBranch == 0 ]]
        then
            echo "-------------------- stash save $devBranchName --------------------"
            git stash
            echo "-------------------- end --------------------"
        fi
        echo "-------------------- switch to $masterBranchName --------------------"
        git switch $masterBranchName
        echo "-------------------- end --------------------"
        echo "-------------------- update $masterBranchName --------------------"
        git pull
        echo "-------------------- end --------------------"
        echo "-------------------- switch to $devBranchName --------------------"
        git switch $devBranchName
        echo "-------------------- end --------------------"
        echo "-------------------- merge $masterBranchName to $devBranchName --------------------"
        git merge $masterBranchName
        echo "-------------------- end --------------------"
        if [[ $bCleanDevBranch == 0 ]]
        then
            echo "-------------------- stash pop $devBranchName --------------------"
            git stash pop
            echo "-------------------- end --------------------"
        fi
    else
        bCleanOriginBranch=0
        if [[ -n $(git diff --stat) ]]
        then
            bCleanOriginBranch=0
        else
            bCleanOriginBranch=1
        fi
        if [[ $bCleanOriginBranch == 0 ]]
        then
            echo "-------------------- stash save $originBranchName --------------------"
            git stash
            echo "-------------------- end --------------------"
        fi
        echo "-------------------- switch to $masterBranchName --------------------"
        git switch $masterBranchName
        echo "-------------------- end --------------------"
        echo "-------------------- update $masterBranchName --------------------"
        git pull
        echo "-------------------- end --------------------"
        echo "-------------------- switch to $devBranchName --------------------"
        git switch $devBranchName
        echo "-------------------- end --------------------"
        echo "-------------------- merge $masterBranchName to $devBranchName --------------------"
        git merge $masterBranchName
        echo "-------------------- end --------------------"
        echo "-------------------- switch to $originBranchName --------------------"
        git switch $originBranchName
        echo "-------------------- end --------------------"
        if [[ $bCleanOriginBranch == 0 ]]
        then
            echo "-------------------- stash pop $originBranchName --------------------"
            git stash pop
            echo "-------------------- end --------------------"
        fi
    fi
}

echo -e "\033[36m---------- update `pwd` ----------\033[0m"
originSrcBranchName=`git rev-parse --abbrev-ref HEAD`
update $originSrcBranchName $masterSrcBranchName $devSrcBranchName
echo -e "\033[36m-------------------- end --------------------\033[0m"

cd $projectRootDir/common
echo -e "\033[36m---------- update `pwd` ----------\033[0m"
originSrcBranchName=`git rev-parse --abbrev-ref HEAD`
update $originSrcBranchName $masterConfigBranchName $devConfigBranchName
echo -e "\033[36m-------------------- end --------------------\033[0m"
