-- sql/24_dim_channel.sql
INSERT INTO warehouse.dim_channel
    (channel_key, channel_name, channel_type)
SELECT
    ROW_NUMBER() OVER (ORDER BY channel)           AS channel_key,
    channel                                        AS channel_name,
    CASE channel
        WHEN 'Online'  THEN 'Digital'
        WHEN 'Store'   THEN 'Physical'
        WHEN 'Partner' THEN 'Indirect'
        ELSE 'Unknown'
    END                                            AS channel_type
FROM (SELECT DISTINCT channel FROM staging.orders) t;
