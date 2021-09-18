#!/bin/bash

# 将某目录下的部分文件复制到指定的目录下
# 目前2种方式
# 1，全复制不过可以用filterFileNameArr筛选
# 2，部分复制
#   a，传参进来只复制指定的文件，不过过程就要scan所以会慢啲（可以用-sd指定目录加快scan），同样会用filterFileNameArr筛选
#   b，-sf 后加上相对路径文件，不会scan所以比较快，不会用filterFileNameArr筛选

copyFromFullPath="/f/xxx"
copyToFullPath="/c/Users/yourname/Desktop/xxx"
filterFileNameArr=(
    ".git"
    ".vscode"
    ".gitignore"
    ".gitmodules"
    "main.code-workspace"
    "workspace.code-workspace"
    "copy.sh"
    "zzzPyTools"
    "test.drawio"
    "update.sh"
)
declare -A copyPartFileNameMap      # 定义一个map结构
copyPartFileNum=0
curCopiedPartFileNum=0
copyPartDir=""
specifyRelativeFiles=()

isFilterFile()
{
    local ret=0
    for name in ${filterFileNameArr[*]}
    do
        # echo $name
        if [ $name == $1 ]
        then
            ret=1
            break
        fi
    done
    echo $ret       # 捕获函数返回值的一种形式，先echo，外面再$()获取
    return $?
}

copyPart()
{
    if [ $curCopiedPartFileNum -ge $copyPartFileNum ]
    then
        return
    fi

    local filePath=${1}
    local centerPath=${filePath/$copyFromFullPath/""}       # 字符串替换

    if [ $centerPath ]
    then
        echo -e "\033[32m[I]\033[0m[scan dir] : $centerPath"
    else
        echo -e "\033[32m[I]\033[0m[scan dir] : /"
    fi

    for fileName in `ls ${1}`
    do
        local b=$(isFilterFile $fileName)
        if [ $b == 0 ]
        then
            local fullPath="${1}/$fileName"
            if [ -d $fullPath ]
            then
                copyPart $fullPath
            else
                if [ ${copyPartFileNameMap[$fileName]} ]
                then
                    echo -e "\033[32m[I]\033[0m\033[36m[found]\033[0m : $centerPath/$fileName"

                    local toFullPath="$copyToFullPath$centerPath"

                    if [ ! -d $toFullPath ]
                    then
                        `mkdir -p $toFullPath`
                    fi

                    toFullPath="$toFullPath/$fileName"
                    `cp -f $fullPath $toFullPath`

                    curCopiedPartFileNum=$(( $curCopiedPartFileNum + 1 ))       # 算数运算
                fi
            fi
        fi
    done
}

copyPartEX()
{
    if [ $copyPartFileNum -gt 0 ]
    then
        local fullPath="$copyFromFullPath$copyPartDir"
        copyPart $fullPath
    fi
    copyPartFileNameMap=()
    copyPartFileNum=0
    curCopiedPartFileNum=0
    copyPartDir=""
}

copySpecifyRelativeFiles()
{
    local len=${#specifyRelativeFiles[*]}
    if [ $len -gt 0 ]
    then
        for filePath in ${specifyRelativeFiles[@]}
        do
            # echo $filePath
            local fromFilePath="$copyFromFullPath/$filePath"
            local toFilePath="$copyToFullPath/$filePath"
            cpEX $fromFilePath $toFilePath
        done
    fi
}

cpEX()
{
    local fromFilePath=${1}
    local toFilePath=${2}

    echo -e "\033[32m[I]\033[0mfrom $fromFilePath to $toFilePath"

    if [ -f $fromFilePath ]
    then
        # echo "$fromFilePath is file"

        local toFileDir=${toFilePath%/*}
        if [ ! -d $toFileDir ]
        then
            `mkdir -p $toFileDir`
        fi

        `cp -f $fromFilePath $toFilePath`
    elif [ -d $fromFilePath ]
    then
        # echo "$fromFilePath is directory"

        `cp -Rf $fromFilePath/. $toFilePath`        # 唔加 /. 会有问题！！
    else
        echo -e "\033[33m[W]\033[0munknow $fromFilePath"
    fi
}

main()
{
    local startTime=`date +%s%3N`

    echo -e "\033[32m[I]\033[0mcopying..."

    if [ ! -d $copyToFullPath ]
    then
        `mkdir -p $copyToFullPath`
    fi

    local paramsNum=$#
    if [ $paramsNum -gt 0 ]
    then
        local specifyArg=""
        local specifyArgIndex=0

        # 部分复制
        for paramValue in $@
        do
            # echo $paramValue

            if [ $paramValue == "-sd" ]
            then
                specifyArg=$paramValue
                specifyArgIndex=1
                copyPartEX
            elif [ $paramValue == "-sf" ]
            then
                specifyArg=$paramValue
                specifyArgIndex=1
            elif [ $specifyArgIndex -gt 0 ]
            then
                if [ $specifyArg == "-sd" ]
                then
                    if [ $specifyArgIndex == 1 ]
                    then
                        copyPartDir=$paramValue
                    else
                        copyPartFileNameMap[$paramValue]=1
                        copyPartFileNum=$(( $copyPartFileNum + 1 ))
                    fi
                    specifyArgIndex=$(( $specifyArgIndex + 1 ))
                elif [ $specifyArg == "-sf" ]
                then
                    specifyRelativeFiles[$specifyArgIndex]=$paramValue
                    specifyArgIndex=$(( $specifyArgIndex + 1 ))
                fi
            fi
        done

        copyPartEX

        copySpecifyRelativeFiles
    else
        # 全复制
        for fileName in `ls $copyFromFullPath`
        do
            local b=$(isFilterFile $fileName)

            if [ $b == 0 ]
            then
                local fromFilePath="$copyFromFullPath/$fileName"
                local toFilePath="$copyToFullPath/$fileName"

                cpEX $fromFilePath $toFilePath
            fi
        done
    fi

    local endTime=`date +%s%3N`

    awk "BEGIN{ printf \"\033[32m[I]\033[0mcopy done(%0.1fs)\n\", ($endTime-$startTime)/1000 }"
}

main $@
