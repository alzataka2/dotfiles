#!/bin/bash

#######################################################################
# スクリプトが置かれているディレクトリと同階層に存在する              #
# .XXXファイル／ディレクトリのシンボリックリンクを ${HOME} に作成する #
# (. .. .git このスクリプト自体 は対象外とする)                       #
#                                                                     #
# - ${HOME} 内に同名のファイル／ディレクトリが存在していた場合        #
#   -- [既に自分に対するシンボリックリンク]                           #
#   -- [ファイルかつ差分がない場合]                                   #
#       --- なにもしない                                              #
#                                                                     #
#   -- [ファイルかつ差分がある場合]                                   #
#   -- [他のファイルに対するシンボリックリンク]                       #
#   -- [ディレクトリの場合]                                           #
#       --- コンソールに表示した上で、そのファイル／ディレクトリを    #
#           ./backupディレクトリに退避してシンボリックリンクを作成    #
#######################################################################

# スクリプトが置かれているパスに移動する
cd `dirname $0`


# リンク作成先のパス(${HOME})
TARGET_PATH="${HOME}"

# バックアップ先ディレクトリ
BACKUP_DIR="${PWD}/backup/`date +%Y%m%d%H%M%S`"

# バックアップしたファイルを後でまとめて表示する
BACKUP=""



# $1のファイルのシンボリックリンクを${TARGET_PATH}に作成する
make_link() {
    ln -s ${PWD}/$1 ${TARGET_PATH}/$1
    echo "create link $1 ..."
}



# ${TARGET_PATH}/$1 のファイルを${BACKUP_DIR}に移動する
bkup_orig_file() {
    # バックアップ先のディレクトリがない場合は作成する
    if [ ! -e ${BACKUP_DIR} ]; then
        mkdir -p ${BACKUP_DIR}
    fi

    # バックアップ先ディレクトリにmv
    mv $1 ${BACKUP_DIR}/.
    BACKUP="${BACKUP}\nbackup to ${BACKUP_DIR}/`basename $1`"
}



# 同階層の.XXXファイル／ディレクトリを列挙(ファイル名にスペースを含まないこと！)
for file in `ls -a | grep -v ^.git$ | grep -v ^.gitignore$ | grep -v ^.gitkeep$ | egrep '^\.[^.]+'`; do

    # リンク先ファイル名
    target=${TARGET_PATH}/${file}

    # オリジナルファイルの退避が必要か
    need_backup=0

    if [ -e "${target}" ]; then

        # ファイルタイプ(ファイル、ディレクトリ、リンク)をチェック
        if [ -n "`find \"${target}\" -maxdepth 0 -type l`" ]; then
            # リンク

            # 既に自分へのリンクの場合はなにもしない
            if [ "`readlink -f ${target}`" = "${PWD}/${file}" ]; then
                echo "${target} is already linked"
                continue
            fi

            # 他ファイルへのリンクなのでバックアップする
            need_backup=1

        elif [ -d "${target}" ]; then
            # ディレクトリはバックアップする
            need_backup=1

        elif [ -f "${target}" ]; then
            # 既存のファイルをバックアップする
            need_backup=1

        else
            # ないと思う
            echo "little bit strange ${target} ..."
            continue
        fi
    fi

    # バックアップが必要ならバックアップする
    if [ $need_backup -eq 1 ]; then
        bkup_orig_file ${target}
    fi

    # シンボリックリンクを作成する
    make_link ${file}
done

# バックアップしたファイルを表示
echo -e "${BACKUP}"
