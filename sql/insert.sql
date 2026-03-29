SET execution.runtime-mode = batch;
insert into events_vortex select * from datagen_source;
select * from events_vortex where user_id = 40;
insert into events_parquet select * from datagen_source;
select * from events_parquet where user_id = 40;