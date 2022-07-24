# ファンチャート
# 今回は各プロダクトごとの最古のデータを100%基準としてファンチャートを作成してみます。

with hoge as (
    select * from (
        SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
        FROM orders
    )  peke
)
,
-- 月とプロダクトごとに売上金額の合計値を出力する
base_data as (
select 
    sa_month,sum(total) as amount,product_id, prod.title
from hoge 
    inner join products as prod
    on product_id = prod.id
where 
 -- データが多いとみづらいので3,4だけに絞る
 product_id in(3,4)
group by sa_month,product_id,title
order by product_id,sa_month
)

select 
  sa_month,
  product_id,
  title,
  -- sa_monthで並び替え最古のデータを取得(first_value)
  -- このデータを100%のデータとする
  first_value(amount)
  over(partition by product_id  order by sa_month, product_id rows unbounded preceding) as base_data,
  -- 100%のデータに対しての割合を計算する
  100.0 * amount / first_value(amount)
  over(partition by product_id  order by sa_month, product_id rows unbounded preceding) as rate
 from base_data

# Zチャート
# 月次売上/売上累計/移動年計
# 当該月を2017/11月にしましょう

# ステップ１：月毎に集計します
# ファンチャートのSQLをそのまま使います
# ステップ２：次ごとの累計を少しづつ足していきます。
# 各合計をひと月づつずらしていくイメージです。
# 移動年計は当該月の売上と過去11ヶ月の売上累計を足し合わせます
with hoge as (
    select * from (
        SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
        FROM orders
    )  peke
)
,
-- 月ごとの集計
-- 当該月を2018-01として行い、2017年のZチャートを作成したい
-- 移動年計を出すためには2016-01月からデータが必要(11ヶ月前のデータを足すため)
base_data as (
select 
    sa_month,sum(total) as month_amount
from hoge 
inner join products as prod
on product_id = prod.id
where 
 sa_month between '2016-01' and '2017-12'
group by sa_month
order by sa_month
)

, nenkei as (
-- 月累計を行う
select 

    sa_month,month_amount as "月次",
    -- 2017のZチャートにしたいので条件をつけて集計する
    sum(case when sa_month like '%2017%' then month_amount end) over( order by sa_month ) as "累計",
    -- 11ヶ月前のデータを対象とする
    sum(month_amount) over(order by sa_month , sa_month rows between 11 preceding and CURRENT ROW) as "移動"

from 
    base_data
)

select 
    * 
from 
    nenkei
where
    sa_month like '%2017%'
order by sa_month

# プロダクトごとに集計することも可能です

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

-- ntileを使ってユーザーの購入金額に応じて10個のグループに分割する
decile_base as (
SELECT
    user_id,name,user_amount,
    ntile(10) over(order by user_amount desc) as decile
from user_amount_data
)
,

-- グループごとに集計値を出す
math_base as (
select 
    decile,
    sum(user_amount) as group_amount,
    avg(user_amount) as avg_amount,
    -- 小技。overの条件を無くすことで、全てのユーザごとのデータを足し合わせている(=つまり総計)。
    sum(sum(user_amount)) over() as total_amount,
    -- 累計は並び替えながら足すことで計算する事が可能
    sum(sum(user_amount)) over(order by decile) as cumilative_amount
from 
decile_base
group by decile 
)

select 
  decile,
  group_amount,
  avg_amount,
  -- 構成比を出力する
  100.0 * group_amount / total_amount as total_ratio,
  100.0 * cumilative_amount/ total_amount as cumilative_ratio
from 
math_base

# ABC分析
## 売れ筋の商品をA~Cランクに分ける
# Aランク 0~70
# Bランク 70~90
# Cランク 90~10

with hoge as (
    select * from (
        SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
        FROM orders
    )  peke
)
,
base_data as (
select 
    sum(total) as amount,product_id, prod.title
from hoge 
    inner join products as prod
    on product_id = prod.id
group by product_id,title
order by amount
)

-- 売上における構成費を出力する
,composition as (
select
    title,
    -- プロダクトごとの売上
    sum(amount) as product_amount,
    -- 全体の売上 
    sum(sum(amount)) over() as total_amount,
    100.0 * sum(amount) / sum(sum(amount)) over() as composition_ratio
from base_data
group by title
order by composition_ratio desc
)
,
-- 累計割合を出す
cumulative as (
select 
    title,
    product_amount,
    composition_ratio,
    sum(composition_ratio) over(order by composition_ratio desc) as cumulative_ratio
from composition
)

