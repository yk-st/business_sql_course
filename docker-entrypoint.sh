#!/bin/sh

# Metabaseを起動
java -jar metabase.jar &

# フォアグラウンドでMetabaseを実行
wait
