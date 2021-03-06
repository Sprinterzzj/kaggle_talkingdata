-- takling.train2
SELECT
*,
TIMESTAMP_DIFF(click_time, LAG(click_time) OVER(partition by ip order by click_time), SECOND) as timediff,
EXTRACT(year from click_time) as year,
EXTRACT(month from click_time) as month,
EXTRACT(day from click_time) as day,
EXTRACT(DAYOFWEEK from click_time) as dayofweek,
EXTRACT(HOUR from click_time) as hour
FROM
  `talking.train`

-- takling.test2
SELECT
*,
TIMESTAMP_DIFF(click_time, LAG(click_time) OVER(partition by ip order by click_time), SECOND) as timediff,
EXTRACT(year from click_time) as year,
EXTRACT(month from click_time) as month,
EXTRACT(day from click_time) as day,
EXTRACT(DAYOFWEEK from click_time) as dayofweek,
EXTRACT(HOUR from click_time) as hour
FROM
  `talking.test`

-- takling.train_test
SELECT
null as click_id,
ip, app, device, os, channel, click_time, attributed_time, is_attributed, timediff, year, month, day, dayofweek, hour
FROM
`talking.train2`
UNION ALL
SELECT
click_id,
ip, app, device, os, channel, click_time, null as attributed_time, null as is_attributed, timediff, year, month, day, dayofweek, hour
FROM
`talking.test2`

