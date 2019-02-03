#!/bin/bash

# 定数ファイル
../cinfig/env.sh

# 変数
whale_branch_name=""
static_branch_name=""
app_branch_name=""

change_dir () {
  dir_name="attype"
  if [ $1 = "whale" ]; then
    dir_name=${dir_name}"_whale18go"
  elif [ $1 = "static" ]; then
    dir_name=${dir_name}"_static"
  fi

  # cd //c/${dir_name}
  cd ${GAT_PATH}/test/${dir_name}

  return 0
}

get_branch_name () {
  echo "==========================================" >> ${LOG_FILE}
  echo $1" ブランチ名取得開始" >> ${LOG_FILE}

  # ディレクトリ移動
  change_dir $1

  # ローカルリポジトリ最新化
  git fetch

  # 引数で取得した番号のブランチリストを取得
  BRANCH_LIST=(`git branch |grep ${BRANCH_NUMBER}_ |xargs`)

  # チケット番号の入ったブランチが1つだけある場合
  if [ ${#BRANCH_LIST[@]} -eq 1 ]; then
    BRANCH_NAME=`echo ${BRANCH_LIST[0]}`
  # 入力されたチケット番号含むブランチが複数ある場合
  elif [ ${#BRANCH_LIST[@]} -gt 1 ]; then
    # 何行目のブランチ名を使用するか確認
    echo "下記から使用するブランチ名を選び、入力してください"
    echo "${BRANCH_LIST[@]}"
    read BRANCH_NAME
  # ブランチ名が存在しない場合
  elif [ ${#BRANCH_LIST[@]} -eq 0 ]; then
    echo "入力されたチケット番号を含むブランチは存在しません。masterをチェックアウトしますか(yes/no)"
    read input
    if [ ${input} = 'yes' ]; then
      BRANCH_NAME="master"
    else
      echo "ブランチ切替を中断しました"
      exit
    fi
  fi

  # 実行結果
  if [ $? -eq 0 ]; then
    echo "ブランチ名取得:"${BRANCH_NAME} >> ${LOG_FILE}
  else
    echo "ブランチ名の取得に失敗しました。ログをチェックしてください" >> ${LOG_FILE}
    exit 1
  fi

  if [ $1 = "whale" ]; then
    whale_branch_name="${BRANCH_NAME}"
  elif [ $1 = "static" ]; then
    static_branch_name="${BRANCH_NAME}"
  else
    app_branch_name="${BRANCH_NAME}"
  fi

  return 0
}

check_out () {
  echo "==========================================" >> ${LOG_FILE}
  echo $1"ブランチ切替開始" >> ${LOG_FILE}

  change_dir $1

  git checkout $2

  # 実行結果
  if [ $? -eq 0 ]; then
    echo $1" : "$2
  else
    echo "ブランチ切替に失敗しました。ログをチェックしてください"
    exit 1
  fi

  return 0
}

# ログファイル準備
LOG_FILE=${GAT_PATH}/"gat.log"
if [ -e ${LOG_FILE} ]; then
  rm ${LOG_FILE}
fi
touch ${LOG_FILE}

# 引数取得
BRANCH_NUMBER=$1
if [ -z "${BRANCH_NUMBER}" ]; then
  echo "[ERROR] コマンド引数にチケット番号を入力してください ex) gat 12345"
  exit
fi

# 入力されたブランチ番号の設定ファイルが既に存在するか
CONF_FILE="${GAT_PATH}/conf/${BRANCH_NUMBER}_conf"
if [ -e ${CONF_FILE} ]; then
  # 存在する場合は設定読込
  whale_branch_name=`sed -n 1P ${CONF_FILE}`
  static_branch_name=`sed -n 2P ${CONF_FILE}`
  app_branch_name=`sed -n 3P ${CONF_FILE}`
else
  # 存在しない場合はブランチ名取得
  get_branch_name "whale" 2>> ${LOG_FILE}
  get_branch_name "static" 2>> ${LOG_FILE}
  get_branch_name "app" 2>> ${LOG_FILE}

  # 設定ファイル作成
  touch ${CONF_FILE}
  echo ${whale_branch_name} >> ${CONF_FILE}
  echo ${static_branch_name} >> ${CONF_FILE}
  echo ${app_branch_name} >> ${CONF_FILE}
fi

# チェックアウト
echo "ブランチ切替"
check_out "whale" ${whale_branch_name} 2>> ${LOG_FILE}
check_out "static" ${static_branch_name} 2>> ${LOG_FILE}
check_out "app" ${app_branch_name} 2>> ${LOG_FILE}

exit 0