-- ランク分けを行う
SELECT
 title,
 product_amount,
 composition_ratio,
 cumulative_ratio,
 CASE
     WHEN cumulative_ratio between 0 and 70 then 'A'
     WHEN cumulative_ratio between 70 and 90 then 'B'
     WHEN cumulative_ratio between 90 and 101 then 'C'
 END as abc_rank
 FROM
 cumulative

# RFM分析
## デシル分析のさらに細かいバージョン

with base_data as (
    select * from (
        SELECT user_id,name,product_id,total,cast(to_char(o.created_at, 'YYYY-MM-DD') as date) AS sa_month
        FROM orders as o
        inner join people as p on user_id = p.id
    )  peke
)
,

rfm as (
SELECT
 user_id,
 Max(sa_month) as recent_date,
 -- 本当はcurrent_dateだが、データ自体が古いのでcurrent_dateを2020-05-10日とする
 --current_date - MAX(sa_month) as recency
 cast('2020-05-20' as date) - MAX(sa_month) as recency,
 -- 購入回数
 count(sa_month) as frequency,
 -- 購入金額
 sum(total) as monetary
from 
 base_data
group by user_id
order by recency,frequency,monetary
)
,
user_rfm as (
-- ランク分けをしていきます
SELECT
 user_id,
 recent_date,
 recency,
 frequency,
 monetary,
 -- rfmをそれぞれランク分けする
 case
  when recency <= 32 then 5
  when recency between 32 and 60 then 4
  when recency between 60 and 80  then 3
  when recency between 80 and 120 then 2
  ELSE 1
 END as r
 ,
 case
  when frequency >=10  then 5
  when frequency between 7 and 10 then 4
  when frequency between 3 and 7  then 3
  when frequency between 2 and 3 then 2
  ELSE 1
 END as f,
 case
  when monetary >=50000  then 5
  when monetary between 40000 and 50000 then 4
  when monetary between 10000 and 40000  then 3
  when monetary between 2000 and 10000 then 2
  ELSE 1
 END as m
from 
 rfm
)
,
rfm_count as(
select 
 r + f + m as total,
 r,f,m,count(user_id)
from user_rfm
group by
 r,f,m
order by
 total desc , f desc, m desc, r desc
)
,
master_rfm as (

select 1 as rank
union all select 2 as rank
union all select 3 as rank
union all select 4 as rank
union all select 5 as rank
)
,
flag as (
SELECT
    rank,
    case when rank = r then 1 else 0 end as r_flag,
    case when rank = f then 1 else 0 end as f_flag,
    case when rank = m then 1 else 0 end as m_flag
from 
 master_rfm
 cross join
 rfm_count

)

select 
    rank,
    sum(r_flag) as r,
    sum(f_flag) as f,
    sum(m_flag) as m
from flag
group by 
  rank
 order by rank desc

# アソシエーション分析
# 2商品缶の関連について紹介する
# データマイニングの一種、データを探索していくという意味
# かなりサイエンスぽい。本来はPythonなどのプログラミングを用いて行う事が多いがSQLでもできる
# 今回は同時というより30日以内に別の商品を購入したら同時に購入したとして扱います。by

# 支持度
# 10件のうちに商品Xと商品Yを同時に購入したログが1件でもあれば、支持率は10%です

# 確度
# 10件のうちXを購入しているデータが2件、そのうちYも購入しているレコードが1件であれば確度は50パーセントです

# リフト
# 10件のうちXを購入しているデータが2件、そのうちYも購入しているレコードが1件で、Y飲みを購入しているログが0件の場合は
# 角度は50,購入確率10%(1/10)となり　50/10 = 5となり、Xを購入した場合Yの購入率は5倍ということになります。
#　一般にリフトが1以上が良いと言われています

with base_data as (
    select * from (
        SELECT user_id,product_id,total,cast(to_char(o.created_at, 'YYYY-MM-DD') as date) AS sa_month
            FROM orders as o
            inner join people as p on user_id = p.id
        where 
         product_id < 50
    )  peke
),

base_data2 as (
    select * from (
        SELECT user_id,product_id,total,cast(to_char(o.created_at, 'YYYY-MM-DD') as date) AS sa_month
         FROM orders as o
            inner join people as p on user_id = p.id
        where 
         product_id < 50
    )  peke
)

-- 購入ログの総数
-- 商品Xを購入した数
-- 商品Yを購入した数
, data1 as (

SELECT
    product_id,
    -- 購入ログ数の総数
    sum(count(*)) over() as total,
    -- X,Yそれぞれの購入した数
    count(*) as product_total
from 
 base_data
group by 
 product_id
)