-- takling.train_test2
SELECT
  *,
  avg(is_attributed) OVER(partition by ip order by click_time ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as avg_ip,
  sum(cast(is_attributed as int64)) OVER(partition by ip order by click_time ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as sum_attr,
  TIMESTAMP_DIFF(click_time, MAX(attributed_time) OVER(partition by ip order by click_time ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), SECOND) as last_attr
FROM
  `talking.train_test`

-- takling.mst_app
SELECT
  app,
  avg(is_attributed) avg_app,
  count(1) / 184903890 cnt_app
  --CASE WHEN count(1) >= 100 THEN avg(is_attributed) ELSE -1 END avg_app
FROM
  `talking.train`
GROUP BY
  app

-- takling.mst_device
SELECT
  device,
  avg(is_attributed) avg_device,
  count(1) / 184903890 cnt_device
  --CASE WHEN count(1) >= 100 THEN avg(is_attributed) ELSE -1 END avg_device
FROM
  `talking.train`
GROUP BY
  device

-- takling.mst_os
SELECT
  os,
  avg(is_attributed) avg_os,
  count(1) / 184903890 cnt_os
  --CASE WHEN count(1) >= 100 THEN avg(is_attributed) ELSE -1 END avg_os
FROM
  `talking.train`
GROUP BY
  os

-- takling.mst_channel
SELECT
  channel,
  avg(is_attributed) avg_channel,
  count(1) / 184903890 cnt_channel
  --CASE WHEN count(1) >= 100 THEN avg(is_attributed) ELSE -1 END avg_channel
FROM
  `talking.train`
GROUP BY
  channel

-- takling.mst_hour
SELECT
  hour,
  avg(is_attributed) avg_hour,
  count(1) / 184903890 cnt_hour
  --CASE WHEN count(1) >= 100 THEN avg(is_attributed) ELSE -1 END avg_hour
FROM
  `talking.train2`
GROUP BY
  hour

-- takling.train_test3
SELECT
  t.*,
  a.avg_app, d.avg_device, o.avg_os, c.avg_channel, h.avg_hour,
  a.cnt_app, d.cnt_device, o.cnt_os, c.cnt_channel, h.cnt_hour,
  AVG(t.is_attributed) OVER(partition by t.ip, t.day, t.hour order by click_time ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as avg_ipdayhour,
  ROW_NUMBER() OVER(partition by t.ip order by click_time) as cnt_ip,
  SUM(t.is_attributed) OVER(partition by t.ip order by click_time ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as sum_ip
FROM
  `talking.train_test2` as t
LEFT OUTER JOIN
  talking.mst_app as a
ON
  a.app = t.app
LEFT OUTER JOIN
  talking.mst_device as d
ON
  d.device = t.device
LEFT OUTER JOIN
  talking.mst_os as o
ON
  o.os = t.os
LEFT OUTER JOIN
  talking.mst_channel as c
ON
  c.channel = t.channel
LEFT OUTER JOIN
  talking.mst_hour as hz
ON
  h.hour = t.hour


-- dmt_train
SELECT
  ip,
  concat('[', STRING_AGG(CASE WHEN is_attributed is not null THEN cast(is_attributed as string) ELSE '-1' END order by click_time), ']') as list_target,
  concat('[', STRING_AGG(CASE WHEN app is not null THEN cast(app as string) ELSE '-1' END order by click_time), ']') as list_app,
  concat('[', STRING_AGG(CASE WHEN device is not null THEN cast(device as string) ELSE '-1' END order by click_time), ']') as list_device,
  concat('[', STRING_AGG(CASE WHEN os is not null THEN cast(os as string) ELSE '-1' END order by click_time), ']') as list_os,
  concat('[', STRING_AGG(CASE WHEN channel is not null THEN cast(channel as string) ELSE '-1' END order by click_time), ']') as list_ch,
  concat('[', STRING_AGG(CASE WHEN timediff is not null THEN cast(timediff as string) ELSE '-1' END order by click_time), ']') as list_timediff,
  concat('[', STRING_AGG(CASE WHEN hour is not null THEN cast(hour as string) ELSE '-1' END order by click_time), ']') as list_hour,
  concat('[', STRING_AGG(CASE WHEN sum_attr is not null THEN cast(sum_attr as string) ELSE '-1' END order by click_time), ']') as list_sum_attr,
  concat('[', STRING_AGG(CASE WHEN last_attr is not null THEN cast(last_attr as string) ELSE '-1' END order by click_time), ']') as list_attr,
  concat('[', STRING_AGG(CASE WHEN avg_ip is not null THEN cast(avg_ip as string) ELSE '-1' END order by click_time), ']') as list_avg_ip
FROM
  `talking.train_test3`
WHERE
  click_id is null
group by
  ip

-- dmt_test
SELECT
*
FROM
(
SELECT
  ip,
  concat('[', STRING_AGG(cast(click_id as string) order by click_time), ']') as flg,
  concat('[', STRING_AGG(CASE WHEN click_id is not null THEN cast(click_id as string) ELSE '-1' END order by click_time), ']') as list_click_id,
  concat('[', STRING_AGG(CASE WHEN app is not null THEN cast(app as string) ELSE '-1' END order by click_time), ']') as list_app,
  concat('[', STRING_AGG(CASE WHEN device is not null THEN cast(device as string) ELSE '-1' END order by click_time), ']') as list_device,
  concat('[', STRING_AGG(CASE WHEN os is not null THEN cast(os as string) ELSE '-1' END order by click_time), ']') as list_os,
  concat('[', STRING_AGG(CASE WHEN channel is not null THEN cast(channel as string) ELSE '-1' END order by click_time), ']') as list_ch,
  concat('[', STRING_AGG(CASE WHEN timediff is not null THEN cast(timediff as string) ELSE '-1' END order by click_time), ']') as list_timediff,
  concat('[', STRING_AGG(CASE WHEN hour is not null THEN cast(hour as string) ELSE '-1' END order by click_time), ']') as list_hour,
  concat('[', STRING_AGG(CASE WHEN sum_attr is not null THEN cast(sum_attr as string) ELSE '-1' END order by click_time), ']') as list_sum_attr,
  concat('[', STRING_AGG(CASE WHEN last_attr is not null THEN cast(last_attr as string) ELSE '-1' END order by click_time), ']') as list_attr,
  concat('[', STRING_AGG(CASE WHEN avg_ip is not null THEN cast(avg_ip as string) ELSE '-1' END order by click_time), ']') as list_avg_ip
FROM
  `talking.train_test3`
group by
  ip
)
WHERE
  flg is not null


  SELECT
click_id,
ip,
sum_attr, last_attr, cnt_ip,
app,
LAG(app, 1) OVER(partition by ip order by click_time) app_1,
LAG(app, 2) OVER(partition by ip order by click_time) app_2,
LAG(app, 3) OVER(partition by ip order by click_time) app_3,
LAG(app, 4) OVER(partition by ip order by click_time) app_4,
device,
LAG(device, 1) OVER(partition by ip order by click_time) device_1,
LAG(device, 2) OVER(partition by ip order by click_time) device_2,
LAG(device, 3) OVER(partition by ip order by click_time) device_3,
LAG(device, 4) OVER(partition by ip order by click_time) device_4,
os,
LAG(os, 1) OVER(partition by ip order by click_time) os_1,
LAG(os, 2) OVER(partition by ip order by click_time) os_2,
LAG(os, 3) OVER(partition by ip order by click_time) os_3,
LAG(os, 4) OVER(partition by ip order by click_time) os_4,
channel,
LAG(channel, 1) OVER(partition by ip order by click_time) channel_1,
LAG(channel, 2) OVER(partition by ip order by click_time) channel_2,
LAG(channel, 3) OVER(partition by ip order by click_time) channel_3,
LAG(channel, 4) OVER(partition by ip order by click_time) channel_4,
is_attributed,
LAG(is_attributed, 1) OVER(partition by ip order by click_time) is_attributed_1,
LAG(is_attributed, 2) OVER(partition by ip order by click_time) is_attributed_2,
LAG(is_attributed, 3) OVER(partition by ip order by click_time) is_attributed_3,
LAG(is_attributed, 4) OVER(partition by ip order by click_time) is_attributed_4,
LAG(is_attributed, 5) OVER(partition by ip order by click_time) is_attributed_5,
hour,
LAG(hour, 1) OVER(partition by ip order by click_time) hour_1,
LAG(hour, 2) OVER(partition by ip order by click_time) hour_2,
LAG(hour, 3) OVER(partition by ip order by click_time) hour_3,
LAG(hour, 4) OVER(partition by ip order by click_time) hour_4,
avg_app,
LAG(avg_app, 1) OVER(partition by ip order by click_time) avg_app_1,
LAG(avg_app, 2) OVER(partition by ip order by click_time) avg_app_2,
LAG(avg_app, 3) OVER(partition by ip order by click_time) avg_app_3,
LAG(avg_app, 4) OVER(partition by ip order by click_time) avg_app_4,
avg_device,
LAG(avg_device, 1) OVER(partition by ip order by click_time) avg_device_1,
LAG(avg_device, 2) OVER(partition by ip order by click_time) avg_device_2,
LAG(avg_device, 3) OVER(partition by ip order by click_time) avg_device_3,
LAG(avg_device, 4) OVER(partition by ip order by click_time) avg_device_4,
avg_os,
LAG(avg_os, 1) OVER(partition by ip order by click_time) avg_os_1,
LAG(avg_os, 2) OVER(partition by ip order by click_time) avg_os_2,
LAG(avg_os, 3) OVER(partition by ip order by click_time) avg_os_3,
LAG(avg_os, 4) OVER(partition by ip order by click_time) avg_os_4,
avg_channel,
LAG(avg_channel, 1) OVER(partition by ip order by click_time) avg_channel_1,
LAG(avg_channel, 2) OVER(partition by ip order by click_time) avg_channel_2,
LAG(avg_channel, 3) OVER(partition by ip order by click_time) avg_channel_3,
LAG(avg_channel, 4) OVER(partition by ip order by click_time) avg_channel_4,
avg_day,
LAG(avg_day, 1) OVER(partition by ip order by click_time) avg_day_1,
LAG(avg_day, 2) OVER(partition by ip order by click_time) avg_day_2,
LAG(avg_day, 3) OVER(partition by ip order by click_time) avg_day_3,
LAG(avg_day, 4) OVER(partition by ip order by click_time) avg_day_4,
avg_hour,
LAG(avg_hour, 1) OVER(partition by ip order by click_time) avg_hour_1,
LAG(avg_hour, 2) OVER(partition by ip order by click_time) avg_hour_2,
LAG(avg_hour, 3) OVER(partition by ip order by click_time) avg_hour_3,
LAG(avg_hour, 4) OVER(partition by ip order by click_time) avg_hour_4,
avg_ipdayhour,
LAG(avg_ipdayhour, 1) OVER(partition by ip order by click_time) avg_ipdayhour_1,
LAG(avg_ipdayhour, 2) OVER(partition by ip order by click_time) avg_ipdayhour_2,
LAG(avg_ipdayhour, 3) OVER(partition by ip order by click_time) avg_ipdayhour_3,
LAG(avg_ipdayhour, 4) OVER(partition by ip order by click_time) avg_ipdayhour_4,
avg_ip,
LAG(avg_ip, 1) OVER(partition by ip order by click_time) avg_ip_1,
LAG(avg_ip, 2) OVER(partition by ip order by click_time) avg_ip_2,
LAG(avg_ip, 3) OVER(partition by ip order by click_time) avg_ip_3,
LAG(avg_ip, 4) OVER(partition by ip order by click_time) avg_ip_4,
sum_ip,
LAG(sum_ip, 1) OVER(partition by ip order by click_time) sum_ip_1,
LAG(sum_ip, 2) OVER(partition by ip order by click_time) sum_ip_2,
LAG(sum_ip, 3) OVER(partition by ip order by click_time) sum_ip_3,
LAG(sum_ip, 4) OVER(partition by ip order by click_time) sum_ip_4
FROM
`talking.train_test3`
WHERE
  click_id is null AND
  click_time <= '2017-11-08 16:00:00'


  SELECT
click_id,
ip,
sum_attr, last_attr, cnt_ip,
app,
LAG(app, 1) OVER(partition by ip order by click_time) app_1,
LAG(app, 2) OVER(partition by ip order by click_time) app_2,
LAG(app, 3) OVER(partition by ip order by click_time) app_3,
LAG(app, 4) OVER(partition by ip order by click_time) app_4,
device,
LAG(device, 1) OVER(partition by ip order by click_time) device_1,
LAG(device, 2) OVER(partition by ip order by click_time) device_2,
LAG(device, 3) OVER(partition by ip order by click_time) device_3,
LAG(device, 4) OVER(partition by ip order by click_time) device_4,
os,
LAG(os, 1) OVER(partition by ip order by click_time) os_1,
LAG(os, 2) OVER(partition by ip order by click_time) os_2,
LAG(os, 3) OVER(partition by ip order by click_time) os_3,
LAG(os, 4) OVER(partition by ip order by click_time) os_4,
channel,
LAG(channel, 1) OVER(partition by ip order by click_time) channel_1,
LAG(channel, 2) OVER(partition by ip order by click_time) channel_2,
LAG(channel, 3) OVER(partition by ip order by click_time) channel_3,
LAG(channel, 4) OVER(partition by ip order by click_time) channel_4,
is_attributed,
LAG(is_attributed, 1) OVER(partition by ip order by click_time) is_attributed_1,
LAG(is_attributed, 2) OVER(partition by ip order by click_time) is_attributed_2,
LAG(is_attributed, 3) OVER(partition by ip order by click_time) is_attributed_3,
LAG(is_attributed, 4) OVER(partition by ip order by click_time) is_attributed_4,
LAG(is_attributed, 5) OVER(partition by ip order by click_time) is_attributed_5,
hour,
LAG(hour, 1) OVER(partition by ip order by click_time) hour_1,
LAG(hour, 2) OVER(partition by ip order by click_time) hour_2,
LAG(hour, 3) OVER(partition by ip order by click_time) hour_3,
LAG(hour, 4) OVER(partition by ip order by click_time) hour_4,
avg_app,
LAG(avg_app, 1) OVER(partition by ip order by click_time) avg_app_1,
LAG(avg_app, 2) OVER(partition by ip order by click_time) avg_app_2,
LAG(avg_app, 3) OVER(partition by ip order by click_time) avg_app_3,
LAG(avg_app, 4) OVER(partition by ip order by click_time) avg_app_4,
avg_device,
LAG(avg_device, 1) OVER(partition by ip order by click_time) avg_device_1,
LAG(avg_device, 2) OVER(partition by ip order by click_time) avg_device_2,
LAG(avg_device, 3) OVER(partition by ip order by click_time) avg_device_3,
LAG(avg_device, 4) OVER(partition by ip order by click_time) avg_device_4,
avg_os,
LAG(avg_os, 1) OVER(partition by ip order by click_time) avg_os_1,
LAG(avg_os, 2) OVER(partition by ip order by click_time) avg_os_2,
LAG(avg_os, 3) OVER(partition by ip order by click_time) avg_os_3,
LAG(avg_os, 4) OVER(partition by ip order by click_time) avg_os_4,
avg_channel,
LAG(avg_channel, 1) OVER(partition by ip order by click_time) avg_channel_1,
LAG(avg_channel, 2) OVER(partition by ip order by click_time) avg_channel_2,
LAG(avg_channel, 3) OVER(partition by ip order by click_time) avg_channel_3,
LAG(avg_channel, 4) OVER(partition by ip order by click_time) avg_channel_4,
avg_day,
LAG(avg_day, 1) OVER(partition by ip order by click_time) avg_day_1,
LAG(avg_day, 2) OVER(partition by ip order by click_time) avg_day_2,
LAG(avg_day, 3) OVER(partition by ip order by click_time) avg_day_3,
LAG(avg_day, 4) OVER(partition by ip order by click_time) avg_day_4,
avg_hour,
LAG(avg_hour, 1) OVER(partition by ip order by click_time) avg_hour_1,
LAG(avg_hour, 2) OVER(partition by ip order by click_time) avg_hour_2,
LAG(avg_hour, 3) OVER(partition by ip order by click_time) avg_hour_3,
LAG(avg_hour, 4) OVER(partition by ip order by click_time) avg_hour_4,
avg_ipdayhour,
LAG(avg_ipdayhour, 1) OVER(partition by ip order by click_time) avg_ipdayhour_1,
LAG(avg_ipdayhour, 2) OVER(partition by ip order by click_time) avg_ipdayhour_2,
LAG(avg_ipdayhour, 3) OVER(partition by ip order by click_time) avg_ipdayhour_3,
LAG(avg_ipdayhour, 4) OVER(partition by ip order by click_time) avg_ipdayhour_4,
avg_ip,
LAG(avg_ip, 1) OVER(partition by ip order by click_time) avg_ip_1,
LAG(avg_ip, 2) OVER(partition by ip order by click_time) avg_ip_2,
LAG(avg_ip, 3) OVER(partition by ip order by click_time) avg_ip_3,
LAG(avg_ip, 4) OVER(partition by ip order by click_time) avg_ip_4,
sum_ip,
LAG(sum_ip, 1) OVER(partition by ip order by click_time) sum_ip_1,
LAG(sum_ip, 2) OVER(partition by ip order by click_time) sum_ip_2,
LAG(sum_ip, 3) OVER(partition by ip order by click_time) sum_ip_3,
LAG(sum_ip, 4) OVER(partition by ip order by click_time) sum_ip_4
FROM
`talking.train_test3`
WHERE
  click_id is null AND
  click_time >= '2017-11-09 04:00:00' AND
  click_time <= '2017-11-09 15:00:00'


  SELECT
click_id,
ip,
sum_attr, last_attr, cnt_ip,
app,
LAG(app, 1) OVER(partition by ip order by click_time) app_1,
LAG(app, 2) OVER(partition by ip order by click_time) app_2,
LAG(app, 3) OVER(partition by ip order by click_time) app_3,
LAG(app, 4) OVER(partition by ip order by click_time) app_4,
device,
LAG(device, 1) OVER(partition by ip order by click_time) device_1,
LAG(device, 2) OVER(partition by ip order by click_time) device_2,
LAG(device, 3) OVER(partition by ip order by click_time) device_3,
LAG(device, 4) OVER(partition by ip order by click_time) device_4,
os,
LAG(os, 1) OVER(partition by ip order by click_time) os_1,
LAG(os, 2) OVER(partition by ip order by click_time) os_2,
LAG(os, 3) OVER(partition by ip order by click_time) os_3,
LAG(os, 4) OVER(partition by ip order by click_time) os_4,
channel,
LAG(channel, 1) OVER(partition by ip order by click_time) channel_1,
LAG(channel, 2) OVER(partition by ip order by click_time) channel_2,
LAG(channel, 3) OVER(partition by ip order by click_time) channel_3,
LAG(channel, 4) OVER(partition by ip order by click_time) channel_4,
is_attributed,
LAG(is_attributed, 1) OVER(partition by ip order by click_time) is_attributed_1,
LAG(is_attributed, 2) OVER(partition by ip order by click_time) is_attributed_2,
LAG(is_attributed, 3) OVER(partition by ip order by click_time) is_attributed_3,
LAG(is_attributed, 4) OVER(partition by ip order by click_time) is_attributed_4,
LAG(is_attributed, 5) OVER(partition by ip order by click_time) is_attributed_5,
hour,
LAG(hour, 1) OVER(partition by ip order by click_time) hour_1,
LAG(hour, 2) OVER(partition by ip order by click_time) hour_2,
LAG(hour, 3) OVER(partition by ip order by click_time) hour_3,
LAG(hour, 4) OVER(partition by ip order by click_time) hour_4,
avg_app,
LAG(avg_app, 1) OVER(partition by ip order by click_time) avg_app_1,
LAG(avg_app, 2) OVER(partition by ip order by click_time) avg_app_2,
LAG(avg_app, 3) OVER(partition by ip order by click_time) avg_app_3,
LAG(avg_app, 4) OVER(partition by ip order by click_time) avg_app_4,
avg_device,
LAG(avg_device, 1) OVER(partition by ip order by click_time) avg_device_1,
LAG(avg_device, 2) OVER(partition by ip order by click_time) avg_device_2,
LAG(avg_device, 3) OVER(partition by ip order by click_time) avg_device_3,
LAG(avg_device, 4) OVER(partition by ip order by click_time) avg_device_4,
avg_os,
LAG(avg_os, 1) OVER(partition by ip order by click_time) avg_os_1,
LAG(avg_os, 2) OVER(partition by ip order by click_time) avg_os_2,
LAG(avg_os, 3) OVER(partition by ip order by click_time) avg_os_3,
LAG(avg_os, 4) OVER(partition by ip order by click_time) avg_os_4,
avg_channel,
LAG(avg_channel, 1) OVER(partition by ip order by click_time) avg_channel_1,
LAG(avg_channel, 2) OVER(partition by ip order by click_time) avg_channel_2,
LAG(avg_channel, 3) OVER(partition by ip order by click_time) avg_channel_3,
LAG(avg_channel, 4) OVER(partition by ip order by click_time) avg_channel_4,
avg_day,
LAG(avg_day, 1) OVER(partition by ip order by click_time) avg_day_1,
LAG(avg_day, 2) OVER(partition by ip order by click_time) avg_day_2,
LAG(avg_day, 3) OVER(partition by ip order by click_time) avg_day_3,
LAG(avg_day, 4) OVER(partition by ip order by click_time) avg_day_4,
avg_hour,
LAG(avg_hour, 1) OVER(partition by ip order by click_time) avg_hour_1,
LAG(avg_hour, 2) OVER(partition by ip order by click_time) avg_hour_2,
LAG(avg_hour, 3) OVER(partition by ip order by click_time) avg_hour_3,
LAG(avg_hour, 4) OVER(partition by ip order by click_time) avg_hour_4,
avg_ipdayhour,
LAG(avg_ipdayhour, 1) OVER(partition by ip order by click_time) avg_ipdayhour_1,
LAG(avg_ipdayhour, 2) OVER(partition by ip order by click_time) avg_ipdayhour_2,
LAG(avg_ipdayhour, 3) OVER(partition by ip order by click_time) avg_ipdayhour_3,
LAG(avg_ipdayhour, 4) OVER(partition by ip order by click_time) avg_ipdayhour_4,
avg_ip,
LAG(avg_ip, 1) OVER(partition by ip order by click_time) avg_ip_1,
LAG(avg_ip, 2) OVER(partition by ip order by click_time) avg_ip_2,
LAG(avg_ip, 3) OVER(partition by ip order by click_time) avg_ip_3,
LAG(avg_ip, 4) OVER(partition by ip order by click_time) avg_ip_4,
sum_ip,
LAG(sum_ip, 1) OVER(partition by ip order by click_time) sum_ip_1,
LAG(sum_ip, 2) OVER(partition by ip order by click_time) sum_ip_2,
LAG(sum_ip, 3) OVER(partition by ip order by click_time) sum_ip_3,
LAG(sum_ip, 4) OVER(partition by ip order by click_time) sum_ip_4
FROM
`talking.train_test3`
WHERE
click_id is not null
