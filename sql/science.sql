月ごとの分析
with hoge as (
    select * from (
        SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
        FROM orders
    )  peke
)
select 
    sa_month,sum(total),product_id
from hoge 
group by sa_month,product_id
order by product_id,sa_month
;


# デシル分析
# ユーザの購入ランクにてランク分けして、10グループに分けてみましょう
# 均等に１０分割できるようにntileを利用して分割します

# 各グループごとの合計を出して
# 全体の売上量と構成比率計算を行います。

with base_data as (
    select * from (
        SELECT user_id,name,product_id,total,to_char(o.created_at, 'YYYY-MM') AS sa_month
        FROM orders as o
        inner join people as p on user_id = p.id
    )  peke
)
,
user_amount_data as (
select 

user_id,name,sum(total) as user_amount
from base_data 
group by user_id,name
order by user_id
)
,
decile_base as (
SELECT
user_id,name,user_amount,
ntile(10) over(order by user_amount desc) as decile
from user_amount_data
)

,
math_base as (
select 
decile,

sum(user_amount) as group_amount,
avg(user_amount) as avg_amount,
sum(sum(user_amount)) over() as total_amount,
sum(sum(user_amount)) over(order by decile) as cumilative_amount

from 
decile_base
group by decile 
)

select 
  decile,
  group_amount,
  avg_amount,
  100.0 * group_amount / total_amount as total_ratio,
  100.0 * cumilative_amount/ total_amount as cumilative_ratio
from 
math_base

 

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

with hoge as (
    select * from (
        SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
        FROM orders
    )  peke
)
,
base_data as (
select 
    sa_month,sum(total) as amount,product_id, prod.title
from hoge 
inner join products as prod
on product_id = prod.id
where 
 product_id in(3,4)
group by sa_month,product_id,title
order by product_id,sa_month
)

select 
  sa_month,
  product_id,
  title,
  first_value(amount)
  over(partition by product_id  order by sa_month, product_id rows unbounded preceding) as base_data,
  100.0 * amount / first_value(amount)
  over(partition by product_id  order by sa_month, product_id rows unbounded preceding) as rate
 from base_data

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