, data2 as (
-- 商品XとYを同日に購入した数
select 
    b1.product_id as b1_product_id,
    b2.product_id as b2_product_id,
    count(case when b1.sa_month = b2.sa_month then 1 end ) as same_timing_total
from base_data as b1
    cross join base_data2 as b2
where b1.product_id <> b2.product_id
    group by 
    b1.product_id,b2.product_id
)

-- Xを紐つける
, add_X as (
SELECT
    total as a,
    product_total as b1_x,
    b1_product_id,
    b2_product_id,
    same_timing_total
from
 data1
inner join data2 on data1.product_id = b1_product_id
)

-- Yを紐つける
, add_Y as (
SELECT
    b1_product_id,
    b2_product_id,
    a,
    b1_x,
    product_total as b2_y,
    same_timing_total
from
 data1
inner join add_X on data1.product_id = b2_product_id
)

-- 支持度、確信度、リフトを出して行く
select 
    b1_product_id,
    b2_product_id,
    100.0 * same_timing_total / a as support,
    100.0 * same_timing_total / b1_x as confidence,
    (100.0 * same_timing_total / b1_x) / (100.0 * b2_y / a) as lift
from add_Y 
order by
 b1_product_id,b2_product_id

# ユークリッド距離とコサイン類似度
# 似ている似ていないを判断することに使える
# 協調フィルタリング
# このアイテムを購入した人は、この商品を購入しています

select
 sqrt(power(x1-x2,2) + power(y1-y2,2)) as dist
from
 (select 1 as x1, 2 as x2, 4 as y1, 7 as y2) loc

# 協調フィリタリング
# ユーザのプロダクトに対する興味の度合いを数値化してみる
# ユーザがプロダクトを買っているかどうかと個数で数値化してみる
# 一次元ベクトル

with base_data as (
    select * from (
        SELECT user_id,product_id,total,cast(to_char(o.created_at, 'YYYY-MM-DD') as date) AS sa_month, quantity
            FROM orders as o
            inner join people as p on user_id = p.id
        where 
         product_id < 50
    )  peke
)

-- ユーザの商品に対する興味度を、購入数に応じてスコアづけを用いて数値化してみる
-- もちろん別の要素を使ってスコア化する事も可能
-- スコアそれぞれが一次元ベクトルと見做している
,
score as ( 
SELECT
    user_id,
    product_id,
    sum( case when quantity = 1 then 0.5 when quantity between 2 and 4 then 0.7 else 1 end) as score
from 
 base_data
group by user_id,product_id
)

-- ユーザーとプロダクト間の組み合わせを作成(正規化なし)
-- SELECT
-- s1.product_id,
-- s2.product_id,
-- count(s1.user_id),
-- -- 一次元ベクトルの内積
-- -- Aプロダクト、Bプロダクト、、、を購入した時のそれぞれのスコアを合計
-- sum(s1.score * s2.score) as score,
-- row_number() over(partition by s1.product_id order by sum(s1.score * s2.score) desc)
-- from 
--     score s1
-- inner join score s2 
--     on s1.user_id = s2.user_id
-- where
-- s1.product_id <> s2.product_id
-- group by s1.product_id,s2.product_id

-- 正規化する
, normalized_ratings as (
SELECT
    user_id,
    product_id,
    score,
    -- |a|を算出している
    sqrt(sum(score * score) over(partition by product_id))  as normalized,
    -- ベクトルの正規化a/|a|
    score / sqrt(sum(score * score) over(partition by product_id)) as normalized_score
from score
)

-- プロダクト(r1_product)=aとプロダクト(r2_product)=bのなす角度を出力する
-- 
-- Σa*b / √Σa^2 + √Σb^2 = a.b / |a|.|b|
-- 正規化するとベクトルの長さがそれぞれ1になるので|a|.|b| = 1となって a.bつまり内積だけをもとればよくなる
SELECT
    r1.product_id as r1_product,
    r2.product_id as r2_product,
    count(r1.user_id) as users,
    -- a.bで内積を計算 = cosθを算出
    sum(r1.normalized_score * r2.normalized_score) as score,
    row_number() over(partition by r1.product_id order by sum(r1.normalized_score * r2.normalized_score) desc) as rank
from
    normalized_ratings as r1
inner join normalized_ratings as r2
    on r1.user_id = r2.user_id
group by r1.product_id,r2.product_id

