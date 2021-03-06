# 相関度
# 

# デシル分析
# ユーザの購入ランクにてランク分けして、5グループに分けてみましょう
# 各グループごとの合計を出して
# 全体の売上量と比率計算を行います。
# 均等に１０分割できるようにntileを利用して分割します

# ABC分析
# Aランク 0~70
# Bランク 70~90
# Cランク 90~10
# ロイヤルユーザとか言ったりする

# RFM分析
# デシル分析のさらに細かいバージョン

# ファンチャート
# とある時点を100として
# 今回は各プロダクトごとの２０１８年1月のデータを100%基準としてファンチャートを作成してみます。

# Zチャート
# 月次売上/売上累計/移動年計
# 各合計をひと月づつずらしていくイメージです。
# 移動年計は当該月の売上と過去11ヶ月の売上累計を足し合わせます

# アソシエーション分析
# 最後に紹介するのはデータマイニングの一種、データを探索していくという意味
# かなりサイエンスぽい。本来はPythonなどのプログラミングを用いて行う事が多いがSQLでもできる

# 支持度
# 10件のうちに商品Xと商品Yをどうにに購入したログが1件でもあれば、支持率は10%です

# 確度
# 10件のうちXを購入しているデータが2件、そのうちYも購入しているレコードが1件であれば確度は50パーセントです

# リフト
# 10件のうちXを購入しているデータが2件、そのうちYも購入しているレコードが1件で、Y飲みを購入しているログが0件の場合は
# 角度は50,購入確率10%(1/10)となり　50/10 = 5となり、Xを購入した場合Yの購入率は5倍ということになります。
#　一般にリフトが1以上が良いと言われています

# ユークリッド距離とコサイン類似度
select
 sqrt(power(x1-x2,2) + power(y1-y2,2)) as dist
from
 location

# User 2 Item
# 好き嫌い判断などに使う事ができる
# ユーザー間で類似性を判定し
# 例えば、肉カウント、魚カウントから定量的なスコアを出す
# 例えば、他のユーザの購入履歴からあなたへのおすすめを出す
